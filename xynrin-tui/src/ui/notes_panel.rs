// ui/notes_panel.rs - CHANGELOG 渲染（极简 markdown）+ 更新确认条
// CHANGELOG rendering (minimal markdown) + update confirm bar.

use ratatui::{
    layout::{Alignment, Rect},
    style::{Color, Style, Stylize},
    text::{Line, Span},
    widgets::{Block, BorderType, Borders, Paragraph, Wrap},
    Frame,
};

use crate::app::App;
use crate::changelog;

pub fn draw(f: &mut Frame, area: Rect, app: &App, scroll: u16) {
    let section = changelog::latest();
    render(f, area, app, section.as_ref(), scroll, " 更新日志 ");
}

pub fn draw_for_confirm(f: &mut Frame, area: Rect, app: &App, _remote: &str) {
    let section = changelog::latest();
    render(f, area, app, section.as_ref(), 0, " 当前版本更新日志 ");
}

pub fn draw_confirm_bar(f: &mut Frame, area: Rect, app: &App, remote: &str) {
    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::default().fg(Color::Yellow));
    let lines = vec![
        Line::from(vec![
            Span::styled(format!("→ {} ", app.i18n.t("update.available")),
                Style::default().fg(Color::Yellow).bold()),
            Span::styled(format!("v{}", remote), Style::default().fg(Color::Green).bold()),
        ]),
        Line::from(Span::styled(app.i18n.t("update.show_notes_after").to_string(),
            Style::default().fg(Color::DarkGray))),
        Line::from(vec![
            Span::styled(" [Y] ", Style::default().fg(Color::Black).bg(Color::Green).bold()),
            Span::raw("  "),
            Span::styled(" [N] ", Style::default().fg(Color::Black).bg(Color::Red).bold()),
        ]),
    ];
    f.render_widget(Paragraph::new(lines).alignment(Alignment::Center).block(block), area);
}

pub fn draw_confirm_compact(f: &mut Frame, area: Rect, app: &App, remote: &str) {
    let lines = vec![
        Line::from(""),
        Line::from(Span::styled(format!("{} v{}", app.i18n.t("update.available"), remote),
            Style::default().fg(Color::Yellow).bold())),
        Line::from(""),
        Line::from(Span::styled(app.i18n.t("update.confirm").to_string(),
            Style::default().fg(Color::Cyan))),
    ];
    f.render_widget(Paragraph::new(lines).alignment(Alignment::Center), area);
}

fn render(f: &mut Frame, area: Rect, app: &App, section: Option<&changelog::Section>, scroll: u16, title: &str) {
    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::default().fg(Color::Cyan))
        .title(Span::styled(title.to_string(), Style::default().fg(Color::Yellow).bold()));

    let lines: Vec<Line> = match section {
        Some(s) => {
            let mut out = vec![
                Line::from(vec![
                    Span::styled(format!("v{}", s.version),
                        Style::default().fg(Color::Green).bold()),
                    Span::raw("   "),
                    Span::styled(s.date.clone(), Style::default().fg(Color::DarkGray)),
                ]),
                Line::from(""),
            ];
            for raw in s.body.lines() {
                out.push(format_md_line(raw));
            }
            out
        }
        None => vec![Line::from(Span::styled(app.i18n.t("notes.no_data").to_string(),
            Style::default().fg(Color::DarkGray)))],
    };

    let p = Paragraph::new(lines).block(block).scroll((scroll, 0)).wrap(Wrap { trim: false });
    f.render_widget(p, area);
}

// 极简 markdown：### 标题分级、- 项目符号、**bold** 加粗
// Minimal markdown: ### headings color-coded, - bullets, **bold**.
fn format_md_line(raw: &str) -> Line<'static> {
    let s = raw.trim_end();
    if let Some(t) = s.strip_prefix("### ") {
        let color = match t.trim() {
            "Added"      => Color::Green,
            "Changed"    => Color::Yellow,
            "Fixed"      => Color::Magenta,
            "Removed"    => Color::Red,
            "Breaking"   => Color::Red,
            "Deprecated" => Color::Red,
            "Security"   => Color::Red,
            _            => Color::Cyan,
        };
        return Line::from(Span::styled(format!(" {} ", t),
            Style::default().fg(color).bold()));
    }
    if let Some(rest) = s.strip_prefix("- ") {
        return Line::from(vec![
            Span::styled("  • ", Style::default().fg(Color::Indexed(214))),
            Span::raw(rest.to_string()),
        ]);
    }
    Line::from(Span::raw(s.to_string()))
}
