#!/usr/bin/env bash
# tui/modules/beautify/shells.sh - bash/zsh/fish 提示符配置
# Shell prompt setup: bash/zsh/fish

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

    export RUNZSH=no CHSH=no KEEP_ZSHRC=no
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

    local custom="$HOME/.oh-my-zsh/custom/plugins"
    [[ ! -d "$custom/zsh-autosuggestions" ]] && \
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$custom/zsh-autosuggestions" &> /dev/null
    [[ ! -d "$custom/zsh-syntax-highlighting" ]] && \
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom/zsh-syntax-highlighting" &> /dev/null

    cat > "$HOME/.zshrc" <<'EOF'
# xynrin-beautify
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
EOF

    cat > "$HOME/.p10k.zsh" <<'EOF'
# xynrin-beautify - pre-baked p10k config (no wizard)
'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs prompt_char)
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time time)
  typeset -g POWERLEVEL9K_MODE=nerdfont-complete
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  # 圆角段：每段两端各画半圆，整条 prompt 像 pill 胶囊
  # Rounded segments — pill-shaped prompt, needs Nerd Font
  # 用 ANSI-C 转义 ($'' / $'')，避免编辑时丢失私用区字符
  # Use ANSI-C escapes so the private-use chars don't get lost on edit
  typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=$''
  typeset -g POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=$''
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=$''
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL=$''
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR=' '

  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND=76
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND=196
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=39
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=103
  typeset -g POWERLEVEL9K_VCS_BRANCH_FOREGROUND=141
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=66
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
  typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
EOF

    local rc="$HOME/.bashrc"
    touch "$rc"
    if ! grep -qF "xynrin-beautify-zsh-launch" "$rc"; then
        cat >> "$rc" <<'EOF'

# xynrin-beautify-zsh-launch
[ -x "$(command -v zsh)" ] && [ -z "$ZSH_VERSION" ] && exec zsh -l
EOF
    fi

    log_ok "zsh + oh-my-zsh + powerlevel10k 已配置（跳过向导，下次进入终端自动启用）"
    log_info "立即体验：当前会话执行 exec zsh -l / Try now: run 'exec zsh -l'"
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
