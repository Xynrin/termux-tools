<div align="center">

# xynrin

**为 Termux 小白打造的 TUI 辅助工具**

[![License](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-3.1.0-brightgreen.svg)](scripts/version)
[![Platform](https://img.shields.io/badge/platform-Termux-black.svg)](https://termux.dev)

[English README](README.md) · [Issues](https://github.com/Xynrin/termux-tools/issues) · [更新日志](CHANGELOG.md)

</div>

> **v3.1.0**：分栏式流式日志 TUI，语义色阶 + 实时滚动；更新前在 TUI 内离线渲染 `CHANGELOG.md`，**整个项目零 GitHub API 调用**。选项 3 支持删除发行版（同步清理多 shell 别名）；选项 7 新增 zsh / fish 提示符配置。
>
> **v3.0.0**：TUI 用 **Rust + ratatui** 重写，bash 版本保留作为兜底引擎。

## 一行安装

```bash
curl -sL https://raw.githubusercontent.com/Xynrin/termux-tools/main/bootstrap.sh | bash
```

bootstrap 只装最小依赖（curl + git）和克隆仓库，剩下的部署步骤（pkg upgrade、fzf/proot-distro、默认 Ubuntu、别名）全部交给 Rust TUI 在实时日志面板里完成。

## 手动安装

```bash
git clone https://github.com/Xynrin/termux-tools.git ~/termux-tools
cd ~/termux-tools
bash install.sh
```

## 命令行

```bash
xynrin                          # 主 TUI
xynrin update                   # 检查 + 显示当前版本 changelog + 确认 + 升级
xynrin update --show-notes      # 离线显示当前版本日志
xynrin sysinfo                  # 纯文本系统信息
xynrin --bootstrap              # 首次部署 TUI
xynrin help / version
xynrin-bash                     # 始终走 bash 兜底引擎
```

## TUI 菜单

| # | 功能 |
|:-:|---|
| 1 | 更新 xynrin |
| 2 | 安装 proot 发行版 |
| 3 | 管理已装发行版（登录 / **删除**，自动清理别名） |
| 4 | 系统信息（自写，不依赖 fastfetch） |
| 5 | 切换镜像源 |
| 6 | 切换语言 |
| 7 | 美化 Termux（主题 + bash/zsh/fish 提示符） |
| 8 | 退出 |

按键：`↑/↓` 或 `j/k` 选择 · `1..8` 直跳 · `Enter` 执行 · `Tab` 切换菜单/日志焦点 · `PgUp/PgDn` 滚日志 · `Esc` 取消运行 · `q` 退出。

## 架构

```
┌─────────────────────────┐
│  xynrin  (Rust TUI)     │  ← 首选，原生二进制，ratatui 分栏
└───────────┬─────────────┘
            │ spawn 子进程，按 ::级别:: 协议捕获 stdout/stderr
            ▼
┌─────────────────────────┐
│  xynrin-bash → modules/ │  ← bash 引擎；每个功能一个模块
└─────────────────────────┘
```

所有动作通过 `xynrin-bash --menu-<动作>` 执行。bash 端按 `::step::` `::ok::` `::warn::` `::err::` `::info::` 协议输出，Rust 端解析并按语义色彩渲染。

## 离线更新日志

`CHANGELOG.md` 通过 `include_str!` 在编译期烧进 Rust 二进制。`xynrin update` 会在 git pull 之前显示当前已装版本的日志；升级完成后 exec `xynrin update --show-notes` 接管显示新版日志。**全程不发 HTTP，不调用 `api.github.com`，无配额限制。**

`scripts/release.sh` 与 GitHub Actions 都通过 `scripts/extract-changelog.sh` 抽取相同的 `## [X.Y.Z]` 段落，并以此作为 GitHub Release body 发布。

## 项目结构

```
termux-tools/
├── CHANGELOG.md
├── bootstrap.sh
├── install.sh
├── tui/
│   ├── xynrin                 （薄派发壳）
│   ├── lang/{zh,en}.sh
│   └── modules/{update,proot,sysinfo,mirror,beautify,language,bootstrap,_common}.sh
├── xynrin-tui/                （Rust + ratatui，无 HTTP 依赖）
│   ├── Cargo.toml
│   └── src/{main,app,i18n,changelog,log_event,runner}.rs + ui/{mod,banner,menu,log_panel,notes_panel,footer}.rs
├── scripts/
│   ├── version
│   ├── extract-changelog.sh
│   └── release.sh
└── .github/workflows/release.yml
```

## 许可证

[GPL-v3](LICENSE) · 作者：**Xynrin**
