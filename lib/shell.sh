#!/usr/bin/env bash
# shell module - zsh + tmux plugin managers. Runs AFTER stow on purpose: both
# writers land inside folded stow dirs, so stow must have created the symlinks
# first or they would write into a real dir that stow then refuses to fold.
#   • TPM clones into ~/.config/tmux/plugins/tpm - and ~/.config/tmux is a symlink
#     into the repo, so this write lands in the repo tree via the fold.
#   • antidote's plugin list (.zsh_plugins.txt) lives under the stowed ~/.config/zsh.
mod_shell() {
  # Antidote (zsh plugin manager) - clones to ~/.antidote (not itself a stow dir).
  local antidote_dir="$HOME/.antidote"
  if [ ! -d "$antidote_dir" ]; then
    info "🔌 Installing Antidote…"
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$antidote_dir" || return 1
  else
    ok "Antidote already installed"
  fi

  # TPM (tmux plugin manager) - clones into the FOLDED ~/.config/tmux/plugins/tpm.
  local tpm_dir="$HOME/.config/tmux/plugins/tpm"
  if [ ! -d "$tpm_dir" ]; then
    info "⬇️  Installing TPM…"
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir" || return 1
  else
    ok "TPM already installed"
  fi
}
