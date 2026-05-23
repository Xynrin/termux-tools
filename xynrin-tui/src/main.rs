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

    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let res = run(&mut terminal, bootstrap, show_notes, update_mode);

    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen, DisableMouseCapture)?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        eprintln!("error: {err}");
    }
    Ok(())
}

fn run<B: ratatui::backend::Backend + io::Write>(
    terminal: &mut Terminal<B>,
    bootstrap: bool,
    show_notes: bool,
    update_mode: bool,
) -> io::Result<()> {
    let mut app = App::new(bootstrap, show_notes, update_mode);
    while !app.should_quit {
        terminal.draw(|f| ui::draw(f, &mut app))?;
        app.tick()?;

        // 交互式动作：挂起 ratatui，把真终端交给 bash，跑完恢复
        // Interactive action: suspend ratatui, hand the real TTY to bash, restore after.
        if let Some(args) = app.pending_interactive.take() {
            suspend(terminal)?;
            let _ = runner::run_interactive(args, app.lang);
            resume(terminal)?;
            // 语言切换后重建 i18n（bash 端写入了 .lang_pref）
            // After a language switch the bash side has written .lang_pref, rebuild i18n.
            let new_lang = i18n::Lang::detect();
            if new_lang != app.lang {
                app.lang = new_lang;
                app.i18n = i18n::I18n::new(new_lang);
            }
        }
    }
    Ok(())
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
