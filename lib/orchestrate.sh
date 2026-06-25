#!/usr/bin/env bash
# Dotfiles orchestrator (the real work). Run after the repo is cloned: setup.sh
# (the entry point) handles the fresh-machine clone, then exec's this. Installs
# tools, links configs, and wires the AI agents.
#
# Lives in lib/ alongside the modules it conducts, but unlike them it is
# EXECUTED, not sourced: it pulls in the define-only mod_* modules and runs them.
#
# No global `set -e`: each module runs under run_step, which records failures and
# keeps going, then the run ends with an explicit summary (see lib/_common.sh).
# This way one broken step is reported, not allowed to abort the whole run or to
# pass silently.

# This file lives in lib/, so the repo root is one level up.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES_DIR

. "$DOTFILES_DIR/lib/_common.sh"

# ── Preflight ─────────────────────────────────────────────────────────────────
# Everything the modules and the gum TUI assume is present. MUST finish before
# the first gum call (gum styles the rest of the run) and before any module runs.

# 1. Homebrew - install if absent (NONINTERACTIVE so it never blocks on RETURN),
#    then put brew on PATH for THIS process (a fresh install lands off-PATH).
if ! have brew; then
  step "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || { err "Homebrew install failed; cannot continue."; exit 1; }
fi
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
have brew || { err "brew not on PATH after install; cannot continue."; exit 1; }

# 2. gum - the TUI primitive the rest of the run uses. Install BEFORE any gum call.
if ! have gum; then
  step "Installing gum"
  brew install gum || { err "gum install failed; cannot continue."; exit 1; }
fi

# 3. sudo - pre-authorize once up front and keep the timestamp warm, so no module
#    stalls mid-run on a hidden password prompt. Read the password from the tty,
#    not the (possibly piped) stdin. sudo steps are never wrapped in `gum spin`.
if ! sudo -n true 2>/dev/null; then
  info "Some steps need sudo. Authorizing once up front…"
  sudo -v <"$TTY" || warn "sudo not authorized; sudo-dependent steps may fail."
fi
# keepalive: refresh the sudo timestamp until the orchestrator exits.
( while true; do sudo -n true 2>/dev/null || exit; sleep 50; done ) &
SUDO_KEEPALIVE_PID=$!
trap '[ -n "${SUDO_KEEPALIVE_PID:-}" ] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

gum style --border rounded --margin "1 0" --padding "0 1" --foreground 4 "🚀 Dotfiles bootstrap"

# ── Modules, in hard dependency order ─────────────────────────────────────────
# brew → stow → node-agents → shell → secrets → wiring → apps. The order is
# load-bearing:
#   • brew is first: it provides stow, gum, gh, mas and the rest of the toolchain.
#   • stow precedes shell: ~/.config/tmux and ~/.config/zsh are FOLDED stow
#     symlinks into the repo, so anything that WRITES into them - TPM cloning into
#     ~/.config/tmux/plugins, antidote's plugin list under ~/.config/zsh - MUST run
#     after stow, or it writes into a real dir that stow then refuses to fold
#     (a fold conflict).
#   • secrets precedes wiring: the agents read the MCP tokens the secrets step
#     stores in the Keychain, so prompt for them before wiring runs the setup.
#   • wiring follows node-agents: it points the freshly-installed claude/pi at
#     this repo's vault, then (gh-gated) inits the private grimoire/docs submodule.
#   • apps is last: GUI/App Store extras are the least critical, slowest steps.
. "$DOTFILES_DIR/lib/brew.sh"
. "$DOTFILES_DIR/lib/stow.sh"
. "$DOTFILES_DIR/lib/node-agents.sh"
. "$DOTFILES_DIR/lib/shell.sh"
. "$DOTFILES_DIR/lib/secrets.sh"
. "$DOTFILES_DIR/lib/wiring.sh"
. "$DOTFILES_DIR/lib/apps.sh"

run_step "Homebrew packages (Brewfile)"  mod_brew
run_step "Stow config packages"          mod_stow
run_step "Node + AI agents"              mod_node_agents
run_step "Shell plugins (antidote, TPM)" mod_shell
run_step "MCP secrets (Keychain)"        mod_secrets
run_step "Agent wiring + docs submodule" mod_wiring
run_step "App Store apps"                mod_apps

# ── Summary ───────────────────────────────────────────────────────────────────
report
rc=$?
if [ "$rc" -eq 0 ]; then
  gum style --foreground 2 "🎉 Setup complete. Restart your shell."
fi
exit "$rc"
