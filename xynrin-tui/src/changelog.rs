// changelog.rs - 编译期内嵌 CHANGELOG.md，纯字符串解析
// Compile-time embedded CHANGELOG.md, pure string parsing (no IO, no HTTP).

const RAW: &str = include_str!("../../CHANGELOG.md");

#[derive(Debug, Clone)]
pub struct Section {
    pub version: String,
    pub date: String,
    pub body: String,
}

pub fn all() -> Vec<Section> {
    let mut out = Vec::new();
    let mut cur: Option<(String, String, String)> = None;
    for line in RAW.lines() {
        if let Some(rest) = line.strip_prefix("## [") {
            if let Some((v, d, b)) = cur.take() {
                out.push(Section { version: v, date: d, body: b });
            }
            // 形如 "## [3.1.0] - 2026-05-23"
            // Form: "## [3.1.0] - 2026-05-23"
            if let Some(end) = rest.find(']') {
                let version = rest[..end].to_string();
                let after = &rest[end + 1..];
                let date = after
                    .trim_start_matches(|c: char| c.is_whitespace() || c == '-')
                    .to_string();
                cur = Some((version, date, String::new()));
            }
        } else if let Some((_, _, ref mut body)) = cur {
            body.push_str(line);
            body.push('\n');
        }
    }
    if let Some((v, d, b)) = cur {
        out.push(Section { version: v, date: d, body: b });
    }
    out
}

pub fn latest() -> Option<Section> {
    all().into_iter().next()
}

#[allow(dead_code)]
pub fn for_version(v: &str) -> Option<Section> {
    all().into_iter().find(|s| s.version == v)
}
