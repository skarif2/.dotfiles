# Nushell Config File
source ~/.config/nushell/env.nu

# ============================================================================
# Aliases - Neovim
# ============================================================================

alias v = nvim
alias vi = nvim
alias vim = nvim

# ============================================================================
# Aliases - Git
# ============================================================================

alias gi = git init
alias ga = git add
alias gs = git status
alias gc = git commit
alias gp = git pull
alias gP = git push

# ============================================================================
# Aliases - LazyGit
# ============================================================================

alias gg = lazygit

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

# Git worktree wrapper function
# Usage: gw clone <repo> | gw df <branch> | gw <any-git-worktree-command>
def gw [command?: string, ...args] {
    match $command {
        "clone" => { 
            bash ~/.scripts/clone-for-worktree.sh ...$args 
        }
        "df" => { 
            bash ~/.scripts/dina/frontend-worktree-add.sh ...$args 
        }
        null => {
            git worktree
        }
        _ => { 
            git worktree $command ...$args 
        }
    }
}

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

$env.PROMPT_INDICATOR = $"((ansi green_bold)❯(ansi reset)) "
$env.PROMPT_INDICATOR_VI_INSERT = $"((ansi green_bold)❯(ansi reset)) "
$env.PROMPT_INDICATOR_VI_NORMAL = $"((ansi purple_bold)❮(ansi reset)) "

use ~/.cache/starship/init.nu
source ~/.cache/carapace/init.nu
