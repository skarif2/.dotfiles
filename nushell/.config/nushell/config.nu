# Nushell Config File
source ~/.config/nushell/env.nu

# ============================================================================
# Aliases
# ============================================================================

# Neovim
alias v = nvim
alias vi = nvim
alias vim = nvim

# Git
alias gi = git init
alias ga = git add
alias gs = git status
alias gc = git commit
alias gp = git pull
alias gP = git push

# LazyGit
alias gg = lazygit

# Dotfiles
def dotfiles [] {
    ^agy ~/.dotfiles
}

# ============================================================================
# Nushell Configuration
# ============================================================================

$env.config = {
    show_banner: false  # Disable welcome banner
    
    edit_mode: vi
    
    # Completions configuration
    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "fuzzy"
    }
    
    # History configuration
    history: {
        max_size: 100_000
        sync_on_enter: true
        file_format: "sqlite"
    }
    
    # Table configuration
    table: {
        mode: rounded
        index_mode: always
        show_empty: true
    }
    
    # Enable syntax highlighting (built-in)
    highlight_resolved_externals: true
}

# ============================================================================
# Custom Functions
# ============================================================================

use ~/.dotfiles/scripts/.scripts/dina-frontend.nu
use ~/.dotfiles/scripts/.scripts/clone-worktree.nu

# Standard git worktree (passes all flags correctly)
alias gw = git worktree

# Custom worktree tools
alias gwf = dina-frontend worktree-add
alias gwc = clone-worktree clone

# ============================================================================
# FZF Integration (Optional)
# ============================================================================

# Fuzzy find files
def fzf-file [] {
    fd --type f | fzf | str trim
}

# Fuzzy find directories
def fzf-dir [] {
    fd --type d | fzf | str trim
}

# Change directory with fuzzy finding
def --env cdf [] {
    let dir = (fd --type d | fzf | str trim)
    if ($dir != "") {
        cd $dir
    }
}

# ============================================================================
# Useful Custom Commands
# ============================================================================

# Quick directory listing with details
def ll [] {
    ls -l
}

# List all files including hidden
def la [] {
    ls -a
}

# List all with details
def lla [] {
    ls -la
}

# $env.PROMPT_INDICATOR = $"((ansi green_bold)❯(ansi reset)) "
# $env.PROMPT_INDICATOR_VI_INSERT = $"((ansi green_bold)❯(ansi reset)) "
# $env.PROMPT_INDICATOR_VI_NORMAL = $"((ansi purple_bold)❮(ansi reset)) "

$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = ""
$env.PROMPT_INDICATOR_VI_NORMAL = ""

use ~/.cache/starship/init.nu
source ~/.cache/carapace/init.nu
