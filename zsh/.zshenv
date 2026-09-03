# Zsh Environment Constants
# These are loaded early, even for non-interactive shells

# Point zsh at its XDG config dir. This is the one zsh file that must live at
# $HOME (zsh reads ~/.zshenv before ZDOTDIR exists); everything else
# (.zshrc, .zsh_fzf.zsh, .zsh_plugins.txt) lives under $ZDOTDIR.
export ZDOTDIR="$HOME/.config/zsh"

# Homebrew — use shellenv so PATH, MANPATH, and crucially fpath
# (for zsh completions at /opt/homebrew/share/zsh/site-functions) are all set.
# This must run before compinit so _brew and other Homebrew completers are found.
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# User local bin (created by pipx)
if [[ -d "$HOME/.local/bin" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# Volta (Node Version Manager) — shim-based, no shell hooks needed
export VOLTA_HOME="$HOME/.volta"
if [[ -d "$VOLTA_HOME/bin" ]]; then
  export PATH="$VOLTA_HOME/bin:$PATH"
fi

# Vite+ (vp) CLI
if [[ -d "$HOME/.vite-plus/bin" ]]; then
  export PATH="$HOME/.vite-plus/bin:$PATH"
fi

# Rust toolchain (rustup, shim-based)
if [[ -d "$HOME/.cargo" ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

# Node Configuration
export NODE_OPTIONS="--max-old-space-size=8192"

# Editor Configuration
export EDITOR="nvim"

# Starship Configuration Path
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
. "$HOME/.cargo/env"

# AWS profile
export AWS_PROFILE=arif

# GRIMOIRE (AI knowledge base). Here rather than .zshrc because agent sandboxes
# run non-interactive shells, which never source .zshrc; an empty $GRIMOIRE
# sends the skills hunting for the vault with a home-wide find.
export GRIMOIRE="$HOME/.dotfiles/grimoire"
export CONTEXT_MODE_DIR="$GRIMOIRE/.context-mode"
