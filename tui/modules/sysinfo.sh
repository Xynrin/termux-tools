#!/usr/bin/env bash
# tui/modules/sysinfo.sh - 自写系统信息（不依赖 fastfetch）
# Self-rendered system info (no fastfetch dependency)

set -uo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MODULE_DIR/_common.sh"

PROJECT_ROOT="$(cd "$MODULE_DIR/../.." && pwd)"

sysinfo_action() {
    local os arch kernel sh cpu mem_total mem_avail storage battery distros version
    os="$(uname -o 2>/dev/null || uname -s)"
    arch="$(uname -m)"
    kernel="$(uname -r)"
    sh="$SHELL"
    cpu="$(awk -F: '/^Hardware|^model name/{gsub(/^[ \t]+/,"",$2); print $2; exit}' /proc/cpuinfo 2>/dev/null)"
    [[ -z "$cpu" ]] && cpu="$(uname -p 2>/dev/null || echo unknown)"
    mem_total="$(awk '/^MemTotal:/ {printf "%.1f GiB", $2/1024/1024}' /proc/meminfo 2>/dev/null)"
    mem_avail="$(awk '/^MemAvailable:/ {printf "%.1f GiB", $2/1024/1024}' /proc/meminfo 2>/dev/null)"
    storage="$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')"
    if command -v termux-battery-status &> /dev/null; then
        battery="$(termux-battery-status 2>/dev/null \
            | awk -F'[:,]' '/percentage/{gsub(/[ "]/,"",$2); print $2"%"}')"
    fi
    if command -v proot-distro &> /dev/null; then
        distros="$(list_installed_distros | wc -l)"
    fi
    version="$(tr -d '[:space:]' < "$PROJECT_ROOT/scripts/version" 2>/dev/null || echo unknown)"

    log_info "${MSG_SYSTEM_INFO:-System Info}"
    log_info "  ${MSG_OS:-OS}: $os"
    log_info "  ${MSG_ARCH:-Arch}: $arch"
    log_info "  ${MSG_KERNEL:-Kernel}: $kernel"
    log_info "  ${MSG_SHELL:-Shell}: $sh"
    [[ -n "${TERMUX_VERSION:-}" ]] && log_info "  ${MSG_TERMUX_VERSION:-Termux}: $TERMUX_VERSION"
    log_info "  ${MSG_SYSINFO_CPU:-CPU}: $cpu"
    [[ -n "$mem_total" ]] && log_info "  ${MSG_SYSINFO_MEM:-Memory}: $mem_avail / $mem_total"
    [[ -n "$storage" ]]   && log_info "  ${MSG_SYSINFO_STORAGE:-Storage}: $storage"
    [[ -n "${battery:-}" ]] && log_info "  ${MSG_SYSINFO_BATTERY:-Battery}: $battery"
    [[ -n "${distros:-}" ]] && log_info "  ${MSG_SYSINFO_DISTROS:-Distros}: $distros"
    log_info "  ${MSG_SYSINFO_XYNRIN:-xynrin}: v$version"
}
