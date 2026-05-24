#!/usr/bin/env bash
# tui/modules/ssh/boot.sh - 开机自启（依赖 Termux:Boot APK）
# Boot autostart (requires Termux:Boot APK from F-Droid)

ssh_boot_enable() {
    log_step "${MSG_SSH_BOOT_ENABLING:-Enabling sshd autostart}"
    mkdir -p "$HOME/.termux/boot" 2>/dev/null || true

    cat > "$SSH_BOOT_FILE" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
. $PREFIX/etc/profile
sshd
EOF

    chmod +x "$SSH_BOOT_FILE" 2>/dev/null || true
    log_ok "${MSG_SSH_BOOT_ENABLED:-Autostart script written: $SSH_BOOT_FILE}"
    log_warn "${MSG_SSH_BOOT_NEEDS_APK:-Requires Termux:Boot APK from F-Droid to actually run on boot}"
}

ssh_boot_disable() {
    log_step "${MSG_SSH_BOOT_DISABLING:-Disabling sshd autostart}"
    rm -f "$SSH_BOOT_FILE" 2>/dev/null || true
    log_ok "${MSG_SSH_BOOT_DISABLED:-Autostart removed}"
}
