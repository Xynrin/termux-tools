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
    for (i, a) in raw.iter().enumerate() {
        match a.as_str() {
            "--bootstrap" => bootstrap = true,
            "--show-notes" => show_notes = true,
            "update" => {
                if raw.get(i + 1).map(String::as_str) == Some("--show-notes") {
                    show_notes = true;
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

    let res = run(&mut terminal, bootstrap, show_notes);

    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen, DisableMouseCapture)?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        eprintln!("error: {err}");
    }
    Ok(())
}

fn run<B: ratatui::backend::Backend>(
    terminal: &mut Terminal<B>,
    bootstrap: bool,
    show_notes: bool,
) -> io::Result<()> {
    let mut app = App::new(bootstrap, show_notes);
    while !app.should_quit {
        terminal.draw(|f| ui::draw(f, &mut app))?;
        app.tick()?;
    }
    Ok(())
}
