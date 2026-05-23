#!/usr/bin/env bash
# tui/modules/proot.sh - proot-distro 安装 / 列表 / 删除 / 登录
# proot-distro install / list / remove / login

set -uo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MODULE_DIR/_common.sh"

proot_install_action() {
    if ! command -v proot-distro &> /dev/null; then
        log_err "proot-distro not found"
        return 1
    fi

    local available
    available="$(proot-distro list 2>/dev/null \
        | awk '/^[[:space:]]*[a-z][a-z0-9-]*[[:space:]]*$/{print $1}' \
        | sort -u)"
    [[ -z "$available" ]] && available=$'ubuntu\ndebian\narchlinux\nfedora\nalpine\nvoid\nopensuse'

    log_info "${MSG_PROOT_DISTRO_NAME:-Pick a distro}"
    local picked
    if command -v fzf &> /dev/null; then
        picked="$(echo "$available" | fzf --height=50% --reverse --no-info --border=rounded \
            --prompt="distro > " --color='border:cyan,prompt:yellow,pointer:green')" || return 0
    else
        echo "${MSG_PROOT_DISTRO_EXAMPLE:-e.g.: ubuntu, debian, archlinux}"
        echo -n "> "
        read -r picked
    fi
    [[ -z "$picked" ]] && { log_warn "${MSG_INVALID_CHOICE:-Invalid choice}"; return 1; }

    log_step "${MSG_PROOT_INSTALLING:-Installing} $picked"
    if proot-distro install "$picked"; then
        write_alias_all_shells "$picked"
        log_ok "${MSG_PROOT_INSTALL_DONE:-Done}: $picked"
        log_info "${MSG_ALIAS_RESTART_HINT:-Restart shell or run: source ~/.bashrc}"
    else
        log_err "${MSG_PROOT_INSTALL_FAILED:-Failed}"
        return 1
    fi
}

proot_list_action() {
    if ! command -v proot-distro &> /dev/null; then
        log_warn "${MSG_PROOT_NOT_INSTALLED:-No proot installed}"
        return 0
    fi
    local installed
    installed="$(list_installed_distros)"
    if [[ -z "$installed" ]]; then
        log_warn "${MSG_PROOT_NOT_INSTALLED:-No proot distros installed}"
        return 0
    fi
    log_info "${MSG_ALIASES_TITLE:-Installed distros}"
    while IFS= read -r d; do
        [[ -z "$d" ]] && continue
        log_info "  $d  →  proot-distro login $d"
    done <<< "$installed"
}

proot_remove_action() {
    local target="${1:-}"
    if [[ -z "$target" ]]; then
        local installed
        installed="$(list_installed_distros)"
        if [[ -z "$installed" ]]; then
            log_warn "${MSG_PROOT_NOT_INSTALLED:-No proot installed}"
            return 0
        fi
        if command -v fzf &> /dev/null; then
            target="$(echo "$installed" | fzf --height=50% --reverse --no-info --border=rounded \
                --prompt="${MSG_PROOT_PICK_DISTRO:-Pick distro} > ")" || return 0
        else
            echo "${MSG_PROOT_PICK_DISTRO:-Pick distro} (one of):"
            echo "$installed"
            echo -n "> "
            read -r target
        fi
    fi
    [[ -z "$target" ]] && return 0

    log_warn "${MSG_PROOT_REMOVE_CONFIRM:-Confirm removal? type y}: $target"
    echo -n "> "
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] || { log_info "cancelled"; return 0; }

    log_step "${MSG_PROOT_REMOVING:-Removing} $target"
    if proot-distro remove "$target"; then
        remove_alias_all_shells "$target"
        log_ok "${MSG_PROOT_REMOVE_DONE:-Removed}: $target"
    else
        log_err "${MSG_PROOT_REMOVE_FAILED:-Remove failed}"
        return 1
    fi
}

proot_login_action() {
    local target="${1:-}"
    if [[ -z "$target" ]]; then
        local installed
        installed="$(list_installed_distros)"
        [[ -z "$installed" ]] && { log_warn "${MSG_PROOT_NOT_INSTALLED:-No proot}"; return 0; }
        if command -v fzf &> /dev/null; then
            target="$(echo "$installed" | fzf --height=50% --reverse --no-info --border=rounded \
                --prompt="login > ")" || return 0
        else
            echo "$installed"
            echo -n "> "
            read -r target
        fi
    fi
    [[ -z "$target" ]] && return 0
    log_info "${MSG_PROOT_LOGIN_HINT:-type 'exit' to return}"
    proot-distro login "$target"
}

proot_manage_menu() {
    local installed
    installed="$(list_installed_distros)"
    if [[ -z "$installed" ]]; then
        log_warn "${MSG_PROOT_NOT_INSTALLED:-No proot installed}"
        return 0
    fi

    log_info "${MSG_PROOT_MANAGE_TITLE:-Distro management}"
    local target
    if command -v fzf &> /dev/null; then
        target="$(echo "$installed" | fzf --height=50% --reverse --no-info --border=rounded \
            --prompt="${MSG_PROOT_PICK_DISTRO:-Pick} > ")" || return 0
    else
        echo "$installed"
        echo -n "> "
        read -r target
    fi
    [[ -z "$target" ]] && return 0

    local actions=(
        "1) ${MSG_PROOT_ACTION_LOGIN:-Log in}"
        "2) ${MSG_PROOT_ACTION_REMOVE:-Remove}"
        "0) ${OPT_BACK:-Back}"
    )
    local picked
    if command -v fzf &> /dev/null; then
        picked="$(printf '%s\n' "${actions[@]}" | fzf --height=30% --reverse --no-info --border=rounded \
            --prompt="${MSG_PROOT_ACTION_TITLE:-Action} > ")" || return 0
    else
        printf '  %s\n' "${actions[@]}"
        echo -n "> "
        read -r raw
        picked="${raw}) "
    fi
    case "$picked" in
        1*) proot_login_action  "$target" ;;
        2*) proot_remove_action "$target" ;;
        *)  return 0 ;;
    esac
}
