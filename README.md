# .dotfiles

Modern, cross-platform development environment configuration managed with [GNU Stow](https://www.gnu.org/software/stow/).

## 📦 What's Inside

### Shell & Prompt

- **[Zsh](https://zsh.sourceforge.io/)** — Fast, default macOS shell configured for simplicity (no oh-my-zsh) with `zsh-autosuggestions` and `zsh-syntax-highlighting`
- **[Starship](https://starship.rs/)** — Fast, minimal prompt with git status, language versions, and execution time
- **[Carapace](https://carapace-sh.github.io/)** — Multi-shell completion engine with support for 1000+ commands

### Terminal & Window Management

- **[Ghostty](https://ghostty.org/)** — GPU-accelerated terminal emulator
- **[Tmux](https://github.com/tmux/tmux)** — Terminal multiplexer for session management and split panes
- **[AeroSpace](https://github.com/nikitabobko/AeroSpace)** — Tiling window manager for macOS (i3-like)

### Development Tools

- **[Neovim](https://neovim.io/)** — Hyperextensible Vim-based text editor
- **[Volta](https://volta.sh/)** — Hassle-free Node.js version manager using shims (no shell hooks needed)
- **[fzf](https://github.com/junegunn/fzf)** — Fuzzy finder for files, commands, and history
- **[fd](https://github.com/sharkdp/fd)** — Fast, user-friendly alternative to `find`
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** — Blazing fast grep alternative

### Custom Scripts

- **Git worktree helpers** — Shortcuts for managing multiple working trees
- **Project-specific utilities** — Custom workflows and automation

## 🎯 Why These Tools?

*Because life's too short for slow shells and janky version managers.*

### Zsh over Heavy Frameworks (like oh-my-zsh)

- **Performance**: Sourcing a couple of essential plugins directly means zero plugin-manager overhead.
- **Simplicity**: No bloated configurations, just what you need.
- **Modern feel built-in**: We manually clone `zsh-autosuggestions` (ghost-text) and `zsh-syntax-highlighting` (valid/invalid command colors) to get all the benefits of modern shells instantly.
- **Built-in**: It is already the default shell on macOS.

### Volta over fnm/nvm

- **Zero configuration**: No shell hooks, no PATH manipulation on every `cd`
- **Shim-based**: Automatically resolves the correct Node version at execution time
- **Package.json aware**: Reads `engines.node` field for per-project versions
- **Shell-agnostic**: Works identically in any shell

### Starship over oh-my-zsh themes

- **Performance**: Written in Rust, renders in milliseconds (your prompt won't lag behind your typing)
- **Universal**: Same prompt in Zsh, Bash, Fish, PowerShell
- **Minimal by default**: Shows only relevant context (git status, Node version, etc.) — no ASCII art locomotives

## 🛠️ Installation

### Prerequisites

- **macOS**: Homebrew installed ([brew.sh](https://brew.sh/))
- **Linux**: Your distro's package manager (apt, dnf, pacman, etc.)

### Quick Start

```bash
# 1. Clone this repo to your home directory (works from anywhere)
git clone https://github.com/YOUR_USERNAME/.dotfiles.git ~/.dotfiles

# 2. Run the setup script (works from anywhere)
bash ~/.dotfiles/setup.sh

# 3. GUI Applications Installation (optional)
# After running `setup.sh`, you can install all GUI applications with one command:
bash ~/.dotfiles/apps/install.sh
```

This installs **19 applications** via Homebrew including:

- Development tools (Antigravity, VS Code, Zed)
- Browsers (Arc, Brave, Chrome, DuckDuckGo)
- Productivity apps (Notion, Obsidian, Slack, Discord)
- Utilities (Bitwarden, VLC, Ice, Sol, and more)

See [`apps/README.md`](apps/README.md) for the complete list and manual installation instructions for apps not available via Homebrew.

### What `setup.sh` Does

The setup script automates the entire installation process:

#### 1. **Platform Detection**

Detects macOS or Linux and adjusts behavior accordingly.

#### 2. **Tool Installation** (macOS only)

On macOS, automatically installs all required tools via Homebrew:

- CLI tools: `stow`, `starship`, `carapace`, `nvim`, `tmux`, `fzf`, `fd`, `rg`
- GUI apps: AeroSpace, Ghostty, Fira Code Nerd Font

On Linux, it checks for missing tools and prompts you to install them manually using your package manager.

#### 3. **Symlink Creation (Stow)**

Uses GNU Stow to create symlinks from `~/.dotfiles/` to your home directory:

``` bash
~/.dotfiles/zsh/.zshrc                   →  ~/.zshrc
~/.dotfiles/zsh/.zshenv                  →  ~/.zshenv
~/.dotfiles/nvim/.config/nvim/init.lua   →  ~/.config/nvim/init.lua
~/.dotfiles/tmux/.config/tmux/tmux.conf  →  ~/.config/tmux/tmux.conf
...
```

This means:

- ✅ Edit files in `~/.dotfiles/` and changes apply immediately
- ✅ Easy to version control
- ✅ Clean uninstall: `stow -D <package>` removes all symlinks

#### 4. **Zsh Plugins**

Instead of using a bulky plugin manager, the setup script clones two essential repositories directly into `~/.zsh_plugins/`:

- `zsh-autosuggestions`
- `zsh-syntax-highlighting`

These are then sourced directly in your `~/.zshrc`.

#### 5. **Volta Installation**

Installs [Volta](https://volta.sh/) using its official installer:

```bash
curl https://get.volta.sh | bash -s -- --skip-setup
```

The `--skip-setup` flag prevents it from modifying shell profiles (we handle PATH in our configs).

#### 6. **Tmux Plugin Manager (TPM)**

Clones [TPM](https://github.com/tmux-plugins/tpm) to `~/.config/tmux/plugins/tpm` for managing Tmux plugins.

### Post-Installation

1. **Restart your shell** or open a new terminal (the classic "turn it off and on again")
2. **Install Node.js** via Volta:

   ```bash
   volta install node@22
   ```

3. **Install Tmux plugins**: Press `Ctrl+Space` then `I` (capital i) inside Tmux

## 🍴 Forking & Customization

This repo is designed to be forked and personalized. Here's how:

### 1. Fork the Repository

Click "Fork" on GitHub, then clone your fork:

```bash
git clone https://github.com/YOUR_USERNAME/.dotfiles.git ~/.dotfiles
```

### 2. Customize Configs

Each directory is a "stow package" containing config files:

```bash
.dotfiles/
├── zsh/                   # Zsh configuration
│   ├── .zshrc             # Interactive shell settings
│   └── .zshenv            # Environment variables
├── nvim/
│   └── .config/nvim/      # Your Neovim config
├── starship/
│   └── .config/starship/
│       └── starship.toml  # Prompt customization
├── tmux/
│   └── .config/tmux/
│       └── tmux.conf      # Tmux keybindings & plugins
└── ...
```

**To customize**:

- Edit files directly in `~/.dotfiles/<package>/.config/...`
- Changes apply immediately (symlinks!)
- Commit and push to your fork

### 3. Add Your Own Packages

Create a new directory for any tool:

```bash
mkdir -p ~/.dotfiles/myapp/.config/myapp
echo "my_setting = true" > ~/.dotfiles/myapp/.config/myapp/config.toml
cd ~/.dotfiles && stow myapp
```

Now `~/.config/myapp/config.toml` is symlinked and version-controlled.

### 4. Remove Unwanted Tools

Don't use Tmux? No judgment. Just delete the directory:

```bash
cd ~/.dotfiles
stow -D tmux          # Remove symlinks
rm -rf tmux/          # Delete the package
```

Update `setup.sh` to remove it from `REQUIRED_CMDS` array.

### 5. Platform-Specific Configs

Use conditional logic in configs:

Use conditional logic in configs:

**Zsh** (`.zshrc`):

```bash
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS-specific PATH additions
fi
```

**Tmux** (`tmux.conf`):

```bash
if-shell "uname | grep -q Darwin" \
    "set -g status-position top" \
    "set -g status-position bottom"
```

## 📁 Repository Structure

```bash
.dotfiles/
├── .gitignore           # Ignore history files, plugins, .DS_Store
├── .stowrc              # Stow config (sets target to ~/)
├── README.md            # This file
├── setup.sh             # Automated installation script
│
├── apps/                # GUI application installation (not stowed)
│   ├── install-apps.sh  # Install all apps via Homebrew
│   └── README.md        # App list and installation guide
│
├── aerospace/           # AeroSpace window manager (macOS)
├── ghostty/             # Ghostty terminal config
├── zsh/                 # Zsh shell config
├── nvim/                # Neovim editor config
├── scripts/             # Custom shell scripts
├── starship/            # Starship prompt config
└── tmux/                # Tmux terminal multiplexer config
```

## 🐧 Linux Compatibility

The setup script detects Linux and:

- ✅ Checks for required tools
- ✅ Stows all packages correctly
- ✅ Installs Volta and TPM
- ⚠️ **Does NOT auto-install tools** (lists what's missing)

**Manual installation example (Ubuntu/Debian)**:

```bash
sudo apt update
sudo apt install stow zsh neovim tmux fzf fd-find ripgrep
```

**Note**: Some package names differ by distro:

- `fd` → `fd-find` on Debian/Ubuntu
- Fonts install to `~/.local/share/fonts/` manually

## 🔧 Maintenance

### Update All Tools (macOS)

```bash
brew update && brew upgrade
```

### Update Tmux Plugins

Press `Ctrl+Space` then `U` inside Tmux.

### Sync Dotfiles Across Machines

```bash
cd ~/.dotfiles
git pull                 # Pull latest changes
bash setup.sh               # Re-run setup (idempotent)
```

### Backup Before Major Changes

```bash
cd ~/.dotfiles
git checkout -b backup-$(date +%Y%m%d)
# Make changes...
git add . && git commit -m "Experimental changes"
# (Future you will thank present you)
```

## 🤝 Contributing

Found a bug or have a suggestion? Open an issue or PR! This repo is meant to be a starting point — fork it, break it, make it yours. That's the whole point.

## 📝 License

MIT — do whatever you want with it.

---

**Happy hacking!** 🎉
