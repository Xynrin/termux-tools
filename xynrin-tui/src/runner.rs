// runner.rs - 启动 bash 子进程，把 stdout/stderr 行通过 mpsc 推回主线程
// Spawn bash subcommand; pipe stdout/stderr lines through mpsc to main thread.

use std::io::{BufRead, BufReader};
use std::process::{Command, Stdio};
use std::sync::mpsc::{self, Receiver, Sender};
use std::thread;

use crate::i18n::Lang;
use crate::log_event::{parse_line, LogLine, Level};

pub enum RunMsg {
    Line(LogLine),
    Done(i32),
}

pub struct Runner {
    pub rx: Receiver<RunMsg>,
    // 子进程在等待线程里被 wait 阻塞，主线程只保留 pgid 用于 try_kill
    // The child is owned by the wait-thread; main keeps just the pgid for try_kill.
    pgid: i32,
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
            let pid = self.pgid;
            if pid <= 0 { return; }
            libc::kill(-pid, libc::SIGTERM);
            for _ in 0..15 {
                std::thread::sleep(std::time::Duration::from_millis(100));
                if libc::kill(-pid, 0) != 0 { return; }
            }
            libc::kill(-pid, libc::SIGKILL);
        }
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

    // pgid 在 setsid 之后等于 child.id()，主线程留它给 try_kill 用
    // pgid equals child.id() after setsid; main thread keeps it for try_kill
    let pgid = child.id() as i32;

    // 后台线程负责 wait —— child.wait() 阻塞直到进程退出，拿到真实 exit code
    // Background thread owns the Child and blocks on wait() to capture real exit code.
    // 之前用 /proc/<pid> 轮询，永远只回 Done(0)，把失败包装成"成功"误导用户。
    // Previous /proc poll always returned Done(0), masking real failures.
    thread::spawn(move || {
        let code = match child.wait() {
            Ok(status) => status.code().unwrap_or_else(|| {
                #[cfg(unix)]
                {
                    use std::os::unix::process::ExitStatusExt;
                    status.signal().map(|s| 128 + s).unwrap_or(-1)
                }
                #[cfg(not(unix))]
                { -1 }
            }),
            Err(_) => -1,
        };
        let _ = tx.send(RunMsg::Done(code));
    });

    Ok(Runner { rx, pgid })
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
            // 处理 apt/pkg 的回车进度条：取最后一段，避免 4096 行缓冲被进度条挤爆
            // Handle apt/pkg \r progress bars: keep only the last segment so
            // the 4096-line ring buffer isn't flooded by carriage-return spam.
            let cleaned = line.rsplit('\r').next().unwrap_or(&line).to_string();
            if cleaned.is_empty() { continue; }
            let mut ev = parse_line(&cleaned);
            if is_stderr && !cleaned.starts_with("::") {
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

