#!/bin/bash
# Dotfiles setup script
# Run this once on a new machine after cloning the repo

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "📦 Setting up dotfiles from $DOTFILES_DIR"

# List of required commands
REQUIRED_CMDS=(
    "stow"     # gnu stow
    "starship" # prompt style
    "carapace" # autocomplete
    "nvim"     # neovim
    "tmux"     # terminal multiplexer
    "fzf"      # fuzzy finder
    "zoxide"   # smarter cd
    "fd"       # find
    "rg"       # ripgrep
)

# List of required GUI apps (macOS Casks)
REQUIRED_CASKS=(
    "nikitabobko/tap/aerospace"
    "ghostty"
    "font-fira-code-nerd-font"
)

# ============================================================================
# Helper Functions
# ============================================================================

check_cmd() {
    command -v "$1" >/dev/null 2>&1
}

ensure_macos_tools() {
    if ! check_cmd "brew"; then
        echo "❌ Homebrew is not installed. Please install it first from https://brew.sh/"
        echo "   Skipping automatic tool installation..."
        return
    fi

    echo "🍺 Checking required tools (Homebrew)..."
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if check_cmd "$cmd" || brew list --formula "$cmd" &>/dev/null; then
            echo "✅ $cmd is installed"
        else
            echo "⬇️ Installing $cmd..."
            brew install "$cmd"
        fi
    done

    echo "🖥️ Checking required GUI apps & Fonts (Casks)..."
    for cask in "${REQUIRED_CASKS[@]}"; do
        if brew list --cask "$cask" &>/dev/null; then
             echo "✅ $cask is installed"
        else
             echo "⬇️ Installing $cask..."
             if brew install --cask "$cask"; then
                 echo "✅ Installed $cask"
             else
                 echo "⚠️  Failed to install $cask (App might already exist in /Applications). Skipping."
             fi
        fi
    done
}

ensure_linux_tools() {
    echo "🐧 Linux detected. Checking for required tools..."
    missing_tools=()
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if check_cmd "$cmd"; then
            echo "✅ $cmd is present"
        else
            echo "❌ Missing: $cmd"
            missing_tools+=("$cmd")
        fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo "⚠️ Please install the following packages manually using your distribution's package manager:"
        echo "   ${missing_tools[*]}"
        echo "   (Example: sudo apt install stow fzf fd-find ripgrep ...)"
    fi
}

# ============================================================================
# Platform Check & Tool Installation
# ============================================================================

if [[ "$(uname)" == "Darwin" ]]; then
    ensure_macos_tools
else
    ensure_linux_tools
fi

# ============================================================================
# Stow all packages
# ============================================================================

echo "🔗 Stowing dotfiles..."
if ! check_cmd "stow"; then
    echo "❌ Error: 'stow' command not found. Cannot proceed with linking configs."
    exit 1
fi

cd "$DOTFILES_DIR"
# Auto-stow all directories (each directory is a stow package)
for package in */; do
    package="${package%/}"  # Remove trailing slash
    
    # Skip hidden dirs (e.g. .git) and setup script itself
    if [[ "$package" == .* ]]; then continue; fi
    
    echo "  → Stowing $package"
    stow "$package"
done

# ============================================================================
# Antidote (Zsh Plugin Manager) Installation
# ============================================================================
ANTIDOTE_DIR="$HOME/.antidote"

if [ ! -d "$ANTIDOTE_DIR" ]; then
    echo "🔌 Installing Antidote plugin manager..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
else
    echo "✅ Antidote is already installed"
fi


# ============================================================================
# Volta (Node Version Manager) Setup
# ============================================================================

if ! check_cmd "volta"; then
    echo "⬇️ Installing Volta (Node version manager)..."
    curl https://get.volta.sh | bash -s -- --skip-setup
    echo "✅ Installed Volta"
else
    echo "✅ Volta is already installed"
fi

# ============================================================================
# Tmux Plugin Manager (TPM) Setup
# ============================================================================

TPM_DIR="$HOME/.config/tmux/plugins/tpm"

if [ ! -d "$TPM_DIR" ]; then
    echo "⬇️ Installing Tmux Plugin Manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    echo "✅ Installed TPM to $TPM_DIR"
else
    echo "✅ TPM is already installed at $TPM_DIR"
fi

echo "🎉 Setup complete! Please restart your shell."