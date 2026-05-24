#!/usr/bin/env bash
# tui/modules/cleanup.sh - 派发壳：把工作分到 cleanup/ 子文件
# Thin shim — delegates to the split files in cleanup/
#
# v3.3.0 拓展功能 #4：存储空间分析与一键清理
# v3.3.0 feature #4: storage analysis + one-shot cleanup
#   _init.sh   共享常量 + load _common
#   main.sh    顶层菜单 cleanup_action
#   scan.sh    扫描分析（apt/tmp/proot/HOME top10/df）
#   safe.sh    安全清理（apt clean / tmp / ~/.cache）
#   deep.sh    深度清理（safe + journal vacuum + proot 选删，二次确认）
set -uo pipefail

_CLEANUP_SHIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_CLEANUP_SHIM_DIR/cleanup/_init.sh"
source "$_CLEANUP_SHIM_DIR/cleanup/scan.sh"
source "$_CLEANUP_SHIM_DIR/cleanup/safe.sh"
source "$_CLEANUP_SHIM_DIR/cleanup/deep.sh"
source "$_CLEANUP_SHIM_DIR/cleanup/main.sh"
