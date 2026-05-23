<div align="center">

# xynrin

**A TUI helper tool for Termux beginners**

[![License](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-3.0.0-brightgreen.svg)](scripts/version)
[![Platform](https://img.shields.io/badge/platform-Termux-black.svg)](https://termux.dev)

[中文 README](README.zh.md) · [Issues](https://github.com/Xynrin/termux-tools/issues)

</div>

> **v3.0.0**: TUI rewritten in **Rust + ratatui** for a smoother native interface. The bash version is kept as a fallback and is still the engine behind every action — Rust just drives the UI. Existing users: run `xynrin update` to migrate seamlessly.
>
> **v2.0.0**: command renamed from `termux-tools` to `xynrin` (the official `termux-tools` package conflicts). Existing users: run `termux-tools update` once and you'll be migrated automatically.

## One-line install

```bash
curl -sL https://raw.githubusercontent.com/Xynrin/termux-tools/main/bootstrap.sh | bash
```

The bootstrap script will:
1. Show the logo + version + author + repo
2. Clone the repo to `~/termux-tools`
3. Install dependencies; try to fetch the pre-built **Rust TUI binary** for your CPU, fall back to the bash TUI if download fails
4. Install Ubuntu via `proot-distro` and configure aliases (e.g. `ubuntu`)
5. Print configured aliases, then auto-launch the TUI

## Manual install

```bash
git clone https://github.com/Xynrin/termux-tools.git ~/termux-tools
cd ~/termux-tools
bash install.sh
```

## Usage

```bash
xynrin              # open TUI (Rust if available, bash otherwise)
xynrin-bash         # always the bash TUI
xynrin help         # CLI help
xynrin version      # show version
xynrin update       # check & pull updates
```

## TUI menu

| Key | Action |
|:---:|---|
| `1` | Update xynrin |
| `2` | Install distro with proot |
| `3` | List distro aliases (only real, usable ones) |
| `4` | System info |
| `5` | Configure mirror sources |
| `6` | Change language |
| `7` | Beautify Termux |
| `8` | Exit |

## Architecture (v3.0.0)

```
┌─────────────────────────┐
│  xynrin  (Rust TUI)     │  ← preferred, native binary
└───────────┬─────────────┘
            │ delegates to
            ▼
┌─────────────────────────┐
│  xynrin-bash  (bash)    │  ← actual implementation, fallback TUI
└─────────────────────────┘
```

The Rust binary handles the menu UI; every concrete action (install distro, update, mirror, beautify…) is dispatched as `xynrin-bash --menu-<action>`. If the Rust binary isn't available for your CPU, `xynrin` is just a symlink to the bash version, so nothing breaks.

## Distro aliases

After installing a distro through option `2`, an alias is added to `~/.bashrc`. Run `source ~/.bashrc` (or restart the terminal) and you can log in directly:

```bash
ubuntu      # = proot-distro login ubuntu
debian      # = proot-distro login debian
```

Option `3` only lists aliases for distros that are **actually installed and properly aliased** — no stale or fake entries.

## Mirror sources (option 5)

Quickly switch the Termux APT mirror. Built-in choices:

- Tsinghua University (China)
- USTC (China)
- Official `packages.termux.dev`
- Or use `termux-change-repo` interactively

## Project structure

```
termux-tools/
├── bootstrap.sh          # one-line online installer
├── install.sh            # main installer (Rust binary + bash fallback)
├── tui/
│   ├── xynrin            # bash TUI (the engine, always installed)
│   └── lang/{zh,en}.sh   # language packs
├── xynrin-tui/           # Rust + ratatui TUI source
│   ├── Cargo.toml
│   └── src/main.rs
├── install-scripts/
│   └── install-tui       # symlink refresher
├── scripts/
│   ├── version           # version file
│   └── release.sh        # tag + release helper
├── .github/workflows/
│   └── release.yml       # cross-compile Rust binaries on tag
├── LICENSE               # GPL-v3
└── README.{md,zh.md}
```

## License

[GPL-v3](LICENSE) · Author: **Xynrin**
