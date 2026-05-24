#!/usr/bin/env bash
# tui/modules/beautify/themes.sh - Termux 配色 + 字体
# Termux color schemes + font

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
