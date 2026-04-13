#!/bin/bash

MODE=${1:-light}

echo "--- PR REVIEW INSTRUCTIONS (CAVEMAN MODE) ---"
cat "$HOME/.dotfiles/ai-core/skills/caveman-review/SKILL.md"

echo ""
echo "--- PR REVIEW CONTEXT ($MODE mode) ---"

# Aggressive Token Saving Exclusions
EXCLUDES="':(exclude)*lock.json' ':(exclude)*.lock' ':(exclude)pnpm-lock.yaml' ':(exclude)bun.lockb' ':(exclude)dist/*' ':(exclude)build/*' ':(exclude).next/*' ':(exclude).nuxt/*' ':(exclude).output/*' ':(exclude)coverage/*' ':(exclude)*.svg' ':(exclude)*.png' ':(exclude)*.min.js' ':(exclude)*.map' ':(exclude)__snapshots__/*' ':(exclude)mocks/*' ':(exclude)vendor/*'"


if [ "$MODE" == "staged" ]; then
    echo "Reviewing local STAGED files."
    DIFF_CMD="git diff --staged -U3"
    FILE_CMD="git diff --staged --name-only"
    
elif [[ "$MODE" == "files" || "$MODE" == "light" ]]; then
    BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || true)
    [ -z "$BASE_BRANCH" ] && { git show-ref --verify --quiet refs/remotes/origin/main && BASE_BRANCH="main" || BASE_BRANCH="master"; }
    echo "Reviewing diff against origin/$BASE_BRANCH."
    DIFF_CMD="git diff origin/$BASE_BRANCH...HEAD -U3"
    FILE_CMD="git diff origin/$BASE_BRANCH...HEAD --name-only"

elif [[ "$MODE" == "deep" || "$MODE" == "heavy" ]]; then
    BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || true)
    [ -z "$BASE_BRANCH" ] && { git show-ref --verify --quiet refs/remotes/origin/main && BASE_BRANCH="main" || BASE_BRANCH="master"; }
    echo "Reviewing deep diff against origin/$BASE_BRANCH."
    DIFF_CMD="git diff origin/$BASE_BRANCH...HEAD -U5"
    FILE_CMD="git diff origin/$BASE_BRANCH...HEAD --name-only"

    # Missing Test Heuristic
    echo ""
    echo "--- HEURISTIC CHECKS ---"
    CHANGED_FILES=$(eval "$FILE_CMD -- . $EXCLUDES")
    HAS_SRC=$(echo "$CHANGED_FILES" | grep -E "^(src/|app/|lib/)" || true)
    HAS_TEST=$(echo "$CHANGED_FILES" | grep -E "(test|spec|__tests__)" || true)
    
    if [ -n "$HAS_SRC" ] && [ -z "$HAS_TEST" ]; then
        echo "🛑 WARNING: Code in src/ was modified but NO tests were updated in this PR. Flag this risk."
    else
        echo "✅ Test coverage checks out."
    fi

    # GitHub Context
    echo ""
    if command -v gh &> /dev/null && gh pr view &> /dev/null; then
        echo "--- GitHub PR Context ---"
        gh pr view --json title,body,state,url
    fi

    # Static Analysis
    echo ""
    echo "--- Static Analysis ---"
    if [ -f "package.json" ]; then
        PM="npm"
        [ -f "pnpm-lock.yaml" ] && PM="pnpm"
        [ -f "yarn.lock" ] && PM="yarn"
        [ -f "bun.lockb" ] && PM="bun"
        if grep -q '"lint":' package.json; then
            echo "Running $PM run lint..."
            $PM run lint || true
        fi
    fi
else
    echo "Unknown mode: $MODE"
    exit 1
fi

echo ""
echo "--- CODE DIFFS ---"
eval "$DIFF_CMD -- . $EXCLUDES"
