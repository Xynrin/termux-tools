#!/usr/bin/env bash
# tui/modules/language.sh - 切换 UI 语言
# Switch UI language

set -uo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MODULE_DIR/_common.sh"

PROJECT_ROOT="$(cd "$MODULE_DIR/../.." && pwd)"
LANG_PREF_FILE="$PROJECT_ROOT/.lang_pref"

language_action() {
    local options=(
        "1) 中文 (zh)"
        "2) English (en)"
        "0) ${OPT_BACK:-Back}"
    )
    log_info "${LANG_TITLE:-Select language}"
    local picked
    if command -v fzf &> /dev/null; then
        picked="$(printf '%s\n' "${options[@]}" | fzf --height=30% --reverse --no-info --border=rounded \
            --prompt="lang > ")" || return 0
    else
        printf '  %s\n' "${options[@]}"
        echo -n "> "
        read -r raw
        picked="${raw}) "
    fi
    case "$picked" in
        1*) echo "zh" > "$LANG_PREF_FILE"; log_ok "${MSG_LANG_SWITCHED:-switched}" ;;
        2*) echo "en" > "$LANG_PREF_FILE"; log_ok "${MSG_LANG_SWITCHED:-switched}" ;;
        0*|"") return 0 ;;
        *) log_warn "${MSG_INVALID_CHOICE:-Invalid choice}" ;;
    esac
}
