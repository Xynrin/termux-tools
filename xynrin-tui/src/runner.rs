// runner.rs - 启动 bash 子进程，把 stdout/stderr 行通过 mpsc 推回主线程
// Spawn bash subcommand; pipe stdout/stderr lines through mpsc to main thread.

use std::io::{BufRead, BufReader};
use std::process::{Child, Command, Stdio};
use std::sync::mpsc::{self, Receiver, Sender};
use std::thread;

use crate::i18n::Lang;
use crate::log_event::{parse_line, LogLine, Level};

pub enum RunMsg {
    Line(LogLine),
    #[allow(dead_code)]
    Done(i32),
}

pub struct Runner {
    pub rx: Receiver<RunMsg>,
    child: Child,
}

impl Runner {
    pub fn try_kill(&mut self) {
        // 先把整个进程组干掉（pkg/curl/git 子进程都收 SIGTERM），
        // 1.5s 后还活着再 SIGKILL —— 防止 ESC 后 CPU 持续被占
        // Kill the whole process group first (so pkg/curl/git children
        // get SIGTERM too), upgrade to SIGKILL after 1.5s if still alive.
        // This stops the "Esc leaves zombies eating CPU" leak on phones.
        #[cfg(unix)]
        unsafe {
            let pid = self.child.id() as i32;
            libc::kill(-pid, libc::SIGTERM);
            for _ in 0..15 {
                std::thread::sleep(std::time::Duration::from_millis(100));
                if libc::kill(-pid, 0) != 0 { return; }
            }
            libc::kill(-pid, libc::SIGKILL);
        }
        #[cfg(not(unix))]
        let _ = self.child.kill();
    }
}

// 流式动作：捕获 stdout/stderr，通过 mpsc 推回 TUI
// Streaming action: capture stdout/stderr, push lines back via mpsc.
pub fn spawn(args: &[&str], lang: Lang) -> std::io::Result<Runner> {
    let bash_path = locate_bash_main();
    let mut cmd = Command::new("bash");
    cmd.arg(&bash_path);
    for a in args { cmd.arg(a); }
    cmd.env("LANG", match lang { Lang::Zh => "zh_CN.UTF-8", Lang::En => "en_US.UTF-8" });
    cmd.stdout(Stdio::piped());
    cmd.stderr(Stdio::piped());
    cmd.stdin(Stdio::null());

    // 让 bash 跑在新进程组里：Esc 杀整个组，不留 pkg/curl/git 残留子进程
    // Put bash in its own process group so Esc kills the whole tree
    // (no leftover pkg/curl/git children chewing CPU on the phone).
    #[cfg(unix)]
    {
        use std::os::unix::process::CommandExt;
        unsafe {
            cmd.pre_exec(|| {
                libc::setsid();
                Ok(())
            });
        }
    }

    let mut child = cmd.spawn()?;
    let stdout = child.stdout.take().expect("piped");
    let stderr = child.stderr.take().expect("piped");

    let (tx, rx) = mpsc::channel::<RunMsg>();
    pump(stdout, tx.clone(), false);
    pump(stderr, tx.clone(), true);

    let id = child.id();
    thread::spawn(move || {
        loop {
            #[cfg(unix)]
            {
                if !std::path::Path::new(&format!("/proc/{}", id)).exists() { break; }
            }
            std::thread::sleep(std::time::Duration::from_millis(100));
        }
        let _ = tx.send(RunMsg::Done(0));
    });

    Ok(Runner { rx, child })
}

// 交互式动作：直接继承 stdio，用真实 TTY 跑 fzf/read
// Interactive action: inherit stdio so fzf/read get a real TTY.
// 调用前由 main loop 负责挂起 ratatui，结束后恢复
// The main loop is responsible for suspending ratatui before this and
// restoring afterwards.
pub fn run_interactive(args: &[&str], lang: Lang) -> std::io::Result<i32> {
    let bash_path = locate_bash_main();
    let mut cmd = Command::new("bash");
    cmd.arg(&bash_path);
    for a in args { cmd.arg(a); }
    cmd.env("LANG", match lang { Lang::Zh => "zh_CN.UTF-8", Lang::En => "en_US.UTF-8" });
    cmd.stdin(Stdio::inherit());
    cmd.stdout(Stdio::inherit());
    cmd.stderr(Stdio::inherit());
    let status = cmd.status()?;
    Ok(status.code().unwrap_or(-1))
}

fn pump<R: std::io::Read + Send + 'static>(reader: R, tx: Sender<RunMsg>, is_stderr: bool) {
    thread::spawn(move || {
        let buf = BufReader::new(reader);
        for line in buf.lines().map_while(Result::ok) {
            let mut ev = parse_line(&line);
            if is_stderr && !line.starts_with("::") {
                ev.level = Level::Warn;
            }
            if tx.send(RunMsg::Line(ev)).is_err() { break; }
        }
    });
}

fn locate_bash_main() -> String {
    if let Ok(exe) = std::env::current_exe() {
        if let Some(dir) = exe.parent() {
            let p = dir.join("xynrin-bash");
            if p.exists() { return p.to_string_lossy().into_owned(); }
        }
    }
    if let Ok(out) = Command::new("which").arg("xynrin-bash").output() {
        if out.status.success() {
            return String::from_utf8_lossy(&out.stdout).trim().to_string();
        }
    }
    "/data/data/com.termux/files/usr/bin/xynrin-bash".into()
}

