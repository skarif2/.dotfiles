#!/usr/bin/env bash
# brew module - install the entire Brewfile (CLI formulae, GUI casks, the nerd
# font, and taps) in one idempotent pass. The Brewfile is the Phase-1 source of
# truth, so GUI casks are installed HERE; the apps module covers only the App
# Store layer that Homebrew cannot reach.
#
# Not wrapped in `gum spin`: cask installs can surface a sudo prompt, and gum
# spin would hide it and look like a hang. Heavy/privileged steps stay on plain
# stdout for exactly this reason.
mod_brew() {
  have brew || { err "brew missing after preflight"; return 1; }
  brew bundle --file="$DOTFILES_DIR/Brewfile"
}
