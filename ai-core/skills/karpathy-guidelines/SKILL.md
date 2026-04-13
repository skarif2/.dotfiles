---
name: karpathy-guidelines
description: Behavioral guidelines reduce LLM coding mistakes. Use for writing, reviewing, refactoring. Avoid overcomplication, make surgical changes, surface assumptions, define verifiable success criteria.
license: MIT
---

# Karpathy Guidelines

Behavioral guidelines reduce LLM coding mistakes, derived from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876).

**Tradeoff:** Bias caution over speed. Trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implement:
- State assumptions explicitly. Ask if uncertain.
- Multiple interpretations exist: present them. Don't pick silently.
- Simpler approach exists: say so. Push back.
- Unclear: stop. Name confusion. Ask.

## 2. Simplicity First

**Minimum code solves problem. Nothing speculative.**

- No features beyond requested.
- No abstractions single-use code.
- No unrequested "flexibility", "configurability".
- No error handling impossible scenarios.
- Rewrite 200 lines to 50.

Ask: "Overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only must. Clean own mess.**

Edit existing code:
- Don't "improve" adjacent code, comments, formatting.
- Don't refactor unbroken things.
- Match existing style.
- Notice unrelated dead code: mention, don't delete.

Orphans:
- Remove imports/variables/functions YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

Test: Every changed line trace directly to user request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks verifiable goals:
- "Add validation" → "Write tests invalid inputs, make pass"
- "Fix bug" → "Write test reproduce, make pass"
- "Refactor X" → "Ensure tests pass before and after"

Multi-step tasks, plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria loop independently. Weak criteria ("make work") require constant clarification.