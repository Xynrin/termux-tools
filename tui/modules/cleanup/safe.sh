#!/usr/bin/env bash
# tui/modules/cleanup/safe.sh - 安全清理：apt 缓存 / tmp / ~/.cache
# Safe cleanup: apt cache / tmp / ~/.cache
#
# 安全清单（不会动用户配置和数据）：
# Safe list (never touches user config/data):
#   1. apt clean / pkg clean — 包缓存（重装可恢复）/ package cache (re-downloadable)
#   2. apt autoremove — 拔掉孤立依赖 / drop orphan deps
#   3. rm -rf $PREFIX/tmp/*  — 临时目录里全是临时文件 / tmp dir
#   4. rm -rf $HOME/.cache/* — 应用缓存（会重新生成）/ app caches (regenerated)

cleanup_safe_action() {
    log_step "${MSG_CLEANUP_SAFE_START:-Running safe cleanup}"

    local before after delta
    before="$(cleanup_avail_kb || true)"

    # ---- apt / pkg 缓存 ----
    if command -v apt-get &> /dev/null; then
        log_step "apt-get clean"
        apt-get clean -y 2>/dev/null || log_warn "apt-get clean returned non-zero"
        log_step "apt-get autoremove"
        apt-get autoremove -y 2>/dev/null || log_warn "apt-get autoremove returned non-zero"
    elif command -v pkg &> /dev/null; then
        log_step "pkg clean"
        pkg clean 2>/dev/null || log_warn "pkg clean returned non-zero"
    else
        log_info "${MSG_CLEANUP_NO_PKG_MGR:-No apt/pkg found, skipping package cache}"
    fi

    # ---- $PREFIX/tmp ----
    local tmp_dir="$CLEANUP_PREFIX/tmp"
    if [[ -d "$tmp_dir" ]]; then
        log_step "${MSG_CLEANUP_RM_TMP:-Clearing} $tmp_dir"
        # shellcheck disable=SC2115  # $CLEANUP_PREFIX 经过非空判断 / guarded above
        rm -rf "${tmp_dir:?}"/* 2>/dev/null || true
    fi

    # ---- ~/.cache ----
    if [[ -d "$HOME/.cache" ]]; then
        log_warn "${MSG_CLEANUP_WARN_HOME_CACHE:-About to clear ~/.cache (apps will rebuild it)}"
        rm -rf "$HOME/.cache"/* 2>/dev/null || true
    fi

    log_ok "${MSG_CLEANUP_SAFE_DONE:-Safe cleanup done}"

    # ---- 节省了多少 ----
    after="$(cleanup_avail_kb || true)"
    if [[ -n "$before" && -n "$after" && "$before" =~ ^[0-9]+$ && "$after" =~ ^[0-9]+$ ]]; then
        delta=$((after - before))
        log_info "${MSG_CLEANUP_FREED:-Freed}: $(cleanup_format_kb_delta "$delta")"
    fi

    # 清理后再扫一次现状 / Re-scan to show current state
    cleanup_scan_action
}
