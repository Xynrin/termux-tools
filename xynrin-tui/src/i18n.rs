// i18n.rs - HashMap-based i18n (按 key 取串，便于增删菜单项)
// HashMap-based i18n (key lookup, easy to add menu items)

use std::collections::HashMap;

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Lang { Zh, En }

impl Lang {
    pub fn detect() -> Self {
        if let Some(home) = std::env::var("HOME").ok() {
            let pref = format!("{}/termux-tools/.lang_pref", home);
            if let Ok(s) = std::fs::read_to_string(&pref) {
                match s.trim() {
                    "zh" => return Lang::Zh,
                    "en" => return Lang::En,
                    _ => {}
                }
            }
        }
        let lang = std::env::var("LANG").unwrap_or_default();
        if lang.contains("zh") || lang.contains("CN") || lang.contains("TW") {
            Lang::Zh
        } else {
            Lang::En
        }
    }
}

pub struct I18n {
    map: HashMap<&'static str, &'static str>,
}

impl I18n {
    pub fn new(lang: Lang) -> Self {
        Self { map: build(lang) }
    }
    pub fn t<'a>(&'a self, key: &'a str) -> &'a str {
        self.map.get(key).copied().unwrap_or(key)
    }
}

fn build(lang: Lang) -> HashMap<&'static str, &'static str> {
    let mut m = HashMap::new();
    match lang {
        Lang::Zh => {
            m.insert("menu.title", "功能菜单");
            m.insert("menu.update", "更新 xynrin");
            m.insert("menu.proot_install", "安装 proot 发行版");
            m.insert("menu.proot_manage", "管理已装发行版（登录/删除）");
            m.insert("menu.system_info", "系统信息");
            m.insert("menu.mirror", "切换镜像源");
            m.insert("menu.language", "切换语言");
            m.insert("menu.beautify", "美化 Termux");
            m.insert("menu.exit", "退出");
            m.insert("hint.menu", "↑/↓ 选择 · Enter 执行 · Tab 切换焦点 · q 退出");
            m.insert("hint.running", "Esc 取消 · PgUp/PgDn 滚动 · Tab 切回菜单");
            m.insert("hint.confirm", "Y 确认 · N 取消");
            m.insert("hint.notes", "↑/↓ 滚动 · Enter 返回 · q 退出");
            m.insert("running.title", "实时日志");
            m.insert("running.empty", "选择左侧菜单项后按 Enter 执行");
            m.insert("running.done", "操作完成");
            m.insert("running.failed", "操作失败");
            m.insert("running.cancelled", "已取消");
            m.insert("notes.title", "更新日志");
            m.insert("notes.no_data", "未找到本版本的更新日志");
            m.insert("update.checking", "正在检查更新...");
            m.insert("update.no_new", "已经是最新版本");
            m.insert("update.available", "发现新版本");
            m.insert("update.confirm", "现在升级？(Y/N)");
            m.insert("update.show_notes_after", "升级完成后会自动显示新版本日志");
            m.insert("bootstrap.title", "首次部署");
            m.insert("welcome", "欢迎使用 xynrin");
        }
        Lang::En => {
            m.insert("menu.title", "Main Menu");
            m.insert("menu.update", "Update xynrin");
            m.insert("menu.proot_install", "Install proot distro");
            m.insert("menu.proot_manage", "Manage installed distros (login/remove)");
            m.insert("menu.system_info", "System info");
            m.insert("menu.mirror", "Configure mirrors");
            m.insert("menu.language", "Change language");
            m.insert("menu.beautify", "Beautify Termux");
            m.insert("menu.exit", "Exit");
            m.insert("hint.menu", "↑/↓ select · Enter run · Tab focus · q quit");
            m.insert("hint.running", "Esc cancel · PgUp/PgDn scroll · Tab menu");
            m.insert("hint.confirm", "Y confirm · N cancel");
            m.insert("hint.notes", "↑/↓ scroll · Enter back · q quit");
            m.insert("running.title", "Live log");
            m.insert("running.empty", "Pick a menu item and press Enter");
            m.insert("running.done", "Done");
            m.insert("running.failed", "Failed");
            m.insert("running.cancelled", "Cancelled");
            m.insert("notes.title", "Changelog");
            m.insert("notes.no_data", "No changelog for this version");
            m.insert("update.checking", "Checking for updates...");
            m.insert("update.no_new", "Already up to date");
            m.insert("update.available", "Update available");
            m.insert("update.confirm", "Upgrade now? (Y/N)");
            m.insert("update.show_notes_after", "Release notes will be shown after upgrade");
            m.insert("bootstrap.title", "First-time setup");
            m.insert("welcome", "Welcome to xynrin");
        }
    }
    m
}

pub const MENU_ITEMS: [&str; 8] = [
    "menu.update",
    "menu.proot_install",
    "menu.proot_manage",
    "menu.system_info",
    "menu.mirror",
    "menu.language",
    "menu.beautify",
    "menu.exit",
];
