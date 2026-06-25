#!/usr/bin/env bash
# stow module - symlink every config package into $HOME. MUST run before the
# shell module: ~/.config/tmux and ~/.config/zsh are folded stow symlinks into
# the repo, so the shell module's writers (TPM, antidote) need those symlinks to
# already exist (see lib/orchestrate.sh's module-order comment).
mod_stow() {
  have stow || { err "stow missing (brew step failed?)"; return 1; }
  cd "$DOTFILES_DIR" || return 1

  # Directories that are NOT stow packages:
  #   grimoire - AI knowledge vault, reached via $GRIMOIRE + its own setup scripts
  #   scripts  - shell helpers sourced directly from the repo path
  #   lib      - orchestrate.sh + the mod_* modules it sources
  # (.stowrc --ignore filters package *contents*, not selection, so this skip-list
  #  is the authoritative exclusion.)
  local NON_STOW=(grimoire scripts lib)

  local package
  for package in */; do
    package="${package%/}"
    [[ "$package" == .* ]] && continue
    if [[ " ${NON_STOW[*]} " == *" $package "* ]]; then
      info "  → skipping $package (not a stow package)"
      continue
    fi
    info "  → stowing $package"
    stow "$package" || return 1
  done
}
