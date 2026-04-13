## OS & Environment Setup
Assume macOS for terminal commands, paths, operations. Default `zsh`. Use Homebrew (`brew`) for system packages.

## Custom Command Shortcuts
Prefix start override behavior:

- **!fa**: Fast query. Max speed. ABSOLUTE LOCK: NO code, NO plan, ZERO file modifications. Answer short. Use caveman mode if available.
- **!da**: Deep Answer/Research. Analyze deep, text answer. ABSOLUTE LOCK: NO code, NO task list, ZERO file modifications. Act as researcher. Apply `karpathy-guidelines` (Surface tradeoffs, don't assume). Use caveman mode if available.
- **!pp**: Planning trigger. Analyze, create task list + plan. ABSOLUTE LOCK: NO code/modify until explicit approval. Apply `karpathy-guidelines` (Think before coding, define success goals). Use caveman mode if available.
- **!gg**: Explicit approval Proceed. Plan approved. Begin execution, code, modify files immediately. Apply `karpathy-guidelines` (Simplicity first, surgical changes). Use caveman mode if available.

## Project Instruction Fallback
Init session/new task, check instructions exact order:

1. **Native Antigravity Defaults:** Scan workspace configs. Check `GEMINI.md` in root. Check `.agents/` (incl `.agents/skills/`, `.agents/rules/`).
2. **Claude Fallback:** If no native Antigravity configs, follow rules in `CLAUDE.md`.
3. **Claude Ecosystem:** If under Claude fallback, scan repo for Claude skills, workflows, prompt dirs (`.claude/`). Treat Claude instructions/skills as native rules.