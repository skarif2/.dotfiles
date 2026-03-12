#!/usr/bin/env bash
# Git Bare Clone for Worktrees Module (Bash/Zsh Port)

function clone_worktree() {
    local url=""
    local name_arg=""
    local custom_name=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--name)
                custom_name="$2"
                shift 2
                ;;
            *)
                if [[ -z "$url" ]]; then
                    url="$1"
                elif [[ -z "$name_arg" ]]; then
                    name_arg="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$url" ]]; then
        echo "Usage: gwc [-n name] <url> [<name>]"
        return 1
    fi

    # Determine repo name
    local basename
    basename=$(basename "$url")
    local repo_name=""
    
    if [[ -n "$custom_name" ]]; then
        repo_name="$custom_name"
    elif [[ -n "$name_arg" ]]; then
        repo_name="$name_arg"
    else
        repo_name="${basename%.git}"
    fi

    mkdir -p "$repo_name"
    cd "$repo_name" || return 1

    # 1. Clone bare repository
    git clone --bare "$url" .bare

    # 2. Set up .git pointer
    echo "gitdir: ./.bare" > .git

    # 3. Configure remote fetch
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

    # 4. Fetch all
    git fetch origin

    # 5. Add main/master worktree
    # Check if master or main exists
    local default_branch="main"
    if git rev-parse --verify master >/dev/null 2>&1; then
        default_branch="master"
    fi

    git worktree add main "$default_branch"
}

# ============================================================================
# Zsh Tab Completion for clone_worktree / gwc
# ============================================================================
# Supports:
#   gwc <url>                 → Clone a bare repo
#   gwc -n my-name <url>      → Clone with custom folder name
#   gwc <url> <name>          → Clone with positional name

function _clone_worktree() {
    local current_word="${words[$CURRENT]}"
    local prev_word="${words[$((CURRENT - 1))]}"

    # Right after -n / --name → user types the folder name, offer directory completion
    if [[ "$prev_word" == "-n" || "$prev_word" == "--name" ]]; then
        _message "Custom folder name for the cloned repo"
        _files -/
        return 0
    fi

    # Count positional args already typed (excluding flags and their values)
    local positional_count=0
    local skip_next=0
    local word
    for word in "${words[@]:1:$((CURRENT - 2))}"; do
        if [[ $skip_next -eq 1 ]]; then
            skip_next=0
            continue
        fi
        if [[ "$word" == "-n" || "$word" == "--name" ]]; then
            skip_next=1
            continue
        fi
        (( positional_count++ ))
    done

    case $positional_count in
        0)
            # First positional = the git URL
            if [[ "$current_word" == -* ]]; then
                # Offer flags if user typed a dash
                _arguments \
                    '(-n --name)'{-n,--name}'[Custom folder name for the cloned repo]'
            else
                _message "Git clone URL (e.g. git@github.com:org/repo.git)"
            fi
            ;;
        1)
            # Second positional = optional folder name
            _message "Optional folder name (defaults to repo name)"
            _files -/
            ;;
    esac
}

