use std::io;
use std::process::Command;

use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEventKind},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Alignment, Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style, Stylize},
    text::{Line, Span},
    widgets::{Block, BorderType, Borders, List, ListItem, ListState, Paragraph, Wrap},
    Frame, Terminal,
};

const VERSION: &str = env!("CARGO_PKG_VERSION");
const AUTHOR: &str = "Xynrin";
const REPO: &str = "https://github.com/Xynrin/termux-tools";

#[derive(Clone, Copy, PartialEq, Eq)]
enum Lang {
    Zh,
    En,
}

impl Lang {
    fn detect() -> Self {
        // 优先读取偏好文件 / Prefer the saved preference
        if let Some(home) = dirs_home() {
            let pref = format!("{}/termux-tools/.lang_pref", home);
            if let Ok(s) = std::fs::read_to_string(&pref) {
                if s.trim() == "zh" {
                    return Lang::Zh;
                }
                if s.trim() == "en" {
                    return Lang::En;
                }
            }
        }
        // 回退到 LANG 环境变量 / Fallback to $LANG
        let lang = std::env::var("LANG").unwrap_or_default();
        if lang.contains("zh") || lang.contains("CN") || lang.contains("TW") {
            Lang::Zh
        } else {
            Lang::En
        }
    }

    #[allow(dead_code)]
    fn save(self) {
        if let Some(home) = dirs_home() {
            let pref = format!("{}/termux-tools/.lang_pref", home);
            let _ = std::fs::write(&pref, match self { Lang::Zh => "zh", Lang::En => "en" });
        }
    }
}

fn dirs_home() -> Option<String> {
    std::env::var("HOME").ok()
}

struct I18n {
    menu_title: &'static str,
    options: [&'static str; 8],
    press_enter: &'static str,
    quit_hint: &'static str,
}

fn i18n(lang: Lang) -> I18n {
    match lang {
        Lang::Zh => I18n {
            menu_title: "功能菜单",
            options: [
                "更新 xynrin",
                "使用 proot 安装发行版",
                "列出发行版别名",
                "系统信息",
                "添加或设置镜像源",
                "切换语言",
                "美化 Termux",
                "退出",
            ],
            press_enter: "按 Enter 返回菜单",
            quit_hint: "↑/↓ 选择 · Enter 执行 · q 退出",
        },
        Lang::En => I18n {
            menu_title: "Main Menu",
            options: [
                "Update xynrin",
                "Install distro with proot",
                "List distro aliases",
                "System info",
                "Configure mirror sources",
                "Change language",
                "Beautify Termux",
                "Exit",
            ],
            press_enter: "Press Enter to return",
            quit_hint: "↑/↓ select · Enter run · q quit",
        },
    }
}

enum AppMode {
    Menu,
    AfterAction,
}

struct App {
    lang: Lang,
    mode: AppMode,
    list: ListState,
    last_action: String,
}

impl App {
    fn new() -> Self {
        let mut list = ListState::default();
        list.select(Some(0));
        Self {
            lang: Lang::detect(),
            mode: AppMode::Menu,
            list,
            last_action: String::new(),
        }
    }

    fn next(&mut self) {
        let i = self.list.selected().unwrap_or(0);
        self.list.select(Some((i + 1) % 8));
    }

    fn prev(&mut self) {
        let i = self.list.selected().unwrap_or(0);
        self.list.select(Some(if i == 0 { 7 } else { i - 1 }));
    }
}

fn main() -> io::Result<()> {
    // 终端初始化 / Terminal setup
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let res = run_app(&mut terminal);

    // 终端清理 / Terminal cleanup
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        eprintln!("error: {err}");
    }
    Ok(())
}

fn run_app<B: ratatui::backend::Backend + io::Write>(terminal: &mut Terminal<B>) -> io::Result<()> {
    let mut app = App::new();
    loop {
        terminal.draw(|f| draw(f, &mut app))?;

        if let Event::Key(key) = event::read()? {
            if key.kind != KeyEventKind::Press {
                continue;
            }
            match app.mode {
                AppMode::Menu => match key.code {
                    KeyCode::Char('q') | KeyCode::Esc => return Ok(()),
                    KeyCode::Down | KeyCode::Char('j') => app.next(),
                    KeyCode::Up | KeyCode::Char('k') => app.prev(),
                    KeyCode::Enter => {
                        let idx = app.list.selected().unwrap_or(0);
                        if idx == 7 {
                            return Ok(()); // exit
                        }
                        // 离开 ratatui 屏幕，运行 bash 子命令，再回到 TUI
                        // Leave ratatui screen, run bash subcommand, return to TUI
                        leave_alt_screen(terminal)?;
                        let action = run_bash_action(idx, app.lang);
                        app.last_action = action;
                        if idx == 5 {
                            // 切换语言后立即刷新 / refresh language after switch
                            app.lang = Lang::detect();
                        }
                        enter_alt_screen(terminal)?;
                        app.mode = AppMode::AfterAction;
                    }
                    _ => {}
                },
                AppMode::AfterAction => match key.code {
                    KeyCode::Enter | KeyCode::Esc | KeyCode::Char('q') => {
                        app.mode = AppMode::Menu;
                    }
                    _ => {}
                },
            }
        }
    }
}

fn leave_alt_screen<B: ratatui::backend::Backend + io::Write>(
    terminal: &mut Terminal<B>,
) -> io::Result<()> {
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;
    Ok(())
}

fn enter_alt_screen<B: ratatui::backend::Backend + io::Write>(
    terminal: &mut Terminal<B>,
) -> io::Result<()> {
    enable_raw_mode()?;
    execute!(terminal.backend_mut(), EnterAlternateScreen, EnableMouseCapture)?;
    terminal.clear()?;
    Ok(())
}

// 调用底层 bash 实现：把所有具体功能委托给现有的 xynrin-bash 脚本
// Delegate every concrete action to the existing xynrin-bash script
fn run_bash_action(idx: usize, lang: Lang) -> String {
    // 找到 xynrin-bash 脚本（旧的 bash 主程序，作为 fallback 留下）
    // Locate the xynrin-bash script (the old bash main, kept as fallback)
    let bash_path = locate_bash_main();
    let arg = match idx {
        0 => "--menu-update",
        1 => "--menu-proot-install",
        2 => "--menu-list-aliases",
        3 => "--menu-system-info",
        4 => "--menu-mirror",
        5 => "--menu-language",
        6 => "--menu-beautify",
        _ => return String::new(),
    };

    let mut cmd = Command::new("bash");
    cmd.arg(&bash_path).arg(arg);
    cmd.env(
        "LANG",
        match lang {
            Lang::Zh => "zh_CN.UTF-8",
            Lang::En => "en_US.UTF-8",
        },
    );

    let status = cmd.status();
    match status {
        Ok(s) if s.success() => match lang {
            Lang::Zh => "操作完成".into(),
            Lang::En => "Done".into(),
        },
        Ok(_) => match lang {
            Lang::Zh => "操作失败".into(),
            Lang::En => "Failed".into(),
        },
        Err(e) => format!("error: {e}"),
    }
}

fn locate_bash_main() -> String {
    // 1) 同目录：rust 二进制旁的 xynrin-bash
    if let Ok(exe) = std::env::current_exe() {
        if let Some(dir) = exe.parent() {
            let p = dir.join("xynrin-bash");
            if p.exists() {
                return p.to_string_lossy().into_owned();
            }
        }
    }
    // 2) PATH 中的 xynrin-bash
    if let Ok(out) = Command::new("which").arg("xynrin-bash").output() {
        if out.status.success() {
            return String::from_utf8_lossy(&out.stdout).trim().to_string();
        }
    }
    // 3) 兜底
    "/data/data/com.termux/files/usr/bin/xynrin-bash".into()
}

fn draw(f: &mut Frame, app: &mut App) {
    let i = i18n(app.lang);
    let area = f.area();

    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(9),    // banner
            Constraint::Min(8),       // body
            Constraint::Length(3),    // footer
        ])
        .split(area);

    draw_banner(f, chunks[0]);

    match app.mode {
        AppMode::Menu => draw_menu(f, chunks[1], app, &i),
        AppMode::AfterAction => draw_after(f, chunks[1], app, &i),
    }

    draw_footer(f, chunks[2], &i);
}

fn draw_banner(f: &mut Frame, area: Rect) {
    let lines = vec![
        Line::from(Span::styled(
            " ██╗  ██╗██╗   ██╗███╗   ██╗██████╗ ██╗███╗   ██╗",
            Style::default().fg(Color::Indexed(202)).add_modifier(Modifier::BOLD),
        )),
        Line::from(Span::styled(
            " ╚██╗██╔╝╚██╗ ██╔╝████╗  ██║██╔══██╗██║████╗  ██║",
            Style::default().fg(Color::Indexed(208)).add_modifier(Modifier::BOLD),
        )),
        Line::from(Span::styled(
            "  ╚███╔╝  ╚████╔╝ ██╔██╗ ██║██████╔╝██║██╔██╗ ██║",
            Style::default().fg(Color::Indexed(214)).add_modifier(Modifier::BOLD),
        )),
        Line::from(Span::styled(
            "  ██╔██╗   ╚██╔╝  ██║╚██╗██║██╔══██╗██║██║╚██╗██║",
            Style::default().fg(Color::Indexed(220)).add_modifier(Modifier::BOLD),
        )),
        Line::from(Span::styled(
            " ██╔╝ ██╗   ██║   ██║ ╚████║██║  ██║██║██║ ╚████║",
            Style::default().fg(Color::Indexed(226)).add_modifier(Modifier::BOLD),
        )),
        Line::from(Span::styled(
            " ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝",
            Style::default().fg(Color::Indexed(226)).add_modifier(Modifier::BOLD),
        )),
        Line::from(""),
        Line::from(vec![
            Span::raw("  "),
            Span::styled("Version ", Style::default().fg(Color::Cyan).bold()),
            Span::styled(format!("v{} ", VERSION), Style::default().fg(Color::Green)),
            Span::styled("Author ", Style::default().fg(Color::Cyan).bold()),
            Span::styled(format!("{} ", AUTHOR), Style::default().fg(Color::Green)),
            Span::styled("Repo ", Style::default().fg(Color::Cyan).bold()),
            Span::styled(REPO, Style::default().fg(Color::Blue)),
        ]),
    ];

    let p = Paragraph::new(lines).alignment(Alignment::Left);
    f.render_widget(p, area);
}

fn draw_menu(f: &mut Frame, area: Rect, app: &mut App, i: &I18n) {
    let items: Vec<ListItem> = i
        .options
        .iter()
        .enumerate()
        .map(|(idx, o)| {
            ListItem::new(Line::from(vec![
                Span::styled(format!(" {} ", idx + 1), Style::default().fg(Color::Indexed(214)).bold()),
                Span::raw("│ "),
                Span::raw(*o),
            ]))
        })
        .collect();

    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::default().fg(Color::Cyan))
        .title(Span::styled(
            format!(" {} ", i.menu_title),
            Style::default().fg(Color::Yellow).bold(),
        ));

    let list = List::new(items)
        .block(block)
        .highlight_style(
            Style::default()
                .bg(Color::Indexed(238))
                .fg(Color::Indexed(226))
                .add_modifier(Modifier::BOLD),
        )
        .highlight_symbol(" ❯ ");

    f.render_stateful_widget(list, area, &mut app.list);
}

fn draw_after(f: &mut Frame, area: Rect, app: &App, i: &I18n) {
    let lines = vec![
        Line::from(""),
        Line::from(Span::styled(
            &app.last_action,
            Style::default().fg(Color::Green).bold(),
        )),
        Line::from(""),
        Line::from(Span::styled(
            i.press_enter,
            Style::default().fg(Color::DarkGray),
        )),
    ];
    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::default().fg(Color::Green));
    let p = Paragraph::new(lines)
        .alignment(Alignment::Center)
        .wrap(Wrap { trim: true })
        .block(block);
    f.render_widget(p, area);
}

fn draw_footer(f: &mut Frame, area: Rect, i: &I18n) {
    let p = Paragraph::new(Line::from(vec![Span::styled(
        i.quit_hint,
        Style::default().fg(Color::DarkGray),
    )]))
    .alignment(Alignment::Center)
    .block(
        Block::default()
            .borders(Borders::TOP)
            .border_style(Style::default().fg(Color::DarkGray)),
    );
    f.render_widget(p, area);
}
