#!/usr/bin/env bash
# termux-tools English language pack
# 英文语言包

# General messages / 通用消息
MSG_WELCOME="Welcome to xynrin!"
MSG_CURRENT_VERSION="Current version"
MSG_LATEST_VERSION="Latest version"
MSG_ALREADY_LATEST="Already up to date!"
MSG_UPDATE_AVAILABLE="Update available!"
MSG_UPDATING="Checking for updates..."
MSG_UPDATE_DONE="Update complete!"
MSG_UPDATE_FAILED="Update failed. Check your network."
MSG_APPLYING_MIGRATION="Applying migration..."
MSG_PRESS_ENTER="Press Enter to continue..."
MSG_GOODBYE="Goodbye!"
MSG_INVALID_CHOICE="Invalid choice."

# Menu / 菜单
MENU_TITLE="Main Menu"
OPT_UPDATE="Update xynrin"
OPT_PROOT_INSTALL="Install distro with proot"
OPT_PROOT_BACKUP="Backup / restore / launchers"
OPT_X11="X11 desktop (XFCE / LXQt)"
OPT_SSH="SSH helper (remote into phone)"
OPT_CLEANUP="Storage analyzer & cleanup"
OPT_BOOT="Termux:Boot console"
OPT_SYSTEM_INFO="System info (live dashboard)"
OPT_MIRROR="Configure mirror sources"
OPT_LANGUAGE="Change language"
OPT_BEAUTIFY="Beautify Termux"
OPT_EXIT="Exit"
OPT_BACK="Back"

# proot / proot 相关
MSG_PROOT_DISTRO_NAME="Enter the distro name to install"
MSG_PROOT_DISTRO_EXAMPLE="e.g.: ubuntu, debian, archlinux, fedora, alpine"
MSG_PROOT_INSTALLING="Installing"
MSG_PROOT_INSTALL_DONE="Installation complete!"
MSG_PROOT_INSTALL_FAILED="Installation failed."
MSG_PROOT_NOT_INSTALLED="No proot distros installed."
MSG_PROOT_MANAGE_TITLE="Distro management"
MSG_PROOT_PICK_DISTRO="Pick a distro"
MSG_PROOT_ACTION_TITLE="Choose action"
MSG_PROOT_ACTION_LOGIN="Log in"
MSG_PROOT_ACTION_REMOVE="Remove (with alias)"
MSG_PROOT_REMOVE_CONFIRM="Confirm removal (irreversible)? type y"
MSG_PROOT_REMOVING="Removing"
MSG_PROOT_REMOVE_DONE="Removal complete"
MSG_PROOT_REMOVE_FAILED="Removal failed"
MSG_PROOT_LOGIN_HINT="Type 'exit' inside the distro to return to xynrin"

# Aliases / 别名
MSG_ALIASES_TITLE="Available distro aliases"
MSG_NO_ALIAS="No aliases configured."
MSG_ALIAS_CONFIGURED="Alias configured"
MSG_ALIAS_RESTART_HINT="Restart shell or run: source ~/.bashrc"

# System info / 系统信息
MSG_SYSTEM_INFO="System Info"
MSG_OS="OS"
MSG_ARCH="Architecture"
MSG_KERNEL="Kernel"
MSG_SHELL="Shell"
MSG_TERMUX_VERSION="Termux Version"

# Mirror / 镜像源
MSG_MIRROR_TITLE="Configure Mirror Sources"
MSG_MIRROR_TSINGHUA="Tsinghua University (China)"
MSG_MIRROR_USTC="USTC (China)"
MSG_MIRROR_OFFICIAL="Official (packages.termux.dev)"
MSG_MIRROR_REPAIR="Detected broken mirror config, reset to official"
MSG_MIRROR_APPLYING="Applying mirror"
MSG_MIRROR_APPLIED="Mirror applied"
MSG_MIRROR_UPDATING="Updating package index..."
MSG_MIRROR_UPDATE_WARN="Index update failed; mirror may be unreachable."
MSG_MIRROR_BACKUP_WARN="Could not back up sources.list (continuing)."
MSG_MIRROR_WRITE_FAIL="Failed to write sources.list"

# fzf
MSG_FZF_INSTALLING="fzf not found, installing..."
MSG_FZF_FALLBACK="fzf unavailable, using fallback prompt"

# CLI / CLI 命令
CLI_HELP_USAGE="Usage: xynrin [command]"
CLI_HELP_CMDS="Commands:"
CLI_HELP_MENU="  menu      Open main menu (default)"
CLI_HELP_HELP="  help      Show this help"
CLI_HELP_VERSION="  version   Show version"
CLI_HELP_UPDATE="  update    Check and update xynrin"

# Language / 语言
LANG_TITLE="Select Language / 选择语言"
LANG_ZH="中文"
LANG_EN="English"
MSG_LANG_SWITCHED="Language switched."

# Beautify / 美化
MSG_BEAUTIFY_TITLE="Beautify Termux"
MSG_BEAUTIFY_DRACULA="Dracula theme (purple/black)"
MSG_BEAUTIFY_CATPPUCCIN="Catppuccin theme (warm pastel)"
MSG_BEAUTIFY_NORD="Nord theme (cool blues)"
MSG_BEAUTIFY_UNINSTALL="Uninstall (auto-detect)"
MSG_BEAUTIFY_DOWNLOADING_FONT="Downloading font..."
MSG_BEAUTIFY_FONT_FAIL="Font download failed, skipped."
MSG_BEAUTIFY_INSTALLING_STARSHIP="Installing starship prompt..."
MSG_BEAUTIFY_APPLIED="Beautify applied"
MSG_BEAUTIFY_NONE_FOUND="No xynrin-managed beautify config found."
MSG_BEAUTIFY_DETECTED="Detected beautify items"
MSG_BEAUTIFY_REMOVED="Beautify uninstalled. Backups kept."
MSG_BEAUTIFY_SHELL_TITLE="Choose shell prompt"
MSG_BEAUTIFY_SHELL_BASH="bash + starship (default)"
MSG_BEAUTIFY_SHELL_ZSH="zsh + oh-my-zsh + powerlevel10k"
MSG_BEAUTIFY_SHELL_FISH="fish + fisher + tide"
MSG_BEAUTIFY_SHELL_SKIP="Skip shell setup"
MSG_BEAUTIFY_INSTALLING_SHELL="Installing shell"
MSG_BEAUTIFY_CHSH_HINT="To switch default shell, run: chsh -s"

# System info / 系统信息（扩展）
MSG_SYSINFO_CPU="CPU"
MSG_SYSINFO_MEM="Memory"
MSG_SYSINFO_STORAGE="Storage"
MSG_SYSINFO_BATTERY="Battery"
MSG_SYSINFO_DISTROS="Installed distros"
MSG_SYSINFO_XYNRIN="xynrin version"

# bootstrap
MSG_BOOTSTRAP_TITLE="First-time setup"
MSG_BOOTSTRAP_PKG_UPDATE="Updating package index..."
MSG_BOOTSTRAP_PKG_INSTALL="Installing dependencies..."
MSG_BOOTSTRAP_UBUNTU="Installing default container Ubuntu..."
MSG_BOOTSTRAP_DONE="Setup complete, entering main menu"
MSG_BOOTSTRAP_HINT_DISTRO="Tip: run option 2 to install a Linux distro on demand"
MSG_BOOTSTRAP_PRETTY="Installing lsd / bat (icons + syntax highlight)..."
MSG_BOOTSTRAP_PRETTY_DONE="tree / cat / fastfetch dressed up"

# CHANGELOG / Update confirm
MSG_CHANGELOG_TITLE="Changelog"
MSG_UPDATE_CONFIRM="Confirm update? (Y/N)"
MSG_UPDATE_CHECKING="Checking remote version..."
MSG_UPDATE_NO_NEW="Already on the latest version"
