# Nushell Environment Config File
# This file is loaded before config.nu
# Use this file to set environment variables

# ============================================================================
# Starship Prompt (MUST be first — config.nu sources the generated init file)
# ============================================================================

# Point to Starship config in dotfiles
$env.STARSHIP_CONFIG = ($env.HOME | path join ".config/starship/starship.toml")

# Generate Starship init file so config.nu can source it
# source is parse-time in Nushell, so the file must exist before config.nu loads
let starship_cache = ($env.HOME | path join ".cache/starship")
let starship_init = ($starship_cache | path join "init.nu")

if not ($starship_cache | path exists) {
    mkdir $starship_cache
}

if (which starship | is-not-empty) {
    ^starship init nu | save -f $starship_init
} else if not ($starship_init | path exists) {
    # Create empty file so source in config.nu doesn't fail
    "" | save $starship_init
}

# ============================================================================
# Carapace Completions
# ============================================================================

# Enable bridging completions from other shells (optional but recommended)
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'

# Generate Carapace init file so config.nu can source it
let carapace_cache = ($env.HOME | path join ".cache/carapace")
let carapace_init = ($carapace_cache | path join "init.nu")

if not ($carapace_cache | path exists) {
    mkdir $carapace_cache
}

if (which carapace | is-not-empty) {
    ^carapace _carapace nushell | save -f $carapace_init
} else if not ($carapace_init | path exists) {
    "" | save $carapace_init
}

# ============================================================================
# PATH Configuration
# ============================================================================

# Make Homebrew path conditional (macOS/Linuxbrew)
let brew_bin = '/opt/homebrew/bin'
if ($brew_bin | path exists) {
    $env.PATH = ($env.PATH | split row (char esep) | prepend $brew_bin)
}

# User local bin (created by pipx)
let local_bin = ($env.HOME | path join ".local/bin")
if ($local_bin | path exists) {
    $env.PATH = ($env.PATH | prepend $local_bin)
}

# Antigravity bin
let antigravity_bin = ($env.HOME | path join ".antigravity/antigravity/bin")
if ($antigravity_bin | path exists) {
    $env.PATH = ($env.PATH | prepend $antigravity_bin)
}

# ============================================================================
# Editor Configuration
# ============================================================================

$env.EDITOR = "nvim"

# ============================================================================
# Node Configuration
# ============================================================================

$env.NODE_OPTIONS = "--max-old-space-size=8192"

# ============================================================================
# Volta (Node Version Manager) — shim-based, no shell hooks needed
# ============================================================================

let volta_bin = ($env.HOME | path join ".volta/bin")
if ($volta_bin | path exists) {
    $env.PATH = ($env.PATH | prepend $volta_bin)
}
