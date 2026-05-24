#!/usr/bin/env bash
# tui/modules/ssh/install.sh - 安装 openssh + 引导用户设密码
# Install openssh and walk the user through setting a login password

ssh_install_action() {
    log_step "${MSG_SSH_INSTALLING:-Installing openssh}"
    if ! pkg install -y openssh; then
        log_err "${MSG_SSH_INSTALL_FAIL:-openssh install failed}"
        return 1
    fi
    log_ok "${MSG_SSH_INSTALLED:-openssh installed}"

    log_info "${MSG_SSH_PASSWD_HINT:-Set a login password (used by ssh)}"
    log_step "${MSG_SSH_PASSWD_RUN:-Running passwd}"
    # passwd 直接和真终端交互（ratatui 此时已挂起）
    # passwd talks to the real TTY directly (ratatui is suspended here)
    if passwd; then
        log_ok "${MSG_SSH_PASSWD_OK:-Password set}"
    else
        log_warn "${MSG_SSH_PASSWD_SKIP:-passwd skipped or failed}"
    fi
}
