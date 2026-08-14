# Working with Arif

## About me

Fazlul Haque Arif, call me Arif. Software engineer, 11+ years.
Senior SWE at Craftsmen Ltd (craftsmensoftware.com), 7 years.
Craftsmen: software team extension for companies in Europe, UK, US.
I work with Saga (saganews.com), a Norwegian team under Fonn Group (fonngroup.com).

Assume I know my stuff. Skip basics.

## How to talk to me

**No dashes as punctuation.** No em dash (U+2014), no en dash (U+2013), no `--`. Chat, code, commits, plans, reviews, ADRs, PR text, everything you write for me. Use a comma, colon, parentheses, or end the sentence. Hard rule, no exceptions. Not punctuation, so fine: `--verbose`, CSS custom properties, `i--`.

**ASCII only** in files you write for me. No box-drawing, no arrows, no typographic quotes, no middots. Draw trees with indentation. Write `->` and `<-` if you need an arrow.

- Answer first. No "Great question", no preamble, no restating the question.
- Short unless I ask for depth.
- No closing summary of what you just said. Stop when the answer is done.
- Prose by default. Bullets only for real lists.
- Say "I don't know" plainly. Never guess to fill the gap.

> Claude Code only (PI ignores): `AskUserQuestion` labels max 5 words, descriptions max 1 sentence, never raw tool output in options. The box is harness-rendered and unthemeable, so readability is all content.

## Code

- No comments unless necessary. A comment explains *why*, never *what*. Max 3 lines.
- Show the tradeoff you rejected, not just the one you picked.

# GRIMOIRE

## OS

macOS, `zsh`, Homebrew (`brew`) for system packages.

## Project knowledge structure

Lives under `$GRIMOIRE/docs/`, mirroring `~/Projects/`. Path detection and lazy folder rules: `$GRIMOIRE/templates/PROJECT-INIT.md`.

```
$GRIMOIRE/docs/
  {group}/                  saga, craftsmen, personal
    index.md, context/, adr/, concepts/     group-level shared distilled pages
    {project}/              frontend, netcheck, adlc
      index.md              the MAP. Catalog of distilled pages. READ FIRST, then drill in
      [distilled wiki: durable, interlinked, read every task]
      context/, adr/, concepts/, components/, lessons/, gotchas.md
      [raw source, central]
      handoffs/             from /handoff, deleted once /plan supersedes it (confirm first)

<repo-root>/grimoire/       raw sources. Repo/worktree-local, gitignored, @-mentionable
  plan.md                   one active plan per repo/worktree. /gg prunes it on Done
  review.md                 /review overwrites each run
  pr.md                     /gg overwrites each run
```

Vars, derived from cwd:
- `DOCS_ROOT` project docs, `$GRIMOIRE/docs/saga/frontend`
- `SHARED_ROOT` group pool, `$GRIMOIRE/docs/saga`
- `RAW_ROOT` repo-local raw, `<repo-root>/grimoire`, falls back to `DOCS_ROOT` when the repo *is* the toolkit
- `PROJECT_ID` ctx label, `saga/frontend`

Session start:
1. **Read `$DOCS_ROOT/index.md` first.** It is the map. Pick pages by their one-line summaries, open only those, follow their `[[wikilinks]]`. Cheaper than scanning everything.
2. Load `$DOCS_ROOT/context/`, `$DOCS_ROOT/adr/`, the pages the index pointed to. Same for `$SHARED_ROOT/index.md`, `context/`, `adr/`.
3. `ctx_search(queries: ["<task keywords>"], source: "$PROJECT_ID")`. Secondary to the index, not a replacement.

## Knowledge indexing

Skills index files as they create them. Label is `$PROJECT_ID:<suffix>` (e.g. `saga/frontend:adr`).

Suffixes: `plans` `adr` `context` `concepts` `components` `lessons` `gotchas` `index` `handoffs`, plus `patterns` (review patterns) and `reviews` (review summaries).

`:plans` and `:reviews` index local files that do not persist: `plan.md` is pruned on Done, `review.md` is overwritten every run. Chunks outlive the file. Treat those hits as history, not truth, and confirm against the live file or the wiki before acting. `/reindex` rebuilds from disk.

## Templates

Load the matching format template from `$GRIMOIRE/templates/` before writing any knowledge file: `INDEX-FMT` `ADR-FMT` `CONTEXT-FMT` `CONCEPT-FMT` `COMPONENT-FMT` `LESSON-FMT` `GOTCHA-FMT` `HANDOFF-FMT` `PLAN-FMT` `REVIEW-FMT` (all `.md`).

## Compiled wiki layer

Two layers, hard boundary (Karpathy's LLM-wiki pattern).

**Raw sources.** Episodic inputs to distillation. **Never listed in `index.md`.**
- Local, in-repo, gitignored, `@`-mentionable: `$RAW_ROOT/plan.md` (one active plan per repo/worktree, pruned on Done), `review.md` and `pr.md` (overwritten each run; for a PR, GitHub is the durable record). Written by `/plan`, `/gg`, `/review`.
- Central: `$DOCS_ROOT/handoffs/`, many per project, deleted when a plan is created. Written by `/handoff`.

**Distilled wiki.** `context/` `adr/` `concepts/` `components/` `lessons/` `gotchas.md`. Durable, interlinked, kept current. Compiled *from* raw sources. This is what future sessions load.

**Map.** `index.md`. Every distilled page, one line each. Read first.

**Distillation** runs at ticket close, inside `/gg` and `/review`: read the raw source just produced, **draft** new/updated pages plus `index.md` entries plus backlinks, **present for confirmation**. Never auto-write the wiki. The failure mode is stale synthesis masquerading as truth.

Every distilled page carries:
- `Source:` naming the originating plan/branch/task as plain text, **not** a `[[link]]` (raw files get pruned, the link would dangle), plus durable anchors (`file:line`, PR, commit).
- `Status:` current | needs-verification | stale, and `Updated:` date.
- Wikilinks: `[[concept_slug]]` `[[component_slug]]` `[[adr_slug]]` `[[gotchas#heading]]`. No inbound or outbound link means orphan, lint flags it.
- An `index.md` entry, written in the same pass.

Naming: `concept_{slug}.md` `component_{slug}.md` `lesson_{slug}.md` `adr_{slug}.md` `context_{slug}.md`. Gotchas are `###` entries inside one `gotchas.md`.

## Phased plans

Phased **only** when the plan holds a literal `## Phases` section. Detection is structural, never a keyword in prose. No section means single-phase.

Each phase carries `**Depends on:**`, `**Status:** pending | done`, `**Baseline:**`, `**Notes:**`, and its own `verify:`-bearing task list (`templates/PLAN-FMT.md`). One phase per session, clean context.

Two invariants, everywhere, not just inside `/gg`:
- **Never auto-commit.** Propose the message plus copy-pasteable `git add ... && git commit` scoped to that run's files. Never run it. Never `git add -A`. The user drives git.
- **Never auto-write the wiki.** Draft, confirm, then write.

`/gg` owns the mechanics: phase selection, working-tree baselines, tree-vs-tree diffs, resumability, per-phase notes, self-review, deferred distillation, archive. See `prompts/gg.md`, the single source of truth. Do not restate it here.

# context-mode, MANDATORY routing

Protects the context window. One unrouted command can dump 56 KB.

## Think in code, MANDATORY

Analyzing, counting, filtering, comparing, processing? Write code via `ctx_execute(language, code)` and `console.log()` the answer only. Never read raw data into context. Pure JS, Node built-ins only (`fs`, `path`, `child_process`). Always `try/catch`, handle `null`/`undefined`.

## BLOCKED

- `curl` / `wget` -> `ctx_fetch_and_index(url, source)`
- Inline HTTP (`node -e "fetch(..."`, `python -c "requests.get(..."`) -> `ctx_execute(language, code)`
- Any direct web fetch -> `ctx_fetch_and_index`, then `ctx_search`

## REDIRECTED

The test is **intent and volume**, not a command allowlist.

- **Bash** when *observing* short fixed output (`git status` on a clean tree, `pwd`, a five-line `ls`) or *mutating* state (`git`, `mkdir`, `rm`, `mv`, `cd`, `npm install`, `pip install`).
- **Sandbox** when *processing* output (filter, count, parse, aggregate) or when it could run past ~20 lines: `ctx_batch_execute(commands, queries)` for several commands, `ctx_execute(language: "shell", code)` for one.
- `grep` / `find`: targeted hit in bash, wide sweep in the sandbox.
- Reading to analyze -> `ctx_execute_file(path, language, code)`. Use `read` only when you intend to edit, since Edit needs the exact bytes.

## Tool selection

0. **Resume** -> `ctx_search(sort: "timeline")` before asking the user anything.
1. **Gather** -> `ctx_batch_execute(commands, queries)`. Runs all, auto-indexes, returns hits. One call replaces many.
2. **Follow-up** -> `ctx_search(queries: [...])`. Batch every question into one call.
3. **Process** -> `ctx_execute` / `ctx_execute_file`. Only stdout enters context.
4. **Web** -> `ctx_fetch_and_index`, then `ctx_search`. Raw HTML never enters context.
5. **Store** -> `ctx_index(content, source)`.

## Parallel I/O

Always pass `concurrency: N` (1-8) for multi-URL fetches or multi-API calls. 4-8 for I/O-bound work (network, API, `gh`). 1 for CPU-bound (test, build, lint) or shared state. GitHub API caps at 4.

## Output

Two disciplines. The first must not suppress the second.

**Context**: raw bytes stay OUT. Artifacts go to files, never inline; return the path plus one line. Process in the sandbox, surface the result.

**Presentation**: format what you do surface. Concise is not the same as unstyled. Under *Prose by default*: structure structured content (multi-field results to a table, code/paths/commands in backticks or fences, grouped findings under `##`), plain prose otherwise. **Bold** key terms.

## Session continuity

Skills, roles, and decisions persist until revoked. Do not drop them as context grows.

On resume, search before asking: `ctx_search(queries: ["decision"], sort: "timeline")` and `ctx_search(queries: ["constraint"])`. No results means fresh session.

## ctx commands

`ctx stats` savings and session stats. `ctx doctor` runtimes, hooks, FTS5, versions. `ctx upgrade` update, rebuild, fix hooks. `ctx purge` delete all indexed content, irreversible.

Knowledge base survives /clear and /compact.
