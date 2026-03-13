# ============================================================================
# Tmux Auto-Start
# ============================================================================
# Automatically attach to or create a Tmux session when opening a terminal
if command -v tmux &>/dev/null && [[ -z "$TMUX" ]]; then
    tmux attach-session -t main 2>/dev/null || tmux new-session -s main
fi

# ============================================================================
# Basic Zsh Settings
# ============================================================================

# History configuration
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups


# Zsh vi-mode is handled by the `zsh-vi-mode` plugin below.
# ZVM forcefully overwrites keymaps on load, so custom bindings must go here:

# Custom widget: don't enter normal mode if the prompt is empty
function custom_vi_escape() {
    if [[ -z $BUFFER ]]; then
        return
    else
        zle vi-cmd-mode
    fi
}
zle -N custom_vi_escape

function zvm_after_init() {
    bindkey -M vicmd 'k' history-substring-search-up
    bindkey -M vicmd 'j' history-substring-search-down
    bindkey -M viins '^[' custom_vi_escape
}

# ============================================================================
# Aliases
# ============================================================================

# Neovim
alias v="nvim"
alias vi="nvim"
alias vim="nvim"


# Dotfiles
function dotfiles() {
    cd ~/.dotfiles && agy .
}

# Standard git worktree
alias gw="git worktree"

# Custom worktree tools (functions sourced below)
alias gwf="dina_worktree_add"
alias gwc="clone_worktree"

# Directory listing
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias ls='ls -G'
else
    alias ls='ls --color=auto'
fi
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'


# ============================================================================
# Custom Functions/Scripts
# ============================================================================

# Source custom scripts (converted from Nushell)
if [[ -f "$HOME/.dotfiles/scripts/.scripts/dina-frontend.sh" ]]; then
    source "$HOME/.dotfiles/scripts/.scripts/dina-frontend.sh"
fi

if [[ -f "$HOME/.dotfiles/scripts/.scripts/clone-worktree.sh" ]]; then
    source "$HOME/.dotfiles/scripts/.scripts/clone-worktree.sh"
fi

# Async Antidote Updater
function async_antidote_update() {
    (
        source ~/.antidote/antidote.zsh
        antidote update > ~/.antidote_update.log 2>&1
    ) &!
}

# Run the async update once a day (if the log file is older than 24h)
if [[ ! -f ~/.antidote_update.log || $(find ~/.antidote_update.log -mtime +1 2>/dev/null) ]]; then
    async_antidote_update
fi

# ============================================================================
# Antidote Plugin Manager Initialization
# ============================================================================

# Source the antidote utility
source ~/.antidote/antidote.zsh

# Setup plugin paths
zsh_plugins=${ZDOTDIR:-~}/.zsh_plugins
zsh_manifest=${ZDOTDIR:-~}/.zsh_plugins.txt

# Generate static plugin files if manifest was updated
if [[ ! -f ${zsh_plugins}.zsh || ${zsh_manifest} -nt ${zsh_plugins}.zsh ]]; then
    echo "📦 Compiling Zsh plugins..."
    # 1. Early plugins (completions, autosuggestions, vi-mode)
    egrep -v 'fzf-tab|syntax-highlighting|ohmyzsh|substring-search' ${zsh_manifest} | antidote bundle > ${zsh_plugins}.zsh
    # 2. Late plugins (fzf-tab, syntax-highlighting, ohmyzsh plugins relying on compinit)
    egrep 'fzf-tab|syntax-highlighting|ohmyzsh|substring-search' ${zsh_manifest} | antidote bundle > ${zsh_plugins}_late.zsh
fi

# ============================================================================
# Completions & Prompts
# ============================================================================

# Source the early plugins (modifies fpath, adds aliases/widgets)
source ${zsh_plugins}.zsh

# Initialize native Zsh completions (Must run AFTER early plugins alter fpath)
# Only rebuild completion dump if it's older than 24 hours (speeds up startup)
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-~}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Source late plugins (fzf-tab MUST be loaded after compinit)
source ${zsh_plugins}_late.zsh

# FZF config — sourced after fzf-tab is loaded so zstyles apply correctly
source "$HOME/.dotfiles/zsh/.zsh_fzf.zsh"

# Register custom completions (must be after compinit)
source "$HOME/.dotfiles/zsh/.zsh_completions.zsh"

# Override OMZ git plugin aliases that conflict with our own
alias gg="lazygit"

# Completions are provided by:
#   - zsh native completers (compinit)
#   - zsh-users/zsh-completions plugin (~1000 additional completers)
#   - ohmyzsh plugins: git, aws, sudo, command-not-found
#   - Homebrew (auto-injects into fpath)
# No carapace needed — native completers are faster and conflict-free.

# Zoxide Implementation
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Starship Prompt (Must be loaded at the very end)
if command -v starship >/dev/null 2>&1; then
    mkdir -p ~/.cache
    if [[ ! -f ~/.cache/starship.zsh ]]; then
        starship init zsh > ~/.cache/starship.zsh
    fi
    source ~/.cache/starship.zsh
fi

# Added by Antigravity
export PATH="/Users/skarif/.antigravity/antigravity/bin:$PATH"
