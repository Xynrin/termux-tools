#!/usr/bin/env bash
# tui/modules/ssh/stop.sh - 停止 sshd
# Stop sshd

ssh_stop_action() {
    log_step "${MSG_SSH_STOPPING:-Stopping sshd}"
    pkill sshd 2>/dev/null || true
    log_ok "${MSG_SSH_STOPPED:-sshd stopped}"
}
