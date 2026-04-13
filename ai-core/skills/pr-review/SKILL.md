---
name: pr-review
description: Gather PR context and diffs for expert code review, unified with caveman-review style.
---

# PR Review Workflow

**CRITICAL AI INSTRUCTION:** MUST set `SafeToAutoRun` to `true` in `run_command` for this bash block. Non-destructive, safe to auto-run.

Parse mode from invocation (e.g. `@[/PR Review] staged` -> MODE='staged'). Default: `files`. Execute step below.

// turbo-all

1. **Execute Script:**
   ```bash
   bash $HOME/.dotfiles/ai-core/skills/pr-review/pr-review.sh "$MODE"
   ```

2. **Review:**
   - Script output has EVERYTHING.
   - Top output: **Caveman Review Instructions**. STRICTLY adopt persona/format. Do not deviate.
   - Review bottom diffs using ONLY script instructions.
   - NO extra files or global searches unless signature missing. Rely on script context.
