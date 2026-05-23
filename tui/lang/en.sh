#!/usr/bin/env bash
# 使用 env 查找 bash，提高跨平台兼容性
# Use env to locate bash for better cross-platform compatibility
#
# ============================================================
# termux-tools English language pack
# termux-tools 英文语言包
#
# Loaded by the main program via `source`. All variables defined
# here are injected into the main program's runtime environment.
# 文件由主程序通过 source 命令加载，所有变量会被注入到主程序的运行环境
#
# Naming convention / 命名规范:
#   MSG_*  - general messages / 通用提示信息
#   OPT_*  - menu option labels / 菜单选项文本
#   MENU_* - menu titles / 菜单标题
#   CLI_*  - CLI help texts / CLI 命令帮助文本
#   LANG_* - language switching / 语言切换相关
# ============================================================

# ============================================================
# General messages
# 通用提示信息
# ============================================================

# Welcome message shown at startup
# 启动时显示的欢迎语
MSG_WELCOME="Welcome to termux-tools!"

# Label for current version (e.g. "Current version: 1.0.0")
# 当前版本号标签
MSG_CURRENT_VERSION="Current version"

# Label for remote latest version
# 远程最新版本号标签
MSG_LATEST_VERSION="Latest version"

# Already up to date notice
# 已是最新版本提示
MSG_ALREADY_LATEST="Already up to date!"

# Update available notice
# 发现新版本提示
MSG_UPDATE_AVAILABLE="Update available!"

# In-progress message during update
# 正在更新的进度提示
MSG_UPDATING="Updating..."

# Update success message
# 更新成功完成提示
MSG_UPDATE_DONE="Update complete! Please restart termux-tools."

# Update failure (usually network issue)
# 更新失败提示
MSG_UPDATE_FAILED="Update failed. Please check your network connection."

# Press-Enter-to-continue prompt
# 等待用户按 Enter 的提示
MSG_PRESS_ENTER="Press Enter to continue..."

# Goodbye message on exit
# 退出时的告别语
MSG_GOODBYE="Goodbye!"

# Error shown when user input is invalid
# 用户输入无效时的错误提示
MSG_INVALID_CHOICE="Invalid choice, please try again."

# ============================================================
# Main menu options
# 主菜单选项
# ============================================================

# Menu title bar
# 菜单标题
MENU_TITLE="Main Menu"

# Option 1: self-update
# 选项 1：自我更新
OPT_UPDATE="Update termux-tools"

# Option 2: install a new distro
# 选项 2：使用 proot-distro 安装新发行版
OPT_PROOT_INSTALL="Install distro with proot"

# Option 3: login to installed distro
# 选项 3：登录已安装的 proot 发行版
OPT_PROOT_LOGIN="Login to proot distro"

# Option 4: show system info
# 选项 4：显示系统信息
OPT_SYSTEM_INFO="System info"

# Option 5: change UI language
# 选项 5：切换界面语言
OPT_LANGUAGE="Change language"

# Option 0: exit program
# 选项 0：退出程序
OPT_EXIT="Exit"

# ============================================================
# proot-related messages
# proot 相关提示
# ============================================================

# Prompt user to enter distro name
# 提示用户输入要安装的发行版名
MSG_PROOT_DISTRO_NAME="Enter the distro name to install"

# Examples of common distros
# 提供常见发行版示例
MSG_PROOT_DISTRO_EXAMPLE="e.g.: ubuntu, debian, archlinux, fedora"

# Installing message (followed by distro name)
# 安装中提示（后面会拼接发行版名）
MSG_PROOT_INSTALLING="Installing"

# Distro install succeeded
# 发行版安装成功
MSG_PROOT_INSTALL_DONE="Installation complete!"

# Distro install failed
# 发行版安装失败
MSG_PROOT_INSTALL_FAILED="Installation failed."

# No proot distros installed
# 没有任何已安装的 proot 发行版
MSG_PROOT_NOT_INSTALLED="No proot distros installed."

# Prompt to select a distro for login
# 选择登录哪个发行版的提示
MSG_PROOT_SELECT="Select a distro to login"

# Reminder to use 'exit' to leave proot env
# 提醒用户使用 exit 退出 proot 环境
MSG_PROOT_LOGIN_HINT="Tip: Use 'exit' command to leave proot environment"

# ============================================================
# System info labels
# 系统信息标签
# ============================================================

# "System info" section title
# "系统信息" 区块标题
MSG_SYSTEM_INFO="System Info"

# OS label
# 操作系统标签
MSG_OS="OS"

# Architecture label
# CPU 架构标签
MSG_ARCH="Architecture"

# Kernel version label
# 内核版本标签
MSG_KERNEL="Kernel"

# Shell label
# 当前 Shell 标签
MSG_SHELL="Shell"

# Termux version label
# Termux 版本标签
MSG_TERMUX_VERSION="Termux Version"

# ============================================================
# CLI command help texts
# CLI 命令帮助文本
# ============================================================

# Title line for help command
# help 命令的标题行
CLI_HELP_TITLE="termux-tools - Termux helper tool"

# Usage syntax
# 用法说明
CLI_HELP_USAGE="Usage: termux-tools [command]"

# "Available commands:" header
# "可用命令：" 区块标题
CLI_HELP_CMDS="Available commands:"

# menu subcommand description
# menu 子命令说明
CLI_HELP_MENU="  menu      Open main menu (default)"

# help subcommand description
# help 子命令说明
CLI_HELP_HELP="  help      Show this help message"

# version subcommand description
# version 子命令说明
CLI_HELP_VERSION="  version   Show version"

# update subcommand description
# update 子命令说明
CLI_HELP_UPDATE="  update    Check and update termux-tools"

# ============================================================
# Language selection menu
# 语言选择菜单
# ============================================================

# Language selection title (bilingual)
# 语言选择标题（中英文双语）
LANG_TITLE="Select Language / 选择语言"

# Chinese option label
# 中文选项标签
LANG_ZH="中文"

# English option label
# 英文选项标签
LANG_EN="English"
