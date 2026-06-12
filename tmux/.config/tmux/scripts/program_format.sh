#!/usr/bin/env bash
# Sets a tmux automatic-rename-format that turns the running program into a Nerd
# Font icon (#W becomes the icon, or the raw command name when unmapped). Built
# here, not inline in tmux.conf, so glyphs come from codepoints — no fragile
# literal glyphs in the config. Claude renames its process to its version (e.g.
# "2.1.170"), so it's matched by a version regex rather than by name.
#
# Tweak: edit MAP below (program -> Nerd Font codepoint hex from
# https://www.nerdfonts.com/cheat-sheet, the digits after "U+").

cmd='#{pane_current_command}'

# codepoint (hex, U+E000..U+FFFF) -> glyph as raw UTF-8 bytes via octal printf.
# Pure arithmetic: works in bash 3.2, needs no UTF-8 locale or $'\u' (both of
# which tmux's run-shell environment lacks).
g() {
    local cp=$((16#$1))
    printf "\\$(printf '%03o' $(( 0xE0 | (cp >> 12) )))"
    printf "\\$(printf '%03o' $(( 0x80 | ((cp >> 6) & 0x3F) )))"
    printf "\\$(printf '%03o' $(( 0x80 | (cp & 0x3F) )))"
}

# program (pane_current_command)  ->  Nerd Font codepoint
MAP=(
    "node:E718"   "volta-shim:E718" "npm:E71E"   "yarn:E718"  "deno:EB52"
    "python:E73C" "python3:E73C"
    "nvim:E6AE"   "vim:E62B"   "vi:E62B"
    "lazygit:E702" "git:E702"  "gitui:E702"
    "go:E627"     "cargo:E7A8" "rustc:E7A8" "ruby:E23E"
    "docker:F308"
    "zsh:E795"    "bash:E795"  "fish:E795"
    "vite:F0E7"   "vp:F0E7"
)

fmt="$cmd"   # fallback: the raw command name for anything unmapped
for pair in "${MAP[@]}"; do
    key="${pair%%:*}"; cp="${pair##*:}"
    fmt="#{?#{==:$cmd,$key},$(g "$cp"),$fmt}"
done

# Claude (process renamed to its version). Added last => outermost => checked first.
regex='^[0-9]+\.[0-9]+\.[0-9]+$'
fmt="#{?#{m/r:$regex,$cmd},$(g F069),$fmt}"

tmux set-option -g automatic-rename-format "$fmt"
