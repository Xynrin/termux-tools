#!/usr/bin/env bash
# tui/modules/beautify/_init.sh - 共享常量 + 加载 _common
# Shared constants + load _common
[[ -n "${__XYNRIN_BEAUTIFY_INIT:-}" ]] && return 0
__XYNRIN_BEAUTIFY_INIT=1

BEAUTIFY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BEAUTIFY_DIR/../_common.sh"

BEAUTIFY_MARKER="# xynrin-beautify"
