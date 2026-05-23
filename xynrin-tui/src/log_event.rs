// log_event.rs - 日志条目类型
// LogLine + Level shared between runner and the log panel.

use ratatui::style::Color;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Level {
    Info,
    Step,
    Ok,
    Warn,
    Err,
    Debug,
}

impl Level {
    pub fn color(self) -> Color {
        match self {
            Level::Info => Color::Gray,
            Level::Step => Color::Cyan,
            Level::Ok => Color::Green,
            Level::Warn => Color::Yellow,
            Level::Err => Color::Red,
            Level::Debug => Color::DarkGray,
        }
    }
    pub fn icon(self) -> &'static str {
        match self {
            Level::Info => "  ",
            Level::Step => "→ ",
            Level::Ok => "✓ ",
            Level::Warn => "! ",
            Level::Err => "✗ ",
            Level::Debug => "· ",
        }
    }
}

#[derive(Clone, Debug)]
pub struct LogLine {
    pub level: Level,
    pub text: String,
}

// 解析约定的前缀协议；无前缀则按关键字模糊判定
// Parse the agreed prefix protocol; fall back to keyword fuzzing.
pub fn parse_line(raw: &str) -> LogLine {
    let raw = raw.trim_end_matches(['\r', '\n']);
    if let Some(rest) = raw.strip_prefix("::step::") {
        return LogLine { level: Level::Step, text: rest.to_string() };
    }
    if let Some(rest) = raw.strip_prefix("::ok::") {
        return LogLine { level: Level::Ok, text: rest.to_string() };
    }
    if let Some(rest) = raw.strip_prefix("::warn::") {
        return LogLine { level: Level::Warn, text: rest.to_string() };
    }
    if let Some(rest) = raw.strip_prefix("::err::") {
        return LogLine { level: Level::Err, text: rest.to_string() };
    }
    if let Some(rest) = raw.strip_prefix("::info::") {
        return LogLine { level: Level::Info, text: rest.to_string() };
    }
    if let Some(rest) = raw.strip_prefix("::remote::") {
        // 内部信号：远端版本，runner 会单独处理 / internal: remote version, handled by runner
        return LogLine { level: Level::Debug, text: format!("__remote__{rest}") };
    }
    if raw.trim() == "::restart::" || raw.starts_with("::restart::") {
        // 内部信号：升级完成，让主循环 exec 新二进制
        // Internal signal: upgrade succeeded, main loop should exec the new binary
        return LogLine { level: Level::Debug, text: "__restart__".to_string() };
    }
    let lower = raw.to_lowercase();
    let level = if lower.contains("error") || lower.contains("failed") || lower.contains("fatal") {
        Level::Err
    } else if lower.contains("warn") {
        Level::Warn
    } else {
        Level::Info
    };
    LogLine { level, text: raw.to_string() }
}
