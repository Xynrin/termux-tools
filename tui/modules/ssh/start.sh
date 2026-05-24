#!/usr/bin/env bash
# tui/modules/ssh/start.sh - 启动 sshd
# Start sshd

ssh_start_action() {
    if pgrep sshd > /dev/null 2>&1; then
        log_warn "${MSG_SSH_ALREADY_RUNNING:-sshd is already running}"
        return 0
    fi
    log_step "${MSG_SSH_STARTING:-Starting sshd}"
    sshd 2>/dev/null || true
    sleep 0.5
    if pgrep sshd > /dev/null 2>&1; then
        log_ok "${MSG_SSH_RUNNING:-sshd running}"
    else
        log_err "${MSG_SSH_START_FAIL:-sshd failed to start}"
        return 1
    fi
}
