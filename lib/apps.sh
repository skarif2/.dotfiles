#!/usr/bin/env bash
# apps module - App Store apps, i.e. the GUI apps Homebrew cannot install. GUI
# *casks* are already handled by the brew module via the unified Brewfile, so the
# only remaining GUI layer is `mas` (the Mac App Store CLI).
#
# Kept LAST in the module order (least critical, slowest, needs an App Store
# sign-in). FAILURE-TOLERANT by design: a missing sign-in logs each app as
# skipped and the step still exits 0, so it never fails the whole run (the
# README notes the App Store sign-in requirement).
mod_apps() {
  have mas || { warn "mas not installed; skipping App Store apps."; return 0; }

  # id:name pairs - mas installs by numeric App Store id.
  local apps=( "937984704:Amphetamine" "6450279539:Second Clock" )
  local pair id name
  for pair in "${apps[@]}"; do
    id=${pair%%:*}; name=${pair#*:}
    if mas list 2>/dev/null | grep -q "^${id} "; then
      ok "$name already installed"
    elif mas install "$id" >/dev/null 2>&1; then
      ok "Installed $name"
    else
      warn "Could not install $name ($id); sign in to the App Store and re-run. Skipping."
    fi
  done
  return 0
}
