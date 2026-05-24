#!/usr/bin/env bash
# tui/modules/beautify.sh - 派发壳：把工作分到 beautify/ 子文件
# Thin shim — delegates to the split files in beautify/
#
# v3.2.0 把这个曾经 416 行的大文件拆成了 beautify/ 目录下的小文件：
#   _init.sh      共享常量
#   themes.sh     Termux 配色 + 字体
#   shells.sh     bash/zsh/fish 提示符
#   preview.sh    fzf 主题预览
#   uninstall.sh  卸载
#   main.sh       顶层菜单
# 这个壳保留是为了 v3.1.x 老用户升级时 tui/xynrin 的 load_module 能继续工作
# This shim stays so v3.1.x users mid-upgrade keep working: the dispatcher
# in tui/xynrin still loads "beautify" as one entry point.
set -uo pipefail

_BEAUTIFY_SHIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_BEAUTIFY_SHIM_DIR/beautify/_init.sh"
source "$_BEAUTIFY_SHIM_DIR/beautify/themes.sh"
source "$_BEAUTIFY_SHIM_DIR/beautify/shells.sh"
source "$_BEAUTIFY_SHIM_DIR/beautify/preview.sh"
source "$_BEAUTIFY_SHIM_DIR/beautify/uninstall.sh"
source "$_BEAUTIFY_SHIM_DIR/beautify/main.sh"
