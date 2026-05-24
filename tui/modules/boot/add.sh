#!/usr/bin/env bash
# tui/modules/boot/add.sh - 添加预设 / 自定义 boot 脚本
# Add preset or custom boot script

# 把一段 body 写到 $BOOT_DIR/<name>，自动加 shebang + chmod +x
# Write body into $BOOT_DIR/<name> with shebang prepended and chmod +x applied
_boot_write_script() {
    local name="$1"
    local body="$2"
    local target="$BOOT_DIR/$name"

    if [[ -e "$target" ]]; then
        log_warn "${MSG_BOOT_OVERWRITE:-Overwriting existing $name}"
    fi

    {
        printf '%s\n' "$BOOT_SHEBANG"
        printf '%s\n' "$body"
    } > "$target" || {
        log_err "${MSG_BOOT_WRITE_FAIL:-Failed to write $target}"
        return 1
    }

    chmod +x "$target" 2>/dev/null || {
        log_err "${MSG_BOOT_CHMOD_FAIL:-Failed to chmod +x $target}"
        return 1
    }

    log_ok "${MSG_BOOT_WROTE:-Wrote $target (+x)}"
}

boot_add_preset() {
    boot_require_dir || return 0

    local options=(
        "1) start-sshd      — ${MSG_BOOT_PRESET_SSHD:-Launch openssh sshd}"
        "2) start-x11       — ${MSG_BOOT_PRESET_X11:-Launch Termux:X11 desktop (start-desktop)}"
        "3) start-pulseaudio — ${MSG_BOOT_PRESET_PULSE:-Launch pulseaudio}"
        "4) start-cron      — ${MSG_BOOT_PRESET_CRON:-Launch crond/cron daemon}"
        "5) start-user      — ${MSG_BOOT_PRESET_USER:-User-defined template (edit before use)}"
        "0) ${OPT_BACK:-Back}"
    )

    local picked
    if command -v fzf &> /dev/null; then
        picked="$(printf '%s\n' "${options[@]}" | fzf \
            --height=60% --reverse --no-info --border=rounded \
            --prompt="boot/preset > " \
            --color='border:cyan,prompt:yellow,pointer:green')" || return 0
    else
        printf '  %s\n' "${options[@]}"
        echo -n "> "
        read -r raw
        picked="${raw}) "
    fi

    case "$picked" in
        1*)
            log_step "${MSG_BOOT_ADD_SSHD:-Adding start-sshd}"
            _boot_write_script "start-sshd" '. $PREFIX/etc/profile && sshd'
            ;;
        2*)
            log_step "${MSG_BOOT_ADD_X11:-Adding start-x11}"
            if [[ -x "$BOOT_BIN_DIR/start-desktop" ]]; then
                _boot_write_script "start-x11" '. $PREFIX/etc/profile && exec start-desktop'
            else
                log_err "${MSG_BOOT_X11_MISSING:-start-desktop not found in $BOOT_BIN_DIR — install X11 from the main menu first}"
                return 1
            fi
            ;;
        3*)
            log_step "${MSG_BOOT_ADD_PULSE:-Adding start-pulseaudio}"
            _boot_write_script "start-pulseaudio" '. $PREFIX/etc/profile && pulseaudio --start --exit-idle-time=-1'
            ;;
        4*)
            log_step "${MSG_BOOT_ADD_CRON:-Adding start-cron}"
            local cron_body
            cron_body='. $PREFIX/etc/profile
if command -v crond >/dev/null 2>&1; then
    crond
elif command -v cron >/dev/null 2>&1; then
    cron
else
    echo "no crond/cron installed" >&2
    exit 1
fi'
            _boot_write_script "start-cron" "$cron_body"
            ;;
        5*)
            log_step "${MSG_BOOT_ADD_USER:-Adding start-user template}"
            local user_body
            user_body='# user-defined boot script — edit me
. $PREFIX/etc/profile
# put your command here, e.g.:
# termux-wake-lock
# echo "booted at $(date)" >> $HOME/boot.log
true'
            _boot_write_script "start-user" "$user_body"
            log_info "${MSG_BOOT_USER_EDIT_HINT:-Edit $BOOT_DIR/start-user to put your real command}"
            ;;
        0*|"") return 0 ;;
        *) log_warn "${MSG_INVALID_CHOICE:-Invalid choice}" ;;
    esac
}

boot_add_custom() {
    boot_require_dir || return 0

    log_info "${MSG_BOOT_CUSTOM_HINT:-Custom boot script — provide a name + a one-line command}"

    local name
    echo -n "${MSG_BOOT_CUSTOM_NAME:-script name (e.g. start-myapp)}: "
    read -r name
    if [[ -z "$name" ]]; then
        log_warn "${MSG_BOOT_NAME_EMPTY:-Empty name — aborted}"
        return 0
    fi
    # 清理路径分隔符避免逃逸 / strip path separators to keep it inside BOOT_DIR
    name="${name//\//_}"

    local cmd
    echo -n "${MSG_BOOT_CUSTOM_CMD:-command (one line)}: "
    read -r cmd
    if [[ -z "$cmd" ]]; then
        log_warn "${MSG_BOOT_CMD_EMPTY:-Empty command — aborted}"
        return 0
    fi

    log_step "${MSG_BOOT_ADD_CUSTOM:-Adding custom boot script $name}"
    local body
    body=". \$PREFIX/etc/profile
$cmd"
    _boot_write_script "$name" "$body"
}
