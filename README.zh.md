<div align="center">

# termux-tools

**为 Termux 小白打造的 TUI 辅助工具**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-brightgreen.svg)](scripts/version)
[![Platform](https://img.shields.io/badge/platform-Termux-black.svg)](https://termux.dev)
[![Language](https://img.shields.io/badge/lang-Bash-89e051.svg)](https://www.gnu.org/software/bash/)

[English README](README.md) · [报告 Bug](https://github.com/Xynrin/termux-tools/issues) · [功能建议](https://github.com/Xynrin/termux-tools/issues)

</div>

---

## 项目简介

`termux-tools` 是一个面向 Termux 小白的 TUI 辅助工具，几次按键即可完成常见操作 —— 安装 Linux 发行版、管理 proot 环境、自我更新，无需记忆复杂命令。

## 功能特性

| | |
|---|---|
| **自动语言** | 检测 locale，自动显示中文或英文界面 |
| **自我更新** | 对比本地与远程版本，一键拉取更新 |
| **proot 助手** | 不用记完整命令即可安装/登录发行版 |
| **系统信息** | 一键查看操作系统、内核、架构、Termux 版本 |
| **CLI 模式** | 在 TUI 之外提供完整命令行接口 |
| **零依赖** | 纯 Bash 实现，无需 dialog/whiptail/python |

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/Xynrin/termux-tools.git
cd termux-tools

# 安装（在 Termux 中运行）
bash install.sh

# 启动
termux-tools
```

## 使用方法

### 交互式 TUI

```bash
termux-tools           # 打开主菜单
```

### 命令行

```bash
termux-tools help      # 查看帮助
termux-tools version   # 查看当前版本
termux-tools update    # 检查并拉取更新
termux-tools menu      # 显式打开 TUI
```

### 菜单选项

| 按键 | 功能 |
|:---:|---|
| `1` | 更新 termux-tools |
| `2` | 使用 proot 安装发行版 |
| `3` | 登录已安装的 proot 发行版 |
| `4` | 查看系统信息 |
| `5` | 切换界面语言 |
| `0` | 退出 |

## 项目结构

```
termux-tools/
├── README.md              # 英文文档
├── README.zh.md           # 中文文档
├── LICENSE                # GPL-v3 许可证
├── .gitignore             # Git 忽略规则
├── install.sh             # 主安装脚本
├── install-scripts/
│   └── install-tui        # TUI 独立安装脚本
├── scripts/
│   └── version            # 版本文件（用于更新检查）
└── tui/
    ├── termux-tools       # 主程序
    └── lang/
        ├── zh.sh          # 中文语言包
        └── en.sh          # 英文语言包
```

## 工作流程

```
                      ┌─────────────────┐
                      │  termux-tools   │
                      └────────┬────────┘
                               │
            ┌──────────────────┼──────────────────┐
            ▼                  ▼                  ▼
       ┌─────────┐        ┌─────────┐        ┌─────────┐
       │   CLI   │        │   TUI   │        │  i18n   │
       │ help/   │        │  菜单   │        │ 中/英   │
       │version/ │        │ 循环    │        │  自动   │
       │ update  │        │         │        │  检测   │
       └─────────┘        └────┬────┘        └─────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
        ┌──────────┐     ┌──────────┐     ┌──────────┐
        │  更新    │     │  proot   │     │  系统    │
        │  检查    │     │  安装/   │     │  信息    │
        │ + 拉取   │     │  登录    │     │          │
        └──────────┘     └──────────┘     └──────────┘
```

## 添加新语言

1. 复制 `tui/lang/en.sh` 为 `tui/lang/<你的locale>.sh`
2. 翻译所有 `MSG_*`、`OPT_*`、`MENU_*`、`CLI_*`、`LANG_*` 变量值
3. 必要时修改 `tui/termux-tools` 中的 `detect_language()` 函数
4. 用 `LANG=<你的locale> termux-tools` 测试

## 系统要求

- Termux（建议最新稳定版）
- 网络连接（用于安装与更新）
- 大约 5 MB 可用空间

## 许可证

本项目基于 [GPL-v3](LICENSE) 许可证开源。

## 作者

**Xynrin** — [GitHub 主页](https://github.com/Xynrin)

<div align="center">

为 Termux 小白而做，欢迎 PR。

</div>
