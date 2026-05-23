<div align="center">

# xynrin

**为 Termux 小白打造的 TUI 辅助工具**

[![License](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-3.0.0-brightgreen.svg)](scripts/version)
[![Platform](https://img.shields.io/badge/platform-Termux-black.svg)](https://termux.dev)

[English README](README.md) · [Issues](https://github.com/Xynrin/termux-tools/issues)

</div>

> **v3.0.0**：TUI 用 **Rust + ratatui** 重写，原生体验更流畅。bash 版本继续保留为 fallback，并且仍是所有功能的真正引擎 —— Rust 只负责界面。老用户运行 `xynrin update` 即可平滑升级。
>
> **v2.0.0**：命令名由 `termux-tools` 改为 `xynrin`（官方 `termux-tools` 包名冲突）。老用户只需运行一次 `termux-tools update`，会自动迁移。

## 一行安装

```bash
curl -sL https://raw.githubusercontent.com/Xynrin/termux-tools/main/bootstrap.sh | bash
```

引导脚本会：
1. 显示 Logo + 版本号 + 作者 + 仓库地址
2. 克隆仓库到 `~/termux-tools`
3. 安装依赖；尝试下载与你 CPU 匹配的 **Rust TUI 二进制**，下载失败时自动回退到 bash 版 TUI
4. 通过 `proot-distro` 默认安装 Ubuntu，并配置别名（如 `ubuntu`）
5. 打印已配置的别名后，自动进入 TUI

## 手动安装

```bash
git clone https://github.com/Xynrin/termux-tools.git ~/termux-tools
cd ~/termux-tools
bash install.sh
```

## 使用方法

```bash
xynrin              # 打开 TUI（有 Rust 走 Rust，没有就 bash）
xynrin-bash         # 始终走 bash 版 TUI
xynrin help         # CLI 帮助
xynrin version      # 查看版本
xynrin update       # 检查并拉取更新
```

## TUI 菜单

| 按键 | 功能 |
|:---:|---|
| `1` | 更新 xynrin |
| `2` | 使用 proot 安装发行版 |
| `3` | 列出发行版别名（只显示真实可用的） |
| `4` | 系统信息 |
| `5` | 添加或设置镜像源 |
| `6` | 切换语言 |
| `7` | 美化 Termux |
| `8` | 退出 |

## 架构（v3.0.0）

```
┌─────────────────────────┐
│  xynrin  (Rust TUI)     │  ← 首选，原生二进制
└───────────┬─────────────┘
            │ 委托给
            ▼
┌─────────────────────────┐
│  xynrin-bash  (bash)    │  ← 真正的实现，也是 fallback TUI
└─────────────────────────┘
```

Rust 二进制只画菜单界面；每个具体操作（安装发行版、更新、镜像、美化……）都通过 `xynrin-bash --menu-<动作>` 委托给 bash 主程序。当你的 CPU 没有对应的 Rust 二进制时，`xynrin` 就是一个指向 bash 版的软链，体验完全不会断。

## 发行版别名

通过选项 `2` 安装发行版后，会自动写入 `~/.bashrc` 别名。运行 `source ~/.bashrc`（或重启终端），就可直接登录：

```bash
ubuntu      # = proot-distro login ubuntu
debian      # = proot-distro login debian
```

选项 `3` 只会展示**实际已安装并已配置别名**的容器，不会有失效条目。

## 镜像源（选项 5）

快速切换 Termux APT 镜像，内置：

- 清华大学（中国）
- 中科大（中国）
- 官方 `packages.termux.dev`
- 或调用 `termux-change-repo` 交互式选择

## 项目结构

```
termux-tools/
├── bootstrap.sh          # 一行命令在线安装入口
├── install.sh            # 主安装脚本（Rust 二进制 + bash fallback）
├── tui/
│   ├── xynrin            # bash 主程序（真正的引擎，始终部署）
│   └── lang/{zh,en}.sh   # 语言包
├── xynrin-tui/           # Rust + ratatui TUI 源码
│   ├── Cargo.toml
│   └── src/main.rs
├── install-scripts/
│   └── install-tui       # 软链刷新脚本
├── scripts/
│   ├── version           # 版本文件
│   └── release.sh        # 一键打 tag + 发布
├── .github/workflows/
│   └── release.yml       # 推 tag 时跨平台编译 Rust 二进制
├── LICENSE               # GPL-v3
└── README.{md,zh.md}
```

## 许可证

[GPL-v3](LICENSE) · 作者：**Xynrin**
