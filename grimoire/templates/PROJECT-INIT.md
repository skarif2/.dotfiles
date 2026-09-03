# Project Initialisation

When a skill writes its first file for a project, create the necessary folders on demand. Nothing is pre-created.

## Folder structure

All knowledge lives under `$GRIMOIRE/docs/`, mirroring `~/Projects/`:

```
$GRIMOIRE/docs/
├── {group}/                    ← e.g. saga, craftsmen, personal
│   ├── index.md                ← group-level catalog of shared distilled pages
│   ├── context/                ← group-level shared context (API contracts, cross-project terms)
│   ├── adr/                    ← group-level shared decisions
│   ├── concepts/               ← group-level shared concepts
│   └── {project}/              ← e.g. frontend, netcheck, adlc
│       ├── index.md            ← MAP: catalog of this project's distilled pages (read first)
│       │                          ── distilled wiki layer (durable, interlinked, read later) ──
│       ├── context/            ← glossary / domain terms
│       ├── adr/                ← decisions
│       ├── concepts/           ← how-it-works domain knowledge (concept_{slug}.md)
│       ├── components/         ← entity pages for real modules (component_{slug}.md)
│       ├── lessons/            ← what-we-learned takeaways (lesson_{slug}.md)
│       ├── gotchas.md          ← single file of one-line traps (### entries)
│       │                          ── raw source layer (episodic) ──
│       └── handoffs/             ← multiple per project; deleted when a plan is created
```

**Plans and reviews are NOT stored centrally.** They are local single working files in the project itself, so you can `@`-mention them:

```
<repo-root>/grimoire/          ← gitignored; anchored at the git repo/worktree root
├── plan.md                    ← the one active plan; pruned on Done
└── review.md                  ← the latest review; overwritten each run
```

**Two layers, one boundary.** The **raw source** layer is *never* listed in `index.md`: **handoffs** live centrally here, while **plans and reviews** are local single working files in the project (`<repo-root>/grimoire/plan.md` and `review.md`, gitignored): the plan is pruned on Done, the review overwritten each run. The **distilled wiki** layer (`context/`, `adr/`, `concepts/`, `components/`, `lessons/`, `gotchas.md`) is compiled *from* the raw layer at ticket close (draft → user confirms), is fully interlinked with `[[wikilinks]]`, carries provenance + freshness markers (provenance **names** the raw source, never links it), and *is* what the AI loads on future work. `index.md` is the map between them.

## Detecting the project path

```bash
: "${GRIMOIRE:?GRIMOIRE is unset; export it in ~/.zshenv. Never go looking for it: a home-wide find walks Desktop, Documents and the Photos library, and macOS prompts for each.}"
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
```

## Lazy creation rules

Create directories only when about to write into them — never speculatively:

| Writing a… | Create if missing |
|---|---|
| Plan file (local) | `<repo-root>/grimoire/` → single `plan.md`, pruned on Done |
| Review file (local) | `<repo-root>/grimoire/` → single `review.md`, overwritten each run |
| ADR | `$DOCS_ROOT/adr/` |
| Context file | `$DOCS_ROOT/context/` |
| Concept page | `$DOCS_ROOT/concepts/` |
| Component page | `$DOCS_ROOT/components/` |
| Lesson page | `$DOCS_ROOT/lessons/` |
| Gotcha entry | `$DOCS_ROOT/gotchas.md` (single file) |
| Index | `$DOCS_ROOT/index.md` (single file) |
| Handoff file | `$DOCS_ROOT/handoffs/` |
| Group-level context/ADR/concept | `$SHARED_ROOT/context/`, `$SHARED_ROOT/adr/`, or `$SHARED_ROOT/concepts/` |

## Template references

Before writing any file, load the relevant format template:

| File type | Template |
|---|---|
| Index | `$GRIMOIRE/templates/INDEX-FMT.md` |
| ADR | `$GRIMOIRE/templates/ADR-FMT.md` |
| Context file | `$GRIMOIRE/templates/CONTEXT-FMT.md` |
| Concept | `$GRIMOIRE/templates/CONCEPT-FMT.md` |
| Component | `$GRIMOIRE/templates/COMPONENT-FMT.md` |
| Lesson | `$GRIMOIRE/templates/LESSON-FMT.md` |
| Gotcha | `$GRIMOIRE/templates/GOTCHA-FMT.md` |
| Handoff | `$GRIMOIRE/templates/HANDOFF-FMT.md` |
| Plan | `$GRIMOIRE/templates/PLAN-FMT.md` |
| Review | `$GRIMOIRE/templates/REVIEW-FMT.md` |
