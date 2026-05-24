// ui/mod.rs - 响应式 layout
// Responsive layout entry point.

pub mod banner;
pub mod menu;
pub mod log_panel;
pub mod notes_panel;
pub mod footer;
pub mod dashboard;

use ratatui::{
    layout::{Constraint, Direction, Layout, Rect},
    Frame,
};

use crate::app::{App, Screen};

pub fn draw(f: &mut Frame, app: &mut App) {
    let area = f.area();
    let banner_h: u16 = if area.height >= 28 { 9 }
                        else if area.height >= 18 { 1 }
                        else { 0 };
    let footer_h: u16 = if area.height >= 18 { 2 } else { 1 };

    let mut constraints = vec![];
    if banner_h > 0 { constraints.push(Constraint::Length(banner_h)); }
    constraints.push(Constraint::Min(5));
    constraints.push(Constraint::Length(footer_h));

    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints(constraints)
        .split(area);

    let mut idx = 0;
    if banner_h > 0 {
        banner::draw(f, chunks[idx], banner_h);
        idx += 1;
    }
    let body = chunks[idx];
    idx += 1;
    let footer_area = chunks[idx];

    match &app.screen {
        Screen::Menu => draw_menu_only(f, body, app),
        Screen::Notes { scroll } => notes_panel::draw(f, body, app, *scroll),
        Screen::UpdateConfirm { remote_version } => draw_confirm(f, body, app, remote_version),
        Screen::Running { .. } => draw_split(f, body, app),
        Screen::Bootstrap { .. } => draw_log_full(f, body, app),
        Screen::Dashboard => dashboard::draw(f, body, app),
    }

    footer::draw(f, footer_area, app);
}

fn draw_menu_only(f: &mut Frame, area: Rect, app: &mut App) {
    if area.width < 60 {
        menu::draw(f, area, app);
    } else {
        let chunks = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([Constraint::Length(36), Constraint::Min(20)])
            .split(area);
        menu::draw(f, chunks[0], app);
        log_panel::draw_empty(f, chunks[1], app);
    }
}

fn draw_split(f: &mut Frame, area: Rect, app: &mut App) {
    if area.width < 60 {
        // 窄屏纵向堆叠 / narrow: stack vertically
        let chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([Constraint::Length(10), Constraint::Min(5)])
            .split(area);
        menu::draw(f, chunks[0], app);
        log_panel::draw(f, chunks[1], app);
    } else {
        let menu_w = if area.width >= 100 { area.width * 30 / 100 } else { 30 };
        let chunks = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([Constraint::Length(menu_w), Constraint::Min(20)])
            .split(area);
        menu::draw(f, chunks[0], app);
        log_panel::draw(f, chunks[1], app);
    }
}

fn draw_log_full(f: &mut Frame, area: Rect, app: &App) {
    log_panel::draw(f, area, app);
}

fn draw_confirm(f: &mut Frame, area: Rect, app: &App, remote: &str) {
    use ratatui::layout::Constraint::*;
    if area.width < 60 || area.height < 12 {
        notes_panel::draw_confirm_compact(f, area, app, remote);
        return;
    }
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Min(5), Length(5)])
        .split(area);
    notes_panel::draw_for_confirm(f, chunks[0], app, remote);
    notes_panel::draw_confirm_bar(f, chunks[1], app, remote);
}
