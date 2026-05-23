// ui/banner.rs - 渐变 ASCII Logo（窄屏自动塌缩）
// Gradient ASCII logo with collapse on small screens.

use ratatui::{
    layout::{Alignment, Rect},
    style::{Color, Modifier, Style, Stylize},
    text::{Line, Span},
    widgets::Paragraph,
    Frame,
};

const VERSION: &str = env!("CARGO_PKG_VERSION");

pub fn draw(f: &mut Frame, area: Rect, h: u16) {
    if h <= 1 || area.width < 50 {
        let p = Paragraph::new(Line::from(vec![
            Span::styled("xynrin ", Style::default().fg(Color::Indexed(214)).bold()),
            Span::styled(format!("v{} ", VERSION), Style::default().fg(Color::Green)),
            Span::styled("by Xynrin", Style::default().fg(Color::Cyan)),
        ]))
        .alignment(Alignment::Left);
        f.render_widget(p, area);
        return;
    }

    let lines = vec![
        Line::from(Span::styled(" ██╗  ██╗██╗   ██╗███╗   ██╗██████╗ ██╗███╗   ██╗",
            Style::default().fg(Color::Indexed(202)).add_modifier(Modifier::BOLD))),
        Line::from(Span::styled(" ╚██╗██╔╝╚██╗ ██╔╝████╗  ██║██╔══██╗██║████╗  ██║",
            Style::default().fg(Color::Indexed(208)).add_modifier(Modifier::BOLD))),
        Line::from(Span::styled("  ╚███╔╝  ╚████╔╝ ██╔██╗ ██║██████╔╝██║██╔██╗ ██║",
            Style::default().fg(Color::Indexed(214)).add_modifier(Modifier::BOLD))),
        Line::from(Span::styled("  ██╔██╗   ╚██╔╝  ██║╚██╗██║██╔══██╗██║██║╚██╗██║",
            Style::default().fg(Color::Indexed(220)).add_modifier(Modifier::BOLD))),
        Line::from(Span::styled(" ██╔╝ ██╗   ██║   ██║ ╚████║██║  ██║██║██║ ╚████║",
            Style::default().fg(Color::Indexed(226)).add_modifier(Modifier::BOLD))),
        Line::from(Span::styled(" ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝",
            Style::default().fg(Color::Indexed(226)).add_modifier(Modifier::BOLD))),
        Line::from(""),
        Line::from(vec![
            Span::raw("  "),
            Span::styled("v", Style::default().fg(Color::Cyan)),
            Span::styled(VERSION, Style::default().fg(Color::Green).bold()),
            Span::raw("  ·  "),
            Span::styled("Xynrin", Style::default().fg(Color::Cyan)),
            Span::raw("  ·  "),
            Span::styled("github.com/Xynrin/termux-tools", Style::default().fg(Color::Blue)),
        ]),
    ];
    f.render_widget(Paragraph::new(lines).alignment(Alignment::Left), area);
}
