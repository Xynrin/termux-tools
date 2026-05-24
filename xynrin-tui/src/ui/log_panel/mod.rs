// ui/log_panel.rs - 流式日志面板（语义着色、滚动、高亮报错、运行结果状态）
// Streaming log panel: semantic colors, scrolling, error highlight, exit status.

use ratatui::{
    layout::Rect,
    style::{Color, Style, Stylize},
    text::{Line, Span},
    widgets::{Block, BorderType, Borders, Paragraph, Wrap},
    Frame,
};

use crate::app::{App, Screen};

pub fn draw(f: &mut Frame, area: Rect, app: &App) {
    let base = app.i18n.t("running.title");
    let scrolling = app.i18n.t("running.scrolling");

    // 根据子进程退出状态决定边框颜色和标题装饰：
    //   未完成 → 焦点态 cyan / 非焦点态 dark gray
    //   完成且 exit==0 → 绿色 + ✓ + "操作完成"
    //   完成且 exit!=0 → 红色 + ✗ + "操作失败"
    // Border + title reflect runtime state so the user can see at a glance
    // whether the action succeeded — fixes the "always shows ok" bug from
    // the audit (exit code was hardcoded to 0 in runner.rs).
    let exit_state = match &app.screen {
        Screen::Running { finished: true, exit_ok: Some(true), .. } => Some(true),
        Screen::Running { finished: true, exit_ok: Some(false), .. } => Some(false),
        Screen::Bootstrap { finished: true } => app.last_exit_code.map(|c| c == 0),
        _ => None,
    };

    let (border_color, title) = match exit_state {
        Some(true) => (
            Color::Green,
            format!(" {} [✓ {}] ", base, app.i18n.t("running.done")),
        ),
        Some(false) => (
            Color::Red,
            format!(" {} [✗ {}] ", base, app.i18n.t("running.failed")),
        ),
        None => {
            let t = if app.log_scroll.is_some() {
                format!(" {} [{}] ", base, scrolling)
            } else {
                format!(" {} ", base)
            };
            (
                if app.focus_log { Color::Cyan } else { Color::DarkGray },
                t,
            )
        }
    };

    let title_color = match exit_state {
        Some(true) => Color::Green,
        Some(false) => Color::Red,
        None => Color::Yellow,
    };

    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::default().fg(border_color))
        .title(Span::styled(title, Style::default().fg(title_color).bold()));

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
