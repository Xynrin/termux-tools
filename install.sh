#!/usr/bin/env bash
#
# termux-tools / xynrin 安装脚本
#   bash install.sh              首次安装 / first install
#   bash install.sh --upgrade    旧版迁移（仅刷链）/ migrate from old version
#
set -euo pipefail

UPGRADE_MODE=0
[[ "${1:-}" == "--upgrade" ]] && UPGRADE_MODE=1

# ============================================================
# Termux 检测
# ============================================================
if [[ -z "${TERMUX_VERSION:-}" ]]; then
    echo "错误：请在 Termux 中运行 / Error: must run inside Termux"
    exit 1
fi

# ============================================================
# 路径
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BASH_SOURCE_FILE="$SCRIPT_DIR/tui/xynrin"

# 二进制部署目标 / binary deploy target
XYNRIN_BIN="$PREFIX/bin/xynrin"           # Rust 二进制（首选）/ Rust binary preferred
BASH_BIN="$PREFIX/bin/xynrin-bash"        # bash 主程序（fallback + Rust 调用源）
LEGACY_BIN="$PREFIX/bin/termux-tools"

# Rust 二进制下载 URL（按 tag 取最新）
# Rust binary download URLs (latest tag)
VERSION="$(cat "$SCRIPT_DIR/scripts/version" | tr -d '[:space:]')"
RUST_TAG="v${VERSION}"
RUST_REPO="https://github.com/Xynrin/termux-tools"

# ============================================================
# 尝试下载预编译的 Rust 二进制
# Try fetching pre-built Rust binary
# 必须定义在 UPGRADE_MODE 块之前，因为升级路径会调用它
# Must be defined before the UPGRADE_MODE block, since upgrade calls it
# ============================================================
try_install_rust_binary() {
    local arch
    arch="$(uname -m)"
    local asset
    case "$arch" in
        aarch64|arm64)  asset="xynrin-tui-aarch64-linux-android" ;;
        armv7*|armv8l)  asset="xynrin-tui-armv7-linux-androideabi" ;;
        x86_64)         asset="xynrin-tui-x86_64-linux-android" ;;
        *)              return 1 ;;
    esac

    local url="${RUST_REPO}/releases/download/${RUST_TAG}/${asset}"
    echo "正在下载 Rust TUI / Downloading Rust TUI: $asset"

    local tmp
    tmp="$(mktemp)"
    if curl -fsSL --connect-timeout 10 "$url" -o "$tmp"; then
        rm -f "$XYNRIN_BIN"
        mv "$tmp" "$XYNRIN_BIN"
        chmod +x "$XYNRIN_BIN"
        echo "Rust TUI 已安装 / Rust TUI installed"
        return 0
    fi
    rm -f "$tmp"
    echo "Rust TUI 下载失败，将使用 bash 版本 / Rust TUI unavailable, using bash version"
    return 1
}

# ============================================================
# 升级模式：刷新 bash 软链 + 尝试更新 Rust 二进制
# ============================================================
if [[ $UPGRADE_MODE -eq 1 ]]; then
    echo "正在迁移 / Migrating..."
    rm -f "$LEGACY_BIN"
    rm -f "$BASH_BIN"
    ln -s "$BASH_SOURCE_FILE" "$BASH_BIN"
    chmod +x "$BASH_SOURCE_FILE"

    # 尝试拉 Rust 二进制；失败则保持 bash
    # Try to fetch the Rust binary; keep bash on failure
    if try_install_rust_binary; then
        :
    else
        # 没有 Rust 二进制时，让 xynrin 直接指向 bash 版
        # Without Rust, point xynrin at the bash version
        rm -f "$XYNRIN_BIN"
        ln -s "$BASH_SOURCE_FILE" "$XYNRIN_BIN"
    fi
    echo "迁移完成 / Migration done"
    exit 0
fi

# ============================================================
# 安装依赖
# ============================================================
PACKAGES=(curl git wget fzf fastfetch proot-distro)
echo "正在更新系统并安装依赖... / Updating system and installing deps..."
pkg update -y && pkg upgrade -y
pkg install -y "${PACKAGES[@]}"

# ============================================================
# 部署 bash 主程序（Rust 会调用它）
# Deploy bash main (Rust delegates to this)
# ============================================================
rm -f "$BASH_BIN" "$LEGACY_BIN"
ln -s "$BASH_SOURCE_FILE" "$BASH_BIN"
chmod +x "$BASH_SOURCE_FILE"

# ============================================================
# 部署 xynrin（Rust 优先，失败则回退到 bash）
# Deploy xynrin (Rust preferred, fallback to bash)
# ============================================================
if ! try_install_rust_binary; then
    rm -f "$XYNRIN_BIN"
    ln -s "$BASH_SOURCE_FILE" "$XYNRIN_BIN"
fi

# ============================================================
# 默认 Ubuntu 容器
# ============================================================
echo ""
echo "正在安装默认容器：Ubuntu... / Installing Ubuntu..."
proot-distro install ubuntu || echo "（Ubuntu 已存在或失败 / already installed or failed）"

# ============================================================
# 配置常用容器别名
# ============================================================
ALIASES_FILE="$SCRIPT_DIR/.aliases"
RC="$HOME/.bashrc"
touch "$RC"

add_alias_if_installed() {
    local name="$1"
    if proot-distro list --installed 2>/dev/null | grep -qE "^[[:space:]]*\*?[[:space:]]*${name}([[:space:]]|$)"; then
        local line="alias ${name}='proot-distro login ${name}'"
        grep -qF "$line" "$RC" || echo "$line" >> "$RC"
        grep -qx "$name" "$ALIASES_FILE" 2>/dev/null || echo "$name" >> "$ALIASES_FILE"
    fi
}

for d in ubuntu debian archlinux fedora alpine; do
    add_alias_if_installed "$d"
done

# ============================================================
# 打印别名
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
else
    echo "  （无 / none）"
fi
echo "==================================================="
echo ""

# ============================================================
# 启动 TUI
# ============================================================
echo "正在启动 xynrin... / Launching xynrin..."
echo ""
exec "$XYNRIN_BIN"
