# ============================================================================
# FZF Configuration
# Sourced by .zshrc after plugins and compinit are loaded.
# ============================================================================

# ----------------------------------------------------------------------------
# Core FZF Options (Tokyo Night theme)
# ----------------------------------------------------------------------------
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#283457,bg:#16161e,spinner:#27a1b9,hl:#ff9e64 \
  --color=fg:#c0caf5,header:#ff9e64,info:#545c7e,pointer:#27a1b9 \
  --color=marker:#27a1b9,fg+:#c0caf5,prompt:#27a1b9,hl+:#ff9e64 \
  --bind=ctrl-d:half-page-down,ctrl-u:half-page-up"

# ----------------------------------------------------------------------------
# FZF Helper Functions
# ----------------------------------------------------------------------------

# Fuzzy find and open a file
function fzf-file() {
    fd --type f | fzf
}

# Fuzzy find a directory
function fzf-dir() {
    fd --type d | fzf
}

# Fuzzy cd into a directory
function cdf() {
    local dir
    dir=$(fd --type d | fzf)
    if [[ -n "$dir" ]]; then
        cd "$dir"
    fi
}

# ----------------------------------------------------------------------------
# Completion Zstyles (zstyle ':completion:*' must be set before compinit,
# but since we source this after compinit, these are evaluated lazily at
# completion time — so ordering here is fine.)
# ----------------------------------------------------------------------------

# Case-insensitive fuzzy matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
# Coloured completion entries matching LS_COLORS
zstyle ':completion:*' list-colors '${(s.:.)LS_COLORS}'
# Disable the default zsh menu — fzf-tab takes over
zstyle ':completion:*' menu no

# ----------------------------------------------------------------------------
# fzf-tab: Group Headers & Colours
# (fzf-tab must be loaded before these take effect — ensured by .zshrc order)
# ----------------------------------------------------------------------------

# Show group headers like [main porcelain command] / [installed casks]
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' group-colors \
    $'\033[15m' $'\033[14m' $'\033[33m' $'\033[35m' \
    $'\033[15m' $'\033[14m' $'\033[33m' $'\033[35m'

# ----------------------------------------------------------------------------
# fzf-tab: Context-Aware Previews
# Only shown where they add real value — not as a catch-all.
# ----------------------------------------------------------------------------

# cd / zoxide: show directory contents before navigating
zstyle ':fzf-tab:complete:cd:*'         fzf-preview 'ls -lah --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls -lah --color=always $realpath'

# Any command completing a file/dir argument: bat for files, ls for dirs
# argument-rest matches positional arguments — covers any newly installed tool automatically
zstyle ':fzf-tab:complete:*:argument-rest:*' fzf-preview \
    '[[ -f $realpath ]] && bat --color=always --style=numbers $realpath 2>/dev/null \
  || [[ -d $realpath ]] && ls -lah --color=always $realpath'

# git: diff preview when staging / diffing files
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
    'git diff --color=always $word 2>/dev/null | delta'
# git log: show recent commits for a branch/ref
zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
    'git log --color=always --oneline --decorate $word 2>/dev/null'
# git show: show commit contents
zstyle ':fzf-tab:complete:git-show:*' fzf-preview \
    'git show --color=always $word 2>/dev/null | delta'
# git help: render man page
zstyle ':fzf-tab:complete:git-help:*' fzf-preview \
    'git help $word | bat -plman --color=always 2>/dev/null'
