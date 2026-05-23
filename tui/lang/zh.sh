#!/usr/bin/env bash
# 使用 env 查找 bash，提高跨平台兼容性
# Use env to locate bash for better cross-platform compatibility
#
# ============================================================
# termux-tools 中文语言包
# termux-tools Chinese language pack
#
# 文件由主程序通过 source 命令加载，所有变量会被注入到主程序的运行环境
# Loaded by main program via `source`, all variables are injected
# into the main program's runtime environment.
#
# 命名规范 / Naming convention:
#   MSG_*  - 通用提示信息 / general messages
#   OPT_*  - 菜单选项文本 / menu option labels
#   MENU_* - 菜单标题 / menu titles
#   CLI_*  - CLI 命令帮助文本 / CLI help texts
#   LANG_* - 语言切换相关 / language switching
# ============================================================

# ============================================================
# 通用提示信息
# General messages
# ============================================================

# 启动时显示的欢迎语
# Welcome message shown at startup
MSG_WELCOME="欢迎使用 termux-tools！"

# 当前版本号标签（用于显示 "当前版本: 1.0.0"）
# Label for current version (used like "Current version: 1.0.0")
MSG_CURRENT_VERSION="当前版本"

# 远程最新版本号标签
# Label for remote latest version
MSG_LATEST_VERSION="最新版本"

# 已是最新版本提示
# "Already up to date" notice
MSG_ALREADY_LATEST="已是最新版本！"

# 发现新版本提示
# "Update available" notice
MSG_UPDATE_AVAILABLE="发现新版本！"

# 正在更新的进度提示
# In-progress message during update
MSG_UPDATING="正在更新..."

# 更新成功完成提示
# Update success message
MSG_UPDATE_DONE="更新完成！请重新启动 termux-tools。"

# 更新失败提示（通常因为网络）
# Update failure (usually network issue)
MSG_UPDATE_FAILED="更新失败，请检查网络连接。"

# 等待用户按 Enter 的提示
# Press-Enter-to-continue prompt
MSG_PRESS_ENTER="按 Enter 继续..."

# 退出时的告别语
# Goodbye message on exit
MSG_GOODBYE="再见！"

# 用户输入无效时的错误提示
# Error shown when user input is invalid
MSG_INVALID_CHOICE="无效选择，请重试。"

# ============================================================
# 主菜单选项
# Main menu options
# ============================================================

# 菜单标题
# Menu title bar
MENU_TITLE="功能菜单"

# 选项 1：自我更新
# Option 1: self-update
OPT_UPDATE="更新 termux-tools"

# 选项 2：使用 proot-distro 安装新发行版
# Option 2: install a new distro via proot-distro
OPT_PROOT_INSTALL="使用 proot 安装发行版"

# 选项 3：登录已安装的 proot 发行版
# Option 3: login to an installed proot distro
OPT_PROOT_LOGIN="登录 proot 发行版"

# 选项 4：显示系统信息
# Option 4: show system info
OPT_SYSTEM_INFO="系统信息"

# 选项 5：切换界面语言
# Option 5: change UI language
OPT_LANGUAGE="切换语言"

# 选项 0：退出程序
# Option 0: exit program
OPT_EXIT="退出"

# ============================================================
# proot 相关提示
# proot-related messages
# ============================================================

# 提示用户输入要安装的发行版名
# Prompt user to enter distro name to install
MSG_PROOT_DISTRO_NAME="请输入要安装的发行版名称"

# 提供常见发行版示例
# Examples of common distros
MSG_PROOT_DISTRO_EXAMPLE="例如：ubuntu, debian, archlinux, fedora"

# 安装中提示（后面会拼接发行版名）
# Installing message (followed by distro name)
MSG_PROOT_INSTALLING="正在安装"

# 发行版安装成功
# Distro install succeeded
MSG_PROOT_INSTALL_DONE="安装完成！"

# 发行版安装失败
# Distro install failed
MSG_PROOT_INSTALL_FAILED="安装失败。"

# 没有任何已安装的 proot 发行版
# No proot distros installed
MSG_PROOT_NOT_INSTALLED="未安装任何 proot 发行版。"

# 选择登录哪个发行版的提示
# Prompt to select a distro for login
MSG_PROOT_SELECT="选择要登录的发行版"

# 提醒用户使用 exit 退出 proot 环境
# Reminder to use 'exit' to leave proot env
MSG_PROOT_LOGIN_HINT="提示：使用 exit 命令退出 proot 环境"

# ============================================================
# 系统信息标签
# System info labels
# ============================================================

# "系统信息" 区块标题
# "System info" section title
MSG_SYSTEM_INFO="系统信息"

# 操作系统标签
# OS label
MSG_OS="操作系统"

# CPU 架构标签
# Architecture label
MSG_ARCH="架构"

# 内核版本标签
# Kernel version label
MSG_KERNEL="内核版本"

# 当前 Shell 标签（保持英文 "Shell" 通用易懂）
# Shell label (kept as "Shell" for universality)
MSG_SHELL="Shell"

# Termux 版本标签
# Termux version label
MSG_TERMUX_VERSION="Termux 版本"

# ============================================================
# CLI 命令帮助文本
# CLI command help texts
# ============================================================

# help 命令的标题行
# Title line for help command
CLI_HELP_TITLE="termux-tools - Termux 辅助工具"

# 用法说明
# Usage syntax
CLI_HELP_USAGE="用法：termux-tools [命令]"

# "可用命令：" 区块标题
# "Available commands:" header
CLI_HELP_CMDS="可用命令："

# menu 子命令说明
# menu subcommand description
CLI_HELP_MENU="  menu      打开功能菜单（默认）"

# help 子命令说明
# help subcommand description
CLI_HELP_HELP="  help      显示此帮助信息"

# version 子命令说明
# version subcommand description
CLI_HELP_VERSION="  version   显示版本号"

# update 子命令说明
# update subcommand description
CLI_HELP_UPDATE="  update    检查并更新 termux-tools"

# ============================================================
# 语言选择菜单
# Language selection menu
# ============================================================

# 语言选择标题（中英文双语，避免用户看不懂）
# Language selection title (bilingual to avoid confusion)
LANG_TITLE="选择语言 / Select Language"

# 中文选项标签
# Chinese option label
LANG_ZH="中文"

# 英文选项标签
# English option label
LANG_EN="English"
