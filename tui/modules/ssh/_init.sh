#!/usr/bin/env bash
# tui/modules/ssh/_init.sh - 共享常量 + 加载 _common
# Shared constants + load _common
[[ -n "${__XYNRIN_SSH_INIT:-}" ]] && return 0
__XYNRIN_SSH_INIT=1

SSH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SSH_DIR/../_common.sh"

# Termux openssh 默认端口 / Termux openssh default port
SSH_PORT=8022

# 开机自启脚本路径 / Boot autostart script path
SSH_BOOT_FILE="$HOME/.termux/boot/start-sshd"
