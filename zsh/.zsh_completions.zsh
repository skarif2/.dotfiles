# ============================================================================
# Custom Completion Registrations
# Sourced by .zshrc after compinit and late plugins.
# ============================================================================

# Register custom completions for worktree tools
# Functions are defined in scripts/.scripts/saga_frontend.sh and clone_worktree.sh

# saga_worktree_add (gwf)
compdef _saga_worktree_add saga_worktree_add
compdef _saga_worktree_add gwf

# clone_worktree (gwc)
compdef _clone_worktree clone_worktree
compdef _clone_worktree gwc
