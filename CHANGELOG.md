# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.1.1] - 2026-05-23

### Fixed
- 修复交互式选项卡死的 bug / Fix UI hang on interactive options — language / mirror / beautify / proot install & manage all use `fzf` and `read`, but with ratatui holding the alt-screen and piping stdio the bash child had no usable TTY. Now those actions suspend ratatui and run with the real terminal, then restore the TUI.

## [3.1.0] - 2026-05-23

### Added
- **流式日志 TUI** / Streaming-log TUI panel — every action runs inside a ratatui split-pane view with semantic color levels (info/step/ok/warn/err), live scrolling, error highlighting, and PgUp/PgDn manual scroll.
- **离线 CHANGELOG 渲染** / Offline CHANGELOG rendering — `xynrin update` now shows release notes before applying, fully offline via `include_str!` (no GitHub API calls).
- **proot 发行版管理** / proot distro management — option 3 now lets you list, log in, AND delete distros (alias removal across `~/.bashrc`, `~/.zshrc`, `~/.config/fish/config.fish`).
- **Shell 美化** / Shell beautify variants — option 7 now offers bash+starship / zsh+oh-my-zsh+powerlevel10k / fish+fisher+tide.
- **响应式布局** / Responsive layout — TUI adapts to narrow terminals, banner collapses gracefully on small screens.
- **bootstrap TUI** — first-time install also runs inside the ratatui interface once the Rust binary is on disk.
- **新 CLI 子命令** / New CLI subcommands — `xynrin sysinfo`, `xynrin update --show-notes`, `xynrin --bootstrap`.

### Changed
- **菜单交互** / Menu interaction — no more alt-screen flicker; menu stays in left pane, log streams in right pane.
- **bash 模块化** / Bash modularization — `tui/xynrin` split into `tui/modules/{update,proot,sysinfo,mirror,beautify,language,bootstrap}.sh` for easier extension.
- **Rust TUI 模块化** / Rust modularization — `main.rs` split into `app.rs` / `i18n.rs` (HashMap-based) / `runner.rs` / `changelog.rs` / `ui/*`.
- **system info 自写** / Self-rendered system info — option 4 no longer hard-depends on `fastfetch`; built-in renderer covers OS, kernel, CPU, RAM, storage, battery, distros.
- **alias 多 shell 写入** / Multi-shell alias — option 2 now writes the distro alias to bash, zsh, and fish rc files when present.
- **release 流程** / Release flow — `scripts/release.sh` and CI both pull release body from `CHANGELOG.md` via the shared `scripts/extract-changelog.sh` (replaces auto-generated commit list).

### Fixed
- 选项 3 现在能真正删除发行版 / Option 3 can actually delete distros (and clean up aliases).
- 选项 2 安装后 alias 在 zsh / fish 用户下也能生效 / Option 2 alias now works for zsh / fish users, not just bash.

## [3.0.0] - 2026-05-23

### Added
- Rust + ratatui TUI rewrite, with bash kept as fallback engine.
- Pre-built Android binaries (aarch64 / armv7 / x86_64) attached to GitHub Releases.
- `xynrin-bash` command — direct access to the bash engine.

### Changed
- Command renamed from `termux-tools` to `xynrin` (avoids conflict with the official Termux package).
- `install.sh` now deploys Rust binary preferentially, with bash symlink fallback.
