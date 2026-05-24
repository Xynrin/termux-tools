#!/usr/bin/env bash
# tui/modules/x11.sh - 派发壳：把工作分到 x11/ 子文件
# Thin shim — delegates to the split files in x11/
#
# v3.3.0 新增：Termux:X11 + XFCE/LXQt 桌面一键部署
#   _init.sh      共享常量 + _common
#   install.sh    安装 termux-x11 + 桌面 + start-desktop 脚本
#   uninstall.sh  删 start-desktop（桌面包默认保留）
#   main.sh       顶层菜单
set -uo pipefail

_X11_SHIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_X11_SHIM_DIR/x11/_init.sh"
source "$_X11_SHIM_DIR/x11/install.sh"
source "$_X11_SHIM_DIR/x11/uninstall.sh"
source "$_X11_SHIM_DIR/x11/main.sh"
