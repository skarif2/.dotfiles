#!/usr/bin/env bash
# secrets module - prompt for the MCP tokens and store them in the login
# Keychain, BEFORE the wiring module that the agents read them through. Each
# token is skippable (empty input = skip, no Keychain entry), and an
# already-present entry is left untouched, so a re-run never clobbers a stored
# secret. Prompts read from "$TTY", never an fd-0 redirect (see lib/_common.sh).
#
# Entry names match the grimoire setup scripts' Keychain checks
# (github-mcp-token, context7-api-key).
mod_secrets() {
  have gum || { warn "gum missing; skipping secret prompts."; return 0; }
  local entry val
  for entry in github-mcp-token context7-api-key; do
    if security find-generic-password -a "$USER" -s "$entry" -w >/dev/null 2>&1; then
      ok "Keychain entry '$entry' already set"
      continue
    fi
    val=$(gum input --password \
      --placeholder "Paste $entry (press Enter to skip)" <"$TTY")
    if [ -z "$val" ]; then
      info "  Skipped $entry (no Keychain entry created)."
      continue
    fi
    if security add-generic-password -a "$USER" -s "$entry" -w "$val" -U; then
      ok "Stored $entry in the login Keychain"
    else
      warn "Failed to store $entry in the Keychain."
    fi
  done
  return 0
}
