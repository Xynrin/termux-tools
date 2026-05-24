// main.rs - 终端 setup + CLI 解析 + 主循环
// Terminal setup, CLI parsing, main loop.

mod app;
mod changelog;
mod i18n;
mod log_event;
mod runner;
mod ui;

use std::io;

use crossterm::{
    event::{DisableMouseCapture, EnableMouseCapture},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{backend::CrosstermBackend, Terminal};

use crate::app::App;

fn main() -> io::Result<()> {
    let raw: Vec<String> = std::env::args().skip(1).collect();
    let mut bootstrap = false;
    let mut show_notes = false;
    let mut update_mode = false;
    for (i, a) in raw.iter().enumerate() {
        match a.as_str() {
            "--bootstrap" => bootstrap = true,
            "--show-notes" => show_notes = true,
            "update" => {
                if raw.get(i + 1).map(String::as_str) == Some("--show-notes") {
                    show_notes = true;
                } else {
                    update_mode = true;
                }
            }
            "version" | "-v" | "--version" => {
                println!("xynrin v{}", env!("CARGO_PKG_VERSION"));
                return Ok(());
            }
            "help" | "-h" | "--help" => {
                println!("Usage: xynrin [menu|update [--show-notes]|--bootstrap|version|help]");
                return Ok(());
            }
            _ => {}
        }
    }

    // 进入主菜单前静默检查新版本：有则进 update_mode，无则正常进 TUI
    // 但升级刚完成的那次启动跳过 —— 由 XYNRIN_POST_UPGRADE 标记，避免循环
    // Skip the silent check on the post-upgrade launch (marked via env var)
    // so we land in show-notes / menu instead of re-prompting.
    if !bootstrap && !show_notes && !update_mode
        && std::env::var("XYNRIN_POST_UPGRADE").ok().as_deref() != Some("1")
    {
        if silent_update_available() {
            update_mode = true;
        }
    }

    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let res = run(&mut terminal, bootstrap, show_notes, update_mode);
    let restart = res.as_ref().map(|r| *r).unwrap_or(false);

    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen, DisableMouseCapture)?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        eprintln!("error: {err}");
        return Ok(());
    }

    // 升级成功后无感重启 —— exec 替换当前进程，旧 PID 直接消失
    // After upgrade success, exec replaces the process; old PID/memory go away.
    // 同时设 XYNRIN_POST_UPGRADE=1 让新二进制跳过静默检查、直接进 show-notes
    if restart {
        #[cfg(unix)]
        {
            use std::os::unix::process::CommandExt;
            use std::process::Command;
            let exe = std::env::current_exe()
                .unwrap_or_else(|_| std::path::PathBuf::from("xynrin"));
            let _err = Command::new(exe)
                .arg("update")
                .arg("--show-notes")
                .env("XYNRIN_POST_UPGRADE", "1")
                .exec();
        }
    }
    Ok(())
}

fn run<B: ratatui::backend::Backend + io::Write>(
    terminal: &mut Terminal<B>,
    bootstrap: bool,
    show_notes: bool,
    update_mode: bool,
) -> io::Result<bool> {
    let mut app = App::new(bootstrap, show_notes, update_mode);
    while !app.should_quit {
        terminal.draw(|f| ui::draw(f, &mut app))?;
        app.tick()?;

        if let Some(args) = app.pending_interactive.take() {
            suspend(terminal)?;
            let _ = runner::run_interactive(args, app.lang);
            resume(terminal)?;
            let new_lang = i18n::Lang::detect();
            if new_lang != app.lang {
                app.lang = new_lang;
                app.i18n = i18n::I18n::new(new_lang);
            }
        }
    }
    Ok(app.restart_after_quit)
}

// 启动前静默对比 git ls-remote tag 与本地版本：完全静默，3 秒超时，
// 失败/无网络一律视作"无更新"，不打扰用户
// Pre-launch silent compare: git ls-remote vs local version. 3-second
// timeout, any failure / no-network counts as "no update" — never blocks.
fn silent_update_available() -> bool {
    use std::process::{Command, Stdio};
    use std::time::Duration;
    let local = env!("CARGO_PKG_VERSION").trim().to_string();
    let mut child = match Command::new("timeout")
        .arg("3")
        .arg("git")
        .arg("ls-remote")
        .arg("--tags")
        .arg("--refs")
        .arg("https://github.com/Xynrin/termux-tools")
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
    {
        Ok(c) => c,
        Err(_) => return false,
    };
    let _ = child.wait_timeout(Duration::from_secs(3));
    let out = match child.wait_with_output() {
        Ok(o) if o.status.success() => o.stdout,
        _ => return false,
    };
    let text = String::from_utf8_lossy(&out);
    let mut latest: Option<(u32, u32, u32)> = None;
    for line in text.lines() {
        if let Some(tag) = line.split("refs/tags/v").nth(1) {
            if let Some(v) = parse_semver(tag.trim()) {
                if latest.map(|cur| v > cur).unwrap_or(true) {
                    latest = Some(v);
                }
            }
        }
    }
    let local_v = match parse_semver(&local) { Some(v) => v, None => return false };
    matches!(latest, Some(v) if v > local_v)
}

fn parse_semver(s: &str) -> Option<(u32, u32, u32)> {
    let mut parts = s.split('.');
    let a = parts.next()?.parse().ok()?;
    let b = parts.next()?.parse().ok()?;
    let c = parts.next()?.split(|ch: char| !ch.is_ascii_digit()).next()?.parse().ok()?;
    Some((a, b, c))
}

trait WaitTimeout { fn wait_timeout(&mut self, _: std::time::Duration) -> std::io::Result<()>; }
impl WaitTimeout for std::process::Child {
    fn wait_timeout(&mut self, d: std::time::Duration) -> std::io::Result<()> {
        let start = std::time::Instant::now();
        loop {
            match self.try_wait()? {
                Some(_) => return Ok(()),
                None if start.elapsed() >= d => { let _ = self.kill(); return Ok(()); }
                None => std::thread::sleep(std::time::Duration::from_millis(100)),
            }
        }
    }
}

fn suspend<B: ratatui::backend::Backend + io::Write>(terminal: &mut Terminal<B>) -> io::Result<()> {
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen, DisableMouseCapture)?;
    terminal.show_cursor()?;
    Ok(())
}

fn resume<B: ratatui::backend::Backend + io::Write>(terminal: &mut Terminal<B>) -> io::Result<()> {
    enable_raw_mode()?;
    execute!(terminal.backend_mut(), EnterAlternateScreen, EnableMouseCapture)?;
    terminal.clear()?;
    Ok(())
}
