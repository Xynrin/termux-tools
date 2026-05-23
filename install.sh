#!/usr/bin/env bash
#
# termux-tools / xynrin 安装脚本
# Install script for termux-tools / xynrin
#
# 用法 / Usage:
#   bash install.sh              首次安装 / first install
#   bash install.sh --upgrade    旧版迁移（仅同步链接，不重装容器）/ migrate from old version
#

set -euo pipefail

UPGRADE_MODE=0
if [[ "${1:-}" == "--upgrade" ]]; then
    UPGRADE_MODE=1
fi

# ============================================================
# 依赖包 / Dependencies
# ============================================================
PACKAGES=(curl git wget fzf fastfetch proot-distro)

# ============================================================
# Termux 检测 / Detect Termux
# ============================================================
if [[ -z "${TERMUX_VERSION:-}" ]]; then
    echo "错误：请在 Termux 中运行。"
    echo "Error: Please run inside Termux."
    exit 1
fi

# ============================================================
# 路径 / Paths
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
TUI_SOURCE="$SCRIPT_DIR/tui/xynrin"
TUI_TARGET="$PREFIX/bin/xynrin"
LEGACY_TARGET="$PREFIX/bin/termux-tools"

# ============================================================
# 升级模式：仅刷新软链 / Upgrade mode: just refresh symlink
# ============================================================
if [[ $UPGRADE_MODE -eq 1 ]]; then
    echo "正在迁移到 xynrin... / Migrating to xynrin..."

    # 移除旧 termux-tools 命令（无论它是软链还是文件）
    # Remove old termux-tools command (symlink or file)
    rm -f "$LEGACY_TARGET"

    # 重建 xynrin 软链 / Re-link xynrin
    rm -f "$TUI_TARGET"
    ln -s "$TUI_SOURCE" "$TUI_TARGET"
    chmod +x "$TUI_SOURCE"

    echo "迁移完成！请使用 xynrin 命令。"
    echo "Migration done! Use the xynrin command."
    exit 0
fi

# ============================================================
# 系统更新 + 依赖 / System update + deps
# ============================================================
echo "正在更新系统并安装依赖... / Updating system and installing deps..."
pkg update -y && pkg upgrade -y
pkg install -y "${PACKAGES[@]}"

# ============================================================
# 部署主命令 / Deploy main command
# ============================================================
# 因官方包名冲突，强制使用 xynrin / Use xynrin to avoid conflict
rm -f "$TUI_TARGET" "$LEGACY_TARGET"
ln -s "$TUI_SOURCE" "$TUI_TARGET"
chmod +x "$TUI_SOURCE"

# ============================================================
# 默认安装 Ubuntu 容器 / Install Ubuntu by default
# ============================================================
echo ""
echo "正在安装默认容器：Ubuntu... / Installing default container: Ubuntu..."
proot-distro install ubuntu || echo "（Ubuntu 已安装或安装失败 / Ubuntu already installed or failed）"

# ============================================================
# 配置常用容器别名 / Set up common container aliases
# ============================================================
ALIASES_FILE="$SCRIPT_DIR/.aliases"
RC="$HOME/.bashrc"

# Termux 默认 shell 是 bash，确保 .bashrc 存在
# Default Termux shell is bash; ensure .bashrc exists
touch "$RC"

# 仅为已安装的容器写别名 / Only write alias for installed distros
add_alias_if_installed() {
    local name="$1"
    local installed
    installed="$(proot-distro list --installed 2>/dev/null | grep -E "^$name\b" || true)"
    if [[ -n "$installed" ]]; then
        local line="alias ${name}='proot-distro login ${name}'"
        if ! grep -qF "$line" "$RC"; then
            echo "$line" >> "$RC"
        fi
        if ! grep -qx "$name" "$ALIASES_FILE" 2>/dev/null; then
            echo "$name" >> "$ALIASES_FILE"
        fi
    fi
}

# 默认仅 Ubuntu，但若用户已安装其他容器也会被识别
# Default just Ubuntu, but other installed distros are also picked up
for d in ubuntu debian archlinux fedora alpine; do
    add_alias_if_installed "$d"
done

# ============================================================
# 打印已配置的别名 / Print configured aliases
# ============================================================
echo ""
echo "==================================================="
echo "  已配置的发行版别名 / Configured distro aliases"
echo "==================================================="
if [[ -s "$ALIASES_FILE" ]]; then
    while IFS= read -r alias_name; do
        echo "  $alias_name  →  proot-distro login $alias_name"
    done < "$ALIASES_FILE"
    echo ""
    echo "重启终端或运行：source ~/.bashrc"
    echo "Restart shell or run: source ~/.bashrc"
else
    echo "  （无 / none）"
fi
echo "==================================================="
echo ""

# ============================================================
# 启动 TUI / Launch TUI
# ============================================================
echo "正在启动 xynrin... / Launching xynrin..."
echo ""
exec "$TUI_TARGET"
