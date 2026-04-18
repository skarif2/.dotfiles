#!/bin/bash

# setup-ai.sh - Binds AI Core folder to different LLM agents

CORE_DIR="$HOME/.dotfiles/ai-core"

echo "Setting up AI Core symlinks..."

# 1. Gemini / Antigravity
mkdir -p "$HOME/.gemini"
rm -rf "$HOME/.gemini/GEMINI.md" "$HOME/.gemini/skills"
ln -s "$CORE_DIR/master-rules.md" "$HOME/.gemini/GEMINI.md"
ln -s "$CORE_DIR/skills" "$HOME/.gemini/skills"
echo "✅ Gemini/Antigravity connected."

# 2. Pi
mkdir -p "$HOME/.pi/agent"
rm -rf "$HOME/.pi/agent/AGENTS.md" "$HOME/.pi/agent/skills"
ln -s "$CORE_DIR/master-rules.md" "$HOME/.pi/agent/AGENTS.md"
ln -s "$CORE_DIR/skills" "$HOME/.pi/agent/skills"
echo "✅ Pi agent connected."

echo "All agents are now sharing the same brain."
