#!/usr/bin/env bash
# tui/modules/boot.sh - 派发壳：把工作分到 boot/ 子文件
# Thin shim — delegates to the split files in boot/
#
# v3.3.0 拓展功能 #5：Termux:Boot 开机自启控制台
# v3.3.0 feature #5: Termux:Boot autostart console
#   _init.sh    共享常量 + load _common
#   main.sh     顶层菜单 boot_action
#   list.sh     列出 $BOOT_DIR 下脚本
#   add.sh      添加预设 / 自定义脚本
#   remove.sh   删除脚本（二次确认）
#   toggle.sh   整目录 enable / disable
set -uo pipefail

_BOOT_SHIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_BOOT_SHIM_DIR/boot/_init.sh"
source "$_BOOT_SHIM_DIR/boot/list.sh"
source "$_BOOT_SHIM_DIR/boot/add.sh"
source "$_BOOT_SHIM_DIR/boot/remove.sh"
source "$_BOOT_SHIM_DIR/boot/toggle.sh"
source "$_BOOT_SHIM_DIR/boot/main.sh"
