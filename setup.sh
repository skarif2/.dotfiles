#!/usr/bin/env bash
# The single entry point for this dotfiles repo, served at
# skarif.dev/dotfiles/install.sh (a redirect to this file's GitHub-raw URL).
# The whole flow is one command:
#
#   curl -fsSL https://skarif.dev/dotfiles/install.sh | bash      # fresh machine
#   bash ~/.dotfiles/setup.sh                                     # re-sync a checkout
#
# Idempotent and self-contained on purpose: it runs BEFORE the repo exists, so it
# sources nothing and assumes only a bare macOS (no Homebrew, no Xcode CLT, no
# git). It gets the machine to a cloned repo (or pulls an existing one), then
# hands off to the orchestrator (lib/orchestrate.sh), which does the real work.
#
# No `set -e`: a fresh-Mac setup should report what failed and stop with a clear
# message, never abort halfway with a bare non-zero from some sub-step.

REPO_URL="https://github.com/skarif2/.dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

# ── Logging ───────────────────────────────────────────────────────────────────
info() { printf '%s\n' "$*"; }
ok()   { printf '✅ %s\n' "$*"; }
warn() { printf '⚠️  %s\n' "$*"; }
err()  { printf '❌ %s\n' "$*" >&2; }
step() { printf '\n▶ %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
die()  { err "$*"; exit 1; }

# ── Terminal ──────────────────────────────────────────────────────────────────
# Under `curl … | bash` stdin IS the pipe, and bash reads THIS SCRIPT from it.
# So we must NOT `exec </dev/tty`: redirecting fd 0 mid-script makes bash read
# its own remaining lines from the keyboard, hanging the bootstrap. Instead,
# resolve an explicit terminal handle (mirroring lib/_common.sh) and feed it to
# the interactive commands that need it. No tty (CI) -> /dev/null, reads see EOF
# cleanly and we lean on NONINTERACTIVE/-n flags.
if [ -e /dev/tty ]; then
  TTY=/dev/tty
else
  TTY=/dev/null
fi

# warm_sudo - refresh the sudo timestamp, reading the password from the tty (never
# the piped stdin). Called immediately before the step that needs it, NOT once up
# front: the Xcode CLT GUI wait below can run for many minutes and the default
# 5-minute sudo timestamp would go cold before Homebrew's (non-prompting,
# NONINTERACTIVE) install probes it.
warm_sudo() {
  [ "$TTY" = /dev/null ] && return 0
  sudo -n true 2>/dev/null && return 0
  info "Authorizing sudo…"
  sudo -v <"$TTY" || warn "sudo not authorized; the next privileged step may fail."
}

# ── Xcode Command Line Tools ──────────────────────────────────────────────────
# Homebrew and git both need the CLT. `xcode-select --install` pops the GUI
# installer and returns non-zero when they are ALREADY installed, so its exit
# code is ignored; readiness is decided by polling instead. The poll is bounded:
# the GUI install is user-driven and may never finish, so we time out with an
# error rather than loop forever.
if ! xcode-select -p >/dev/null 2>&1; then
  step "Installing Xcode Command Line Tools"
  info "A GUI prompt will appear; click Install and accept the licence."
  xcode-select --install >/dev/null 2>&1 || true

  clt_deadline=$(( $(date +%s) + 1800 ))   # 30-minute bound
  until xcode-select -p >/dev/null 2>&1 && git --version >/dev/null 2>&1; do
    [ "$(date +%s)" -ge "$clt_deadline" ] && \
      die "Timed out waiting for Xcode Command Line Tools. Finish the GUI installer, then re-run."
    sleep 5
  done
  ok "Xcode Command Line Tools ready"
else
  ok "Xcode Command Line Tools already installed"
fi

# ── Homebrew ──────────────────────────────────────────────────────────────────
# NONINTERACTIVE so the installer never blocks on RETURN when stdin is a pipe.
# A fresh install lands off-PATH, so eval its shellenv to use brew in THIS shell.
if ! have brew; then
  step "Installing Homebrew"
  # Warm sudo HERE, right before the install: NONINTERACTIVE Homebrew needs sudo
  # but will not prompt for the password itself, so the timestamp must be fresh
  # now (the CLT wait above may have blown past the 5-minute sudo window).
  warm_sudo
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || die "Homebrew install failed; cannot continue."
fi
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
have brew || die "brew not on PATH after install; cannot continue."

# gum - the TUI primitive the orchestrator styles its run with. Installed here so
# the orchestrator finds it already present.
if ! have gum; then
  step "Installing gum"
  brew install gum || die "gum install failed; cannot continue."
fi

# ── Clone (or update) the repo ────────────────────────────────────────────────
# Public repo, so no token. NON-recursive on purpose: the grimoire/docs submodule
# is private and HTTPS credentials are not ready yet, so submodule init is
# deferred to the orchestrator's wiring module. Re-running pulls in place.
if [ -d "$DOTFILES_DIR/.git" ]; then
  step "Updating existing dotfiles checkout"
  git -C "$DOTFILES_DIR" pull --ff-only || warn "git pull failed; using the existing checkout."
else
  step "Cloning dotfiles to $DOTFILES_DIR"
  git clone "$REPO_URL" "$DOTFILES_DIR" || die "Clone failed; cannot continue."
fi

# ── Hand off to the orchestrator ──────────────────────────────────────────────
# Invoked via `bash`, not `exec "$file"`, so the handoff does not depend on the
# orchestrator's execute bit surviving the clone (a bare `exec` of a non-+x file
# would fail hard, and only on the untestable fresh-clone path). lib/orchestrate.sh
# opens /dev/tty itself for its prompts; we still point its stdin at "$TTY" so it
# inherits the terminal (not the now-exhausted pipe) for any plain `read`.
step "Handing off to the orchestrator"
exec bash "$DOTFILES_DIR/lib/orchestrate.sh" <"$TTY"
