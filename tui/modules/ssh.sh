#!/usr/bin/env bash
# tui/modules/ssh.sh - 派发壳：把工作分到 ssh/ 子文件
# Thin shim — delegates to the split files in ssh/
#
# v3.3.0 SSH 一键助手 / SSH one-tap helper:
#   _init.sh      共享常量 + 加载 _common
#   main.sh       顶层菜单 + ssh_action
#   install.sh    安装 openssh + 设密码
#   start.sh      启动 sshd
#   stop.sh       停止 sshd
#   info.sh       显示连接信息
#   boot.sh       开机自启 enable/disable
set -uo pipefail

_SSH_SHIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SSH_SHIM_DIR/ssh/_init.sh"
source "$_SSH_SHIM_DIR/ssh/install.sh"
source "$_SSH_SHIM_DIR/ssh/start.sh"
source "$_SSH_SHIM_DIR/ssh/stop.sh"
source "$_SSH_SHIM_DIR/ssh/info.sh"
source "$_SSH_SHIM_DIR/ssh/boot.sh"
source "$_SSH_SHIM_DIR/ssh/main.sh"
