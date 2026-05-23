<div align="center">

# termux-tools

**A TUI helper tool for Termux beginners**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-brightgreen.svg)](scripts/version)
[![Platform](https://img.shields.io/badge/platform-Termux-black.svg)](https://termux.dev)
[![Language](https://img.shields.io/badge/lang-Bash-89e051.svg)](https://www.gnu.org/software/bash/)

[中文 README](README.zh.md) · [Report Bug](https://github.com/Xynrin/termux-tools/issues) · [Request Feature](https://github.com/Xynrin/termux-tools/issues)

</div>

---

## About

`termux-tools` is a beginner-friendly TUI helper that simplifies common Termux workflows. Install Linux distros, manage proot environments, and check for updates with a few keystrokes — no memorization required.

## Features

| | |
|---|---|
| **Auto language** | Detects locale and shows Chinese or English UI |
| **Self-update** | Compares local version with remote and pulls updates |
| **proot helper** | Install / login distros without typing the full command |
| **System info** | One-shot view of OS, kernel, arch, and Termux version |
| **CLI mode** | Full command-line interface alongside TUI |
| **Zero deps** | Pure Bash, no dialog/whiptail/python required |

## Quick Start

```bash
# Clone
git clone https://github.com/Xynrin/termux-tools.git
cd termux-tools

# Install (run inside Termux)
bash install.sh

# Launch
termux-tools
```

## Usage

### Interactive TUI

```bash
termux-tools           # opens the main menu
```

### Command-line

```bash
termux-tools help      # show help
termux-tools version   # show current version
termux-tools update    # check & pull updates
termux-tools menu      # explicitly open TUI
```

### Menu options

| Key | Action |
|:---:|---|
| `1` | Update termux-tools |
| `2` | Install a distro via proot |
| `3` | Login to an installed distro |
| `4` | Show system information |
| `5` | Switch UI language |
| `0` | Exit |

## Project Structure

```
termux-tools/
├── README.md              # English documentation
├── README.zh.md           # Chinese documentation
├── LICENSE                # GPL-v3 license
├── .gitignore             # Git ignore rules
├── install.sh             # Main installer
├── install-scripts/
│   └── install-tui        # Standalone TUI installer
├── scripts/
│   └── version            # Version file (used for update checks)
└── tui/
    ├── termux-tools       # Main program
    └── lang/
        ├── zh.sh          # Chinese language pack
        └── en.sh          # English language pack
```

## How It Works

```
                      ┌─────────────────┐
                      │  termux-tools   │
                      └────────┬────────┘
                               │
            ┌──────────────────┼──────────────────┐
            ▼                  ▼                  ▼
       ┌─────────┐        ┌─────────┐        ┌─────────┐
       │   CLI   │        │   TUI   │        │  i18n   │
       │ help/   │        │  menu   │        │ zh / en │
       │version/ │        │ loop    │        │ auto    │
       │ update  │        │         │        │ detect  │
       └─────────┘        └────┬────┘        └─────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
        ┌──────────┐     ┌──────────┐     ┌──────────┐
        │  update  │     │  proot   │     │  system  │
        │  check   │     │ install/ │     │   info   │
        │ + pull   │     │  login   │     │          │
        └──────────┘     └──────────┘     └──────────┘
```

## Adding a New Language

1. Copy `tui/lang/en.sh` to `tui/lang/<your-locale>.sh`
2. Translate every `MSG_*`, `OPT_*`, `MENU_*`, `CLI_*`, `LANG_*` value
3. Update `detect_language()` in `tui/termux-tools` if needed
4. Test with `LANG=<your-locale> termux-tools`

## Requirements

- Termux (latest stable recommended)
- Internet connection (for installation and updates)
- ~5 MB free space

## License

Released under the [GPL-v3](LICENSE) license.

## Author

**Xynrin** — [GitHub](https://github.com/Xynrin)

<div align="center">

Made for Termux beginners. PRs welcome.

</div>
