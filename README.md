# .dotfiles

Modern macOS development environment, provisioned by a single command and managed with [GNU Stow](https://www.gnu.org/software/stow/).

## ⚡ One-command install

A fresh Mac is provisioned end-to-end by a single command:

```bash
curl -fsSL https://skarif.dev/dotfiles/install.sh | bash
```

`setup.sh` installs the Xcode Command Line Tools and Homebrew, clones this repo
to `~/.dotfiles`, then hands off to the orchestrator (`lib/orchestrate.sh`). It is
idempotent, so the same command re-syncs an existing checkout.

> **⚠️ Prerequisite: the redirect must be configured first.** The one-liner only
> works once `skarif.dev/dotfiles/install.sh` is set up as an HTTP redirect (302)
> to the entry script. This lives in **external infrastructure, not in this repo**:
>
> ```
> https://skarif.dev/dotfiles/install.sh
>   → https://raw.githubusercontent.com/skarif2/.dotfiles/main/setup.sh
> ```
>
> The target is **`setup.sh`** (the entry script was renamed from `bootstrap.sh`).
> Until this redirect exists and points at `…/main/setup.sh`, the command above
> 404s. With no redirect yet, bootstrap directly from raw instead:
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/skarif2/.dotfiles/main/setup.sh | bash
> ```

> **Two prompts are expected and intentional:** the macOS GUI dialog for the
> Xcode Command Line Tools, and a one-time `sudo` password. App Store apps
> additionally need you to be **signed in to the App Store** (see below); if you
> are not, that step is logged as skipped and the run still completes.

## 📦 What's Inside

### Shell & Prompt

- **[Zsh](https://zsh.sourceforge.io/)** — Fast, default macOS shell configured for simplicity using [Antidote](https://getantidote.github.io/) for fast, lightweight plugin management
- **[Starship](https://starship.rs/)** — Fast, minimal prompt with git status, language versions, and execution time
- **[Carapace](https://carapace-sh.github.io/)** — Multi-shell completion engine with support for 1000+ commands

### Terminal & Window Management

- **[Ghostty](https://ghostty.org/)** — GPU-accelerated terminal emulator
- **[Tmux](https://github.com/tmux/tmux)** — Terminal multiplexer for session management and split panes
- **[AeroSpace](https://github.com/nikitabobko/AeroSpace)** — Tiling window manager for macOS (i3-like)

### Development Tools

- **[Neovim](https://neovim.io/)** — Hyperextensible Vim-based text editor
- **[Volta](https://volta.sh/)** — Hassle-free Node.js version manager using shims (no shell hooks needed)
- **[fzf](https://github.com/junegunn/fzf)** — Fuzzy finder for files, commands, and history
- **[fd](https://github.com/sharkdp/fd)** — Fast, user-friendly alternative to `find`
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** — Blazing fast grep alternative

### AI Agents

- **[Claude Code](https://claude.com/claude-code)** and **[pi](https://pi.dev/)** — both pointed at the shared `grimoire/` vault (skills, prompts, `AGENTS.md`)

## 🎯 Why These Tools?

*Because life's too short for slow shells and janky version managers.*

### Zsh Plugin Management with Antidote

- **Performance**: Antidote compiles the plugin loading script statically, meaning zero overhead during startup compared to heavy frameworks like oh-my-zsh.
- **Simplicity**: Manage plugins declaratively in a simple `zsh/.config/zsh/.zsh_plugins.txt` file.
- **Modern feel built-in**: We use essential plugins like `zsh-autosuggestions`, `fzf-tab`, and `zsh-syntax-highlighting` to get all the benefits of modern shells instantly, without the bloat.
- **Built-in Shell**: Zsh is already the default shell on macOS.

### Volta over fnm/nvm

- **Zero configuration**: No shell hooks, no PATH manipulation on every `cd`
- **Shim-based**: Automatically resolves the correct Node version at execution time
- **Package.json aware**: Reads `engines.node` field for per-project versions
- **Shell-agnostic**: Works identically in any shell

### Starship over oh-my-zsh themes

- **Performance**: Written in Rust, renders in milliseconds (your prompt won't lag behind your typing)
- **Universal**: Same prompt in Zsh, Bash, Fish, PowerShell
- **Minimal by default**: Shows only relevant context (git status, Node version, etc.) — no ASCII art locomotives

## 🛠️ How the install works

The one command above runs two layers. Both are idempotent: re-running pulls the
latest repo and skips anything already in place.

### 1. `setup.sh` (entry point)

The single entry point, self-contained so it can run before the repo exists. It
resolves a terminal handle for its prompts, installs the **Xcode Command Line
Tools** (bounded poll) and **Homebrew**, installs **gum**, clones this repo
**non-recursively** to `~/.dotfiles` (or pulls an existing checkout), then hands
off to the orchestrator. The clone is non-recursive on purpose: the private
`grimoire/docs` submodule is initialised later, once GitHub credentials exist.

### 2. `lib/orchestrate.sh` (orchestrator)

Sources the `lib/*.sh` modules and runs them in a **hard dependency order**.
There is no `set -e`: each step runs under `run_step`, which records failures and
keeps going, then the run ends with an explicit summary (one broken step is
reported, never silently swallowed or allowed to abort the whole run).

| Order | Module | What it does |
|-------|--------|--------------|
| 1 | `brew` | Installs the entire [`Brewfile`](Brewfile) (CLI formulae, GUI casks, the nerd font, taps) in one pass |
| 2 | `stow` | Symlinks every config package into `$HOME` via GNU Stow |
| 3 | `node-agents` | Volta + default Node, then Claude Code and pi |
| 4 | `shell` | Antidote (zsh plugins) and TPM (tmux plugins) |
| 5 | `secrets` | Prompts for MCP tokens (`github-mcp-token`, `context7-api-key`) and stores them in the login Keychain; each is skippable |
| 6 | `wiring` | Runs `grimoire/setup-claude.sh` + `setup-pi.sh` (always), then initialises the private `grimoire/docs` submodule (gated on `gh` auth) |
| 7 | `apps` | App Store apps via `mas` (failure-tolerant) |

The order is load-bearing. In particular, **`stow` precedes `shell`** because
`~/.config/tmux` and `~/.config/zsh` are *folded* stow symlinks into the repo, so
anything that writes into them (TPM, antidote) must run after the symlinks exist;
and **`secrets` precedes `wiring`** because the agents read the tokens it stores.

### Symlinks (Stow)

GNU Stow creates symlinks from `~/.dotfiles/` into your home directory, so edits
in the repo apply immediately and a clean uninstall is `stow -D <package>`:

```bash
~/.dotfiles/zsh/.config/zsh/.zshrc        →  ~/.config/zsh/.zshrc
~/.dotfiles/nvim/.config/nvim/init.lua    →  ~/.config/nvim/init.lua
~/.dotfiles/tmux/.config/tmux/tmux.conf   →  ~/.config/tmux/tmux.conf
...
```

### Agent wiring & the private submodule

`setup-claude.sh` and `setup-pi.sh` are **auth-free** and always run: they only
symlink `skills/`, `prompts/`, and `AGENTS.md` out of this **public** repo and
write local settings. Only the **private** `grimoire/docs` submodule needs
credentials, so it is gated separately: if `gh auth status` fails you are
prompted to `gh auth login`; declining skips just the submodule, leaving the
agent wiring intact. (A green `gh auth status` alone does not configure git's
HTTPS helper, so `gh auth setup-git` runs before the submodule clone.)

### App Store apps

[`Amphetamine`](https://apps.apple.com/app/id937984704) and
[`Second Clock`](https://apps.apple.com/app/id6450279539) install via `mas`. This
step needs you to be **signed in to the App Store** (`mas` cannot sign in for
you). If you are not signed in, the step logs each app as skipped and the run
still completes — sign in and re-run to pick them up.

### Post-install

1. **Restart your shell** or open a new terminal.
2. **Install a Node version** via Volta if you need a specific one: `volta install node@22`.
3. **Install Tmux plugins**: press `Ctrl+Space` then `I` (capital i) inside Tmux.

## 🍴 Forking & Customization

This repo is designed to be forked and personalized.

### Customize Configs

Each directory is a "stow package" containing config files:

```bash
.dotfiles/
├── zsh/                   # Zsh configuration (ZDOTDIR layout under .config/zsh)
├── nvim/                  # Neovim config
├── starship/              # Starship prompt config
├── tmux/                  # Tmux keybindings & plugins
└── ...
```

Edit files directly in `~/.dotfiles/<package>/.config/...`; changes apply
immediately through the symlinks. Commit and push to your fork.

### Add Your Own Package

```bash
mkdir -p ~/.dotfiles/myapp/.config/myapp
echo "my_setting = true" > ~/.dotfiles/myapp/.config/myapp/config.toml
cd ~/.dotfiles && stow myapp
```

### Remove a Tool

```bash
cd ~/.dotfiles
stow -D tmux          # remove symlinks
rm -rf tmux/          # delete the package
```

Then drop its entry from the [`Brewfile`](Brewfile).

## 📁 Repository Structure

```bash
.dotfiles/
├── setup.sh             # Single entry point (served via the redirect; also re-syncs)
├── Brewfile             # Declarative brew formulae, casks, font, taps
├── .stowrc              # Stow config (target = ~/)
├── lib/                 # orchestrate.sh + the mod_* modules (brew, stow, …)
├── grimoire/            # AI agent vault + setup-claude.sh / setup-pi.sh
│
├── aerospace/           # AeroSpace window manager
├── ghostty/             # Ghostty terminal config
├── zsh/ · nvim/ · tmux/ · starship/   # stow packages
└── scripts/             # Custom shell scripts
```

## 🔧 Maintenance

### Update everything

```bash
brew update && brew upgrade
```

### Sync dotfiles across machines

```bash
bash ~/.dotfiles/setup.sh   # idempotent: pulls latest, re-runs, skips what's done
```

### Update Tmux plugins

Press `Ctrl+Space` then `U` inside Tmux.

## 📝 License

MIT — do whatever you want with it.

---

**Happy hacking!** 🎉
