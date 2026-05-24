// ui/footer.rs - 底部提示栏
// Footer hint bar.

use ratatui::{
    layout::{Alignment, Rect},
    style::{Color, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Paragraph},
    Frame,
};

use crate::app::{App, Screen};

pub fn draw(f: &mut Frame, area: Rect, app: &App) {
    let key = match &app.screen {
        Screen::Menu => "hint.menu",
        Screen::Notes { .. } => "hint.notes",
        Screen::UpdateConfirm { .. } => "hint.confirm",
        Screen::Running { .. } | Screen::Bootstrap { .. } => "hint.running",
    };
    let p = Paragraph::new(Line::from(Span::styled(app.i18n.t(key).to_string(),
        Style::default().fg(Color::DarkGray))))
        .alignment(Alignment::Center)
        .block(Block::default()
            .borders(Borders::TOP)
            .border_style(Style::default().fg(Color::DarkGray)));
    f.render_widget(p, area);
}
