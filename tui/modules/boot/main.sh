#!/usr/bin/env bash
# tui/modules/boot/main.sh - 顶层菜单 boot_action
# Top-level fzf menu: list / add preset / add custom / remove / enable / disable / back

boot_action() {
    local options=(
        "1) ${MSG_BOOT_OPT_LIST:-List boot scripts}"
        "2) ${MSG_BOOT_OPT_ADD_PRESET:-Add preset boot script}"
        "3) ${MSG_BOOT_OPT_ADD_CUSTOM:-Add custom boot script}"
        "4) ${MSG_BOOT_OPT_REMOVE:-Remove a boot script}"
        "5) ${MSG_BOOT_OPT_ENABLE:-Enable boot dir}"
        "6) ${MSG_BOOT_OPT_DISABLE:-Disable boot dir}"
        "0) ${OPT_BACK:-Back}"
    )
    log_info "${MSG_BOOT_TITLE:-Termux:Boot autostart console}"

    local picked
    if command -v fzf &> /dev/null; then
        picked="$(printf '%s\n' "${options[@]}" | fzf \
            --height=60% --reverse --no-info --border=rounded \
            --prompt="boot > " \
            --color='border:cyan,prompt:yellow,pointer:green')" || return 0
    else
        printf '  %s\n' "${options[@]}"
        echo -n "> "
        read -r raw
        picked="${raw}) "
    fi

    case "$picked" in
        1*) boot_list ;;
        2*) boot_add_preset ;;
        3*) boot_add_custom ;;
        4*) boot_remove ;;
        5*) boot_enable ;;
        6*) boot_disable ;;
        0*|"") return 0 ;;
        *) log_warn "${MSG_INVALID_CHOICE:-Invalid choice}" ;;
    esac
}
