#!/usr/bin/env bash
# tui/modules/update.sh - 检查远端版本 + git pull + install --upgrade
# Check remote version + git pull + install --upgrade

set -uo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MODULE_DIR/_common.sh"

PROJECT_ROOT="$(cd "$MODULE_DIR/../.." && pwd)"
REPO_HTTPS="https://github.com/Xynrin/termux-tools"
REPO_RAW="https://raw.githubusercontent.com/Xynrin/termux-tools/main"

# 检查远端 tag，纯 git/curl，不走 GitHub API
# Check remote tag via git/curl only — no GitHub API
update_check_action() {
    local current remote
    current="$(tr -d '[:space:]' < "$PROJECT_ROOT/scripts/version" 2>/dev/null || echo unknown)"
    log_info "current=$current"

    log_step "${MSG_UPDATE_CHECKING:-Checking remote}"
    if command -v git &> /dev/null; then
        remote="$(git ls-remote --tags --refs "$REPO_HTTPS" 2>/dev/null \
            | awk -F'refs/tags/v' 'NF==2 {print $2}' \
            | sort -V | tail -n1)"
    fi
    if [[ -z "${remote:-}" ]]; then
        remote="$(curl -sL -H 'Cache-Control: no-cache' \
            "${REPO_RAW}/scripts/version?t=$(date +%s)" 2>/dev/null \
            | tr -d '[:space:]')"
    fi
    if [[ -z "${remote:-}" ]]; then
        log_err "${MSG_UPDATE_FAILED:-Update check failed}"
        return 1
    fi

    log_info "remote=$remote"
    if [[ "$current" == "$remote" ]]; then
        log_ok "${MSG_UPDATE_NO_NEW:-Already up to date}"
        return 0
    fi
    log_warn "${MSG_UPDATE_AVAILABLE:-Update available}: $current -> $remote"
    # Rust 端读到 remote=... 后会展示 changelog 和 [Y/N] 确认
    # Rust side will read remote=... then show changelog + [Y/N]
    printf '::remote::%s\n' "$remote"
}

# 真正执行更新（被 Rust 在用户确认后调用）
# Actually do the update (called by Rust after user confirms)
update_apply_action() {
    if ! command -v git &> /dev/null || [[ ! -d "$PROJECT_ROOT/.git" ]]; then
        log_err "git not found or not a git checkout"
        return 1
    fi
    log_step "discarding local changes"
    ( cd "$PROJECT_ROOT" && git checkout -- . 2>/dev/null || true )
    log_step "git pull"
    ( cd "$PROJECT_ROOT" && git pull --ff-only origin main ) || {
        log_err "git pull failed"
        return 1
    }
    log_step "${MSG_APPLYING_MIGRATION:-Applying migration}"
    bash "$PROJECT_ROOT/install.sh" --upgrade || log_warn "upgrade returned non-zero"
    log_ok "${MSG_UPDATE_DONE:-Update done}"
    # 通知 Rust 端 exec 新二进制 / Tell Rust side to exec the new binary
    printf '::restart::\n'
}
