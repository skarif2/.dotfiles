#!/usr/bin/env bash
# Builds the folder portion of a tmux window label. No maps, all on the fly.
#
# Prints a single line:  <color><TAB><label>
#
#   Rule: build the FULL label first — "repo" or "repo/worktree" using full
#   names. If it fits in MAXLEN (10) chars, show it untouched (".dotfiles" stays
#   ".dotfiles", "backend" stays "backend"). Only when it's longer do we
#   abbreviate: the repo collapses to its segment-initials code and the worktree
#   is cut to WTMAX chars + an ellipsis:
#       "frontend/shift-enter-issue-in-instance" -> "Fr/shift-e…"
#       "control-conter"                          -> "CC"
#
#   color: a stable catppuccin colour derived from the project (repo/folder)
#   name, so every worktree of a repo shares one colour and repos differ.
#
# Abbreviation rule (segment initials): split on -, _ and camelCase; take each
# segment's first letter. Single-word names fall back to their first two letters
# (+ any trailing digits, so "frontend2" -> "Fr2").
#
# Usage: window_label.sh <path>

# Force UTF-8 so multibyte handling is correct: tmux hooks invoke this under
# LC_ALL=C, which makes bash mangle the "…" literal and any non-ASCII path.
export LC_ALL=en_US.UTF-8

MAXLEN=10   # show the full label untouched at or below this length
WTMAX=7     # chars of the worktree kept when the label must be abbreviated
ELL=$(printf '\xe2\x80\xa6')   # "…" built from bytes so it survives any locale

abbrev() {
    local name="${1#.}"              # drop a leading dot (".dotfiles" -> "dotfiles")
    local spaced wc base digits
    # camelCase -> two words, and -/_ -> spaces
    spaced=$(printf '%s' "$name" | sed -E 's/([a-z0-9])([A-Z])/\1 \2/g; s/[-_]+/ /g')
    wc=$(printf '%s' "$spaced" | wc -w | tr -d ' ')
    if [ "$wc" -ge 2 ]; then
        # first letter of each segment, uppercased: "control conter" -> "CC"
        printf '%s' "$spaced" | awk '{r="";for(i=1;i<=NF;i++) r=r toupper(substr($i,1,1)); printf "%s", r}'
    else
        # single word: First + second char, plus any trailing digits
        base=$(printf '%s' "$name" | sed -E 's/[0-9]+$//')
        digits=$(printf '%s' "$name" | grep -oE '[0-9]+$')
        printf '%s%s%s' \
            "$(printf '%s' "$base" | cut -c1 | tr 'a-z' 'A-Z')" \
            "$(printf '%s' "$base" | cut -c2)" \
            "$digits"
    fi
}

# build_label <name> <worktree-or-empty>
build_label() {
    local name="$1" wt="$2" full shown
    [ -n "$wt" ] && full="$name/$wt" || full="$name"
    if [ "${#full}" -le "$MAXLEN" ]; then
        printf '%s' "$full"                  # fits -> show in full, untouched
    elif [ -n "$wt" ]; then
        shown="${wt:0:WTMAX}"
        [ "${#wt}" -gt "$WTMAX" ] && shown="$shown$ELL"
        printf '%s/%s' "$(abbrev "$name")" "$shown"
    else
        abbrev "$name"                       # long standalone repo -> just the code
    fi
}

color_for() {
    local key="$1" h idx
    # catppuccin mocha accents (no greys, so colours stay readable)
    local palette=(89b4fa a6e3a1 cba6f7 f38ba8 fab387 f9e2af 94e2d5 89dceb f5c2e7 b4befe eba0ac f2cdcd)
    h=$(printf '%s' "$key" | cksum | cut -d' ' -f1)
    idx=$(( h % ${#palette[@]} ))
    printf '#%s' "${palette[$idx]}"
}

# emit <project-key> <name> <worktree-or-empty>
emit() { printf '%s\t%s\n' "$(color_for "$1")" "$(build_label "$2" "$3" | tr 'A-Z' 'a-z')"; }

path="${1:-$PWD}"
[ -d "$path" ] || exit 0

# --git-common-dir points at the *main* repo's .git for both plain repos and
# worktrees; empty means we're not inside a git repo.
common=$(git -C "$path" rev-parse --git-common-dir 2>/dev/null)
if [ -z "$common" ]; then
    folder=$(basename "$path")
    emit "$folder" "$folder" ""
    exit 0
fi

# Repo root = parent of the common .git dir — identical for every worktree.
repo_root=$(cd "$path" 2>/dev/null && cd "$(dirname "$common")" 2>/dev/null && pwd -P)
repo=$(basename "${repo_root:-$path}")

# This checkout's own root. If it differs from the repo root, it's a worktree.
toplevel=$(git -C "$path" rev-parse --show-toplevel 2>/dev/null)
if [ -n "$toplevel" ] && [ "$toplevel" != "$repo_root" ]; then
    emit "$repo" "$repo" "$(basename "$toplevel")"
else
    emit "$repo" "$repo" ""
fi
