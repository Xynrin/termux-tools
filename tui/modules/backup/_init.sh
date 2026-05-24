#!/usr/bin/env bash
# tui/modules/backup/_init.sh - 共享常量 + 加载 _common
# Shared constants + load _common
[[ -n "${__XYNRIN_BACKUP_INIT:-}" ]] && return 0
__XYNRIN_BACKUP_INIT=1

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BACKUP_DIR/../_common.sh"

# 备份输出目录：优先用 termux ~/storage/shared 共享区，便于通过文件管理器拷出
# 没装 termux-setup-storage 时退到 ~/xynrin-backups
# Backup output dir: prefer termux ~/storage/shared (visible to file managers).
# Fall back to ~/xynrin-backups if termux-setup-storage hasn't been run.
if [[ -d "$HOME/storage/shared" ]]; then
    BACKUP_OUT_DIR="$HOME/storage/shared/xynrin-backups"
else
    BACKUP_OUT_DIR="$HOME/xynrin-backups"
fi

# proot-distro rootfs 父目录（PREFIX 由 termux 注入）
# proot-distro rootfs parent dir (PREFIX is provided by termux)
BACKUP_ROOTFS_PARENT="${PREFIX:-/data/data/com.termux/files/usr}/var/lib/proot-distro/installed-rootfs"

# 启动器命名前缀，避免和系统命令冲突
# Launcher name prefix — guards against shadowing system commands
BACKUP_LAUNCH_PREFIX="xynrin-launch-"
BACKUP_BIN_DIR="${PREFIX:-/data/data/com.termux/files/usr}/bin"

# 共用：检测 proot-distro 是否就位，否则提示走主菜单装容器
# Shared guard: bail out with a hint when proot-distro is missing
backup_require_proot() {
    if ! command -v proot-distro &> /dev/null; then
        log_err "${MSG_BACKUP_NO_PROOT:-proot-distro not found — install a container from the main menu first}"
        return 1
    fi
    return 0
}
