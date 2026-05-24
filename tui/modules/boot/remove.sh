#!/usr/bin/env bash
# tui/modules/boot/remove.sh - fzf 选 boot 脚本，二次确认后 rm
# Pick a boot script via fzf, double-confirm, then rm

boot_remove() {
    boot_require_dir || return 0

    # 列文件名（不含 . / ..）/ list filenames, exclude . and ..
    local files=()
    shopt -s nullglob dotglob
    local f
    for f in "$BOOT_DIR"/*; do
        [[ -f "$f" ]] || continue
        files+=("$(basename "$f")")
    done
    shopt -u nullglob dotglob

    if (( ${#files[@]} == 0 )); then
        log_warn "${MSG_BOOT_REMOVE_EMPTY:-No boot scripts to remove}"
        return 0
    fi

    local picked
    if command -v fzf &> /dev/null; then
        picked="$(printf '%s\n' "${files[@]}" | fzf \
            --height=60% --reverse --no-info --border=rounded \
            --prompt="boot/remove > " \
            --color='border:cyan,prompt:yellow,pointer:green')" || return 0
    else
        printf '  %s\n' "${files[@]}"
        echo -n "> "
        read -r picked
    fi

    [[ -z "$picked" ]] && return 0

    local target="$BOOT_DIR/$picked"
    [[ -f "$target" ]] || {
        log_warn "${MSG_BOOT_REMOVE_NOFILE:-File not found: $picked}"
        return 0
    }

    # fzf 二次确认 / fzf double-confirm
    local confirm
    if command -v fzf &> /dev/null; then
        confirm="$(printf '%s\n' "no" "yes" | fzf \
            --height=30% --reverse --no-info --border=rounded \
            --prompt="really remove $picked ? > " \
            --color='border:red,prompt:red,pointer:red')" || return 0
    else
        echo -n "${MSG_BOOT_CONFIRM_REMOVE:-really remove $picked ? [yes/no]}: "
        read -r confirm
    fi

    if [[ "$confirm" != "yes" ]]; then
        log_info "${MSG_BOOT_REMOVE_CANCELLED:-Cancelled}"
        return 0
    fi

    log_step "${MSG_BOOT_REMOVING:-Removing $picked}"
    if rm -f "$target"; then
        log_ok "${MSG_BOOT_REMOVED:-Removed $picked}"
    else
        log_err "${MSG_BOOT_REMOVE_FAIL:-Failed to remove $target}"
        return 1
    fi
}
