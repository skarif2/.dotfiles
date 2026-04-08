#!/usr/bin/env bash
# Saga Git Worktree Management Module (Bash/Zsh Port)

function __saga_worktree_add_core() {
    local link_patterns=()
    local git_args=()
    local branch=""
    local force=0
    local worktree_path=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --link)
                link_patterns+=("$2")
                shift 2
                ;;
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
        echo "Usage: gwf|gwb|gwd [-b branch] <path> [<commit>]"
        return 1
    fi

    # Pre-flight: verify all link targets exist in the project root BEFORE touching git state
    if [[ ${#link_patterns[@]} -gt 0 ]]; then
        local project_root
        project_root=$(pwd)
        local missing=0
        for pattern in "${link_patterns[@]}"; do
            if ! ls ./$~pattern > /dev/null 2>&1; then
                echo "Error: Required file/folder matching '$pattern' not found." >&2
                missing=1
            fi
        done
        if [[ $missing -eq 1 ]]; then
            echo "  → Place missing items in: $project_root" >&2
            echo "  → Then re-run this command." >&2
            return 1
        fi
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

    # 6. Link files/folders from the project root (bare repo root)
    if [[ ${#link_patterns[@]} -gt 0 ]]; then
        for pattern in "${link_patterns[@]}"; do
            for f in ../$~pattern; do
                [[ -e "$f" ]] || continue

                local name
                name=$(basename "$f")

                if [[ ! -e "$name" ]]; then
                    ln -s "$f" "$name"
                    echo "  ✓ Linked: $name"
                fi
            done
        done
    fi

    # 7. Open
    if command -v agy >/dev/null 2>&1; then
        agy .
    fi
}

# ============================================================================
# User-Facing Commands
# ============================================================================
function gwf() { __saga_worktree_add_core --link ".env*" "$@" }
function gwb() { __saga_worktree_add_core "$@" }
function gwd() { __saga_worktree_add_core "$@" }

# ============================================================================
# Zsh Tab Completion for Worktree Tools
# ============================================================================
function _saga_worktree_add_core() {
    local -a branches filtered
    local has_b=0 word prefix

    for word in "${words[@]}"; do
        if [[ "$word" == "-b" || "$word" == "--branch" ]]; then
            has_b=1
            break
        fi
    done

    local current_word="${words[$CURRENT]}"
    local prev_word="${words[$((CURRENT - 1))]}"

    if [[ "$prev_word" == "-b" || "$prev_word" == "--branch" ]]; then
        _message "New branch name (e.g. imp/my-feature)"
        return 0
    fi

    if [[ "$prev_word" == "-f" || "$prev_word" == "--force" ]]; then
        return 0
    fi

    local positional_count=0
    local skip_next=0
    for word in "${words[@]:1:$((CURRENT - 2))}"; do
        if [[ $skip_next -eq 1 ]]; then
            skip_next=0
            continue
        fi
        if [[ "$word" == "-b" || "$word" == "--branch" ]]; then
            skip_next=1  
            continue
        fi
        if [[ "$word" == "-f" || "$word" == "--force" ]]; then
            continue
        fi
        (( positional_count++ ))
    done

    if [[ $positional_count -eq 0 ]]; then
        _message "Worktree folder name"
        return 0
    fi

    branches=($(git branch --all --format='%(refname:short)' 2>/dev/null \
        | sed 's|^origin/||' \
        | sort -u))

    if [[ ${#branches[@]} -eq 0 ]]; then
        _message "No git branches found (not in a git repo?)"
        return 1
    fi

    prefix="$current_word"

    if [[ -n "$prefix" ]]; then
        filtered=()
        for b in $branches; do
            [[ "$b" == ${prefix}* ]] && filtered+=("$b")
        done

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

# Emitting completions only if compdef exists in current shell scope
if type compdef >/dev/null 2>&1; then
    compdef _saga_worktree_add_core gwf
    compdef _saga_worktree_add_core gwb
    compdef _saga_worktree_add_core gwd
fi
