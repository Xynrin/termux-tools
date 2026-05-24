// ui/dashboard - 原生 Rust 实时硬件监控仪表盘
// Native Rust live hardware dashboard: CPU / mem / battery / storage gauges + sparkline.

use std::collections::VecDeque;
use std::fs;
use std::time::Instant;

use ratatui::{
    layout::{Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style, Stylize},
    text::{Line, Span},
    widgets::{Block, BorderType, Borders, Gauge, Paragraph, Sparkline},
    Frame,
};

use crate::app::App;

// CPU sparkline 历史值（最近 60 个采样）
// CPU sparkline history (last 60 samples)
pub struct DashboardState {
    pub cpu_history: VecDeque<u64>,
    pub mem_history: VecDeque<u64>,
    pub last_cpu_total: u64,
    pub last_cpu_idle: u64,
    pub last_tick: Instant,
}

impl DashboardState {
    pub fn new() -> Self {
        let (total, idle) = read_cpu_jiffies().unwrap_or((0, 0));
        Self {
            cpu_history: VecDeque::with_capacity(60),
            mem_history: VecDeque::with_capacity(60),
            last_cpu_total: total,
            last_cpu_idle: idle,
            last_tick: Instant::now(),
        }
    }

    // 每帧调用：解析 /proc/stat 算 cpu%，/proc/meminfo 算内存%
    // Per-frame: derive cpu% from /proc/stat delta, mem% from /proc/meminfo
    pub fn sample(&mut self) {
        let (total, idle) = read_cpu_jiffies().unwrap_or((self.last_cpu_total, self.last_cpu_idle));
        let dt_total = total.saturating_sub(self.last_cpu_total);
        let dt_idle = idle.saturating_sub(self.last_cpu_idle);
        let cpu_pct = if dt_total > 0 {
            ((dt_total - dt_idle) * 100 / dt_total).min(100)
        } else { 0 };
        self.last_cpu_total = total;
        self.last_cpu_idle = idle;
        if self.cpu_history.len() >= 60 { self.cpu_history.pop_front(); }
        self.cpu_history.push_back(cpu_pct);

        let mem_pct = read_mem_pct().unwrap_or(0);
        if self.mem_history.len() >= 60 { self.mem_history.pop_front(); }
        self.mem_history.push_back(mem_pct);
        self.last_tick = Instant::now();
    }
}

fn read_cpu_jiffies() -> Option<(u64, u64)> {
    let stat = fs::read_to_string("/proc/stat").ok()?;
    let line = stat.lines().next()?;
    let nums: Vec<u64> = line.split_whitespace().skip(1)
        .filter_map(|s| s.parse().ok()).collect();
    if nums.len() < 4 { return None; }
    let idle = nums.get(3).copied().unwrap_or(0);
    let total: u64 = nums.iter().sum();
    Some((total, idle))
}

fn read_mem_pct() -> Option<u64> {
    let mem = fs::read_to_string("/proc/meminfo").ok()?;
    let mut total = 0u64;
    let mut avail = 0u64;
    for line in mem.lines() {
        if let Some(rest) = line.strip_prefix("MemTotal:") {
            total = rest.split_whitespace().next()?.parse().ok()?;
        } else if let Some(rest) = line.strip_prefix("MemAvailable:") {
            avail = rest.split_whitespace().next()?.parse().ok()?;
        }
    }
    if total == 0 { return None; }
    let used = total.saturating_sub(avail);
    Some((used * 100 / total).min(100))
}

fn read_uptime_secs() -> Option<u64> {
    let s = fs::read_to_string("/proc/uptime").ok()?;
    let first = s.split_whitespace().next()?;
    Some(first.split('.').next()?.parse().ok()?)
}

fn format_uptime(secs: u64) -> String {
    let d = secs / 86400;
    let h = (secs % 86400) / 3600;
    let m = (secs % 3600) / 60;
    if d > 0 { format!("{}d {}h {}m", d, h, m) }
    else if h > 0 { format!("{}h {}m", h, m) }
    else { format!("{}m", m) }
}

// 读 termux-battery-status JSON（如果有）/ termux-battery-status JSON if available
fn read_battery() -> Option<(u64, String, Option<f64>)> {
    let out = std::process::Command::new("termux-battery-status")
        .output().ok()?;
    if !out.status.success() { return None; }
    let s = String::from_utf8_lossy(&out.stdout);
    let pct = extract_json_num(&s, "percentage")? as u64;
    let status = extract_json_str(&s, "status").unwrap_or_else(|| "unknown".into());
    let temp = extract_json_num(&s, "temperature");
    Some((pct, status, temp))
}

fn extract_json_num(s: &str, key: &str) -> Option<f64> {
    let needle = format!("\"{}\":", key);
    let idx = s.find(&needle)?;
    let rest = &s[idx + needle.len()..];
    let end = rest.find(|c: char| c == ',' || c == '}' || c == '\n')?;
    rest[..end].trim().parse().ok()
}

fn extract_json_str(s: &str, key: &str) -> Option<String> {
    let needle = format!("\"{}\":", key);
    let idx = s.find(&needle)?;
    let rest = &s[idx + needle.len()..].trim_start();
    let rest = rest.strip_prefix('"')?;
    let end = rest.find('"')?;
    Some(rest[..end].to_string())
}

fn read_storage_pct() -> Option<u64> {
    let prefix = std::env::var("PREFIX").unwrap_or_else(|_| "/data/data/com.termux/files/usr".into());
    let out = std::process::Command::new("df")
        .arg("-P").arg(&prefix).output().ok()?;
    let s = String::from_utf8_lossy(&out.stdout);
    let line = s.lines().nth(1)?;
    let cols: Vec<&str> = line.split_whitespace().collect();
    let pct_str = cols.get(4)?.trim_end_matches('%');
    pct_str.parse().ok()
}

pub fn draw(f: &mut Frame, area: Rect, app: &App) {
    let state = match &app.dashboard {
        Some(s) => s,
        None => {
            // 状态尚未初始化（不应发生 — App::new 已建好）/ Should never happen
            let block = Block::default().borders(Borders::ALL).title(" Dashboard ");
            f.render_widget(block, area);
            return;
        }
    };

    let outer = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::default().fg(Color::Cyan))
        .title(Span::styled(format!(" {} ", app.i18n.t("menu.system_info")),
            Style::default().fg(Color::Yellow).bold()));
    let inner = outer.inner(area);
    f.render_widget(outer, area);

    // 三段：上栏 gauges / 中栏 sparkline / 下栏 info
    // Three rows: gauges / sparkline / info
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(8),
            Constraint::Length(6),
            Constraint::Min(5),
        ])
        .split(inner);

    draw_gauges(f, chunks[0], state);
    draw_sparkline(f, chunks[1], state);
    draw_info(f, chunks[2], app);
}

fn draw_gauges(f: &mut Frame, area: Rect, state: &DashboardState) {
    let cpu = state.cpu_history.back().copied().unwrap_or(0);
    let mem = state.mem_history.back().copied().unwrap_or(0);
    let storage = read_storage_pct().unwrap_or(0);
    let battery = read_battery();

    let cols = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(2),
            Constraint::Length(2),
            Constraint::Length(2),
            Constraint::Length(2),
        ])
        .split(area);

    let gauge_color = |v: u64| match v {
        0..=50 => Color::Green,
        51..=80 => Color::Yellow,
        _ => Color::Red,
    };

    f.render_widget(
        Gauge::default()
            .block(Block::default().title(Span::styled("CPU", Style::default().fg(Color::Cyan).bold())))
            .gauge_style(Style::default().fg(gauge_color(cpu)).add_modifier(Modifier::BOLD))
            .percent(cpu as u16)
            .label(format!("{}%", cpu)),
        cols[0],
    );
    f.render_widget(
        Gauge::default()
            .block(Block::default().title(Span::styled("Memory", Style::default().fg(Color::Cyan).bold())))
            .gauge_style(Style::default().fg(gauge_color(mem)))
            .percent(mem as u16)
            .label(format!("{}%", mem)),
        cols[1],
    );
    f.render_widget(
        Gauge::default()
            .block(Block::default().title(Span::styled("Storage", Style::default().fg(Color::Cyan).bold())))
            .gauge_style(Style::default().fg(gauge_color(storage)))
            .percent(storage as u16)
            .label(format!("{}%", storage)),
        cols[2],
    );
    if let Some((pct, status, temp)) = battery {
        let color = if pct < 20 { Color::Red } else if pct < 50 { Color::Yellow } else { Color::Green };
        let label = match temp {
            Some(t) => format!("{}% · {} · {:.1}°C", pct, status, t),
            None => format!("{}% · {}", pct, status),
        };
        f.render_widget(
            Gauge::default()
                .block(Block::default().title(Span::styled("Battery", Style::default().fg(Color::Cyan).bold())))
                .gauge_style(Style::default().fg(color))
                .percent(pct.min(100) as u16)
                .label(label),
            cols[3],
        );
    } else {
        f.render_widget(
            Paragraph::new(Line::from(vec![
                Span::styled("Battery  ", Style::default().fg(Color::Cyan).bold()),
                Span::styled("(termux-battery-status unavailable)",
                    Style::default().fg(Color::DarkGray)),
            ])),
            cols[3],
        );
    }
}

fn draw_sparkline(f: &mut Frame, area: Rect, state: &DashboardState) {
    let cpu_data: Vec<u64> = state.cpu_history.iter().copied().collect();
    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::default().fg(Color::DarkGray))
        .title(Span::styled(" CPU history (60s) ",
            Style::default().fg(Color::Cyan).bold()));
    f.render_widget(
        Sparkline::default()
            .block(block)
            .data(&cpu_data)
            .max(100)
            .style(Style::default().fg(Color::Green)),
        area,
    );
}

fn draw_info(f: &mut Frame, area: Rect, app: &App) {
    let arch = std::env::consts::ARCH;
    let kernel = fs::read_to_string("/proc/version")
        .ok()
        .and_then(|s| s.split_whitespace().nth(2).map(String::from))
        .unwrap_or_else(|| "?".into());
    let uptime = read_uptime_secs().map(format_uptime).unwrap_or_else(|| "?".into());
    let shell = std::env::var("SHELL").unwrap_or_else(|_| "?".into());
    let termux_ver = std::env::var("TERMUX_VERSION").unwrap_or_else(|_| "?".into());

    let lines = vec![
        info_line("Arch", arch.to_string()),
        info_line("Kernel", kernel),
        info_line("Uptime", uptime),
        info_line("Shell", shell),
        info_line("Termux", termux_ver),
        info_line("xynrin", env!("CARGO_PKG_VERSION").to_string()),
        Line::from(""),
        Line::from(Span::styled(app.i18n.t("hint.dashboard").to_string(),
            Style::default().fg(Color::DarkGray))),
    ];

    f.render_widget(
        Paragraph::new(lines)
            .block(Block::default()
                .borders(Borders::ALL)
                .border_type(BorderType::Rounded)
                .border_style(Style::default().fg(Color::DarkGray))
                .title(Span::styled(" System ",
                    Style::default().fg(Color::Cyan).bold()))),
        area,
    );
}

fn info_line(key: &str, value: String) -> Line<'static> {
    Line::from(vec![
        Span::styled(format!(" {:<8} ", key), Style::default().fg(Color::Cyan).bold()),
        Span::raw(value),
    ])
}
