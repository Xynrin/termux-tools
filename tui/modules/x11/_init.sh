#!/usr/bin/env bash
# tui/modules/x11/_init.sh - 共享常量 + 加载 _common
# Shared constants + load _common
[[ -n "${__XYNRIN_X11_INIT:-}" ]] && return 0
__XYNRIN_X11_INIT=1

X11_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$X11_DIR/../_common.sh"

# start-desktop 启动脚本路径 / launcher script path
X11_LAUNCHER="${PREFIX:-/data/data/com.termux/files/usr}/bin/start-desktop"
