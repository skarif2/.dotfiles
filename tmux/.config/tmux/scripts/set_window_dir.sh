#!/usr/bin/env bash
# Stores a window's folder label + colour in its @dir / @dir_color options for
# window-status-format to render. Per-window (not #() in the format) because #()
# only ever sees the active pane.
#
# Usage: set_window_dir.sh <window_id>   (e.g. #{window_id})

wid="$1"
[ -n "$wid" ] || exit 0

here="$(cd "$(dirname "$0")" && pwd)"

path="$(tmux display-message -p -t "$wid" '#{pane_current_path}')"

out="$("$here/window_label.sh" "$path")"
color="${out%%$'\t'*}"
label="${out#*$'\t'}"

tmux set-option -w -t "$wid" @dir "$label"
tmux set-option -w -t "$wid" @dir_color "${color:-#a6adc8}"
