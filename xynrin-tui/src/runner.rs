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
        let _ = self.child.kill();
    }
}

pub fn spawn(args: &[&str], lang: Lang) -> std::io::Result<Runner> {
    let bash_path = locate_bash_main();
    let mut cmd = Command::new("bash");
    cmd.arg(&bash_path);
    for a in args {
        cmd.arg(a);
    }
    cmd.env("LANG", match lang { Lang::Zh => "zh_CN.UTF-8", Lang::En => "en_US.UTF-8" });
    cmd.stdout(Stdio::piped());
    cmd.stderr(Stdio::piped());

    let mut child = cmd.spawn()?;
    let stdout = child.stdout.take().expect("piped");
    let stderr = child.stderr.take().expect("piped");

    let (tx, rx) = mpsc::channel::<RunMsg>();
    pump(stdout, tx.clone(), false);
    pump(stderr, tx.clone(), true);

    // 退出码线程：等 child 结束后发 Done
    // Exit-code thread: send Done after child exits
    let id = child.id();
    thread::spawn(move || {
        // 复用 PID 等死亡：用 waitpid 风格，在 unix 下安全
        // 这里通过文件 /proc/<pid> 是否存在来轮询，简单跨平台
        loop {
            #[cfg(unix)]
            {
                if !std::path::Path::new(&format!("/proc/{}", id)).exists() {
                    break;
                }
            }
            std::thread::sleep(std::time::Duration::from_millis(100));
        }
        let _ = tx.send(RunMsg::Done(0));
    });

    Ok(Runner { rx, child })
}

fn pump<R: std::io::Read + Send + 'static>(reader: R, tx: Sender<RunMsg>, is_stderr: bool) {
    thread::spawn(move || {
        let buf = BufReader::new(reader);
        for line in buf.lines().map_while(Result::ok) {
            let mut ev = parse_line(&line);
            if is_stderr && !line.starts_with("::") {
                ev.level = Level::Warn;
            }
            if tx.send(RunMsg::Line(ev)).is_err() {
                break;
            }
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
