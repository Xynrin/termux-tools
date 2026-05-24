#!/usr/bin/env bash
# tui/modules/cleanup/main.sh - 顶层菜单 cleanup_action
# Top-level fzf menu: scan / safe clean / deep clean / back
# 默认进入先做一次扫描分析，让用户先看清状况再决定
# Default: run a scan first so user sees the picture before acting

cleanup_action() {
    # 进来先扫一遍，让用户看清现状再选动作
    # First scan on entry — user sees the state before picking an action
    cleanup_scan_action

    while true; do
        local options=(
            "1) ${MSG_CLEANUP_OPT_SCAN:-Scan & analyze}"
            "2) ${MSG_CLEANUP_OPT_SAFE:-One-shot safe cleanup}"
            "3) ${MSG_CLEANUP_OPT_DEEP:-Deep cleanup (with confirm)}"
            "0) ${OPT_BACK:-Back}"
        )
        log_info "${MSG_CLEANUP_TITLE:-Storage cleanup}"
        local picked
        if command -v fzf &> /dev/null; then
            picked="$(printf '%s\n' "${options[@]}" | fzf \
                --height=60% --reverse --no-info --border=rounded \
                --prompt="cleanup > " \
                --color='border:cyan,prompt:yellow,pointer:green')" || return 0
        else
            printf '  %s\n' "${options[@]}"
            echo -n "> "
            read -r raw
            picked="${raw}) "
        fi
        case "$picked" in
            1*) cleanup_scan_action ;;
            2*) cleanup_safe_action ;;
            3*) cleanup_deep_action ;;
            0*|"") return 0 ;;
            *) log_warn "${MSG_INVALID_CHOICE:-Invalid choice}" ;;
        esac
    done
}
