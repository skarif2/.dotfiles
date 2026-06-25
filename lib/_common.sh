#!/usr/bin/env bash
# Shared helpers for the dotfiles orchestrator. Sourced by lib/orchestrate.sh and
# every lib/*.sh module - never run directly.
#
# Deliberately NO `set -e`: the orchestrator collects failures instead of
# aborting on the first one (see run_step/report), so a single broken step is
# reported at the end rather than killing the whole run.

# ── Terminal ──────────────────────────────────────────────────────────────────
# Under `curl … | bash` (and `printf '' | ./setup.sh`) stdin is the pipe, not
# the keyboard, so a bare `read` / `gum input` would hit EOF instead of the user.
# Resolve an interactive handle once: the controlling terminal when one exists,
# else /dev/null so reads return EOF cleanly (CI) rather than hanging. Interactive
# steps read from "$TTY", never from stdin.
if [ -e /dev/tty ]; then
  TTY=/dev/tty
else
  TTY=/dev/null
fi
export TTY

# ── Logging ───────────────────────────────────────────────────────────────────
info() { printf '%s\n' "$*"; }
ok()   { printf '✅ %s\n' "$*"; }
warn() { printf '⚠️  %s\n' "$*"; }
err()  { printf '❌ %s\n' "$*" >&2; }
step() { printf '\n▶ %s\n' "$*"; }

# command -v wrapper: `have foo` is true when foo is on PATH.
have() { command -v "$1" >/dev/null 2>&1; }

# ── Failure collection ────────────────────────────────────────────────────────
# Instead of `set -e`, modules return non-zero on failure and run_step records
# the label. report() prints the accumulated failures at the end and sets the
# process exit code. A clean run leaves FAILURES empty and exits 0.
FAILURES=()

# run_step "<label>" command [args…]  - run a step, record it if it fails, keep going.
run_step() {
  local label="$1"; shift
  step "$label"
  "$@"
  local rc=$?   # capture immediately; an `if "$@"; then…fi` would reset $? to 0
  if [ "$rc" -ne 0 ]; then
    err "$label failed (exit $rc)"
    FAILURES+=("$label")
  fi
  return "$rc"
}

# report - print the end-of-run summary; exit-code source of truth for the run.
report() {
  echo
  if [ "${#FAILURES[@]}" -eq 0 ]; then
    ok "All steps completed."
    return 0
  fi
  warn "${#FAILURES[@]} step(s) failed:"
  local f
  for f in "${FAILURES[@]}"; do
    printf '   - %s\n' "$f"
  done
  return 1
}
