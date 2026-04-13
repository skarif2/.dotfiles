# AI Core Hub

This directory (`~/.dotfiles/ai-core/`) centralizes all custom LLM rules, shortcuts (`!fa`, `!da`), and modular tools ("skills") into a single repository.

By using simple symlinks and aliases, we ensure that every AI agent you use (Gemini, Pi, Claude-Code, etc.) reads from this exact same directory. Update a rule or download a skill once, and it instantly syncs across all your terminal agents.

## Directory Structure

- `master-rules.md`: The global rules file containing system prompts, definitions of shortcuts like `!fa`, and caveman mode defaults.
- `skills/`: The folder containing all Markdown-based tools and executable snippets.
- `setup-ai.sh`: The installer script that re-binds agents to this hub if you move to a new machine.

---

## Adding New Agents in the Future

If you adopt a new agent (e.g., `claude-code`, `open-code`), follow this exact 3-step playbook to integrate them into AI Core:

### Step 1: Identify the Agent's Native Path

Where does the new agent look for instructions out of the box?

- Does it look for a global config file? (e.g., `~/.claude-code/config.md`)
- Does it look for a skills folder? (e.g., `~/.opencode/skills/`)
- Or does it only accept rules via a CLI flag? (e.g., `--system-prompt`)

### Step 2: Establish the Link

Based on Step 1, connect the agent to AI Core.

**If they read a global rules file:**

```bash
ln -s ~/.dotfiles/ai-core/master-rules.md ~/.new-agent/config.md
```

**If they read a skills folder:**

```bash
ln -s ~/.dotfiles/ai-core/skills ~/.new-agent/skills
```

**If they only take CLI flags for rules:**  
Add an alias to your `~/.zshrc`:

```bash
alias cl="cl --system-prompt ~/.dotfiles/ai-core/master-rules.md"
```

### Step 3: Update `setup-ai.sh`

Always map your success back to the installer. Once you figure out the exact symlink or bash logic from Step 2, open `setup-ai.sh` and add a new section for the agent. This ensures if you clone your dotfiles to a fresh MacBook, running `setup-ai.sh` configures the new agent perfectly on day one.
