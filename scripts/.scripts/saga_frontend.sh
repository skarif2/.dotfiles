#!/usr/bin/env bash
# Saga Frontend Git Worktree Management Module (Bash/Zsh Port)

function saga_worktree_add() {
    local branch=""
    local force=0
    local worktree_path=""
    local git_args=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -b|--branch)
                branch="$2"
                git_args+=("-b" "$branch")
                shift 2
                ;;
            -f|--force)
                force=1
                git_args+=("-f")
                shift
                ;;
            *)
                if [[ -z "$worktree_path" ]]; then
                    worktree_path="$1"
                else
                    git_args+=("$1")
                fi
                shift
                ;;
        esac
    done

    # 1. Find the bare repo root (parent of .bare)
    local common_dir
    common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    
    if [[ -z "$common_dir" ]]; then
        echo "Error: Not in a git repository or couldn't find common dir" >&2
        return 1
    fi
    
    local root_dir
    root_dir=$(dirname "$common_dir")
    cd "$root_dir" || return 1

    # 2. Identify the worktree path
    if [[ -z "$worktree_path" ]]; then
        echo "Usage: gwf [-b branch] <path> [<commit>]"
        return 1
    fi

    # Fetch latest from remote quietly
    git fetch -q 2>/dev/null

    # 3 & 4. Run git worktree add
    git worktree add "$worktree_path" "${git_args[@]}"
    
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create worktree." >&2
        return 1
    fi

    # 5. CD into the folder
    if [[ -d "$worktree_path" ]]; then
        cd "$worktree_path" || return 1
    else
        echo "Error: Worktree path ($worktree_path) does not exist." >&2
        return 1
    fi

    # 6. Link .env files (The "Efficient way")
    local env_source=""
    
    if [[ -f "../.env" ]]; then
        env_source=".."
    elif [[ -f "../main/.env" ]]; then
        env_source="../main"
    fi

    if [[ -n "$env_source" ]]; then
        for f in "$env_source"/.env*; do
            # Check if matching files exist to avoid literal wildcard pass
            [[ -e "$f" ]] || continue
            
            local name
            name=$(basename "$f")
            
            if [[ ! -e "$name" ]]; then
                ln -s "$f" "$name"
            fi
        done
        echo "Linked .env files from $env_source"
    fi

    # 7. Open
    if command -v agy >/dev/null 2>&1; then
        agy .
    fi
}

# ============================================================================
# Zsh Tab Completion for saga_worktree_add / gwf
# ============================================================================
# Supports two usage patterns:
#   gwf -b imp/new-branch folder-name imp/base-branch
#   gwf folder-name imp/base-branch
#
# TAB completion behaviour:
#   - After `-b`            → free text (new branch name), no completion
#   - After `-f`            → nothing
#   - First positional      → free text (folder name), no completion
#   - Last positional (base branch) → existing branch completion with filtering

function _saga_worktree_add() {
    local -a branches filtered
    local has_b=0 word prefix

    # Count arguments and check if -b flag is present
    for word in "${words[@]}"; do
        if [[ "$word" == "-b" || "$word" == "--branch" ]]; then
            has_b=1
            break
        fi
    done

    # Determine what the CURRENT position is completing:
    #
    # With -b:    gwf -b <new-branch> <folder> <base-branch>
    #             pos:     2             3         4
    # Without -b: gwf <folder> <base-branch>
    #             pos:   1         2

    local current_word="${words[$CURRENT]}"
    local prev_word="${words[$((CURRENT - 1))]}"

    # Right after -b or --branch → user is typing the NEW branch name, skip
    if [[ "$prev_word" == "-b" || "$prev_word" == "--branch" ]]; then
        _message "New branch name (e.g. imp/my-feature)"
        return 0
    fi

    # Right after -f or --force → nothing to complete
    if [[ "$prev_word" == "-f" || "$prev_word" == "--force" ]]; then
        return 0
    fi

    # Count positional args already typed (excluding flags and their values)
    local positional_count=0
    local skip_next=0
    for word in "${words[@]:1:$((CURRENT - 2))}"; do
        if [[ $skip_next -eq 1 ]]; then
            skip_next=0
            continue
        fi
        if [[ "$word" == "-b" || "$word" == "--branch" ]]; then
            skip_next=1  # skip the next word (new branch name)
            continue
        fi
        if [[ "$word" == "-f" || "$word" == "--force" ]]; then
            continue
        fi
        (( positional_count++ ))
    done

    # First positional = folder name → no completion
    if [[ $positional_count -eq 0 ]]; then
        _message "Worktree folder name"
        return 0
    fi

    # Second positional onward = base branch → complete from existing branches
    branches=($(git branch --all --format='%(refname:short)' 2>/dev/null \
        | sed 's|^origin/||' \
        | sort -u))

    if [[ ${#branches[@]} -eq 0 ]]; then
        _message "No git branches found (not in a git repo?)"
        return 1
    fi

    prefix="$current_word"

    if [[ -n "$prefix" ]]; then
        # Priority 1: branches that START with the typed prefix
        filtered=()
        for b in $branches; do
            [[ "$b" == ${prefix}* ]] && filtered+=("$b")
        done

        # Priority 2: fallback to branches that CONTAIN the typed prefix
        if [[ ${#filtered[@]} -eq 0 ]]; then
            for b in $branches; do
                [[ "$b" == *${prefix}* ]] && filtered+=("$b")
            done
        fi

        if [[ ${#filtered[@]} -gt 0 ]]; then
            compadd -a filtered
        else
            _message "No branches matching '$prefix'"
        fi
    else
        compadd -a branches
    fi
}

