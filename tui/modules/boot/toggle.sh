#!/usr/bin/env bash
# tui/modules/boot/toggle.sh - 整目录 enable / disable
# Enable or disable the whole boot dir (preserves contents via .disabled rename)

boot_enable() {
    log_step "${MSG_BOOT_ENABLING:-Enabling Termux:Boot autostart dir}"

    # 如果之前 disable 过（变成 .disabled），先把它恢复回来
    # If previously disabled (renamed to .disabled), restore it
    if [[ ! -d "$BOOT_DIR" && -d "${BOOT_DIR}.disabled" ]]; then
        if mv "${BOOT_DIR}.disabled" "$BOOT_DIR"; then
            log_ok "${MSG_BOOT_RESTORED:-Restored ${BOOT_DIR} from .disabled backup}"
        else
            log_err "${MSG_BOOT_RESTORE_FAIL:-Failed to restore ${BOOT_DIR}.disabled}"
            return 1
        fi
    fi

    if ! mkdir -p "$BOOT_DIR"; then
        log_err "${MSG_BOOT_MKDIR_FAIL:-Failed to create $BOOT_DIR}"
        return 1
    fi

    # 确保所有脚本是可执行的 — Termux:Boot 跳过 non-executable
    # Make sure every script is +x — Termux:Boot skips non-executable files
    local f count=0
    shopt -s nullglob dotglob
    for f in "$BOOT_DIR"/*; do
        [[ -f "$f" ]] || continue
        chmod +x "$f" 2>/dev/null && count=$((count + 1))
    done
    shopt -u nullglob dotglob

    log_ok "${MSG_BOOT_ENABLED:-Boot dir enabled at $BOOT_DIR ($count script(s) marked +x)}"
    log_warn "${MSG_BOOT_NEEDS_APK:-Install Termux:Boot APK from F-Droid for these scripts to actually run on boot}"
    log_info "${MSG_BOOT_APK_URL:-https://f-droid.org/en/packages/com.termux.boot/}"
}

boot_disable() {
    log_step "${MSG_BOOT_DISABLING:-Disabling Termux:Boot autostart dir}"

    if [[ ! -d "$BOOT_DIR" ]]; then
        log_warn "${MSG_BOOT_ALREADY_DISABLED:-$BOOT_DIR already absent — nothing to disable}"
        return 0
    fi

    # 已经存在 .disabled 备份则先清掉 / drop stale .disabled backup if any
    if [[ -e "${BOOT_DIR}.disabled" ]]; then
        log_warn "${MSG_BOOT_DROP_STALE:-Removing stale ${BOOT_DIR}.disabled backup}"
        rm -rf "${BOOT_DIR}.disabled" 2>/dev/null || true
    fi

    if mv "$BOOT_DIR" "${BOOT_DIR}.disabled"; then
        log_ok "${MSG_BOOT_DISABLED:-Boot dir disabled (renamed to ${BOOT_DIR}.disabled, contents preserved)}"
        log_info "${MSG_BOOT_REENABLE_HINT:-Choose \"Enable boot dir\" later to restore}"
    else
        log_err "${MSG_BOOT_DISABLE_FAIL:-Failed to rename $BOOT_DIR}"
        return 1
    fi
}
