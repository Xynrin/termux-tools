#!/usr/bin/env bash
# tui/modules/backup/restore.sh - 从 tar.gz 恢复 distro
# Restore a distro rootfs from a tar.gz archive

backup_do_restore() {
    backup_require_proot || return 1

    if [[ ! -d "$BACKUP_OUT_DIR" ]]; then
        log_warn "${MSG_BACKUP_NO_DIR:-No backup directory yet}: $BACKUP_OUT_DIR"
        return 0
    fi

    # 列出 .tar.gz / .tgz 备份；按时间倒序（最新的在最上面）
    # List .tar.gz / .tgz archives, newest first
    local archives
    archives="$(find "$BACKUP_OUT_DIR" -maxdepth 1 -type f \
        \( -name '*.tar.gz' -o -name '*.tgz' \) -printf '%T@ %p\n' 2>/dev/null \
        | sort -rn | awk '{ $1=""; sub(/^ /,""); print }')"
    if [[ -z "$archives" ]]; then
        log_warn "${MSG_BACKUP_NO_ARCHIVES:-No backup archives found in}: $BACKUP_OUT_DIR"
        return 0
    fi

    local picked
    if command -v fzf &> /dev/null; then
        picked="$(echo "$archives" | fzf --height=60% --reverse --no-info --border=rounded \
            --prompt="${MSG_BACKUP_PICK_ARCHIVE:-Pick archive to restore} > ")" || return 0
    else
        echo "$archives"
        echo -n "> "
        read -r picked
    fi
    [[ -z "$picked" ]] && return 0
    if [[ ! -f "$picked" ]]; then
        log_err "${MSG_BACKUP_ARCHIVE_MISSING:-Archive not found}: $picked"
        return 1
    fi

    # 从归档第一层目录推断 distro 名，比解析文件名稳
    # Derive distro name from archive's top-level dir — more reliable than filename parsing
    local distro
    distro="$(tar -tzf "$picked" 2>/dev/null | head -n1 | awk -F/ '{print $1}')"
    if [[ -z "$distro" ]]; then
        log_err "${MSG_BACKUP_ARCHIVE_BAD:-Could not read archive}: $picked"
        return 1
    fi

    log_warn "${MSG_BACKUP_RESTORE_WARN:-This will OVERWRITE distro}: $distro"
    log_info "  src: $picked"
    log_info "  dst: $BACKUP_ROOTFS_PARENT/$distro"
    echo -n "${MSG_BACKUP_CONFIRM:-Type y to continue}: "
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] || { log_info "${MSG_BACKUP_CANCELLED:-Cancelled}"; return 0; }

    # 必须先 remove，避免目录非空报错；忽略未安装时的失败
    # Must remove first so the target dir is empty; ignore failure if it wasn't installed
    if list_installed_distros | grep -qx "$distro"; then
        log_step "${MSG_BACKUP_REMOVE_OLD:-Removing existing} $distro"
        proot-distro remove "$distro" &> /dev/null || \
            log_warn "${MSG_BACKUP_REMOVE_OLD_FAIL:-Remove returned non-zero, continuing}"
    fi

    if ! mkdir -p "$BACKUP_ROOTFS_PARENT" 2>/dev/null; then
        log_err "${MSG_BACKUP_MKDIR_FAILED:-Cannot create rootfs parent}: $BACKUP_ROOTFS_PARENT"
        return 1
    fi

    log_step "${MSG_BACKUP_EXTRACTING:-Extracting archive — this can take a few minutes}"
    if tar -xzf "$picked" -C "$BACKUP_ROOTFS_PARENT" 2>/dev/null; then
        log_ok "${MSG_BACKUP_RESTORE_DONE:-Restore done}: $distro"
        log_info "${MSG_BACKUP_RESTORE_HINT:-Test with} proot-distro login $distro"
    else
        log_err "${MSG_BACKUP_RESTORE_FAILED:-Restore failed}"
        return 1
    fi
}
