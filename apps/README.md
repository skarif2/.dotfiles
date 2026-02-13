# Application Installation

This directory contains scripts and documentation for installing GUI applications.

## Quick Install

Install all applications with one command:

```bash
cd ~/.dotfiles/apps
bash install.sh
```

## What Gets Installed

The script installs **19 applications** via Homebrew:

### Development Tools (3)
- **Antigravity** - AI-powered code editor
- **Visual Studio Code** - Code editor
- **Zed** - Modern code editor

### Browsers (4)
- **Arc** - Modern web browser
- **Brave Browser** - Privacy-focused browser
- **Google Chrome** - Web browser
- **DuckDuckGo** - Privacy-focused browser

### Productivity & Notes (2)
- **Notion** - Workspace and notes
- **Obsidian** - Knowledge management

### Communication (2)
- **Slack** - Team communication
- **Discord** - Community chat

### Security & Privacy (2)
- **Bitwarden** - Password manager
- **Cloudflare WARP** - VPN/network security

### Media (1)
- **VLC** - Media player

### Utilities & System Tools (4)
- **Alcove** - Window management/productivity
- **Ice** - Menu bar management
- **Onyx** - System maintenance
- **Sol** - macOS launcher

## Manual Installation Required

**Second Clock** - Time zone clock  
📥 Download from: [Mac App Store](https://apps.apple.com/app/second-clock/id6450279539)

## Keeping Apps Updated

Update all Homebrew-installed apps:

```bash
brew upgrade --cask
```

## Notes

- The script is idempotent (safe to run multiple times)
- Already installed apps will be skipped
- Installation continues even if individual apps fail
- This folder is excluded from stow (see `.stowrc`)
