#!/usr/bin/env bash
#
# bootstrap.sh - 一行命令在线安装入口 / One-line online installer
#
# 用法 / Usage:
#   curl -sL https://raw.githubusercontent.com/Xynrin/termux-tools/main/bootstrap.sh | bash
#

set -euo pipefail

REPO="https://github.com/Xynrin/termux-tools.git"
TARGET="$HOME/termux-tools"
RAW="https://raw.githubusercontent.com/Xynrin/termux-tools/main"

# ============================================================
# 颜色 / Colors
# ============================================================
ORANGE='\e[38;5;202m'
GOLD='\e[38;5;214m'
YELLOW='\e[38;5;226m'
GREEN='\e[32m'
CYAN='\e[36m'
BLUE='\e[34m'
BOLD='\e[1m'
RESET='\e[0m'

# ============================================================
# Logo / Logo
# ============================================================
show_logo() {
    echo ""
    echo -e "${BOLD}${ORANGE} ██╗  ██╗██╗   ██╗███╗   ██╗██████╗ ██╗███╗   ██╗${RESET}"
    echo -e "${BOLD}${ORANGE} ╚██╗██╔╝╚██╗ ██╔╝████╗  ██║██╔══██╗██║████╗  ██║${RESET}"
    echo -e "${BOLD}${GOLD}  ╚███╔╝  ╚████╔╝ ██╔██╗ ██║██████╔╝██║██╔██╗ ██║${RESET}"
    echo -e "${BOLD}${GOLD}  ██╔██╗   ╚██╔╝  ██║╚██╗██║██╔══██╗██║██║╚██╗██║${RESET}"
    echo -e "${BOLD}${YELLOW} ██╔╝ ██╗   ██║   ██║ ╚████║██║  ██║██║██║ ╚████║${RESET}"
    echo -e "${BOLD}${YELLOW} ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝${RESET}"
    echo -e "${BOLD}${ORANGE}              T E R M U X   T O O L S${RESET}"
    echo ""
}

# ============================================================
# Termux 检测 / Termux detection
# ============================================================
if [[ -z "${TERMUX_VERSION:-}" ]]; then
    echo "错误：请在 Termux 中运行此脚本。"
    echo "Error: This script must be run inside Termux."
    exit 1
fi

show_logo

# 获取远程版本号 / Fetch remote version
VERSION="$(curl -sL "$RAW/scripts/version" 2>/dev/null | tr -d '[:space:]' || echo unknown)"

echo -e "  ${BOLD}${CYAN}Version${RESET}  ${GREEN}v${VERSION}${RESET}"
echo -e "  ${BOLD}${CYAN}Author${RESET}   ${GREEN}Xynrin${RESET}"
echo -e "  ${BOLD}${CYAN}Repo${RESET}     ${BLUE}https://github.com/Xynrin/termux-tools${RESET}"
echo ""

# ============================================================
# 安装 git 以便克隆 / Ensure git for cloning
# ============================================================
if ! command -v git &> /dev/null; then
    echo "正在安装 git... / Installing git..."
    pkg install -y git
fi

# ============================================================
# 克隆或更新仓库 / Clone or update repo
# ============================================================
if [[ -d "$TARGET/.git" ]]; then
    echo "仓库已存在，正在更新... / Repo exists, pulling latest..."
    ( cd "$TARGET" && git pull --ff-only origin main )
else
    echo "正在克隆仓库到 $TARGET ... / Cloning to $TARGET ..."
    rm -rf "$TARGET"
    git clone "$REPO" "$TARGET"
fi

# ============================================================
# 执行 install.sh / Run install.sh
# ============================================================
echo ""
echo "正在运行安装脚本... / Running installer..."
cd "$TARGET"
exec bash install.sh
