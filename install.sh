#!/usr/bin/env bash
#
# install.sh - 部署 xynrin（Rust 优先 + bash fallback）
# Deploy xynrin (Rust preferred, bash fallback)
#
#   bash install.sh              首次安装 / first install
#   bash install.sh --upgrade    旧版迁移（仅刷链）/ migrate from old version
#
set -euo pipefail

UPGRADE_MODE=0
[[ "${1:-}" == "--upgrade" ]] && UPGRADE_MODE=1

if [[ -z "${TERMUX_VERSION:-}" ]]; then
    echo "错误：请在 Termux 中运行 / Error: must run inside Termux"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BASH_SOURCE_FILE="$SCRIPT_DIR/tui/xynrin"

XYNRIN_BIN="$PREFIX/bin/xynrin"           # Rust 二进制（首选）/ Rust binary preferred
BASH_BIN="$PREFIX/bin/xynrin-bash"        # bash 主程序（fallback + Rust 调用源）
LEGACY_BIN="$PREFIX/bin/termux-tools"

VERSION="$(tr -d '[:space:]' < "$SCRIPT_DIR/scripts/version")"
RUST_TAG="v${VERSION}"
RUST_REPO="https://github.com/Xynrin/termux-tools"

# ============================================================
# 下载预编译 Rust 二进制（必须定义在 UPGRADE_MODE 之前）
# Download pre-built Rust binary (must be defined before UPGRADE_MODE block)
# ============================================================
try_install_rust_binary() {
    local arch asset
    arch="$(uname -m)"
    case "$arch" in
        aarch64|arm64)  asset="xynrin-tui-aarch64-linux-android" ;;
        armv7*|armv8l)  asset="xynrin-tui-armv7-linux-androideabi" ;;
        x86_64)         asset="xynrin-tui-x86_64-linux-android" ;;
        *)              return 1 ;;
    esac

    local url="${RUST_REPO}/releases/download/${RUST_TAG}/${asset}"
    echo "正在下载 Rust TUI / Downloading Rust TUI: $asset"

    local tmp; tmp="$(mktemp)"
    if curl -fsSL --connect-timeout 10 "$url" -o "$tmp"; then
        rm -f "$XYNRIN_BIN"
        mv "$tmp" "$XYNRIN_BIN"
        chmod +x "$XYNRIN_BIN"
        echo "Rust TUI 已安装 / Rust TUI installed"
        return 0
    fi
    rm -f "$tmp"
    echo "Rust TUI 下载失败，将使用 bash 版本 / Rust TUI unavailable, using bash"
    return 1
}

# ============================================================
# 升级模式：仅刷新软链 + 尝试更新 Rust 二进制
# Upgrade mode: refresh symlinks + try to refresh Rust binary
# ============================================================
if [[ $UPGRADE_MODE -eq 1 ]]; then
    echo "正在迁移 / Migrating..."
    rm -f "$LEGACY_BIN" "$BASH_BIN"
    ln -s "$BASH_SOURCE_FILE" "$BASH_BIN"
    chmod +x "$BASH_SOURCE_FILE"

    if ! try_install_rust_binary; then
        rm -f "$XYNRIN_BIN"
        ln -s "$BASH_SOURCE_FILE" "$XYNRIN_BIN"
    fi
    echo "迁移完成 / Migration done"
    exit 0
fi

# ============================================================
# 首次安装：在没有 Rust 二进制时由 bootstrap.sh 接管 TUI 部署
# First install: bootstrap.sh hands off to the Rust TUI for deps + Ubuntu
# 这里只做最小依赖（curl/git/fzf）和软链部署
# Here we only handle minimal deps (curl/git/fzf) and symlink deploy
# ============================================================
echo "正在安装基础依赖 / Installing base deps..."
pkg update -y &>/dev/null || true
pkg install -y curl git fzf &>/dev/null || true

rm -f "$BASH_BIN" "$LEGACY_BIN"
ln -s "$BASH_SOURCE_FILE" "$BASH_BIN"
chmod +x "$BASH_SOURCE_FILE"

if ! try_install_rust_binary; then
    rm -f "$XYNRIN_BIN"
    ln -s "$BASH_SOURCE_FILE" "$XYNRIN_BIN"
fi

# ============================================================
# 把后续部署（pkg upgrade、proot-distro 等）交给 TUI
# Hand off the rest of the deploy (pkg upgrade, proot-distro etc.) to the TUI
# ============================================================
echo ""
echo "正在启动 xynrin 部署界面 / Launching xynrin bootstrap TUI..."
echo ""
exec "$XYNRIN_BIN" --bootstrap
