#!/usr/bin/env bash
# tui/modules/beautify/main.sh - 顶层菜单 (主题选择 → shell 选择)
# Top-level menu (theme picker → shell picker)

beautify_action() {
    local options=(
        "1) ${MSG_BEAUTIFY_DRACULA:-Dracula}"
        "2) ${MSG_BEAUTIFY_CATPPUCCIN:-Catppuccin}"
        "3) ${MSG_BEAUTIFY_NORD:-Nord}"
        "4) ${MSG_BEAUTIFY_UNINSTALL:-Uninstall}"
        "0) ${OPT_BACK:-Back}"
    )
    log_info "${MSG_BEAUTIFY_TITLE:-Beautify}"
    local picked
    if command -v fzf &> /dev/null; then
        local preview_file="$BEAUTIFY_DIR/preview.sh"
        picked="$(printf '%s\n' "${options[@]}" | fzf \
            --height=70% --reverse --no-info --border=rounded \
            --ansi --prompt="theme > " \
            --preview="bash -c 'source \"$preview_file\" && beautify_preview \"\$1\"' _ {}" \
            --preview-window=right,55%,wrap)" || return 0
    else
        printf '  %s\n' "${options[@]}"
        echo -n "> "
        read -r raw
        picked="${raw}) "
    fi
    case "$picked" in
        1*) beautify_apply_theme "dracula"    ; beautify_shell_menu ;;
        2*) beautify_apply_theme "catppuccin" ; beautify_shell_menu ;;
        3*) beautify_apply_theme "nord"       ; beautify_shell_menu ;;
        4*) beautify_uninstall_action ;;
        0*|"") return 0 ;;
        *) log_warn "${MSG_INVALID_CHOICE:-Invalid choice}" ;;
    esac
}
