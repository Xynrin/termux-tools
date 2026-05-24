#!/usr/bin/env bash
# tui/modules/ssh/main.sh - 顶层菜单 (fzf)
# Top-level menu (fzf-driven)

ssh_action() {
    local options=(
        "1) ${MSG_SSH_OPT_INSTALL:-Install openssh & set password}"
        "2) ${MSG_SSH_OPT_START:-Start sshd}"
        "3) ${MSG_SSH_OPT_STOP:-Stop sshd}"
        "4) ${MSG_SSH_OPT_INFO:-Show connection info}"
        "5) ${MSG_SSH_OPT_BOOT_ON:-Enable autostart on boot}"
        "6) ${MSG_SSH_OPT_BOOT_OFF:-Disable autostart on boot}"
        "0) ${OPT_BACK:-Back}"
    )
    log_info "${MSG_SSH_START:-SSH setup}"

    local picked
    if command -v fzf &> /dev/null; then
        picked="$(printf '%s\n' "${options[@]}" | fzf \
            --height=70% --reverse --no-info --border=rounded \
            --ansi --prompt="ssh > ")" || return 0
    else
        printf '  %s\n' "${options[@]}"
        echo -n "> "
        read -r raw
        picked="${raw}) "
    fi

    case "$picked" in
        1*) ssh_install_action ;;
        2*) ssh_start_action ;;
        3*) ssh_stop_action ;;
        4*) ssh_info_action ;;
        5*) ssh_boot_enable ;;
        6*) ssh_boot_disable ;;
        0*|"") return 0 ;;
        *) log_warn "${MSG_INVALID_CHOICE:-Invalid choice}" ;;
    esac
}
