# Brewfile: the brew-only subset of the dotfiles bootstrap.
#
# This declares everything Homebrew can install: CLI formulae, GUI casks, the
# nerd font, and required taps. It is intentionally NOT the whole story:
# Volta, Antidote, TPM, claude, and pi stay as script installers in lib/orchestrate.sh
# because they are not Homebrew packages. App Store apps (mas "...", id:) are
# also kept out; they live in a separate failure-tolerant `mas install` step.
#
# Apply with:  brew bundle --file=Brewfile

# ── Taps ────────────────────────────────────────────────────────────────────
tap "nikitabobko/tap"                                                   # aerospace
tap "jlcodes99/cockpit-tools", "https://github.com/jlcodes99/cockpit-tools"

# ── Formulae (CLI tools) ─────────────────────────────────────────────────────
brew "stow"      # GNU stow, symlink farm manager
brew "starship"  # prompt
brew "carapace"  # shell completion
brew "neovim"    # editor (nvim)
brew "tmux"      # terminal multiplexer
brew "fzf"       # fuzzy finder
brew "zoxide"    # smarter cd
brew "fd"        # find alternative
brew "ripgrep"   # ripgrep (rg)
brew "gum"       # TUI primitives for the installer
brew "gh"        # GitHub CLI
brew "mas"       # Mac App Store CLI (App Store apps installed separately)

# ── Casks (GUI apps & fonts) ─────────────────────────────────────────────────
# Terminal, WM, font
cask "ghostty"
cask "aerospace"
cask "font-jetbrains-mono-nerd-font"

# Development Tools
cask "antigravity"
cask "visual-studio-code"
cask "zed"
cask "cockpit-tools"          # antigravity quota monitor

# Browsers
cask "arc"
cask "brave-browser"
cask "google-chrome"
cask "duckduckgo"

# Productivity & Notes
cask "notion"
cask "obsidian"

# Communication
cask "slack"
cask "discord"

# Security & Privacy
cask "bitwarden"
cask "cloudflare-warp"

# Media
cask "vlc"

# Utilities & System Tools
cask "alcove"
cask "ice"
cask "onyx"
cask "sol"
