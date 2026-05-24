#!/usr/bin/env bash
# tui/modules/cleanup/deep.sh - 深度清理：safe + journal vacuum + proot 选删
# Deep cleanup: safe + journal vacuum + proot picker
#
# 必须先 fzf 二次确认才走，避免误触：
# Two-step confirm via fzf — guards against fat-fingering the menu:
#   1) 用户必须从两选一里选 [Yes I really want to delete] 才继续
#      User has to pick [Yes I really want to delete] from a 2-option list
#   2) proot 容器是单独再选删，不强删任何容器
#      proot containers are picked individually, never bulk-removed

cleanup_deep_action() {
    log_warn "${MSG_CLEANUP_DEEP_WARN:-Deep cleanup will remove caches and may remove proot containers you pick}"

    # ---- 二次确认 ----
    local confirm_opts=(
        "[No, take me back]"
        "[Yes I really want to delete]"
    )
    local picked
    if command -v fzf &> /dev/null; then
        picked="$(printf '%s\n' "${confirm_opts[@]}" | fzf \
            --height=40% --reverse --no-info --border=rounded \
            --prompt="${MSG_CLEANUP_CONFIRM_PROMPT:-confirm} > " \
            --color='border:red,prompt:red,pointer:red')" || return 0
    else
        printf '  %s\n' "${confirm_opts[@]}"
        echo -n "type exactly: yes I really want to delete > "
        read -r raw
        if [[ "$raw" == "yes I really want to delete" ]]; then
            picked="[Yes I really want to delete]"
        else
            picked="[No, take me back]"
        fi
    fi
    case "$picked" in
        "[Yes I really want to delete]") : ;;
        *) log_info "${MSG_CLEANUP_CANCELLED:-Cancelled}"; return 0 ;;
    esac

    log_step "${MSG_CLEANUP_DEEP_START:-Running deep cleanup}"

    local before after delta
    before="$(cleanup_avail_kb || true)"

    # ---- 跑一遍 safe 那一套（不让它跑结尾的扫描，避免重复打日志）----
    # Run the safe set first — but suppress its trailing scan so we only scan once at the end.
    # 直接把 cleanup_scan_action 替换成 no-op 跑一次再恢复，避免重复实现 safe 的逻辑
    # Override cleanup_scan_action with a no-op for one call, restore afterwards
    local _saved_scan
    _saved_scan="$(declare -f cleanup_scan_action || true)"
    cleanup_scan_action() { :; }
    cleanup_safe_action || true
    # 恢复
    if [[ -n "$_saved_scan" ]]; then
        eval "$_saved_scan"
    fi

    # ---- journalctl vacuum ----
    if command -v journalctl &> /dev/null; then
        log_step "journalctl --vacuum-size=10M"
        journalctl --vacuum-size=10M 2>/dev/null || log_warn "journalctl vacuum returned non-zero"
    else
        log_info "${MSG_CLEANUP_NO_JOURNAL:-journalctl not found, skipping}"
    fi

    # ---- proot 容器选删（不强删）----
    if command -v proot-distro &> /dev/null; then
        local installed
        installed="$(list_installed_distros 2>/dev/null || true)"
        if [[ -n "$installed" ]]; then
            log_warn "${MSG_CLEANUP_PROOT_PICK:-Pick unused proot containers to remove (Tab to multi-select, Esc to skip)}"
            local picks=""
            if command -v fzf &> /dev/null; then
                picks="$(echo "$installed" | fzf --multi \
                    --height=50% --reverse --no-info --border=rounded \
                    --prompt="proot remove > " \
                    --color='border:red,prompt:red,pointer:red,marker:red')" || picks=""
            fi
            if [[ -n "$picks" ]]; then
                local d
                while IFS= read -r d; do
                    [[ -z "$d" ]] && continue
                    log_step "${MSG_CLEANUP_PROOT_REMOVING:-Removing proot} $d"
                    if proot-distro remove "$d" 2>/dev/null; then
                        # alias 也跟着拔掉，保持环境一致
                        # Strip the alias too — keep the env consistent
                        remove_alias_all_shells "$d" 2>/dev/null || true
                        log_ok "${MSG_CLEANUP_PROOT_REMOVED:-Removed proot}: $d"
                    else
                        log_err "${MSG_CLEANUP_PROOT_FAILED:-Failed to remove}: $d"
                    fi
                done <<< "$picks"
            else
                log_info "${MSG_CLEANUP_PROOT_SKIPPED:-No proot containers picked, skipping}"
            fi
        fi
    fi

    log_ok "${MSG_CLEANUP_DEEP_DONE:-Deep cleanup done}"

    after="$(cleanup_avail_kb || true)"
    if [[ -n "$before" && -n "$after" && "$before" =~ ^[0-9]+$ && "$after" =~ ^[0-9]+$ ]]; then
        delta=$((after - before))
        log_info "${MSG_CLEANUP_FREED:-Freed}: $(cleanup_format_kb_delta "$delta")"
    fi

    cleanup_scan_action
}
