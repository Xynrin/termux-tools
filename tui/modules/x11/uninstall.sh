#!/usr/bin/env bash
# tui/modules/x11/uninstall.sh - 删 start-desktop（桌面包默认保留，避免误删用户数据）
# Remove start-desktop launcher; desktop packages kept by default to avoid
# nuking user data — they can pkg uninstall xfce4/lxqt manually.

x11_uninstall() {
    log_info "${MSG_X11_UNINSTALL_TITLE:-Uninstalling X11 launcher}"

    if [[ -f "$X11_LAUNCHER" ]]; then
        log_step "${MSG_X11_RM_LAUNCHER:-Removing} $X11_LAUNCHER"
        rm -f "$X11_LAUNCHER"
    else
        log_warn "${MSG_X11_NO_LAUNCHER:-No start-desktop launcher found}"
    fi

    # 桌面包不自动删 / don't auto-remove desktop packages
    log_info "${MSG_X11_KEEP_PKGS:-Desktop packages (xfce4/lxqt/pulseaudio/dbus/termux-x11-nightly) left installed}"
    log_info "${MSG_X11_MANUAL_RM:-To fully remove run: pkg uninstall -y xfce4 lxqt pulseaudio dbus termux-x11-nightly}"

    log_ok "${MSG_X11_UNINSTALL_DONE:-Launcher removed}"
}
