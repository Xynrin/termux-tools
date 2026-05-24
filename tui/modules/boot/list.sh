#!/usr/bin/env bash
# tui/modules/boot/list.sh - 列出 $BOOT_DIR 内容（标记可执行状态）
# List entries inside $BOOT_DIR, flagging which scripts are +x

boot_list() {
    log_info "${MSG_BOOT_LIST_TITLE:-Boot scripts in $BOOT_DIR}"

    if [[ ! -d "$BOOT_DIR" ]]; then
        log_warn "${MSG_BOOT_DIR_MISSING:-$BOOT_DIR does not exist (boot disabled or never enabled)}"
        if [[ -d "${BOOT_DIR}.disabled" ]]; then
            log_info "${MSG_BOOT_DIR_DISABLED_HINT:-Disabled copy found at ${BOOT_DIR}.disabled — enable to restore}"
        fi
        return 0
    fi

    # 原始 ls 输出（仅信息，行内 log_info）
    # Raw ls output — emitted line-by-line as info
    local line
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        log_info "  $line"
    done < <(ls -la "$BOOT_DIR" 2>/dev/null)

    # 单独枚举每个文件，标记 +x / not-exec — Termux:Boot 只跑可执行文件
    # Enumerate each file separately and tag +x / not-exec — Termux:Boot only runs executables
    local count=0
    local f base mark
    shopt -s nullglob dotglob
    for f in "$BOOT_DIR"/*; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        if [[ -x "$f" ]]; then
            mark="${MSG_BOOT_MARK_EXEC:-[+x]}"
        else
            mark="${MSG_BOOT_MARK_NOEXEC:-[!! not executable — boot will skip]}"
        fi
        log_info "  $mark $base"
        count=$((count + 1))
    done
    shopt -u nullglob dotglob

    if (( count == 0 )); then
        log_warn "${MSG_BOOT_LIST_EMPTY:-No boot scripts yet — add one from the menu}"
    fi
}
