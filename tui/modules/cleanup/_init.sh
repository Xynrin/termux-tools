#!/usr/bin/env bash
# tui/modules/cleanup/_init.sh - 共享常量 + 加载 _common
# Shared constants + load _common
[[ -n "${__XYNRIN_CLEANUP_INIT:-}" ]] && return 0
__XYNRIN_CLEANUP_INIT=1

CLEANUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CLEANUP_DIR/../_common.sh"

# Termux 路径前缀（PREFIX 由 termux 注入；非 termux 环境给个安全默认值）
# Termux path prefix (PREFIX is injected by termux; safe default elsewhere)
CLEANUP_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

# proot rootfs 父目录 / proot rootfs parent dir
CLEANUP_ROOTFS_PARENT="$CLEANUP_PREFIX/var/lib/proot-distro/installed-rootfs"

# 取一个路径的可读总占用，失败回 "?"
# Get human-readable total of a path, "?" on failure
cleanup_du_human() {
    local path="$1"
    [[ -e "$path" ]] || { printf '0B'; return 0; }
    du -sh "$path" 2>/dev/null | awk '{print $1}' || true
}
