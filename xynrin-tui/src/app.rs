// app.rs - 状态机 + 事件处理
// State machine and event dispatch.

use std::collections::VecDeque;
use std::time::Duration;

use crossterm::event::{self, Event, KeyCode, KeyEventKind};
use ratatui::widgets::ListState;

use crate::changelog;
use crate::i18n::{Lang, I18n, MENU_ITEMS};
use crate::log_event::{Level, LogLine};
use crate::runner::{self, RunMsg, Runner};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Action {
    Update,
    ProotInstall,
    SystemInfo,
    Mirror,
    Language,
    Beautify,
}

impl Action {
    pub fn from_index(i: usize) -> Option<Self> {
        Some(match i {
            0 => Action::Update,
            1 => Action::ProotInstall,
            2 => Action::SystemInfo,
            3 => Action::Mirror,
            4 => Action::Language,
            5 => Action::Beautify,
            _ => return None,
        })
    }
    pub fn bash_args(self) -> &'static [&'static str] {
        match self {
            Action::Update        => &["--menu-update-apply"],
            Action::ProotInstall  => &["--menu-proot-install"],
            Action::SystemInfo    => &["--menu-system-info"],
            Action::Mirror        => &["--menu-mirror"],
            Action::Language      => &["--menu-language"],
            Action::Beautify      => &["--menu-beautify"],
        }
    }

    // 需要 fzf / read 的动作：必须挂起 ratatui，把真终端交给 bash
    // Actions that use fzf/read must suspend ratatui and hand the real TTY to bash.
    pub fn is_interactive(self) -> bool {
        matches!(
            self,
            Action::ProotInstall | Action::Mirror
                | Action::Language | Action::Beautify
        )
    }
}

pub enum Screen {
    Menu,
    Notes { scroll: u16 },
    UpdateConfirm { remote_version: String },
    #[allow(dead_code)]
    Running { action: Action, finished: bool, exit_ok: Option<bool> },
    Bootstrap { finished: bool },
}

#[allow(dead_code)]
pub struct App {
    pub i18n: I18n,
    pub lang: Lang,
    pub screen: Screen,
    pub menu: ListState,
    pub log: VecDeque<LogLine>,
    pub log_scroll: Option<usize>,
    pub runner: Option<Runner>,
    pub focus_log: bool,
    pub should_quit: bool,
    pub bootstrap_mode: bool,
    pub show_notes_only: bool,
    // update_mode: 启动即跑 update_check，跑完直接退出（不显示主菜单）
    // update_mode: starts update_check immediately and exits when done (no menu)
    pub update_mode: bool,
    pub update_started: bool,
    // 升级完成需要 exec 新二进制 / Upgrade finished, exec new binary on exit
    pub restart_after_quit: bool,
    // 主循环用：交互式动作请求 / Interactive action request, handled by main loop
    pub pending_interactive: Option<&'static [&'static str]>,
}

impl App {
    pub fn new(bootstrap_mode: bool, show_notes_only: bool, update_mode: bool) -> Self {
        let lang = Lang::detect();
        let mut menu = ListState::default();
        menu.select(Some(0));
        let screen = if show_notes_only {
            Screen::Notes { scroll: 0 }
        } else if bootstrap_mode {
            Screen::Bootstrap { finished: false }
        } else if update_mode {
            Screen::Running { action: Action::Update, finished: false, exit_ok: None }
        } else {
            Screen::Menu
        };
        Self {
            i18n: I18n::new(lang),
            lang,
            screen,
            menu,
            log: VecDeque::with_capacity(1024),
            log_scroll: None,
            runner: None,
            focus_log: false,
            should_quit: false,
            bootstrap_mode,
            show_notes_only,
            update_mode,
            update_started: false,
            restart_after_quit: false,
            pending_interactive: None,
        }
    }

    pub fn push_log(&mut self, line: LogLine) {
        if self.log.len() >= 4096 {
            self.log.pop_front();
        }
        self.log.push_back(line);
    }

    pub fn menu_next(&mut self) {
        let i = self.menu.selected().unwrap_or(0);
        self.menu.select(Some((i + 1) % MENU_ITEMS.len()));
    }
    pub fn menu_prev(&mut self) {
        let i = self.menu.selected().unwrap_or(0);
        self.menu.select(Some(if i == 0 { MENU_ITEMS.len() - 1 } else { i - 1 }));
    }

    fn drain_runner(&mut self) {
        let mut done = false;
        let mut pending: Vec<crate::log_event::LogLine> = Vec::new();
        let mut switch_to_confirm: Option<String> = None;
        let mut restart_signal = false;
        if let Some(r) = self.runner.as_ref() {
            while let Ok(msg) = r.rx.try_recv() {
                match msg {
                    RunMsg::Line(l) => {
                        if l.text.starts_with("__remote__") {
                            switch_to_confirm = Some(l.text.trim_start_matches("__remote__").trim().to_string());
                        } else if l.text == "__restart__" {
                            restart_signal = true;
                        } else {
                            pending.push(l);
                        }
                    }
                    RunMsg::Done(_) => { done = true; }
                }
            }
        }
        for l in pending { self.push_log(l); }
        if let Some(v) = switch_to_confirm {
            self.screen = Screen::UpdateConfirm { remote_version: v };
        }
        if restart_signal {
            self.restart_after_quit = true;
        }
        if done {
            self.runner = None;
            // 升级成功 → 自杀重启 / Upgrade succeeded → kill self and exec new binary
            if self.restart_after_quit {
                self.should_quit = true;
                return;
            }
            match &mut self.screen {
                Screen::Running { finished, exit_ok, .. } => {
                    *finished = true;
                    *exit_ok = Some(true);
                }
                Screen::Bootstrap { finished } => *finished = true,
                _ => {}
            }
        }
    }

    pub fn tick(&mut self) -> std::io::Result<()> {
        self.drain_runner();
        // 启动 bootstrap（首次进入这一屏时）
        if let Screen::Bootstrap { finished: false } = self.screen {
            if self.runner.is_none() && self.log.is_empty() {
                self.start_runner(&["--menu-bootstrap"]);
            }
        }
        // update_mode 入口：直接跑 update-check，不显示菜单
        // update_mode entry: run update-check immediately, skip the menu
        if self.update_mode && !self.update_started {
            if let Screen::Running { action: Action::Update, .. } = self.screen {
                if self.runner.is_none() {
                    self.update_started = true;
                    self.start_runner(&["--menu-update-check"]);
                }
            }
        }

        // 一次 tick 把所有排队事件都吃掉，避免 Esc 要按多次才生效
        // Drain every queued event in this tick — fixes Esc-needs-multiple-presses
        // bug where one event/tick lost keypresses behind queued Resize/Mouse events.
        if event::poll(Duration::from_millis(80))? {
            loop {
                if let Event::Key(k) = event::read()? {
                    if k.kind == KeyEventKind::Press {
                        self.on_key(k.code);
                    }
                }
                if !event::poll(Duration::from_millis(0))? { break; }
            }
        }
        Ok(())
    }

    fn start_runner(&mut self, args: &[&str]) {
        self.log.clear();
        self.log_scroll = None;
        match runner::spawn(args, self.lang) {
            Ok(r) => self.runner = Some(r),
            Err(e) => self.push_log(LogLine { level: Level::Err, text: format!("spawn failed: {e}") }),
        }
    }

    fn on_key(&mut self, code: KeyCode) {
        // 全局：q/Esc 在非运行态退出
        match code {
            KeyCode::Char('q') if matches!(self.screen, Screen::Menu) => {
                self.should_quit = true;
                return;
            }
            _ => {}
        }

        match &self.screen {
            Screen::Menu => self.on_key_menu(code),
            Screen::Notes { .. } => self.on_key_notes(code),
            Screen::UpdateConfirm { .. } => self.on_key_confirm(code),
            Screen::Running { .. } => self.on_key_running(code),
            Screen::Bootstrap { .. } => self.on_key_bootstrap(code),
        }
    }

    fn on_key_menu(&mut self, code: KeyCode) {
        match code {
            KeyCode::Down | KeyCode::Char('j') => self.menu_next(),
            KeyCode::Up   | KeyCode::Char('k') => self.menu_prev(),
            KeyCode::Char(c @ '1'..='7') => {
                let idx = (c as u8 - b'1') as usize;
                self.menu.select(Some(idx));
            }
            KeyCode::Enter => {
                let idx = self.menu.selected().unwrap_or(0);
                if idx == 6 { self.should_quit = true; return; }
                if let Some(action) = Action::from_index(idx) {
                    if action == Action::Update {
                        self.start_runner(&["--menu-update-check"]);
                        self.screen = Screen::Running { action, finished: false, exit_ok: None };
                    } else if action.is_interactive() {
                        // 交给主循环挂起 ratatui 后用真实 TTY 跑
                        // Hand off to main loop: suspend ratatui, run with real TTY
                        self.pending_interactive = Some(action.bash_args());
                        if action == Action::Language {
                            // 语言切换后，菜单文案需要刷新
                            // Flag handled in main: reload lang after returning
                        }
                    } else {
                        self.start_runner(action.bash_args());
                        self.screen = Screen::Running { action, finished: false, exit_ok: None };
                    }
                }
            }
            _ => {}
        }
    }

    fn on_key_running(&mut self, code: KeyCode) {
        match code {
            KeyCode::Esc => {
                if let Some(r) = self.runner.as_mut() { r.try_kill(); }
                self.runner = None;
                if self.update_mode {
                    self.should_quit = true;
                } else {
                    self.screen = Screen::Menu;
                }
                self.log_scroll = None;
            }
            KeyCode::Char('q') => {
                if let Screen::Running { finished: true, .. } = self.screen {
                    if self.update_mode {
                        self.should_quit = true;
                    } else {
                        self.screen = Screen::Menu;
                    }
                }
            }
            KeyCode::Tab => self.focus_log = !self.focus_log,
            KeyCode::Enter => {
                if let Screen::Running { finished: true, .. } = self.screen {
                    if self.update_mode {
                        self.should_quit = true;
                    } else {
                        self.screen = Screen::Menu;
                    }
                }
            }
            KeyCode::PageUp => {
                let cur = self.log_scroll.unwrap_or(self.log.len().saturating_sub(1));
                self.log_scroll = Some(cur.saturating_sub(10));
            }
            KeyCode::PageDown => {
                let cur = self.log_scroll.unwrap_or(self.log.len().saturating_sub(1));
                let new = (cur + 10).min(self.log.len().saturating_sub(1));
                if new == self.log.len().saturating_sub(1) {
                    self.log_scroll = None;
                } else {
                    self.log_scroll = Some(new);
                }
            }
            KeyCode::End => self.log_scroll = None,
            _ => {}
        }
    }

    fn on_key_notes(&mut self, code: KeyCode) {
        if let Screen::Notes { scroll } = &mut self.screen {
            match code {
                KeyCode::Down | KeyCode::Char('j') => *scroll = scroll.saturating_add(1),
                KeyCode::Up   | KeyCode::Char('k') => *scroll = scroll.saturating_sub(1),
                KeyCode::PageDown => *scroll = scroll.saturating_add(10),
                KeyCode::PageUp   => *scroll = scroll.saturating_sub(10),
                KeyCode::Enter | KeyCode::Esc | KeyCode::Char('q') => {
                    if self.show_notes_only {
                        self.should_quit = true;
                    } else {
                        self.screen = Screen::Menu;
                    }
                }
                _ => {}
            }
        }
    }

    fn on_key_confirm(&mut self, code: KeyCode) {
        match code {
            // Y / Enter 都视作确认升级 / Y or Enter both confirm
            KeyCode::Char('y') | KeyCode::Char('Y') | KeyCode::Enter => {
                self.start_runner(&["--menu-update-apply"]);
                self.screen = Screen::Running { action: Action::Update, finished: false, exit_ok: None };
            }
            KeyCode::Char('n') | KeyCode::Char('N') | KeyCode::Esc => {
                if self.update_mode {
                    self.should_quit = true;
                } else {
                    self.screen = Screen::Menu;
                }
            }
            _ => {}
        }
    }

    fn on_key_bootstrap(&mut self, code: KeyCode) {
        // 完成后任意键回菜单 / After finished, any key returns to menu
        if let Screen::Bootstrap { finished: true } = self.screen {
            if matches!(code, KeyCode::Enter | KeyCode::Esc | KeyCode::Char('q')) {
                self.screen = Screen::Menu;
            }
            return;
        }
        // 进行中：Esc / q 取消并杀进程，避免下载期间按键失灵
        // In-progress: Esc/q cancels, kills the runner so the user can bail
        match code {
            KeyCode::Esc | KeyCode::Char('q') => {
                if let Some(r) = self.runner.as_mut() { r.try_kill(); }
                self.runner = None;
                self.screen = Screen::Menu;
                self.log_scroll = None;
            }
            KeyCode::Tab => self.focus_log = !self.focus_log,
            KeyCode::PageUp => {
                let cur = self.log_scroll.unwrap_or(self.log.len().saturating_sub(1));
                self.log_scroll = Some(cur.saturating_sub(10));
            }
            KeyCode::PageDown => {
                let cur = self.log_scroll.unwrap_or(self.log.len().saturating_sub(1));
                let new = (cur + 10).min(self.log.len().saturating_sub(1));
                if new == self.log.len().saturating_sub(1) {
                    self.log_scroll = None;
                } else {
                    self.log_scroll = Some(new);
                }
            }
            KeyCode::End => self.log_scroll = None,
            _ => {}
        }
    }
}

#[allow(dead_code)]
pub fn changelog_latest() -> Option<changelog::Section> {
    changelog::latest()
}
