# Zsh Environment Constants
# These are loaded early, even for non-interactive shells

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

# Antigravity bin
if [[ -d "$HOME/.antigravity/antigravity/bin" ]]; then
  export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
fi

# Volta (Node Version Manager) — shim-based, no shell hooks needed
export VOLTA_HOME="$HOME/.volta"
if [[ -d "$VOLTA_HOME/bin" ]]; then
  export PATH="$VOLTA_HOME/bin:$PATH"
fi

# Node Configuration
export NODE_OPTIONS="--max-old-space-size=8192"

# Editor Configuration
export EDITOR="nvim"

# Starship Configuration Path
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
