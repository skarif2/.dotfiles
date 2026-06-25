#!/usr/bin/env bash
# wiring module - point the AI agents at this repo's grimoire vault, then
# (separately) initialise the private docs submodule.
#
# Two independently-gated parts:
#   1. Agent wiring is AUTH-FREE and ALWAYS runs: setup-claude.sh / setup-pi.sh
#      only symlink skills/prompts/AGENTS.md out of this PUBLIC repo and write
#      local settings. A missing GitHub login must never block it.
#   2. The private grimoire/docs submodule is gated on `gh` auth ONLY. A green
#      `gh auth status` is not enough for an HTTPS clone - git needs a credential
#      helper - so we also run `gh auth setup-git`. Declining login skips just
#      the submodule, with the agent wiring already done.
# Interactive prompts read from "$TTY", never an fd-0 redirect.
mod_wiring() {
  local rc=0

  # ── 1. Auth-free agent wiring (always) ──────────────────────────────────────
  # Run via `bash` so a missing execute bit on a fresh clone can't fail the step.
  bash "$DOTFILES_DIR/grimoire/setup-claude.sh" || { warn "setup-claude.sh failed."; rc=1; }
  bash "$DOTFILES_DIR/grimoire/setup-pi.sh"     || { warn "setup-pi.sh failed.";     rc=1; }

  # ── 2. Private submodule, gated on gh auth ──────────────────────────────────
  if ! have gh; then
    warn "gh not installed; deferring grimoire/docs submodule init."
    return "$rc"
  fi
  if ! gh auth status >/dev/null 2>&1; then
    info "The private grimoire/docs submodule needs a GitHub login."
    if gum confirm "Log in to GitHub now to fetch grimoire/docs?" <"$TTY"; then
      gh auth login <"$TTY" || { warn "gh auth login failed; deferring grimoire/docs."; return "$rc"; }
    else
      info "  Declined login; skipping grimoire/docs (agent wiring is already done)."
      return "$rc"
    fi
  fi

  # gh auth status green still does not configure git's HTTPS credential helper.
  gh auth setup-git || warn "gh auth setup-git failed; the submodule clone may prompt."
  git -C "$DOTFILES_DIR" submodule update --init grimoire/docs \
    || { warn "grimoire/docs submodule init failed."; rc=1; }
  return "$rc"
}
