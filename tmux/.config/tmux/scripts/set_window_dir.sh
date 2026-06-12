#!/usr/bin/env bash
# Computes the folder label + colour for a tmux window and stores them in that
# window's @dir / @dir_color options, which window-status-format then renders.
#
# Storing per-window (instead of using #() in the status format) keeps each
# window correct — #() in a status format only ever sees the active pane.
#
# Usage: set_window_dir.sh <window_id>   (e.g. #{hook_window_id})

wid="$1"
[ -n "$wid" ] || exit 0

here="$(cd "$(dirname "$0")" && pwd)"

# Active pane path for the target window (a plain var, so it resolves reliably).
path="$(tmux display-message -p -t "$wid" '#{pane_current_path}')"

out="$("$here/window_label.sh" "$path")"
color="${out%%$'\t'*}"
label="${out#*$'\t'}"

tmux set-option -w -t "$wid" @dir "$label"
tmux set-option -w -t "$wid" @dir_color "${color:-#a6adc8}"
