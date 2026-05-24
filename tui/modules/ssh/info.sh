#!/usr/bin/env bash
# tui/modules/ssh/info.sh - 显示 SSH 连接信息（IP / 用户 / 端口 / 完整命令）
# Show SSH connection info: IPs, user, port, ready-to-copy command

# 多种方式串联探测设备 IP — 任何一种失败都不能炸
# Probe device IP via multiple fallbacks; never let set -e blow us up.
_ssh_collect_ips() {
    local ips=""

    # 1) ifconfig wlan / rmnet 段
    if command -v ifconfig &> /dev/null; then
        ips="$(ifconfig 2>/dev/null \
            | grep -A1 -E 'wlan|rmnet' \
            | grep 'inet ' \
            | awk '{print $2}' \
            | sed 's/addr://' || true)"
    fi

    # 2) ip addr show wlan0
    if [[ -z "$ips" ]] && command -v ip &> /dev/null; then
        ips="$(ip addr show wlan0 2>/dev/null \
            | grep 'inet ' \
            | awk '{print $2}' \
            | cut -d/ -f1 || true)"
    fi

    # 3) 兜底：ip -4 addr 全捞，过滤掉 lo
    if [[ -z "$ips" ]] && command -v ip &> /dev/null; then
        ips="$(ip -4 addr 2>/dev/null \
            | grep 'inet ' \
            | grep -v '127.0.0.1' \
            | awk '{print $2}' \
            | cut -d/ -f1 || true)"
    fi

    printf '%s\n' "$ips"
}

ssh_info_action() {
    local user
    user="$(whoami 2>/dev/null || echo 'user')"

    local ips
    ips="$(_ssh_collect_ips)"

    log_info "${MSG_SSH_INFO_TITLE:-SSH connection info}"
    log_info "  ${MSG_SSH_INFO_USER:-user}: $user"
    log_info "  ${MSG_SSH_INFO_PORT:-port}: $SSH_PORT"

    if [[ -z "$ips" ]]; then
        log_warn "${MSG_SSH_INFO_NO_IP:-No IP detected — connect to Wi-Fi or mobile data first}"
        return 0
    fi

    log_info "  ${MSG_SSH_INFO_IPS:-IPs}:"
    while IFS= read -r ip; do
        [[ -z "$ip" ]] && continue
        log_info "    - $ip"
    done <<< "$ips"

    log_info "${MSG_SSH_INFO_CMD:-Connect with}:"
    while IFS= read -r ip; do
        [[ -z "$ip" ]] && continue
        log_info "  ssh ${user}@${ip} -p ${SSH_PORT}"
    done <<< "$ips"
}
