// ui/log_panel.rs - 流式日志面板（语义着色、滚动、高亮报错）
// Streaming log panel: semantic colors, scrolling, error highlight.

use ratatui::{
    layout::Rect,
    style::{Color, Style, Stylize},
    text::{Line, Span},
    widgets::{Block, BorderType, Borders, Paragraph, Wrap},
    Frame,
};

use crate::app::App;

pub fn draw(f: &mut Frame, area: Rect, app: &App) {
    let base = app.i18n.t("running.title");
    let scrolling = app.i18n.t("running.scrolling");
    let title = if app.log_scroll.is_some() {
        format!(" {} [{}] ", base, scrolling)
    } else {
        format!(" {} ", base)
    };
    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::default().fg(if app.focus_log { Color::Cyan } else { Color::DarkGray }))
        .title(Span::styled(title, Style::default().fg(Color::Yellow).bold()));

    let inner_h = area.height.saturating_sub(2) as usize;

    // 跟随尾部 / Follow tail by default.
    let total = app.log.len();
    let end = app.log_scroll.map(|s| (s + 1).min(total)).unwrap_or(total);
    let start = end.saturating_sub(inner_h);

    let lines: Vec<Line> = app.log.iter().skip(start).take(end - start).map(|l| {
        Line::from(vec![
            Span::styled(l.level.icon(), Style::default().fg(l.level.color()).bold()),
            Span::styled(l.text.clone(), Style::default().fg(l.level.color())),
        ])
    }).collect();

    let p = Paragraph::new(lines).block(block).wrap(Wrap { trim: false });
    f.render_widget(p, area);
}

pub fn draw_empty(f: &mut Frame, area: Rect, app: &App) {
    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::default().fg(Color::DarkGray))
        .title(Span::styled(format!(" {} ", app.i18n.t("running.title")),
            Style::default().fg(Color::DarkGray).bold()));
    let p = Paragraph::new(vec![
        Line::from(""),
        Line::from(Span::styled(app.i18n.t("running.empty").to_string(),
            Style::default().fg(Color::DarkGray))),
    ]).block(block).wrap(Wrap { trim: true });
    f.render_widget(p, area);
}
