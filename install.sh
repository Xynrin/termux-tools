#!/usr/bin/env bash
# 使用 env 查找 bash 解释器，提高跨平台兼容性
# Use env to locate bash interpreter for better cross-platform compatibility
#
# ============================================================
# termux-tools 安装脚本
# termux-tools install script
#
# 功能 / Purpose:
#   1. 检测 Termux 环境 / Detect Termux environment
#   2. 安装依赖包 / Install dependency packages
#   3. 部署主程序到 ~/.local/bin / Deploy main program to ~/.local/bin
#   4. 配置 PATH 环境变量 / Configure PATH environment variable
# ============================================================

# 启用严格模式
# Enable strict mode
#   -e: 命令失败立即退出 / exit on command failure
#   -u: 未定义变量报错 / error on undefined variable
#   -o pipefail: 管道任何命令失败则失败 / pipeline fails if any command fails
set -euo pipefail

# ============================================================
# 依赖包列表
# Dependency package list
# ============================================================
# 数组形式定义依赖包名 / Define package names as array
PACKAGES=(
    curl          # HTTP 客户端，用于下载 / HTTP client for downloads
    git           # 版本控制，用于自我更新 / Version control for self-update
    wget          # 文件下载工具 / File download tool
    fzf           # 模糊查找器，增强交互体验 / Fuzzy finder for better UX
    fastfetch     # 系统信息显示工具 / System info display tool
    proot-distro  # proot 发行版管理工具 / proot distro manager
)

# ============================================================
# Termux 环境检测
# Termux environment detection
# ============================================================

# 通过 TERMUX_VERSION 环境变量判断
# Detect via TERMUX_VERSION environment variable
#   -n: 测试字符串非空 / test string non-empty
#   ${VAR:-}: 默认空字符串避免未定义报错 / default empty to avoid unset error
if [ -n "${TERMUX_VERSION:-}" ]; then
    # 在 Termux 中：显示当前版本
    # In Termux: show current version
    echo "当前运行环境：Termux v${TERMUX_VERSION}"
    echo "Current environment: Termux v${TERMUX_VERSION}"
else
    # 不是 Termux：报错并退出
    # Not Termux: error and exit
    echo "错误：当前环境不是 Termux，请在 Termux 中运行此脚本。"
    echo "Error: Not running in Termux. Please run this script inside Termux."
    exit 1   # 非零退出码表示失败 / non-zero exit indicates failure
fi

# ============================================================
# 系统更新与依赖安装
# System update and dependency installation
# ============================================================

# 提示更新系统
# Notify system update
echo "正在更新系统... / Updating system..."

# pkg 是 Termux 的包管理器（apt 的封装）
# pkg is Termux package manager (apt wrapper)
#   update -y: 自动确认更新软件源 / auto-confirm repo update
#   upgrade -y: 自动确认升级已装包 / auto-confirm package upgrade
#   &&: 前一命令成功才执行后一命令 / run next only if previous succeeded
pkg update -y && pkg upgrade -y

# 安装 PACKAGES 数组中所有依赖
# Install all packages in PACKAGES array
echo "正在安装依赖包... / Installing dependencies..."
#   "${PACKAGES[@]}": 数组展开为多个独立参数 / expand array to separate args
pkg install -y "${PACKAGES[@]}"

# ============================================================
# 部署 TUI 主程序
# Deploy TUI main program
# ============================================================

# 获取脚本所在目录的绝对路径
# Get absolute path of script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# 源文件：项目目录中的主程序
# Source: main program in project directory
TUI_SOURCE="$SCRIPT_DIR/tui/termux-tools"

# 目标：用户本地 bin 目录
# Target: user local bin directory
TUI_TARGET="$HOME/.local/bin/termux-tools"

# 创建目录（-p：父目录不存在时一起创建，已存在不报错）
# Create directory (-p: create parents, no error if exists)
mkdir -p "$HOME/.local/bin"

# 复制主程序
# Copy main program
cp "$TUI_SOURCE" "$TUI_TARGET"

# 添加可执行权限
# Add executable permission
#   +x: 增加 execute 权限 / add execute permission
chmod +x "$TUI_TARGET"

# ============================================================
# 配置 PATH
# Configure PATH
# ============================================================

# 检查 ~/.local/bin 是否已在 PATH 中
# Check whether ~/.local/bin is already in PATH
#   ":$PATH:": 两端加冒号便于子串匹配 / wrap with colons for substring match
#   != *":...:"*: 通配符不匹配（说明不在）/ glob mismatch means not in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    # 把 export 行追加到 ~/.bashrc
    # Append export line to ~/.bashrc
    #   >>: 追加重定向 / append redirect
    #   单引号防止变量提前展开 / single quotes prevent early expansion
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

    # 立即在当前 shell 中生效
    # Apply to current shell session
    export PATH="$HOME/.local/bin:$PATH"
fi

# ============================================================
# 安装完成提示
# Installation complete message
# ============================================================
echo ""
echo "安装完成！ / Installation complete!"
echo "运行 'termux-tools' 启动 TUI 工具。"
echo "Run 'termux-tools' to launch the TUI tool."
echo "运行 'termux-tools help' 查看帮助。"
echo "Run 'termux-tools help' to view help."
