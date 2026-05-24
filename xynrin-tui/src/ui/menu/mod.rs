// ui/menu.rs - 主菜单面板
// Main menu panel.

use ratatui::{
    layout::Rect,
    style::{Color, Modifier, Style, Stylize},
    text::{Line, Span},
    widgets::{Block, BorderType, Borders, List, ListItem},
    Frame,
};

use crate::app::App;
use crate::i18n::MENU_ITEMS;

pub fn draw(f: &mut Frame, area: Rect, app: &mut App) {
    let items: Vec<ListItem> = MENU_ITEMS
        .iter()
        .enumerate()
        .map(|(i, key)| {
            ListItem::new(Line::from(vec![
                Span::styled(format!(" {} ", i + 1), Style::default().fg(Color::Indexed(214)).bold()),
                Span::raw("│ "),
                Span::raw(app.i18n.t(key).to_string()),
            ]))
        })
        .collect();

    let title_color = if app.focus_log { Color::DarkGray } else { Color::Yellow };
    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::default().fg(if app.focus_log { Color::DarkGray } else { Color::Cyan }))
        .title(Span::styled(format!(" {} ", app.i18n.t("menu.title")),
            Style::default().fg(title_color).bold()));

    let list = List::new(items)
        .block(block)
        .highlight_style(Style::default()
            .bg(Color::Indexed(238))
            .fg(Color::Indexed(226))
            .add_modifier(Modifier::BOLD))
        .highlight_symbol(" ❯ ");

    f.render_stateful_widget(list, area, &mut app.menu);
}
