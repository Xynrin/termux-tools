#!/usr/bin/env bash
# tui/modules/backup/backup.sh - 备份已装 distro 到 tar.gz
# Backup an installed distro into a tar.gz archive

backup_do_backup() {
    backup_require_proot || return 1

    local installed
    installed="$(list_installed_distros)"
    if [[ -z "$installed" ]]; then
        log_warn "${MSG_PROOT_NOT_INSTALLED:-No proot distros installed}"
        return 0
    fi

    local distro
    if command -v fzf &> /dev/null; then
        distro="$(echo "$installed" | fzf --height=50% --reverse --no-info --border=rounded \
            --prompt="${MSG_BACKUP_PICK_DISTRO:-Pick distro to back up} > ")" || return 0
    else
        echo "$installed"
        echo -n "> "
        read -r distro
    fi
    [[ -z "$distro" ]] && return 0

    local rootfs="$BACKUP_ROOTFS_PARENT/$distro"
    if [[ ! -d "$rootfs" ]]; then
        log_err "${MSG_BACKUP_ROOTFS_MISSING:-Rootfs missing}: $rootfs"
        return 1
    fi

    if ! mkdir -p "$BACKUP_OUT_DIR" 2>/dev/null; then
        log_err "${MSG_BACKUP_MKDIR_FAILED:-Cannot create backup dir}: $BACKUP_OUT_DIR"
        return 1
    fi

    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    local out="$BACKUP_OUT_DIR/${distro}-${stamp}.tar.gz"

    log_step "${MSG_BACKUP_START:-Backing up} $distro"
    log_info "  src: $rootfs"
    log_info "  dst: $out"
    log_step "${MSG_BACKUP_TAR_RUNNING:-Compressing — this can take a few minutes}"

    # 用相对路径打包：归档里第一层就是 <distro>/，恢复时直接展回 rootfs 父目录
    # Pack with -C so the archive root is "<distro>/" — restore just unpacks into the parent dir
    if tar -czf "$out" -C "$BACKUP_ROOTFS_PARENT" "$distro" 2>/dev/null; then
        local size
        size="$(du -h "$out" 2>/dev/null | awk '{print $1}')"
        log_ok "${MSG_BACKUP_DONE:-Backup done}: $out (${size:-?})"
    else
        log_err "${MSG_BACKUP_FAILED:-Backup failed}"
        rm -f "$out" 2>/dev/null
        return 1
    fi
}
