---
description: Go, plan approved: execute the plan, self-review the change, distil into the vault, then draft the PR
argument-hint: "[plan filename or partial name]"
---
$ARGUMENTS

Plan approved. Execute now.

## Instructions

1. Detect the project path (see `$GRIMOIRE/templates/PROJECT-INIT.md` for the full spec):
   ```bash
   PROJECTS_ROOT="$HOME/Projects"
   CWD=$(pwd)
   if [[ "$CWD" == "$PROJECTS_ROOT/"* ]]; then
     RELATIVE="${CWD#$PROJECTS_ROOT/}"
     GROUP=$(echo "$RELATIVE" | cut -d'/' -f1 | tr '[:upper:]' '[:lower:]')
     PROJ=$(echo "$RELATIVE" | cut -d'/' -f2 | tr '[:upper:]' '[:lower:]')
     DOCS_ROOT="$GRIMOIRE/docs/$GROUP/$PROJ"
     PROJECT_ID="$GROUP/$PROJ"
   else
     PROJ=$(basename "$CWD" | tr '[:upper:]' '[:lower:]')
     DOCS_ROOT="$GRIMOIRE/docs/$PROJ"
     PROJECT_ID="$PROJ"
   fi
   # Raw-source root: the active plan is a single LOCAL file (so you can @-mention it).
   REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
   RAW_ROOT="$REPO_ROOT/grimoire"
   if [ "$RAW_ROOT" -ef "$GRIMOIRE" ] 2>/dev/null; then RAW_ROOT="$DOCS_ROOT"; fi
   PLAN_FILE="$RAW_ROOT/plan.md"
   PR_FILE="$RAW_ROOT/pr.md"      # PR draft, written at wrap-up (see "PR draft and daily update")
   ```
2. Locate the plan. There is **one active plan per repo/worktree**, the single local file `$PLAN_FILE` (`<repo-root>/grimoire/plan.md`). No partial-name matching, `$ARGUMENTS` is ignored.
   ```bash
   if [ ! -f "$PLAN_FILE" ]; then
     echo "No active plan at $PLAN_FILE, run /plan first."   # then stop
   fi
   ```
3. Read the plan file (use `read`, we will edit it later). If the plan references project ADRs or context in its Context section, load those via `ctx_batch_execute` to avoid flooding context with raw reads.

   **Detect phased vs single-phase (structural, not a keyword).** If the plan contains a literal `## Phases` section, it is **phased**: follow the **Phased execution** section below instead of steps 4 to 8, then stop. A plan that merely mentions "phase" in prose is *not* phased. With no `## Phases` section, the plan is single-phase, continue with steps 4 to 8.
4. Add all tasks to the todo overlay. Then capture a **start-of-run baseline** before editing anything, using the same non-mutating snapshot mechanism as a phase baseline (see **Phased execution → 2. Set the phase baseline**), under the ref `refs/grimoire/baseline/<plan-slug>-run`. This scopes the run's commit proposal later. Non-mutating, so the user's index and the manual-git invariant are untouched.
5. Execute each task one by one. After completing each task:
   - **Before writing code against a third-party library or framework whose current API matters** (a recent version, an unfamiliar call), optionally ground it in current docs via context7 (`resolve-library-id` → `get-library-docs`) to avoid hallucinated or outdated signatures. Keep it contained: pull only the topic you need, or `ctx_fetch_and_index` the docs page then `ctx_search`. Skip for std-lib or stable code.
   - Run the task's `verify:` condition to confirm it actually worked
   - If verification fails, fix it before moving on, do not tick off an unverified task
   - Mark it done in the todo overlay only after verification passes
   - Update the plan file: `- [ ]` → `- [x]`
6. **Self-review the change (reflect).** Before archiving, review your own work once across the same lenses as `/review`, so structural and convention issues get caught here, not by you later. Scope the review to this run's changes via the tree-vs-tree form against the `-run` baseline (see **Propose commit(s) → Scope the run's changes**), so pre-existing dirt and unrelated edits stay out. Adapt depth to the diff: skip for a trivial one-file change, run it for anything non-trivial. See **Self-review (reflect)** below.
7. When all tasks are complete and the self-review is resolved, first **propose commit(s) for this run** (scope to the `-run` baseline ref, see **Propose commit(s)**; propose-only). Then update plan `**Status:** Done`, clean up the run baseline ref, and **prune the plan file** (full prune, no archive; its durable value is distilled into the wiki in step 8):
   ```bash
   # Stable slug from the plan title — plan.md's basename is not unique across worktrees (they share one .git)
   PLAN_SLUG=$(grep -m1 '^# ' "$PLAN_FILE" | sed 's/^# *//;s/[^A-Za-z0-9 -]//g' | tr '[:upper:] ' '[:lower:]-' | cut -c1-40)
   [ -z "$PLAN_SLUG" ] && PLAN_SLUG="plan"
   for ref in $(git for-each-ref --format='%(refname)' "refs/grimoire/baseline/${PLAN_SLUG}-"*); do
     git update-ref -d "$ref"
   done
   rm -f "$PLAN_FILE"   # prune on Done
   ```
8. **Distil into the wiki layer (draft → confirm).** The finished plan is a *raw source*; now compile its durable knowledge into the distilled wiki so future work benefits. (See the "Compiled Wiki Layer" section of `$GRIMOIRE/AGENTS.md` and the page formats in `$GRIMOIRE/templates/{CONCEPT,COMPONENT,LESSON,GOTCHA,INDEX}-FMT.md`.)
   - Re-read the finished plan **and the actual diff** (`ctx_execute(shell, "git diff …")`). Identify durable knowledge: a mechanism learned → **concept**; a module created/heavily touched → **component**; a non-obvious root cause or rejected approach → **lesson**; a sharp trap → **gotcha** entry.
   - For each, decide **new page vs. update existing**, check `$DOCS_ROOT/{concepts,components,lessons}/` and `$DOCS_ROOT/gotchas.md`. Never duplicate; revise in place.
   - Draft each page with a mandatory `Source:` that **names** the originating plan/branch/task plus durable anchors (`path:line`/PR/commit); do **not** link the plan file (it is local and pruned on Done, so a `[[plan]]` link would dangle). Add `Status:`/`Updated:`, and `[[wikilinks]]` to related distilled pages. Draft the matching `index.md` entries and any backlinks on existing pages.
   - **Present the drafts as a confirm batch**, list each proposed page (NEW or UPDATE) with a one-line summary. Do **not** write until the user approves. On `approve`: write the pages, update `$DOCS_ROOT/index.md`, and `ctx_index` each with its `$PROJECT_ID:<type>` source (e.g. `:concepts`, `:gotchas`, `:index`). On `revise: <note>`: adjust and re-present.
   - If the change produced nothing durable (trivial fix), **say so and skip**, never manufacture pages.
   - After the wiki pages are written (or skipped) and the plan is pruned, **propose the final doc-commit** covering the wiki changes (the plan file is local + gitignored, so it never appears in any commit), see **Propose commit(s) → Final doc-commit**.
9. **Draft the PR and a daily update.** As the last wrap-up step, draft a `pr.md` from the project's PR template (if any) and a 1-2 line daily-update message. See **PR draft and daily update** below.

## Execution guidelines

- Make the minimum change that solves the problem, nothing speculative
- Touch only what the task requires, don't improve adjacent code or reformat unrelated things
- Match the existing code style
- Remove imports/variables/functions your changes made unused
- If you notice a simpler approach mid-execution, mention it but keep going unless it changes scope

## Self-review (reflect)

After all tasks pass their `verify:`, run one self-review pass on the change before archiving. This catches structure, naming, and convention issues that `verify:` conditions (which are functional) do not. Skip it for a trivial one-file change; run it for anything non-trivial.

1. **Review the diff once.** Get the diff: when the caller scopes to a baseline (a phase baseline, or the single-phase `-run` baseline), use that run's **tree-vs-tree** diff (see **Propose commit(s) → Scope the run's changes**) so pre-existing dirt stays out; for an ad-hoc review with no baseline, fall back to `ctx_execute(shell, "git diff -U3 -- . :(exclude)*lock.json :(exclude)dist/* :(exclude)build/*")`. Review across the `/review` lenses: correctness, quality/conventions, architecture, tests, security. Load this project's conventions/context and the touched components' gotchas + lessons (`ctx_search` source `$PROJECT_ID:gotchas|lessons|concepts`, or `cat`). Tag each finding Critical / Major / Minor / Nit, and raise it one level if it matches a known gotcha or lesson (name the page).

2. **Surface findings and ask.** Present them grouped by severity, in options style:
   > Self-review found N issues. Fix which?
   > - **fix safe**: I fix the Critical/Major and the clear-cut Minor; you keep the judgment calls
   > - **fix: `<ids>`**: fix only the ones you name
   > - **skip**: leave them and proceed (they are still noted at wrap-up)
   >
   Fix nothing until the user chooses. If there are zero findings, say so and proceed.

3. **Apply approved fixes.** Minimum change per finding, same discipline as the tasks: touch only what the fix needs, match the surrounding style, remove anything the fix made unused.

4. **One re-check (bounded loop).** After applying fixes, re-review only the changed lines and re-run the `verify:` of any task whose code you touched.
   - **Clean**: done, proceed to archive and distil.
   - **A fix introduced a new issue**: surface it and stop. Do not auto-loop again.
   - **A prior finding reappears after its fix** (recurring-finding tripwire): stop and surface it; the fix is not converging, so the user decides.

   Never run more than this one automatic re-check. Beyond it, the user drives.

## PR draft and daily update

The final wrap-up step, after distillation and the doc-commit proposal. Both artifacts are drawn from the **same material**: the plan `Goal:`, the run's cumulative diff (the tree-vs-tree form, see **Propose commit(s) → Scope the run's changes**), and the plan/phase `Notes:`. Do not invent facts (ticket numbers, PR links, deploy order, screenshots), leave the template's placeholders for the user to fill.

### 1. Draft `pr.md` from the project's template

1. **Find the template** (first match wins, case-insensitive):
   ```bash
   PR_TEMPLATE=$(find .github docs . -maxdepth 2 -iname 'pull_request_template.md' 2>/dev/null | head -1)
   # also a multi-template dir: .github/PULL_REQUEST_TEMPLATE/*.md (prefer default.md, else the first)
   [ -z "$PR_TEMPLATE" ] && PR_TEMPLATE=$(find .github -maxdepth 2 -ipath '*pull_request_template/*.md' 2>/dev/null | sort | head -1)
   ```
2. **Fill it.** Copy the template **verbatim**, then complete only the prose sections (summary / what changed / why / type of change / test scenarios) from the run's material. **Keep every section and checklist**, tick a checkbox only when you can do so truthfully (e.g. tests added); leave the rest unchecked and leave placeholders (`<ticket>`, PR links, deploy order, screenshots) untouched for the user.
3. **No template found** → fall back to a minimal structure:
   ```markdown
   ## Summary
   ## What changed
   ## Why
   ## How to test
   ```
4. **Write it.** Write the filled draft to `$PR_FILE` (`<repo-root>/grimoire/pr.md`), overwriting any previous. Like `plan.md` and `review.md` it is local, gitignored (via the global `grimoire/` ignore), and `@`-mentionable. Open it:
   ```bash
   mkdir -p "$RAW_ROOT"
   code "$(pwd)" "$PR_FILE" 2>/dev/null || echo "  saved: $PR_FILE"
   ```

### 2. Daily-update message

Also produce a short **daily-update** message (think standup) for the user to paste. Keep it in the **same style as `/review`'s daily update** so the two feel consistent:

- **Plain and simple English.** Friendly, direct, no jargon, no section headers, no bullet lists.
- **Never mention CI, checks, pipelines, or build status.**
- **Lead with the PR title** (the `pr.md` title just drafted), then say what the PR actually does in **1-2 lines** so a reader who never opened it knows what changed and why. Draw it from the run's cumulative diff and the plan `Goal:`/`Notes:`, not a file-by-file log. Append `(#<num>)` only if a PR number already exists; otherwise omit it.

Present it in its own fenced block, clearly labelled as the thing to paste:

```
Daily update (paste in standup):
> Wrapped up <PR title>. <1-2 lines on what changed and the user-facing or technical payoff>.
```

## Propose commit(s)

After a phase completes (phased) or a single-phase run finishes its self-review, gg **proposes** a commit for that run's work and lets the user run it. gg never runs `git commit` itself and never `git add -A` (the manual-git invariant). A proposal reflects the working tree at the moment it is generated; if the user keeps editing before running it, the proposal can go stale.

### Scope the run's changes (tree-vs-tree)

A bare `git diff <baseline ref>` compares a tree to the working tree and **omits untracked files**, so it would silently drop files the run created. Instead snapshot the current tree the same non-mutating way the baseline was taken, then diff the two trees:

```bash
SCRATCH=$(mktemp -u)
GIT_INDEX_FILE="$SCRATCH" git add -A
CUR=$(GIT_INDEX_FILE="$SCRATCH" git write-tree)
rm -f "$SCRATCH"
BASE=$(git rev-parse <the run's baseline ref>)   # phase baseline, or the single-phase run baseline
git diff --name-only "$BASE" "$CUR"              # files changed by this run, new files included
git diff "$BASE" "$CUR" [-- <file>]              # the run's patch (whole run, or one file)
```

`git diff <tree> <tree>` compares two full snapshots, so files the run created appear as additions. This same tree-vs-tree form is what the cumulative distillation diff uses.

### Build the proposal

1. **Files.** Take the run's changed-file list above. The plan file (`grimoire/plan.md`) is local and **gitignored**, so it never appears in the tree-vs-tree diff or any `git add`, so no special exclusion is needed.
2. **Subject.** Infer the subject style from recent history (`git log --oneline -10`); if there is no history yet, fall back to a plain imperative subject (e.g. `Add <thing>`). Keep it short.
3. **Body.** Draw the "why" from the phase's `Notes:` (phased) or the plan `Goal:` (single-phase), plus what changed.
4. **Commands.** Emit copy-pasteable commands for the user to run or edit, do not run them:
   ```bash
   git add <files of this commit>
   git commit -m "<subject>" -m "<body>"
   ```

### Mixed files (pre-existing dirt)

A file is **mixed** when it was already dirty before the run, i.e. it appears in `git diff HEAD <baseline ref> --name-only` (it differs between `HEAD` and the baseline tree). A whole-file `git add <file>` would also stage the user's unrelated prior edits, so do **not** propose a plain add for it. Flag it and show its run-scoped patch (`git diff "$BASE" "$CUR" -- <file>`) so the user can stage just the run's hunks with `git add -p <file>`. (Known limitation: if the mixed file was *untracked* at baseline, `git add -p` needs a prior `git add -N <file>`.)

### Multiple commits (file-disjoint split)

Default to **one** commit per run. When the run's changes fall into clearly separable concerns that map to **disjoint file sets**, propose a grouped split instead, one `git add <group> && git commit` per group, each with its own subject and body. Concerns that share a file cannot be split at the file level: keep them in one commit, or flag that file for manual `git add -p`. Never propose a split that would need the same file in two commits.

### Final doc-commit (after distillation)

The per-run proposal covers code/work only. After end-of-ticket distillation has written the wiki pages (and the local plan file has been pruned), propose **one** final doc-commit **in the GRIMOIRE docs repo** (`$GRIMOIRE/docs`, where the vault lives) covering those doc changes. The pruned plan was local + gitignored, so it never enters this commit (no rename to stage):

```bash
git add <distilled pages: concepts/…, gotchas.md, index.md, …>
git commit -m "docs: distil <ticket> into the vault"
```

## Phased execution

When the plan has a `## Phases` section (detected in step 3), `/gg` runs **one ready phase per session**, marks it done, and stops with a resume handoff so the next phase starts in a clean context. Single-phase plans never enter this section. State lives entirely in the plan file (per-phase `Status`, `Baseline`, `Notes`, plus task checkboxes), no separate state file.

### 1. Pick the phase to run, or report the plan's state

Scan the phases and decide before touching anything:

- **All phases `Status: done`** → the ticket is complete. Do **not** error. Run the final self-review if not already resolved, then go to *End of ticket* below (distil + archive).
- **A phase is `pending` and every phase in its `Depends on` is `done`** → that is the phase to run. If several qualify, take the first in file order.
- **Phases remain but none is runnable** (a dependency cycle, a `Depends on` that is still `pending`, or a `Depends on` naming a phase that does not exist) → **stop and surface the exact offending phases by name**; do not loop, stall, or guess. The user fixes the plan.

### 2. Set the phase baseline (non-mutating working-tree snapshot)

When the chosen phase has an empty `**Baseline:**`, snapshot the **full** working tree (including untracked files) without touching the user's real index, then anchor it under a ref so it survives gc on a long ticket:

```bash
SCRATCH=$(mktemp -u)
GIT_INDEX_FILE="$SCRATCH" git add -A
TREE=$(GIT_INDEX_FILE="$SCRATCH" git write-tree)
rm -f "$SCRATCH"
# Stable slug from the plan title (plan.md's basename is not unique across worktrees sharing one .git)
PLAN_SLUG=$(grep -m1 '^# ' "$PLAN_FILE" | sed 's/^# *//;s/[^A-Za-z0-9 -]//g' | tr '[:upper:] ' '[:lower:]-' | cut -c1-40)
[ -z "$PLAN_SLUG" ] && PLAN_SLUG="plan"
N=<the chosen phase's number, e.g. 1, 2>
git update-ref "refs/grimoire/baseline/${PLAN_SLUG}-phase${N}" "$TREE"
```

Use the **chosen phase's own number** for `${N}` so each phase gets a distinct ref (`-phase1`, `-phase2`, ...); a literal `phaseN` would make every phase overwrite the same ref and break per-phase and cumulative diffs. Record `refs/grimoire/baseline/${PLAN_SLUG}-phase${N}` as that phase's `**Baseline:**` in the plan file. This never stages anything in the user's index and respects the manual-git invariant. If the phase already has a `Baseline` (a resumed phase), reuse it, do not re-snapshot.

- That phase's diff and the cumulative diff are taken **tree-vs-tree** (snapshot the current tree, then `git diff <baseline-tree> <current-tree>`) so files the run created are included; see **Propose commit(s) → Scope the run's changes**. A bare `git diff <baseline ref>` omits untracked files. The phase diff uses its own baseline ref; the cumulative diff uses the first phase's baseline ref.

### 3. Run the phase (resumable)

1. Add the phase's tasks to the todo overlay.
2. **Re-verify already-checked tasks.** For each `- [x]` task in this phase, re-run its `verify:`. If it now fails, un-check it (`- [x]` → `- [ ]`) and run it again. This makes a mid-phase kill resumable without redoing still-passing work.
3. Run each remaining `- [ ]` task with the same execution discipline as a single-phase plan (minimum change, match style, run `verify:`, only tick `- [x]` after `verify:` passes).
4. **Per-phase self-review (reflect).** Run the **Self-review (reflect)** pass above, scoped to this phase's diff (the tree-vs-tree form against its baseline ref, see **Propose commit(s) → Scope the run's changes**), not deferred to the end. Resolve it as usual before marking the phase done.
5. **Record per-phase notes.** Fill the phase's `**Notes:**` with the decisions made, gotchas discovered, and surprises from this phase, so the rationale survives even after this session is compacted. End-of-ticket distillation reads these notes.
6. Set the phase's `**Status:** done`.
7. **Propose commit(s) for this phase.** Scope to this phase's baseline ref and propose the commit(s), see **Propose commit(s)**. Propose-only; the user runs them.

### 4. Offer downstream-phase revision

If running this phase changed the picture (an assumption broke, the approach shifted, a later phase now looks wrong), prompt before continuing:

> Phase N is done. Its outcome may affect later phases. Revise the remaining phases now, or proceed as planned?

The plan is a living document (refinement mode applies). Fold any approved revisions into the remaining phases. Declining proceeds normally.

### 5. Stop with a resume handoff

If phases still remain, do **not** continue into the next phase and do **not** distil or archive yet. Stop and tell the user:

> Phase N done and marked. For a clean window, run `/compact` or start a new session, then `/gg <plan>` for the next phase.

(A skill cannot auto-compact or spawn a session, so the cross-session break is a prompted user action.)

### End of ticket (only when every phase is `done`)

Reached only when step 1 found all phases `done`. Gate both steps on **every** phase being `done`, not on file order or position.

1. **Distil from the cumulative diff plus per-phase notes.** Intermediate phases skip distillation entirely; it runs once here. Distil the whole ticket from the cumulative diff (the **tree-vs-tree** form against the first phase's baseline ref, so new files are included, see **Propose commit(s) → Scope the run's changes**) **and** every phase's `**Notes:**`, so a fresh session that never saw the earlier phases recovers both *what* changed and *why*. Follow the same draft → confirm flow as step 8 above.
2. **Prune the plan and clean up baseline refs.** Set the plan `**Status:** Done`, remove this plan's baseline refs, then **prune the plan file** (full prune, no archive). Re-derive `PLAN_SLUG` here, since a fresh all-done session never ran section 2, and grep the title *before* pruning:
   ```bash
   PLAN_SLUG=$(grep -m1 '^# ' "$PLAN_FILE" | sed 's/^# *//;s/[^A-Za-z0-9 -]//g' | tr '[:upper:] ' '[:lower:]-' | cut -c1-40)
   [ -z "$PLAN_SLUG" ] && PLAN_SLUG="plan"
   for ref in $(git for-each-ref --format='%(refname)' "refs/grimoire/baseline/${PLAN_SLUG}-"*); do
     git update-ref -d "$ref"
   done
   rm -f "$PLAN_FILE"   # prune on Done
   ```
3. **Propose the final doc-commit.** After the wiki pages are written and the plan is pruned, propose the doc-commit covering those wiki changes (no plan rename to stage), see **Propose commit(s) → Final doc-commit**.
4. **Draft the PR and a daily update.** As the last wrap-up step, draft a `pr.md` from the project's PR template (if any) and a 1-2 line daily-update message, derived from the cumulative diff plus every phase's `Notes:`. See **PR draft and daily update** below.
