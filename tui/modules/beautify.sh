#!/usr/bin/env bash
# tui/modules/beautify.sh - 主题美化 + shell 提示符（bash/zsh/fish）
# Theme beautify + shell prompt (bash/zsh/fish)

set -uo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MODULE_DIR/_common.sh"

BEAUTIFY_MARKER="# xynrin-beautify"

beautify_apply_theme() {
    local theme="$1"
    local props="$HOME/.termux/termux.properties"
    local colors="$HOME/.termux/colors.properties"
    local font="$HOME/.termux/font.ttf"
    mkdir -p "$HOME/.termux"

    local ts="$(date +%s)"
    [[ -f "$colors" ]] && cp "$colors" "${colors}.bak.${ts}"
    [[ -f "$props" ]]  && cp "$props"  "${props}.bak.${ts}"
    [[ -f "$font" ]]   && cp "$font"   "${font}.bak.${ts}"

    log_step "writing theme $theme"
    case "$theme" in
        dracula)
            cat > "$colors" <<'EOF'
# xynrin-beautify: dracula
foreground=#f8f8f2
background=#282a36
cursor=#f8f8f2
color0=#000000
color1=#ff5555
color2=#50fa7b
color3=#f1fa8c
color4=#bd93f9
color5=#ff79c6
color6=#8be9fd
color7=#bfbfbf
color8=#4d4d4d
color9=#ff6e67
color10=#5af78e
color11=#f4f99d
color12=#caa9fa
color13=#ff92d0
color14=#9aedfe
color15=#e6e6e6
EOF
            ;;
        catppuccin)
            cat > "$colors" <<'EOF'
# xynrin-beautify: catppuccin
foreground=#cdd6f4
background=#1e1e2e
cursor=#f5e0dc
color0=#45475a
color1=#f38ba8
color2=#a6e3a1
color3=#f9e2af
color4=#89b4fa
color5=#f5c2e7
color6=#94e2d5
color7=#bac2de
color8=#585b70
color9=#f38ba8
color10=#a6e3a1
color11=#f9e2af
color12=#89b4fa
color13=#f5c2e7
color14=#94e2d5
color15=#a6adc8
EOF
            ;;
        nord)
            cat > "$colors" <<'EOF'
# xynrin-beautify: nord
foreground=#d8dee9
background=#2e3440
cursor=#d8dee9
color0=#3b4252
color1=#bf616a
color2=#a3be8c
color3=#ebcb8b
color4=#81a1c1
color5=#b48ead
color6=#88c0d0
color7=#e5e9f0
color8=#4c566a
color9=#bf616a
color10=#a3be8c
color11=#ebcb8b
color12=#81a1c1
color13=#b48ead
color14=#8fbcbb
color15=#eceff4
EOF
            ;;
    esac

    cat > "$props" <<'EOF'
# xynrin-beautify
terminal-cursor-style = bar
terminal-cursor-blink-rate = 500
extra-keys = [['ESC','/','-','HOME','UP','END','PGUP'],['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN']]
EOF

    log_step "${MSG_BEAUTIFY_DOWNLOADING_FONT:-Downloading font}"
    if ! command -v curl &> /dev/null; then
        pkg install -y curl &> /dev/null || true
    fi
    local font_url="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf"
    if ! curl -fsSL --connect-timeout 10 "$font_url" -o "$font" 2>/dev/null; then
        log_warn "${MSG_BEAUTIFY_FONT_FAIL:-Font download failed}"
    fi

    command -v termux-reload-settings &> /dev/null && termux-reload-settings || true
    log_ok "${MSG_BEAUTIFY_APPLIED:-Beautify applied}: $theme"
}

beautify_setup_bash_starship() {
    if ! command -v starship &> /dev/null; then
        log_step "${MSG_BEAUTIFY_INSTALLING_STARSHIP:-Installing starship}"
        pkg install -y starship &> /dev/null || { log_warn "starship install failed"; return 1; }
    fi
    mkdir -p "$HOME/.config"
    cat > "$HOME/.config/starship.toml" <<'EOF'
# xynrin-beautify
add_newline = true
format = "[┏](bold green) $username$hostname$directory$git_branch$git_status\n[┗](bold green) $character"
[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
[directory]
style = "bold cyan"
truncation_length = 3
[git_branch]
symbol = " "
style = "bold purple"
EOF
    local rc="$HOME/.bashrc"
    touch "$rc"
    if ! grep -qF 'starship init bash' "$rc"; then
        printf '\n%s\neval "$(starship init bash)"\n' "$BEAUTIFY_MARKER" >> "$rc"
    fi
    log_ok "bash + starship configured"
}

beautify_setup_zsh() {
    if ! command -v zsh &> /dev/null; then
        log_step "${MSG_BEAUTIFY_INSTALLING_SHELL:-Installing} zsh"
        pkg install -y zsh &> /dev/null || { log_warn "zsh install failed"; return 1; }
    fi
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_step "installing oh-my-zsh"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended &> /dev/null || \
            log_warn "oh-my-zsh install failed"
    fi
    local p10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    if [[ ! -d "$p10k_dir" ]]; then
        log_step "installing powerlevel10k"
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" &> /dev/null || \
            log_warn "powerlevel10k clone failed"
    fi
    local zrc="$HOME/.zshrc"
    if [[ -f "$zrc" ]] && ! grep -qF "$BEAUTIFY_MARKER" "$zrc"; then
        sed -i.bak 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$zrc"
        rm -f "${zrc}.bak"
        printf '\n%s\n' "$BEAUTIFY_MARKER" >> "$zrc"
    elif [[ ! -f "$zrc" ]]; then
        cat > "$zrc" <<'EOF'
# xynrin-beautify
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)
source $ZSH/oh-my-zsh.sh
EOF
    fi
    log_ok "zsh + oh-my-zsh + powerlevel10k configured"
    log_info "${MSG_BEAUTIFY_CHSH_HINT:-To switch shell run: chsh -s} $(command -v zsh)"
}

beautify_setup_fish() {
    if ! command -v fish &> /dev/null; then
        log_step "${MSG_BEAUTIFY_INSTALLING_SHELL:-Installing} fish"
        pkg install -y fish &> /dev/null || { log_warn "fish install failed"; return 1; }
    fi
    mkdir -p "$HOME/.config/fish"
    local fish_rc="$HOME/.config/fish/config.fish"
    touch "$fish_rc"
    if ! grep -qF "$BEAUTIFY_MARKER" "$fish_rc"; then
        printf '\n%s\n' "$BEAUTIFY_MARKER" >> "$fish_rc"
    fi
    log_step "installing fisher + tide"
    fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher && fisher install IlanCosman/tide@v6' &> /dev/null || \
        log_warn "fisher/tide install failed"
    log_ok "fish + fisher + tide configured"
    log_info "${MSG_BEAUTIFY_CHSH_HINT:-To switch shell run: chsh -s} $(command -v fish)"
}

beautify_shell_menu() {
    local options=(
        "1) ${MSG_BEAUTIFY_SHELL_BASH:-bash + starship}"
        "2) ${MSG_BEAUTIFY_SHELL_ZSH:-zsh + oh-my-zsh + powerlevel10k}"
        "3) ${MSG_BEAUTIFY_SHELL_FISH:-fish + fisher + tide}"
        "0) ${MSG_BEAUTIFY_SHELL_SKIP:-skip}"
    )
    log_info "${MSG_BEAUTIFY_SHELL_TITLE:-Choose shell prompt}"
    local picked
    if command -v fzf &> /dev/null; then
        picked="$(printf '%s\n' "${options[@]}" | fzf --height=30% --reverse --no-info --border=rounded \
            --prompt="shell > ")" || return 0
    else
        printf '  %s\n' "${options[@]}"
        echo -n "> "
        read -r raw
        picked="${raw}) "
    fi
    case "$picked" in
        1*) beautify_setup_bash_starship ;;
        2*) beautify_setup_zsh ;;
        3*) beautify_setup_fish ;;
        0*|"") log_info "skipped shell setup" ;;
    esac
}

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

    for f in "$HOME/.termux/colors.properties" "$HOME/.termux/termux.properties" "$HOME/.config/starship.toml"; do
        [[ -f "$f" ]] && grep -q "$BEAUTIFY_MARKER" "$f" 2>/dev/null && rm -f "$f"
    done
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

beautify_action() {
    local options=(
        "1) ${MSG_BEAUTIFY_DRACULA:-Dracula}"
        "2) ${MSG_BEAUTIFY_CATPPUCCIN:-Catppuccin}"
        "3) ${MSG_BEAUTIFY_NORD:-Nord}"
        "4) ${MSG_BEAUTIFY_UNINSTALL:-Uninstall}"
        "0) ${OPT_BACK:-Back}"
    )
    log_info "${MSG_BEAUTIFY_TITLE:-Beautify}"
    local picked
    if command -v fzf &> /dev/null; then
        picked="$(printf '%s\n' "${options[@]}" | fzf --height=40% --reverse --no-info --border=rounded \
            --prompt="theme > ")" || return 0
    else
        printf '  %s\n' "${options[@]}"
        echo -n "> "
        read -r raw
        picked="${raw}) "
    fi
    case "$picked" in
        1*) beautify_apply_theme "dracula"    ; beautify_shell_menu ;;
        2*) beautify_apply_theme "catppuccin" ; beautify_shell_menu ;;
        3*) beautify_apply_theme "nord"       ; beautify_shell_menu ;;
        4*) beautify_uninstall_action ;;
        0*|"") return 0 ;;
        *) log_warn "${MSG_INVALID_CHOICE:-Invalid choice}" ;;
    esac
}
