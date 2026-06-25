#!/usr/bin/env bash
# node-agents module - Node (via Volta) plus the AI agent CLIs. Volta must supply
# Node BEFORE the pi installer runs: pi.dev's installer does `npm install -g`,
# which goes through Volta's npm shim and can collide with Volta's package store.
mod_node_agents() {
  # Volta (not a Homebrew package).
  if ! have volta; then
    info "⬇️  Installing Volta…"
    curl -fsSL https://get.volta.sh | bash -s -- --skip-setup || return 1
  else
    ok "Volta already installed"
  fi
  # Make the freshly-installed Volta + native installers usable within THIS run.
  export VOLTA_HOME="$HOME/.volta"
  export PATH="$VOLTA_HOME/bin:$HOME/.local/bin:$PATH"

  # Default Node - required by pi's installer and by ccstatusline's npx.
  if have volta; then
    if volta list node 2>/dev/null | grep -q "node@"; then
      ok "Node already managed by Volta"
    else
      info "⬇️  Installing default Node via Volta…"
      volta install node || return 1
    fi
  fi

  # Claude Code - native installer, lands in ~/.local/bin, self-updating.
  if have claude; then
    ok "Claude Code already installed ($(claude --version 2>/dev/null | head -1))"
  else
    info "⬇️  Installing Claude Code…"
    curl -fsSL https://claude.ai/install.sh | bash || return 1
  fi

  # pi coding agent - official installer (installs @earendil-works/pi-coding-agent).
  # It runs `npm install -g`, which can conflict with Volta's global shim.
  # Fallback: if pi is still absent afterwards, redo the global install against a
  # NON-Volta Node (Homebrew's node), bypassing the shim that blocked it.
  if have pi; then
    ok "pi already installed ($(pi --version 2>/dev/null))"
  else
    info "⬇️  Installing pi…"
    curl -fsSL https://pi.dev/install.sh | sh || warn "pi installer returned non-zero; verifying…"
    if ! have pi; then
      warn "pi not on PATH after install.sh - likely the Volta global-npm conflict."
      info "Fallback: installing pi via Homebrew's (non-Volta) Node…"
      brew list node >/dev/null 2>&1 || brew install node || return 1
      "$(brew --prefix node)/bin/npm" install -g @earendil-works/pi-coding-agent || return 1
    fi
  fi
}
