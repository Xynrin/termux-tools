#!/usr/bin/env bash
# tui/modules/beautify/preview.sh - fzf 主题预览（带 ANSI 色块）
# Theme preview rendered via fzf --preview (real ANSI escapes)

beautify_preview() {
    local sel="$1"
    case "$sel" in
        1*)
            printf '%s\n' "Dracula  紫黑配色 / purple-on-black"
            echo
            printf '%s\n' "  bg #282a36   fg #f8f8f2"
            printf '  \e[38;2;255;85;85m███\e[0m red     \e[38;2;80;250;123m███\e[0m green\n'
            printf '  \e[38;2;241;250;140m███\e[0m yellow  \e[38;2;189;147;249m███\e[0m purple\n'
            printf '  \e[38;2;255;121;198m███\e[0m pink    \e[38;2;139;233;253m███\e[0m cyan\n'
            echo
            printf '\e[38;2;80;250;123m  ❯\e[0m ls\n'
            printf '\e[38;2;139;233;253m  documents/  README.md  src/\e[0m\n'
            ;;
        2*)
            printf '%s\n' "Catppuccin  柔和暖色 / soft pastel"
            echo
            printf '%s\n' "  bg #1e1e2e   fg #cdd6f4"
            printf '  \e[38;2;243;139;168m███\e[0m red     \e[38;2;166;227;161m███\e[0m green\n'
            printf '  \e[38;2;249;226;175m███\e[0m yellow  \e[38;2;137;180;250m███\e[0m blue\n'
            printf '  \e[38;2;245;194;231m███\e[0m pink    \e[38;2;148;226;213m███\e[0m teal\n'
            echo
            printf '\e[38;2;166;227;161m  ❯\e[0m ls\n'
            printf '\e[38;2;137;180;250m  documents/  README.md  src/\e[0m\n'
            ;;
        3*)
            printf '%s\n' "Nord  冷色系 / cool blues"
            echo
            printf '%s\n' "  bg #2e3440   fg #d8dee9"
            printf '  \e[38;2;191;97;106m███\e[0m red     \e[38;2;163;190;140m███\e[0m green\n'
            printf '  \e[38;2;235;203;139m███\e[0m yellow  \e[38;2;129;161;193m███\e[0m blue\n'
            printf '  \e[38;2;180;142;173m███\e[0m purple  \e[38;2;136;192;208m███\e[0m cyan\n'
            echo
            printf '\e[38;2;163;190;140m  ❯\e[0m ls\n'
            printf '\e[38;2;129;161;193m  documents/  README.md  src/\e[0m\n'
            ;;
        4*)
            printf '%s\n' "Uninstall / 卸载"
            echo
            printf '%s\n' "  Removes:"
            printf '%s\n' "    ~/.termux/colors.properties     (xynrin marker)"
            printf '%s\n' "    ~/.termux/termux.properties     (xynrin marker)"
            printf '%s\n' "    ~/.termux/font.ttf"
            printf '%s\n' "    ~/.config/starship.toml         (xynrin marker)"
            printf '%s\n' "    xynrin-beautify lines in:"
            printf '%s\n' "      ~/.bashrc / ~/.zshrc / ~/.config/fish/config.fish"
            ;;
        0*) printf '%s\n' "Back / 返回" ;;
    esac
}
