#!/usr/bin/env bash
# tui/modules/x11/main.sh - 顶层菜单 (XFCE / LXQt / 卸载 / 返回)
# Top-level menu (XFCE / LXQt / Uninstall / Back)

x11_action() {
    local options=(
        "1) ${MSG_X11_OPT_XFCE:-Install XFCE desktop}"
        "2) ${MSG_X11_OPT_LXQT:-Install LXQt desktop}"
        "3) ${MSG_X11_OPT_UNINSTALL:-Uninstall launcher}"
        "0) ${OPT_BACK:-Back}"
    )
    log_info "${MSG_X11_TITLE:-Termux:X11 + Desktop}"

    local picked
    if command -v fzf &> /dev/null; then
        picked="$(printf '%s\n' "${options[@]}" | fzf \
            --height=50% --reverse --no-info --border=rounded \
            --ansi --prompt="x11 > ")" || return 0
    else
        printf '  %s\n' "${options[@]}"
        echo -n "> "
        read -r raw
        picked="${raw}) "
    fi

    case "$picked" in
        1*) x11_install "xfce4" ;;
        2*) x11_install "lxqt"  ;;
        3*) x11_uninstall ;;
        0*|"") return 0 ;;
        *) log_warn "${MSG_INVALID_CHOICE:-Invalid choice}" ;;
    esac
}
