#!/usr/bin/env bash
# tui/modules/boot/_init.sh - 共享常量 + 加载 _common
# Shared constants + load _common
[[ -n "${__XYNRIN_BOOT_INIT:-}" ]] && return 0
__XYNRIN_BOOT_INIT=1

BOOT_MOD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../_common.sh
source "$BOOT_MOD_DIR/../_common.sh"

# Termux:Boot 开机自启目录 / Termux:Boot autostart drop-folder
BOOT_DIR="$HOME/.termux/boot"

# Termux 完整 sh 路径 — boot 脚本 shebang 必须用这个，不能写 /bin/sh
# Full Termux sh path — boot script shebang must use this, never /bin/sh
BOOT_SHEBANG="#!/data/data/com.termux/files/usr/bin/sh"

# 可执行 bin 目录（用来探测 start-desktop 是否已生成）
# Termux bin dir (used to probe whether start-desktop already exists)
BOOT_BIN_DIR="${PREFIX:-/data/data/com.termux/files/usr}/bin"

# 共用：检查 BOOT_DIR 是否存在；不存在时提示先 enable
# Shared guard: warn when BOOT_DIR is missing and tell user to enable first
boot_require_dir() {
    if [[ ! -d "$BOOT_DIR" ]]; then
        log_warn "${MSG_BOOT_NOT_ENABLED:-Boot dir missing — pick \"Enable boot dir\" first}"
        return 1
    fi
    return 0
}
