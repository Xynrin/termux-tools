#!/usr/bin/env bash
# tui/modules/cleanup/scan.sh - 扫描分析存储占用
# Scan & analyze storage usage
#
# 收集口径（每项失败都吞掉，避免 set -u/-e 把整个流程炸了）：
# What we collect (every probe is non-fatal so a missing path won't break the run):
#   - apt 缓存 / apt cache
#   - apt archives 子目录 / apt archives subdir
#   - $PREFIX/tmp + ~/.cache
#   - 每个已装 proot distro 的 rootfs 占用 / each installed proot distro rootfs
#   - HOME 大文件 top10 / top10 biggest paths under HOME
#   - df -h $PREFIX 总览 / df -h overview

# 内部：把扫描结果输出，调用方决定写不写到 stdout
# Internal: emit scan output; caller decides whether to print

cleanup_scan_action() {
    log_step "${MSG_CLEANUP_START:-Analyzing storage}"

    # ---- apt / pkg 缓存 ----
    local apt_cache="$CLEANUP_PREFIX/var/cache/apt"
    local apt_arch="$CLEANUP_PREFIX/var/cache/apt/archives"
    local s
    s="$(du -sh "$apt_cache" 2>/dev/null || true)"
    [[ -n "$s" ]] && log_info "apt cache: $s"
    s="$(du -sh "$apt_arch" 2>/dev/null || true)"
    [[ -n "$s" ]] && log_info "apt archives: $s"

    # ---- tmp / ~/.cache ----
    local tmp_dir="$CLEANUP_PREFIX/tmp"
    s="$(du -sh "$tmp_dir" 2>/dev/null || true)"
    [[ -n "$s" ]] && log_info "tmp: $s"
    if [[ -d "$HOME/.cache" ]]; then
        s="$(du -sh "$HOME/.cache" 2>/dev/null || true)"
        [[ -n "$s" ]] && log_info "~/.cache: $s"
    fi

    # ---- proot 容器逐个 du ----
    if command -v proot-distro &> /dev/null; then
        local installed
        installed="$(list_installed_distros 2>/dev/null || true)"
        if [[ -n "$installed" ]]; then
            log_info "${MSG_CLEANUP_PROOT_HEADER:-proot containers:}"
            local d size
            while IFS= read -r d; do
                [[ -z "$d" ]] && continue
                local rootfs="$CLEANUP_ROOTFS_PARENT/$d"
                size="$(du -sh "$rootfs" 2>/dev/null | awk '{print $1}' || true)"
                log_info "  $d: ${size:-?}"
            done <<< "$installed"
        fi
    fi

    # ---- HOME 大文件 top10 ----
    log_info "${MSG_CLEANUP_TOP10_HEADER:-HOME top 10 largest:}"
    # du -ah 在权限拒绝时会喷一堆 stderr，吞掉；sort -rh 按可读尺寸倒排
    # du -ah pollutes stderr on EACCES — silence it. sort -rh sorts human sizes desc.
    local line
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        log_info "  $line"
    done < <(du -ah "$HOME" 2>/dev/null | sort -rh 2>/dev/null | head -10 || true)

    # ---- df 总览 ----
    log_info "${MSG_CLEANUP_DF_HEADER:-Filesystem usage:}"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        log_info "  $line"
    done < <(df -h "$CLEANUP_PREFIX" 2>/dev/null || true)

    log_ok "${MSG_CLEANUP_SCAN_DONE:-Scan complete}"
}

# 单独取 $PREFIX 的可用空间数值（KB），用于 before/after 对比
# Get $PREFIX available space in KB — used for before/after diff
cleanup_avail_kb() {
    df -Pk "$CLEANUP_PREFIX" 2>/dev/null | awk 'NR==2 {print $4}' || true
}

# 把 KB 差值打成可读字符串
# Format a KB delta into a human-readable string
cleanup_format_kb_delta() {
    local kb="$1"
    [[ -z "$kb" || ! "$kb" =~ ^-?[0-9]+$ ]] && { printf '?'; return 0; }
    local sign=""
    if [[ "$kb" -lt 0 ]]; then
        sign="-"
        kb=$((-kb))
    fi
    if   [[ "$kb" -ge 1048576 ]]; then printf '%s%.1fG' "$sign" "$(awk "BEGIN{print $kb/1048576}")"
    elif [[ "$kb" -ge 1024    ]]; then printf '%s%.1fM' "$sign" "$(awk "BEGIN{print $kb/1024}")"
    else printf '%s%dK' "$sign" "$kb"
    fi
}
