# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.1.3] - 2026-05-24

### Changed
- **取消首次部署的 Ubuntu 强制安装** / Drop forced Ubuntu install on first run — bootstrap 现在只装核心依赖（curl/git/wget/fzf/ncurses-utils），用户想要发行版可以随时进选项 2 自己挑。
- **菜单从 8 项精简为 7 项** / Menu trimmed from 8 to 7 items — 删除「管理已装发行版」选项及其所有相关代码（`Action::ProotManage`、`--menu-proot-manage`、`proot_manage_menu`）。
- **所有 UI 文本走 i18n** / All UI text goes through i18n — banner 标签（Version/Author/Repo）、运行态/确认态/notes 态的提示行都按 key 取串，切换语言后整个 UI 同步刷新。

### Fixed
- **版本号硬编码** / Version-string drift — Cargo.toml 的 `version` 之前被卡在 3.1.0，banner 显示也跟着错。release.sh 现在在打 tag 前自动同步 Cargo.toml，杜绝再次跑偏。
- **ESC 残留进程** / ESC leaves zombies — 之前 ESC 只杀 bash，孙子进程（pkg/curl/git）继续吃 CPU。runner 现在把 bash 放进新 setsid 进程组，try_kill 用 `kill(-pid, SIGTERM)` 杀整个组，1.5s 后还活着升级 SIGKILL。
- **主题预览裸露转义码** / Theme preview leaked raw escape codes — 'EOF' 引号 heredoc 把 `\e[31m` 当字面字符串输出，预览里全是 `[38;2;...m`。改用 `printf '\e[...m'` 真正插入 ESC 字节，配合 fzf `--ansi` 渲染。

### Added
- **升级后无感重启** / Seamless restart after upgrade — `update_apply` 完成时输出 `::restart::`，Rust 端识别后用 `exec` 替换当前进程为新二进制并自动跳到 `update --show-notes`，老 PID 直接消失。
- **镜像损坏自检** / Mirror auto-repair — bootstrap 启动时检测 `sources.list` / `x11.list` / `root.list` 三件套，发现 v3.1.0 残留的半截配置就静默重置为官方源。
- **窄屏自适应优化** / Better narrow-screen layout — banner 在小屏自动塌缩为单行 `xynrin vX.Y.Z by Xynrin`，菜单/日志在 60 列以下纵向堆叠。

## [3.1.2] - 2026-05-23

### Fixed
- **`xynrin update` 直进更新流程** / `xynrin update` goes straight to update flow — previously it dropped users into the main menu TUI; now it boots straight into the streaming-log update screen and exits when finished. Esc/Enter/q after completion exits the program instead of returning to the menu.
- **镜像源 sources.list 修复** / Mirror sources.list fix — v3.1.0 的选项 5 只写了 `termux-main`，导致切换后 x11 / root 仓库丢失，`pkg upgrade` 报 404。现在统一写完整的三件套（main + x11 + root），与官方布局一致。镜像站走 `${base}/apt/termux-{main,x11,root}`，官方走 `packages.termux.dev/apt/<repo>` 各自独立 URL。
- **zsh 美化一气呵成** / Zsh beautify is one-shot now — 不再弹 powerlevel10k 配置向导，不再要求重新登录。安装时设置 `RUNZSH=no CHSH=no KEEP_ZSHRC=no`，写预制 `~/.p10k.zsh`（带 `POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true`），并在 `~/.bashrc` 注入 `exec zsh -l`，下次进 termux 自动进入 zsh。同时打包 zsh-autosuggestions / zsh-syntax-highlighting。

### Added
- **主题预览** / Theme preview — beautify 菜单的 fzf 现在带右栏 ASCII 预览，停留在每个主题选项时实时显示该主题的真实色块、前后景色和示例 prompt。

### Removed
- **删除镜像菜单的「交互式选择」选项** / Removed `termux-change-repo` interactive option from the mirror menu — 官方已不再维护这种交互式入口，子选项 1 现在直接是清华源。

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
