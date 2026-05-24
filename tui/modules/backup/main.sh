#!/usr/bin/env bash
# tui/modules/backup/main.sh - 顶层菜单 backup_action
# Top-level fzf menu: backup / restore / new launcher / remove launcher / back

backup_action() {
    local options=(
        "1) ${MSG_BACKUP_OPT_BACKUP:-Back up a distro}"
        "2) ${MSG_BACKUP_OPT_RESTORE:-Restore a distro from archive}"
        "3) ${MSG_BACKUP_OPT_LAUNCHER_NEW:-Create a launcher shortcut}"
        "4) ${MSG_BACKUP_OPT_LAUNCHER_DEL:-Remove a launcher shortcut}"
        "0) ${OPT_BACK:-Back}"
    )
    log_info "${MSG_BACKUP_TITLE:-Backup & launchers}"
    local picked
    if command -v fzf &> /dev/null; then
        picked="$(printf '%s\n' "${options[@]}" | fzf \
            --height=60% --reverse --no-info --border=rounded \
            --prompt="backup > " \
            --color='border:cyan,prompt:yellow,pointer:green')" || return 0
    else
        printf '  %s\n' "${options[@]}"
        echo -n "> "
        read -r raw
        picked="${raw}) "
    fi
    case "$picked" in
        1*) backup_do_backup ;;
        2*) backup_do_restore ;;
        3*) backup_launcher_create ;;
        4*) backup_launcher_remove ;;
        0*|"") return 0 ;;
        *) log_warn "${MSG_INVALID_CHOICE:-Invalid choice}" ;;
    esac
}
