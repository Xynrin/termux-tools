#!/usr/bin/env bash
#
# tui/modules/_common.sh - 模块共享工具：日志协议、路径、shell rc 检测
# Shared module helpers: log protocol, paths, shell rc detection
#
# 日志协议（被 Rust runner 解析）/ Log protocol (parsed by the Rust runner):
#   ::step::<msg>   一步操作开始 / a step is starting
#   ::ok::<msg>     成功 / success
#   ::warn::<msg>   警告 / warning
#   ::err::<msg>    错误 / error
#   ::info::<msg>   普通信息 / info (default)
#   ::ask::<key>    需要用户输入（Rust 端展示输入框）/ user input requested
#

# 防止重复 source / prevent double-source
[[ -n "${__XYNRIN_COMMON_SOURCED:-}" ]] && return 0
__XYNRIN_COMMON_SOURCED=1

log_step() { printf '::step::%s\n' "$*"; }
log_ok()   { printf '::ok::%s\n'   "$*"; }
log_warn() { printf '::warn::%s\n' "$*"; }
log_err()  { printf '::err::%s\n'  "$*"; }
log_info() { printf '::info::%s\n' "$*"; }

# 把所有 shell 的 rc 文件路径列出来（仅返回存在的）
# List all shell rc paths that actually exist
list_shell_rcs() {
    local rcs=()
    [[ -f "$HOME/.bashrc" ]] && rcs+=("$HOME/.bashrc")
    [[ -f "$HOME/.zshrc" ]]  && rcs+=("$HOME/.zshrc")
    [[ -f "$HOME/.config/fish/config.fish" ]] && rcs+=("$HOME/.config/fish/config.fish")
    printf '%s\n' "${rcs[@]}"
}

# 把 alias 行写到所有现存的 shell rc 文件中
# Write alias line into every existing shell rc file
write_alias_all_shells() {
    local distro="$1"
    local bash_line="alias ${distro}='proot-distro login ${distro}'"
    local fish_line="alias ${distro} 'proot-distro login ${distro}'"

    # bash / zsh 用同一种 alias 语法 / bash and zsh share alias syntax
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [[ -f "$rc" ]] || continue
        grep -qF "$bash_line" "$rc" 2>/dev/null || echo "$bash_line" >> "$rc"
    done

    # fish 不一样 / fish has its own syntax
    local fish_rc="$HOME/.config/fish/config.fish"
    if [[ -d "$HOME/.config/fish" ]]; then
        mkdir -p "$(dirname "$fish_rc")"
        touch "$fish_rc"
        grep -qF "$fish_line" "$fish_rc" 2>/dev/null || echo "$fish_line" >> "$fish_rc"
    fi
}

# 从所有 shell rc 文件中删除某个发行版的 alias
# Strip a distro's alias line from every shell rc
remove_alias_all_shells() {
    local distro="$1"
    for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.config/fish/config.fish"; do
        [[ -f "$rc" ]] || continue
        sed -i.bak "/^alias ${distro}[[:space:]=]/d" "$rc" 2>/dev/null || true
        rm -f "${rc}.bak"
    done
}

# 列出已安装发行版（兼容多种 proot-distro 输出格式）
# List installed distros, tolerant of proot-distro format variations
list_installed_distros() {
    proot-distro list --installed 2>/dev/null \
        | sed -E 's/^[[:space:]]*\*?[[:space:]]*//' \
        | awk '/^[a-z][a-z0-9-]*([[:space:]]|$)/{print $1}' \
        | sort -u
}
