#!/usr/bin/env bash
# tui/modules/backup.sh - 派发壳：把工作分到 backup/ 子文件
# Thin shim — delegates to the split files in backup/
#
# v3.3.0 拓展功能 #1：proot 容器一键备份/恢复 + 启动器生成器
# v3.3.0 feature #1: one-shot proot container backup/restore + launcher gen
#   _init.sh      共享常量 + load _common
#   main.sh       顶层菜单 backup_action
#   backup.sh     备份已装 distro 到 tar.gz
#   restore.sh    从 tar.gz 恢复 distro
#   launcher.sh   生成 / 删除 xynrin-launch-* 启动器
set -uo pipefail

_BACKUP_SHIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_BACKUP_SHIM_DIR/backup/_init.sh"
source "$_BACKUP_SHIM_DIR/backup/backup.sh"
source "$_BACKUP_SHIM_DIR/backup/restore.sh"
source "$_BACKUP_SHIM_DIR/backup/launcher.sh"
source "$_BACKUP_SHIM_DIR/backup/main.sh"
