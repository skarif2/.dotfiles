---
description: Review, code review for staged, local diff, or GitHub PR
argument-hint: "[staged | PR number | PR URL]"
---
$ARGUMENTS

Load and follow the `review` skill.

- No argument → review local branch diff against base
- `staged` → review staged changes before commit
- `current` → find the open PR for the current branch and review it
- PR number or URL → full GitHub PR review with CI status, existing comments, linked issues

The skill will save the review to `<repo-root>/grimoire/review.md`, overwriting the previous run, and open it in VS Code.
