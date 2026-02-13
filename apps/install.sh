#!/bin/bash
# Application Installation Script
# Installs all GUI applications via Homebrew
# Run this after setup.sh to install your complete app suite

set -e

echo "🚀 Installing GUI Applications via Homebrew..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Please install it first from https://brew.sh/"
    exit 1
fi

# Update Homebrew
echo "🔄 Updating Homebrew..."
brew update

# List of all GUI applications to install
APPS=(
    # Development Tools
    "antigravity"
    "visual-studio-code"
    "zed"
    
    # Browsers
    "arc"
    "brave-browser"
    "google-chrome"
    "duckduckgo"
    
    # Productivity & Notes
    "notion"
    "obsidian"
    
    # Communication
    "slack"
    "discord"
    
    # Security & Privacy
    "bitwarden"
    "cloudflare-warp"
    
    # Media
    "vlc"
    
    # Utilities & System Tools
    "alcove"
    "ice"
    "onyx"
    "sol"
)

# Install each app
echo ""
echo "📦 Installing ${#APPS[@]} applications..."
echo ""

for app in "${APPS[@]}"; do
    if brew list --cask "$app" &>/dev/null; then
        echo "✅ $app is already installed"
    else
        echo "⬇️  Installing $app..."
        if brew install --cask "$app"; then
            echo "✅ Installed $app"
        else
            echo "⚠️  Failed to install $app (may already exist in /Applications)"
        fi
    fi
done

echo ""
echo "🎉 Homebrew installation complete!"
echo ""
echo "📝 Manual Installation Required:"
echo "   The following apps are NOT available via Homebrew:"
echo ""
echo "   • Second Clock - Time zone clock"
echo "     Download from: https://apps.apple.com/app/second-clock/id6450279539"
echo ""
echo "💡 Tip: Run 'brew upgrade --cask' periodically to keep apps updated"
