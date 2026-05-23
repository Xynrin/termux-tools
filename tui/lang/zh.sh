#!/usr/bin/env bash
# termux-tools 中文语言包
# Chinese language pack

# 通用消息 / General messages
MSG_WELCOME="欢迎使用 xynrin！"
MSG_CURRENT_VERSION="当前版本"
MSG_LATEST_VERSION="最新版本"
MSG_ALREADY_LATEST="已是最新版本！"
MSG_UPDATE_AVAILABLE="发现新版本！"
MSG_UPDATING="正在检查更新..."
MSG_UPDATE_DONE="更新完成！"
MSG_UPDATE_FAILED="更新失败，请检查网络连接。"
MSG_APPLYING_MIGRATION="正在应用迁移..."
MSG_PRESS_ENTER="按 Enter 继续..."
MSG_GOODBYE="再见！"
MSG_INVALID_CHOICE="无效选择。"

# 菜单 / Menu
MENU_TITLE="功能菜单"
OPT_UPDATE="更新 xynrin"
OPT_PROOT_INSTALL="使用 proot 安装发行版"
OPT_SYSTEM_INFO="系统信息"
OPT_MIRROR="添加或设置镜像源"
OPT_LANGUAGE="切换语言"
OPT_BEAUTIFY="美化 Termux"
OPT_EXIT="退出"
OPT_BACK="返回"

# proot 相关 / proot
MSG_PROOT_DISTRO_NAME="请输入要安装的发行版名称"
MSG_PROOT_DISTRO_EXAMPLE="例如：ubuntu, debian, archlinux, fedora, alpine"
MSG_PROOT_INSTALLING="正在安装"
MSG_PROOT_INSTALL_DONE="安装完成！"
MSG_PROOT_INSTALL_FAILED="安装失败。"
MSG_PROOT_NOT_INSTALLED="未安装任何 proot 发行版。"
MSG_PROOT_MANAGE_TITLE="发行版管理"
MSG_PROOT_PICK_DISTRO="选择一个发行版进行操作"
MSG_PROOT_ACTION_TITLE="选择操作"
MSG_PROOT_ACTION_LOGIN="登录"
MSG_PROOT_ACTION_REMOVE="删除（包含别名）"
MSG_PROOT_REMOVE_CONFIRM="确认删除（不可恢复）？输入 y 确认"
MSG_PROOT_REMOVING="正在删除"
MSG_PROOT_REMOVE_DONE="删除完成"
MSG_PROOT_REMOVE_FAILED="删除失败"
MSG_PROOT_LOGIN_HINT="登录后请输入 exit 返回 xynrin"

# 别名 / Aliases
MSG_ALIASES_TITLE="可用的发行版别名"
MSG_NO_ALIAS="暂未配置任何别名。"
MSG_ALIAS_CONFIGURED="别名已配置"
MSG_ALIAS_RESTART_HINT="重启终端或执行：source ~/.bashrc"

# 系统信息 / System info
MSG_SYSTEM_INFO="系统信息"
MSG_OS="操作系统"
MSG_ARCH="架构"
MSG_KERNEL="内核版本"
MSG_SHELL="Shell"
MSG_TERMUX_VERSION="Termux 版本"

# 镜像源 / Mirror
MSG_MIRROR_TITLE="配置镜像源"
MSG_MIRROR_TSINGHUA="清华大学（中国）"
MSG_MIRROR_USTC="中科大（中国）"
MSG_MIRROR_OFFICIAL="官方（packages.termux.dev）"
MSG_MIRROR_REPAIR="检测到镜像配置受损，已重置为官方源"
MSG_MIRROR_APPLYING="正在应用镜像"
MSG_MIRROR_APPLIED="镜像已应用"
MSG_MIRROR_UPDATING="正在更新软件源索引..."
MSG_MIRROR_UPDATE_WARN="索引更新失败，镜像可能无法访问。"
MSG_MIRROR_BACKUP_WARN="无法备份 sources.list（继续）。"
MSG_MIRROR_WRITE_FAIL="无法写入 sources.list"

# fzf
MSG_FZF_INSTALLING="未检测到 fzf，正在安装..."
MSG_FZF_FALLBACK="fzf 不可用，使用回退提示"

# CLI 命令 / CLI
CLI_HELP_USAGE="用法：xynrin [命令]"
CLI_HELP_CMDS="可用命令："
CLI_HELP_MENU="  menu      打开功能菜单（默认）"
CLI_HELP_HELP="  help      显示此帮助信息"
CLI_HELP_VERSION="  version   显示版本号"
CLI_HELP_UPDATE="  update    检查并更新 xynrin"

# 语言 / Language
LANG_TITLE="选择语言 / Select Language"
LANG_ZH="中文"
LANG_EN="English"
MSG_LANG_SWITCHED="语言已切换。"

# 美化 / Beautify
MSG_BEAUTIFY_TITLE="一键美化 Termux"
MSG_BEAUTIFY_DRACULA="Dracula 主题（紫黑配色）"
MSG_BEAUTIFY_CATPPUCCIN="Catppuccin 主题（柔和暖色）"
MSG_BEAUTIFY_NORD="Nord 主题（冷色系）"
MSG_BEAUTIFY_UNINSTALL="卸载美化（自动识别）"
MSG_BEAUTIFY_DOWNLOADING_FONT="正在下载字体..."
MSG_BEAUTIFY_FONT_FAIL="字体下载失败，已跳过。"
MSG_BEAUTIFY_INSTALLING_STARSHIP="正在安装 starship 提示符..."
MSG_BEAUTIFY_APPLIED="美化已应用"
MSG_BEAUTIFY_NONE_FOUND="未检测到本工具创建的美化配置。"
MSG_BEAUTIFY_DETECTED="检测到以下美化项"
MSG_BEAUTIFY_REMOVED="美化已卸载，原配置备份保留。"
MSG_BEAUTIFY_SHELL_TITLE="选择 shell 提示符"
MSG_BEAUTIFY_SHELL_BASH="bash + starship（默认）"
MSG_BEAUTIFY_SHELL_ZSH="zsh + oh-my-zsh + powerlevel10k"
MSG_BEAUTIFY_SHELL_FISH="fish + fisher + tide"
MSG_BEAUTIFY_SHELL_SKIP="跳过 shell 配置"
MSG_BEAUTIFY_INSTALLING_SHELL="正在安装 shell"
MSG_BEAUTIFY_CHSH_HINT="切换默认 shell 请运行：chsh -s"

# 系统信息 / System info（扩展）
MSG_SYSINFO_CPU="CPU"
MSG_SYSINFO_MEM="内存"
MSG_SYSINFO_STORAGE="存储"
MSG_SYSINFO_BATTERY="电池"
MSG_SYSINFO_DISTROS="已装发行版"
MSG_SYSINFO_XYNRIN="xynrin 版本"

# bootstrap
MSG_BOOTSTRAP_TITLE="首次部署"
MSG_BOOTSTRAP_PKG_UPDATE="正在更新软件包索引..."
MSG_BOOTSTRAP_PKG_INSTALL="正在安装依赖..."
MSG_BOOTSTRAP_UBUNTU="正在安装默认容器 Ubuntu..."
MSG_BOOTSTRAP_DONE="部署完成，进入主菜单"
MSG_BOOTSTRAP_HINT_DISTRO="提示：选项 2 可按需安装 Linux 发行版"
MSG_BOOTSTRAP_PRETTY="正在安装 lsd / bat（带图标 + 高亮）..."
MSG_BOOTSTRAP_PRETTY_DONE="tree / cat / fastfetch 已美化"

# CHANGELOG / 更新确认
MSG_CHANGELOG_TITLE="更新日志"
MSG_UPDATE_CONFIRM="确认更新？(Y/N)"
MSG_UPDATE_CHECKING="正在检查远端版本..."
MSG_UPDATE_NO_NEW="已经是最新版本"
