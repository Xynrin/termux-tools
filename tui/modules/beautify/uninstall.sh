#!/usr/bin/env bash
# tui/modules/beautify/uninstall.sh - 卸载所有 xynrin-beautify 痕迹
# Strip every xynrin-beautify trace from configs

beautify_uninstall_action() {
    local found=()
    [[ -f "$HOME/.termux/colors.properties" ]] && grep -q "$BEAUTIFY_MARKER" "$HOME/.termux/colors.properties" 2>/dev/null && found+=("colors.properties")
    [[ -f "$HOME/.termux/termux.properties" ]] && grep -q "$BEAUTIFY_MARKER" "$HOME/.termux/termux.properties" 2>/dev/null && found+=("termux.properties")
    [[ -f "$HOME/.config/starship.toml" ]] && grep -q "$BEAUTIFY_MARKER" "$HOME/.config/starship.toml" 2>/dev/null && found+=("starship.toml")
    [[ -f "$HOME/.bashrc" ]]                && grep -q "$BEAUTIFY_MARKER" "$HOME/.bashrc"                2>/dev/null && found+=(".bashrc")
    [[ -f "$HOME/.zshrc" ]]                 && grep -q "$BEAUTIFY_MARKER" "$HOME/.zshrc"                 2>/dev/null && found+=(".zshrc")
    [[ -f "$HOME/.config/fish/config.fish" ]] && grep -q "$BEAUTIFY_MARKER" "$HOME/.config/fish/config.fish" 2>/dev/null && found+=("config.fish")
    [[ -f "$HOME/.termux/font.ttf" ]] && found+=("font.ttf")

    if [[ ${#found[@]} -eq 0 ]]; then
        log_warn "${MSG_BEAUTIFY_NONE_FOUND:-No beautify config found}"
        return 0
    fi

    log_info "${MSG_BEAUTIFY_DETECTED:-Detected}:"
    for f in "${found[@]}"; do log_info "  - $f"; done

    # colors.properties / starship.toml 是本工具完全产出的文件，可以整删
    # termux.properties 是用户共享的文件，必须只剥本工具的段，不能 rm
    # colors.properties / starship.toml are owned entirely by us — safe to rm.
    # termux.properties is shared with the user — strip only our block,
    # otherwise we'd wipe user's extra-keys / cursor / font tweaks.
    for f in "$HOME/.termux/colors.properties" "$HOME/.config/starship.toml"; do
        [[ -f "$f" ]] && grep -q "$BEAUTIFY_MARKER" "$f" 2>/dev/null && rm -f "$f"
    done
    if [[ -f "$HOME/.termux/termux.properties" ]]; then
        sed -i '/# xynrin-beautify-start/,/# xynrin-beautify-end/d' "$HOME/.termux/termux.properties" 2>/dev/null || true
        # 兜底：处理 v3.2.0 时段标记还没分前后的旧痕迹
        # Fallback: clean v3.2.0 leftover that didn't have start/end markers yet
        sed -i '/^# xynrin-beautify$/,+3d' "$HOME/.termux/termux.properties" 2>/dev/null || true
    fi
    rm -f "$HOME/.termux/font.ttf"

    for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.config/fish/config.fish"; do
        [[ -f "$rc" ]] || continue
        grep -q "$BEAUTIFY_MARKER" "$rc" 2>/dev/null || continue
        sed -i.bak '/# xynrin-beautify/,+1d' "$rc"
        rm -f "${rc}.bak"
    done

    command -v termux-reload-settings &> /dev/null && termux-reload-settings || true
    log_ok "${MSG_BEAUTIFY_REMOVED:-Beautify uninstalled}"
}
