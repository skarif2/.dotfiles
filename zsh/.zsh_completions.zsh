# ============================================================================
# Custom Completion Registrations
# Sourced by .zshrc after compinit and late plugins.
# ============================================================================

# Register custom completions for worktree tools
# Functions are defined in scripts/.scripts/dina-frontend.sh and clone-worktree.sh

# dina_worktree_add (gwf)
compdef _dina_worktree_add dina_worktree_add
compdef _dina_worktree_add gwf

# clone_worktree (gwc)
compdef _clone_worktree clone_worktree
compdef _clone_worktree gwc
