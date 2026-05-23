#!/usr/bin/env bash
# tui/modules/mirror.sh - APT 镜像源切换 / Termux APT mirror

set -uo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MODULE_DIR/_common.sh"

mirror_action() {
    local options=(
        "1) ${MSG_MIRROR_INTERACTIVE:-Interactive} (termux-change-repo)"
        "2) ${MSG_MIRROR_TSINGHUA:-Tsinghua}"
        "3) ${MSG_MIRROR_USTC:-USTC}"
        "4) ${MSG_MIRROR_OFFICIAL:-Official}"
        "0) ${OPT_BACK:-Back}"
    )
    log_info "${MSG_MIRROR_TITLE:-Mirror}"
    local picked
    if command -v fzf &> /dev/null; then
        picked="$(printf '%s\n' "${options[@]}" | fzf --height=40% --reverse --no-info --border=rounded \
            --prompt="mirror > ")" || return 0
    else
        printf '  %s\n' "${options[@]}"
        echo -n "> "
        read -r raw
        picked="${raw}) "
    fi
    case "$picked" in
        1*)
            if command -v termux-change-repo &> /dev/null; then
                termux-change-repo || true
            else
                log_err "termux-change-repo not found"
            fi ;;
        2*) apply_mirror "https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main" "Tsinghua" ;;
        3*) apply_mirror "https://mirrors.ustc.edu.cn/termux/apt/termux-main" "USTC" ;;
        4*) apply_mirror "https://packages.termux.dev/apt/termux-main" "Official" ;;
        0*|"") return 0 ;;
        *) log_warn "${MSG_INVALID_CHOICE:-Invalid choice}" ;;
    esac
}

apply_mirror() {
    local url="$1" name="$2"
    local sources="$PREFIX/etc/apt/sources.list"
    log_step "${MSG_MIRROR_APPLYING:-Applying} $name"
    if [[ -f "$sources" ]]; then
        cp "$sources" "${sources}.bak.$(date +%s)" 2>/dev/null || \
            log_warn "${MSG_MIRROR_BACKUP_WARN:-backup failed}"
    fi
    if ! echo "deb $url stable main" > "$sources" 2>/dev/null; then
        log_err "${MSG_MIRROR_WRITE_FAIL:-write failed}: $sources"
        return 1
    fi
    log_ok "${MSG_MIRROR_APPLIED:-Applied}: $name"
    log_step "${MSG_MIRROR_UPDATING:-Updating index}"
    pkg update -y || log_warn "${MSG_MIRROR_UPDATE_WARN:-index update failed}"
}
