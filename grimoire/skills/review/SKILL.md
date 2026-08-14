---
name: review
description: Multi-lens code review (correctness, quality, architecture, tests, security) for staged changes, local branch diffs, or open PRs. Runs parallel review agents when the host supports them, else a single inline pass. Severity-rated, escalates findings that match your own gotchas/lessons, and writes a paste-ready approval message on Approve. Use /review for local diff, /review staged for pre-commit, /review <number or URL> for a GitHub PR.
---

<modes>

Detect mode from the argument:

- No argument → **local** mode: diff of current branch against base
- Argument is `staged` → **staged** mode: review staged changes before commit
- Argument is `current` → **pr** mode: find the open PR for the current branch and review it
- Argument is a PR number or GitHub PR URL → **pr** mode: full GitHub PR review

</modes>

<noise-exclusions>

Always exclude these from diffs, they add noise without signal:

```
:(exclude)*lock.json
:(exclude)*.lock
:(exclude)pnpm-lock.yaml
:(exclude)bun.lockb
:(exclude)dist/*
:(exclude)build/*
:(exclude).next/*
:(exclude)coverage/*
:(exclude)*.svg
:(exclude)*.png
:(exclude)*.min.js
:(exclude)*.map
:(exclude)__snapshots__/*
```

</noise-exclusions>

<context-mode-rules>

All diff fetching and file analysis MUST use context-mode tools. Never dump raw git output or file contents directly into context.

- Fetch diffs via `ctx_execute(shell, "git diff ...")`, only stdout enters context
- Analyse files via `ctx_execute_file(path, javascript, ...)`, raw content stays in sandbox
- Batch multiple commands via `ctx_batch_execute(commands, queries)`
- Index large diffs via `ctx_index(content, source)` then retrieve with `ctx_search(queries)`

**Verifying library/framework API usage (optional, context7).** When the diff uses a third-party library or framework API and correctness hinges on the **current** API (a recent version, an unfamiliar call), confirm it against real docs instead of memory before flagging or clearing it: `resolve-library-id` then `get-library-docs` for the specific symbol. Keep it contained, pull only the topic you need (or `ctx_fetch_and_index` the docs page then `ctx_search`); context-mode indexes context7 output so it stays searchable. Skip for std-lib or stable APIs.

</context-mode-rules>

<project-detection>

Detect the project path before running any mode. All mode steps reference these variables.

```bash
PROJECTS_ROOT="$HOME/Projects"
CWD=$(pwd)
if [[ "$CWD" == "$PROJECTS_ROOT/"* ]]; then
  RELATIVE="${CWD#$PROJECTS_ROOT/}"
  GROUP=$(echo "$RELATIVE" | cut -d'/' -f1 | tr '[:upper:]' '[:lower:]')
  PROJ=$(echo "$RELATIVE" | cut -d'/' -f2 | tr '[:upper:]' '[:lower:]')
  DOCS_ROOT="$GRIMOIRE/docs/$GROUP/$PROJ"
  SHARED_ROOT="$GRIMOIRE/docs/$GROUP"
  PROJECT_ID="$GROUP/$PROJ"
else
  PROJ=$(basename "$CWD" | tr '[:upper:]' '[:lower:]')
  DOCS_ROOT="$GRIMOIRE/docs/$PROJ"
  SHARED_ROOT=""
  PROJECT_ID="$PROJ"
fi

# Raw-source root: the review is a single LOCAL file so you can @-mention it from the project.
# Anchored at the git repo/worktree root; falls back to cwd outside a repo.
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
RAW_ROOT="$REPO_ROOT/grimoire"
# Guard: never write raw files inside the GRIMOIRE toolkit itself; fall back to central docs.
if [ "$RAW_ROOT" -ef "$GRIMOIRE" ] 2>/dev/null; then RAW_ROOT="$DOCS_ROOT"; fi
REVIEW_FILE="$RAW_ROOT/review.md"

open_in_editor() {
  if [ -n "${VSCODE_GIT_IPC_HANDLE:-}" ] || [ "${TERM_PROGRAM:-}" = "vscode" ]; then
    echo "  saved: $1"
  else
    code "$(pwd)" "$1" 2>/dev/null || echo "  saved: $1"
  fi
}
```

</project-detection>

<staged-mode>

Review staged changes before a commit.

1. Fetch diff and changed files in one call:
```
ctx_batch_execute(
  commands: [
    { label: "Staged diff", command: "git diff --staged -U3 -- . :(exclude)*lock.json :(exclude)*.lock :(exclude)pnpm-lock.yaml :(exclude)bun.lockb :(exclude)dist/* :(exclude)build/* :(exclude).next/* :(exclude)coverage/* :(exclude)*.svg :(exclude)*.png :(exclude)*.min.js :(exclude)*.map :(exclude)__snapshots__/*" },
    { label: "Changed files", command: "git diff --staged --name-only" }
  ],
  queries: ["changes", "risks", "missing tests"]
)
```

2. Check project knowledge:
```
ctx_batch_execute(
  commands: [
    { label: "Project ADRs", command: "cat $DOCS_ROOT/adr/*.md 2>/dev/null || echo 'none'" },
    { label: "Project context", command: "cat $DOCS_ROOT/context/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared ADRs", command: "cat $SHARED_ROOT/adr/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared context", command: "cat $SHARED_ROOT/context/*.md 2>/dev/null || echo 'none'" }
  ],
  queries: ["architecture decisions", "deliberate patterns", "rejected alternatives"]
)
```

3. Query indexed patterns from past reviews:
```
ctx_search(queries: ["[changed component names]", "patterns", "anti-patterns"], source: "$PROJECT_ID:patterns")
```

4. Review and output (see `<output>`).

</staged-mode>

<local-mode>

Review the current branch diff against the base branch.

1. Detect base branch:
```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"
```

2. Fetch diff and changed files in one call:
```
ctx_batch_execute(
  commands: [
    { label: "Diff", command: "git diff origin/<base>...HEAD -U3 -- . :(exclude)*lock.json :(exclude)*.lock :(exclude)pnpm-lock.yaml :(exclude)bun.lockb :(exclude)dist/* :(exclude)build/* :(exclude).next/* :(exclude)coverage/* :(exclude)*.svg :(exclude)*.png :(exclude)*.min.js :(exclude)*.map :(exclude)__snapshots__/*" },
    { label: "Changed files", command: "git diff origin/<base>...HEAD --name-only" }
  ],
  queries: ["changes", "risks", "patterns"]
)
```

3. Run heuristic checks, output is flags only, not file content:
```
ctx_execute("shell", `
  CHANGED=$(git diff origin/<base>...HEAD --name-only 2>/dev/null)
  COUNT=$(echo "$CHANGED" | grep -c . || echo 0)
  [ "$COUNT" -gt 20 ] && echo "Large diff: $COUNT files, consider focused review"
  echo "$CHANGED" | grep -E '^src/.*\.(ts|tsx|js|jsx)$' | grep -Ev '\.(test|spec)\.' | while read -r f; do
    STEM=$(basename "$f" | sed 's/\..*//')
    echo "$CHANGED" | grep -qE "$STEM\.(test|spec)\." || echo "No test counterpart: $f"
  done
`)
```

4. Check project knowledge:
```
ctx_batch_execute(
  commands: [
    { label: "Project ADRs", command: "cat $DOCS_ROOT/adr/*.md 2>/dev/null || echo 'none'" },
    { label: "Project context", command: "cat $DOCS_ROOT/context/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared ADRs", command: "cat $SHARED_ROOT/adr/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared context", command: "cat $SHARED_ROOT/context/*.md 2>/dev/null || echo 'none'" }
  ],
  queries: ["architecture decisions", "deliberate patterns", "rejected alternatives"]
)
```

5. Query indexed patterns from past reviews:
```
ctx_search(queries: ["[changed component names]", "patterns", "anti-patterns"], source: "$PROJECT_ID:patterns")
```

6. Review and output (see `<output>`).

</local-mode>

<pr-mode>

Full PR review using GitHub MCP and context-mode. Requires a PR number or URL.

1. Extract the PR number from the argument:
   - If a URL, parse the number from the end. If parsing fails, abort: "Could not parse a PR number from that URL."
   - If a number, use directly. Fetch the PR with `github_get_pull_request`. If it returns a 404 or error, abort: "PR #[number] not found in [owner/repo]."
   - If `current`, first run step 2 to get the repo owner, then detect from the current branch:
     ```bash
     git branch --show-current
     ```
     Then use `github_list_pull_requests` with `head: "[owner]:[branch]"` and `state: "open"` to find the PR.
     - If one PR found, proceed with that PR number
     - If multiple found, show the list and ask which one to review
     - If none found, tell the user no open PR exists for this branch, then fall back to local mode automatically

2. Detect the repo owner/name:
```bash
git remote get-url origin 2>/dev/null | sed 's/.*github.com[:\/]//' | sed 's/\.git//'
```

3. Fetch **small metadata via GitHub MCP** (these responses are small, safe to receive directly):
   - `github_get_pull_request`, title, body, author, base/head branch, state
   - `github_get_pull_request_status`, CI checks
   - `github_get_pull_request_reviews`, submitted reviews and verdicts

4. Fetch **file patches via ctx_execute**, never via MCP, patches can be hundreds of KB:
```javascript
ctx_execute("javascript", `
  const token = process.env.GITHUB_PERSONAL_ACCESS_TOKEN;
  const [owner, repo] = "<owner/repo>".split("/");
  const pr = <number>;
  const res = await fetch(
    \`https://api.github.com/repos/\${owner}/\${repo}/pulls/\${pr}/files?per_page=100\`,
    { headers: { Authorization: \`Bearer \${token}\`, Accept: "application/vnd.github+json" } }
  );
  const files = await res.json();
  files.forEach(f => {
    console.log(\`\\n### \${f.filename} [\${f.status}] +\${f.additions} -\${f.deletions}\`);
    if (f.patch) console.log(f.patch);
  });
`, intent: "changed files patches risks")
```
   The `intent` param triggers auto-indexing into FTS5, only relevant snippets come back.

5. Fetch **comments via ctx_execute** if the PR has more than 5 comments:
```javascript
ctx_execute("javascript", `
  const token = process.env.GITHUB_PERSONAL_ACCESS_TOKEN;
  const [owner, repo] = "<owner/repo>".split("/");
  const pr = <number>;
  const res = await fetch(
    \`https://api.github.com/repos/\${owner}/\${repo}/pulls/\${pr}/comments\`,
    { headers: { Authorization: \`Bearer \${token}\` } }
  );
  const comments = await res.json();
  comments.forEach(c => console.log(\`[\${c.path}] \${c.user.login}: \${c.body}\`));
`, intent: "existing review comments feedback")
```
   For 5 or fewer comments, `github_get_pull_request_comments` via MCP is fine.

   **Re-review tracking.** When prior review comments exist on this PR (a re-review after the author pushed changes), treat those comments as the change request of record, GitHub is the source of truth, not any local file. Cross-check each prior finding against the updated diff and classify it **resolved / still-open / newly-introduced**. Lead the review output with that resolved/open/new summary so the loop is explicit, then review the new delta as usual.

6. Check project knowledge via `ctx_batch_execute`:
```
ctx_batch_execute(
  commands: [
    { label: "Project ADRs", command: "cat $DOCS_ROOT/adr/*.md 2>/dev/null || echo 'none'" },
    { label: "Project context", command: "cat $DOCS_ROOT/context/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared ADRs", command: "cat $SHARED_ROOT/adr/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared context", command: "cat $SHARED_ROOT/context/*.md 2>/dev/null || echo 'none'" }
  ],
  queries: ["architecture decisions", "deliberate patterns", "rejected alternatives"]
)
```

7. Query indexed patterns from past reviews:
```
ctx_search(queries: ["[changed component names]", "patterns", "anti-patterns"], source: "$PROJECT_ID:patterns")
```

8. Check for linked issues in the PR body (`#NNN`, `fixes #NNN`, `closes #NNN`). If found, fetch with `github_get_issue`, issue descriptions are small, MCP is fine here.

9. Review and output (see `<output>`).

</pr-mode>

<output>

Structure the review clearly. Adapt depth to the size of the diff: a 2-file staged change does not need the same structure as a 30-file PR.

### Review engine: parallel agents if available, else inline

Before writing the review, gather findings with the best engine this host supports. State which path you used in one line at the top of the review.

**Capability check:** if the host exposes a sub-agent / parallel task dispatch capability (Claude Code's Agent tool, or PI's sub-agent equivalent), use **Path A**. Otherwise use **Path B**. No agent definition files are needed: dispatch ad-hoc reviewers with the focused prompts below.

**Path A: parallel specialized reviewers (preferred when available).** Dispatch these as read-only sub-agents in parallel. Give each the same inputs: the changed-file list, the full diff, the loaded conventions/context, and the touched components' gotchas + lessons (see Severity + knowledge escalation). Tell each: "Report findings only, with severity and `file:line`. Do not edit."
- **correctness**: logic errors, null/undefined, race conditions, edge cases
- **quality**: naming, duplication, complexity, convention compliance
- **architecture**: layering, separation of concerns, module boundaries, scope creep
- **tests**: coverage gaps for the diff, mock completeness, determinism (keep the existing judgment: do not demand tests for config-only, type-only, or pure-UI changes)
- **security**: input validation, authz gaps, secret/PII exposure, injection
Collect every agent's findings, then deduplicate overlaps.

**Path B: single inline pass (fallback, e.g. PI without sub-agents).** Do the same five lenses yourself in one sequential pass. Everything downstream is identical.

For tiny diffs, collapse to Path B even when agents are available: a one or two file change does not justify five agent dispatches.

### Severity + knowledge escalation

Tag every finding with a severity:
- **Critical**: must fix before merge (bugs, security, data loss, regressions)
- **Major**: should fix before merge (convention violations, missing tests, architectural smells)
- **Minor**: nice to fix (style, naming, small improvements)
- **Nit**: optional

Then escalate against your own vault: derive the touched components from the diff paths and load their distilled pages (`$DOCS_ROOT/gotchas.md`, `$DOCS_ROOT/lessons/*`, `$DOCS_ROOT/concepts/*`, via `ctx_search` source `$PROJECT_ID:gotchas|lessons|concepts`, or `cat`). If a finding matches a known gotcha or lesson, **raise its severity by one level** and name the page, e.g. "Major (escalated from Minor): trips [[gotchas#mdf-visibility-must-use-search_view-not-default]]." The review gets sharper as the vault grows.

# [PR title or branch name]

**Mode:** staged | local | PR #{number}
**Date:** [YYYY-MM-DD]
**Files changed:** N
**CI:** ✅ passing | ❌ failing | ⏳ pending | n/a (not applicable)

## Summary
One short paragraph describing what the change does and whether it achieves its goal.

## Risks
Specific concerns that could cause bugs, regressions, or production issues. Tag each with its severity (Critical / Major / Minor / Nit) and point to the exact `file:line`. Flag any that were escalated because they match a known gotcha or lesson, naming the page. If none, say so.

## Missing or weak test coverage
Only flag if source changes have no corresponding test changes and the logic is non-trivial. Don't flag test absence for config changes, type-only changes, or pure UI.

## Conflicts with project decisions
If any change contradicts an ADR or established pattern from context files, flag it here with the ADR name.

## Nitpicks
Minor style or naming issues. Low priority, clearly labelled so they're easy to distinguish from real issues.

## Verdict
Derive it from the worst severity present: any **Critical** means **Request changes**; a **Major** with no Critical is a judgment call, default **Needs discussion** unless the Majors are clearly optional; only **Minor/Nit** (no Critical or Major) means **Approve**. One sentence justifying it.

If the verdict is **Approve**, also produce a short approval message to paste on the PR (see `<approval-message>` below); the leftover Minor/Nit findings become its NOTE line.

Whatever the verdict, also produce a short **daily-update** message to paste in standup (see `<daily-update>` below).

---

After writing the review, save it to the single local file and open it.

The review is a **single local working file** at `$REVIEW_FILE` (`<repo-root>/grimoire/review.md`, see the project-detection block). Keep only the latest: each review **overwrites** it, no dated filenames, no accumulation. (For a PR you re-review, GitHub holds the durable record, see `<pr-mode>`.)

```bash
mkdir -p "$RAW_ROOT"
```

Load `$GRIMOIRE/templates/REVIEW-FMT.md` for the output format, then write the full review content to `$REVIEW_FILE` (overwriting any previous review) and open it:
```bash
open_in_editor "$REVIEW_FILE"
```

After saving, scan the findings for reusable patterns, anti-patterns caught, conventions violated, recurring issues. Index each one that a future session should know about:
```
ctx_index(
  content: "Pattern: [description of the pattern or anti-pattern]",
  source: "$PROJECT_ID:patterns"
)
```

Also index a brief review summary:
```
ctx_index(
  content: "Review [date] [branch/PR]: [one-line summary of what was reviewed and the main finding]",
  source: "$PROJECT_ID:reviews"
)
```

Skip indexing if the review found only one-off issues with no reusable signal.

</output>

<approval-message>

When the verdict is **Approve**, also produce a short, copy-pasteable **approval message** for the user to post on the PR, separate from the saved review file. (Skip this entirely for "Request changes" / "Needs discussion".)

**Write it through the `arif-voice` skill.** That skill owns how it sounds; the rules below own what goes in it. This one gets posted on GitHub under his name, so voice matters more here than anywhere else in the review.

Rules:
- **1 to 2 lines.** No section headers, no bullet lists.
- **Never mention CI, checks, pipelines, or build status.**
- If the PR is clean (no issues worth raising), just the approval line, nothing else.
- If there are leftover **Minor/Nit** findings **or a pending Copilot / other review** not yet resolved, still approve, then add **one** `NOTE:` line framing them as a nice-to-have or follow-up, explicitly not a blocker. (Critical or Major findings mean the verdict is not Approve, so they never appear here.)
- Keep the NOTE to a single line; if there are several minor things, summarise them in that one line rather than listing each.

Present it in its own fenced block, clearly labelled as the thing to paste:

```
Approval message (paste on the PR):
> LGTM, clean and well scoped, happy to approve.
> NOTE: the inline type-guard tidy-up is a nice-to-have follow-up, not a blocker.
```

(Drop the `NOTE:` line when there's nothing minor to flag.)

</approval-message>

<daily-update>

Regardless of verdict, also produce a short **daily-update** message (think standup) for the user to paste, drawn from what this review covered. **Write it through the `arif-voice` skill**, same as the approval message above and `/gg`'s daily update.

- **Never mention CI, checks, pipelines, or build status.**
- No section headers, no bullet lists. It is one short paragraph.
- **Lead with the PR title verbatim and its number**, then say what the PR actually does in **1-2 lines** so a reader who never opened it knows what changed and why. Pull this from the diff/description, not a finding-by-finding log.
- **Approve** → `Reviewed and approved <PR title> (#<num>). <1-2 lines on what changed and why>.`
- **Request changes / Needs discussion** → a **single line**: `Reviewed <PR title> (#<num>), sent feedback on <the gist>.`

Present it in its own fenced block, clearly labelled as the thing to paste:

```
Daily update (paste in standup):
> Reviewed and approved <PR title> (#<num>). <1-2 lines on what changed and why>.
```

For a Request changes / Needs discussion verdict, it collapses to one line:

```
Daily update (paste in standup):
> Reviewed <PR title> (#<num>), sent feedback on <the gist>.
```

</daily-update>

<distillation>

After the review is saved and indexed, **distil durable learnings into the wiki layer (draft → confirm)**. A review is a *raw source*; its lasting value, not the per-line nits, should compound into the distilled wiki. Most valuable in `pr` and `local` mode; usually skip for `staged` (pre-commit, ephemeral).

(See the "Compiled Wiki Layer" section of `$GRIMOIRE/AGENTS.md` and `$GRIMOIRE/templates/{CONCEPT,COMPONENT,LESSON,GOTCHA,INDEX}-FMT.md`.)

1. From the findings + the diff, pick only **durable** items: a recurring trap → **gotcha**; a non-obvious behaviour of a module → **component** note; a root cause or pattern worth remembering → **lesson** or **concept**. Per-PR nitpicks and one-offs do **not** qualify.
2. For each, check `$DOCS_ROOT/{concepts,components,lessons}/` and `$DOCS_ROOT/gotchas.md`, **update existing pages in place**, don't duplicate.
3. Draft each page/entry with a mandatory `Source:` that **names** the originating review/branch/PR plus durable anchors (`path:line`/PR #/commit); do **not** link the review file (it is local and overwritten, so a `[[review]]` link would dangle). Add `Status:`/`Updated:`, and `[[wikilinks]]` to related distilled pages. Draft the matching `index.md` entries and backlinks.
4. **Present the drafts as a confirm batch** (each NEW/UPDATE + one-line summary). Do **not** write until the user approves. On `approve`: write the pages, update `$DOCS_ROOT/index.md`, and `ctx_index` each with its `$PROJECT_ID:<type>` source. On `revise: <note>`: adjust and re-present.
5. If nothing durable surfaced, **say so and skip**, never manufacture pages.

When checking "Conflicts with project decisions" above, also consult the distilled `concepts/` and `gotchas.md`, not just ADRs/context, a change may contradict a documented mechanism or trip a known gotcha.

</distillation>

<guidelines>

- Be specific, point to file names and what the issue is, not vague statements like "this could be improved"
- Distinguish signal from noise, a missing semicolon is not the same as a missing null check
- Don't flag deliberate decisions, check ADRs and context files before calling something wrong
- Don't suggest unrelated improvements, review what's in the diff, not the surrounding code
- Existing comments from reviewers, acknowledge them, don't repeat what's already been said

</guidelines>
