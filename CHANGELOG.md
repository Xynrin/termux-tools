# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.2.1] - 2026-05-24

### Fixed
- **子进程退出码被忽略** / Subprocess exit code ignored — `runner.rs` 的等待线程之前轮询 `/proc/<pid>` 是否存在，存在就一直等，消失就硬编码 `Done(0)`，连 `Bash` 脚本因为 `pkg install` 报错、断网、命令不存在退出非 0 也会被 UI 标成"成功"。现在用 `child.wait()` 阻塞等真实退出，把 `ExitStatus.code()`（或 `signal+128`）回传，App 拿到后写进 `last_exit_code`，`Screen::Running.exit_ok` 终于和现实一致。
- **运行结果 UI 不显示成功/失败** / Log panel never showed run status — `running.done` / `running.failed` i18n 串和 `exit_ok` 字段一直是死代码。`log_panel` 现在根据 `exit_ok` 切边框颜色和标题：成功绿框 `[✓ 操作完成]`，失败红框 `[✗ 操作失败]`，日志读起来一眼能看出结果。
- **覆盖用户 termux.properties** / Beautify clobbered user's termux.properties — 老逻辑直接 `cat > "$props"`，会清掉用户自己定制的 extra-keys、字体缩放、输入映射等私有配置；卸载又只删文件不还原备份。现在用 `# xynrin-beautify-start` / `# xynrin-beautify-end` 段标记非破坏性合并：先 `sed` 剥旧段，再 `cat >>` 追加新段；卸载只移除带标记的段，用户其它配置不动。
- **每帧重新解析 CHANGELOG** / Changelog re-parsed every frame — `notes_panel::draw` 每次渲染都调 `changelog::latest()`，里面跑一遍 `RAW.lines()` 遍历 + 每行 `String::push_str` 拼 body，移动设备上一帧好几次堆分配。改成在 `App::new()` 里解析一次缓存到 `App.cached_notes`，notes 面板复用引用，零分配。

### 升级路径 / Upgrade Path
- v3.2.0 → v3.2.1 完全无感：`xynrin update` 走 `git pull` + `install.sh --upgrade`，install.sh 只刷符号链接。
- 老用户已经写过的 `~/.termux/termux.properties`（不带 start/end 标记）这次安装新主题时会被一次性切到带标记的格式 —— 后续升级和卸载都不会再清掉用户其它行。


### Changed
- **项目架构重构（向后兼容）** / Architecture refactor (backward compatible) — 每个 UI 子界面 / 每个功能模块独立目录，方便后续模块化扩展。老用户从 v3.1.5 升级路径不受影响：`tui/xynrin` 的 dispatcher 仍以 `modules/<name>` 为入口，beautify 入口保留为 `modules/beautify.sh`（现在是 26 行的薄壳，转发到 `modules/beautify/{_init,themes,shells,preview,uninstall,main}.sh`）。
  - **Rust 端**：`xynrin-tui/src/ui/{banner,footer,log_panel,menu,notes_panel}.rs` → `ui/<name>/mod.rs`，每个屏幕一个目录，后续可加 `helpers.rs` / `state.rs` 而不污染上层。
  - **Bash 端**：416 行的 `tui/modules/beautify.sh` 拆成 6 个文件：`_init.sh`（共享常量）、`themes.sh`（Termux 配色 + 字体）、`shells.sh`（bash/zsh/fish 提示符）、`preview.sh`（fzf 预览）、`uninstall.sh`、`main.sh`（菜单入口）。其它较小模块（mirror/proot/sysinfo/language/update/bootstrap）暂时保留单文件，未来按需同样拆分。

### 升级路径 / Upgrade Path
- v3.1.x → v3.2.0 完全无感：`xynrin update` 走 `git pull` + `install.sh --upgrade`，install.sh 只刷符号链接，dispatcher 入口名不变。
- 静默版本检查 + `XYNRIN_POST_UPGRADE` 标记继承自 v3.1.5，升级后会自动 exec 新二进制并展示本版本 changelog。

## [3.1.5] - 2026-05-24

### Fixed
- **Esc 需要按多次才生效** / Esc required multiple presses — 主循环每 tick 只读一个事件，Resize/Mouse 排队会把 Esc 顶后面。现在每 tick 把 event 队列吃干，按一次就响应。
- **更新后没自动跳新版** / TUI didn't auto-refresh post-upgrade — 新二进制启动时又跑一次静默检查，如果远端 tag 还没刷就误判"没更新"，绕回老菜单。新增 `XYNRIN_POST_UPGRADE=1` 环境变量，升级后 exec 时带上，新二进制识别后跳过静默检查直接进 show-notes。
- **更新确认条不能用回车确认** / Confirm prompt didn't accept Enter — Y/Enter 都视作确认升级，Esc/N 取消，符合常规 TUI 习惯。

### Added
- **zsh p10k 圆角胶囊段** / Rounded zsh prompt segments — 给 powerlevel10k 写入圆形左右 separator（、），整条 prompt 变成 pill 胶囊样式，配合 Nerd Font 显示。
- **架构 v3.2 路线图** / Architecture refactor pinned to v3.2 — 每个功能选项独立目录、每个 UI 子界面独立目录的全面模块化重构会作为 v3.2.0 主题，避免在 bug 修复版本里引入大改动。

## [3.1.4] - 2026-05-24

### Added
- **启动静默检查更新** / Silent update check on launch — 进主菜单前 3 秒超时 git ls-remote 比对版本，发现新版本直接进 update 模式（带 changelog + 确认条），没有就正常进 TUI，全程静默。
- **bootstrap 自带 tree / cat / fastfetch 美化** / Pretty defaults out of the box — 装 lsd（带图标的 ls/tree 替代）+ bat（带语法高亮的 cat 替代）+ fastfetch；写 alias 到 bash/zsh/fish rc：`ls/ll/la/tree → lsd`、`cat → bat`、`neofetch → fastfetch`；交互式 shell 启动时自动跑一次 fastfetch。

### Fixed
- **下载期间快捷键失灵** / Keys frozen during download — `Screen::Bootstrap` 之前只在 `finished:true` 后处理按键，pkg/curl 跑的时候 Esc/q/Tab 全部哑火。现在运行中也响应：Esc/q 杀整个进程组并回菜单，Tab 切焦点，PgUp/PgDn 滚动日志。
- **apt 进度条挤爆日志缓冲** / apt progress spam — 之前 `\r` 进度条每次刷新都进 4096 行 ring buffer，几秒就把真正的步骤日志挤走。runner 现在按 `\r` 切片只保留每行最后一段，进度条折叠成单行流式输出。
- **log_panel 标题硬编码中文** / Log title hardcoded zh — 标题改走 `running.title` + `running.scrolling` i18n key，跟着语言切换刷新。

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
