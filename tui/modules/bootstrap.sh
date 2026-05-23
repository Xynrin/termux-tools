#!/usr/bin/env bash
# tui/modules/bootstrap.sh - 首次部署：装依赖 + Ubuntu + alias
# First-time setup: install deps + Ubuntu + aliases

set -uo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MODULE_DIR/_common.sh"

bootstrap_action() {
    log_info "${MSG_BOOTSTRAP_TITLE:-First-time setup}"

    log_step "${MSG_BOOTSTRAP_PKG_UPDATE:-Updating package index}"
    pkg update -y && pkg upgrade -y || log_warn "pkg upgrade had warnings"

    log_step "${MSG_BOOTSTRAP_PKG_INSTALL:-Installing dependencies}"
    pkg install -y curl git wget fzf proot-distro || {
        log_err "dependency install failed"
        return 1
    }

    log_step "${MSG_BOOTSTRAP_UBUNTU:-Installing Ubuntu}"
    if proot-distro install ubuntu 2>&1; then
        write_alias_all_shells "ubuntu"
        log_ok "ubuntu installed and aliased"
    else
        log_warn "ubuntu already installed or install failed"
    fi

    log_ok "${MSG_BOOTSTRAP_DONE:-Setup complete}"
}
