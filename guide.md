# Mac + Claude Code — AI Workstation Setup Guide

> Complete installation guide for tech-literate friends. Covers prerequisites,
> Claude Code, local AI models (Ollama), and a 4-pane iTerm2 workflow.
> Every command block is a literal paste — no substitution required unless noted.

**Estimated time:** 3–4 hours total, most of which is waiting for model downloads.

**RAM tiers used throughout this guide:**

| Tier | RAM | What you get |
|------|-----|-------------|
| 🟢 **Base** | 16 GB+ | Claude Code + small local models (fast/code/embed) |
| 🔵 **Mid** | 32 GB+ | Above + reasoning model + larger fast/code models |
| 🔴 **Full** | 64 GB+ | Above + vision model + 32B code model |

Steps marked 🟢 apply to all tiers. Steps marked 🔵 or 🔴 are additive.

---

## Overview

What you're building:

1. **Claude Code** — Anthropic's official AI coding agent, running in your terminal.
2. **Local AI models via Ollama** — private inference on your Mac, no API calls.
3. **4-pane iTerm2 layout** — four specialised Claude Code sessions in one window,
   each with a locked role, model, and permission set.

The result: one `cc` command launches the right Claude model in each pane, and
`llm-fast "..."` or `llm-code "..."` routes a prompt to the right local model.

Two optional add-ons close the remaining gaps: **pane handoff** (Step 19)
routes work between AUDIT and IMPL automatically, and **Sigil** (Step 20)
gives every pane shared, persistent memory across sessions and projects.

---

## Step 1 — Prerequisites

### 1.1 Homebrew

```bash
# Check if Homebrew is already installed:
command -v brew >/dev/null && echo "Homebrew already installed — skip" || \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to your PATH (Apple Silicon only — skip if already in ~/.zshrc):
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

### 1.2 Node.js (required for Claude Code)

```bash
brew install node
```

### 1.3 iTerm2

```bash
brew install --cask iterm2
```

Open iTerm2 once to complete the initial setup, then continue in it.

---

## Step 2 — Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

### 2.1 Authenticate — browser OAuth (recommended)

```bash
claude login
```

This opens a browser window. Sign in with your Anthropic account (Pro or Max plan).
No API key needed with this method.

<details>
<summary>API key alternative (if you don't have a Pro/Max subscription)</summary>

```bash
export ANTHROPIC_API_KEY="sk-ant-your-key-here"
# Add the above line to ~/.zshrc so it persists across sessions.
```

Get a key at console.anthropic.com → API Keys.
</details>

### 2.2 Verify

```bash
claude --version
```

---

## Step 3 — Local AI Models (Ollama) 🟢

This step sets up local inference — models that run entirely on your machine,
no network required after the initial download.

### 3.1 Install Ollama

```bash
brew install ollama
```

Start the server (runs in the background):

```bash
ollama serve &
```

> **Make it persistent:** `ollama serve &` only runs until you close the
> terminal. For Ollama to stay running across reboots (so `cc` and llm-* aliases
> work without manual server starts), run this once now:
>
> ```bash
> brew services start ollama
> ```

### 3.2 Pull models — choose your tier

Pick the block that matches your RAM. Pull times assume a 100 Mbps connection.

**🟢 16 GB+ (~15 min, ~10 GB)**

```bash
ollama pull qwen3:8b              # ~5 GB — fast daily driver
ollama pull qwen3-coder:7b        # ~4.5 GB — code specialist
ollama pull nomic-embed-text      # ~274 MB — embeddings
```

**🔵 32 GB+ (~40 min, ~23 GB total) — pull these instead of the 8b/7b versions**

```bash
ollama pull qwen3:14b             # ~9 GB — replaces qwen3:8b
ollama pull qwen3-coder:14b       # ~8.5 GB — replaces qwen3-coder:7b
ollama pull nomic-embed-text      # ~274 MB
ollama pull deepseek-r1:8b        # ~5 GB — structured reasoning
```

**🔴 64 GB+ (~90 min, ~55 GB total) — use these instead of the 14b versions**

```bash
ollama pull qwen3:14b             # ~9 GB
ollama pull qwen3-coder:32b       # ~20 GB — replaces qwen3-coder:14b
ollama pull nomic-embed-text      # ~274 MB
ollama pull deepseek-r1:8b        # ~5 GB
ollama pull gemma3:27b            # ~16 GB — vision + heavy reasoning
```

> **RAM note on 16 GB:** The reasoning model (deepseek-r1) competes with
> Claude Code's working set. Omitted intentionally — upgrade tier to enable.

### 3.3 Shell aliases + router

Append the relevant block from `zshrc-snippet.sh` (the Ollama section at the
bottom) to your `~/.zshrc`. See Step 6 for full snippet instructions.

After sourcing, you can use:

```bash
llm-fast "explain this error"        # general queries
llm-code "refactor this function"    # code tasks
llm-reason "think through this"      # 🔵 32 GB+ only
llm-embed "text to embed"            # semantic search / RAG
llm-smart "prompt" code              # router: picks the right model
```

---

## Step 4 — Create 4 iTerm2 Profiles

1. Open **iTerm2 → Settings → Profiles** (`⌘,`).
2. Click **+** four times to create four new profiles.
3. Name and colour them:

| Profile Name | Background Hex | Tab Colour Hex | Role                   |
|--------------|----------------|----------------|------------------------|
| `CC-AUDIT`   | `#0d0b18`      | `#a855f7` (purple) | Evaluation / Auditing  |
| `CC-IMPL`    | `#080f0b`      | `#22c55e` (green)  | Implementation         |
| `CC-PROMPT`  | `#080e10`      | `#06b6d4` (cyan)   | Prompt Engineering     |
| `CC-PLAN`    | `#0d0b00`      | `#f59e0b` (amber)  | Planning / Architecture|

For each profile:

### Colors tab
- Click the **Background** colour swatch (in the "Defaults" row).
- In the macOS colour picker, switch to **Hex** mode and enter the hex value.
- Scroll down to **"Tab color"**, tick the checkbox, and set the accent colour.
- Keep all other colours from your base theme (Dracula, Tokyo Night, etc.).

### Text tab
- Set font to **JetBrains Mono 13pt** (or Menlo 13pt if not installed).

### General tab
- **Title:** Click the dropdown. Under "Foreground Job", **uncheck "Job Name"**
  (leave only "Session Name" checked). This prevents `-zsh` or `(claude)` from
  appearing after the role name.
- **Badge:** Set the badge text to the short role name:
  ```
  CC-AUDIT  → AUDIT
  CC-IMPL   → IMPL
  CC-PROMPT → PROMPT
  CC-PLAN   → PLAN
  ```

> **Migrating from DEV-* profiles:** If you already have DEV-AUDIT/DEV-IMPL/
> DEV-PROMPT/DEV-PLAN profiles, rename them in iTerm Preferences → Profiles.
> Then update the `case "$ITERM_PROFILE"` blocks in `~/.zshrc` to match the
> new CC-* names (or run the snippet in Step 6 which uses CC-* already).

---

## Step 5 — Profile Startup Commands & Initial Directory

In each profile → **General** tab:

### Command
Change the dropdown from "Login Shell" to **"Custom Shell"** and enter:

```bash
# Same command for all 4 profiles — only the directory changes per project.
# Role detection uses $ITERM_PROFILE (set automatically by iTerm2),
# so the startup command doesn't need to set PANE_ROLE.
/bin/zsh -c 'cd ~/Desktop/your-project; exec zsh'
```

Replace `your-project` with your project directory name.

### Initial directory
Change from **"Home directory"** to **"Directory:"** and enter the full path:
```
/Users/yourname/Desktop/your-project
```

> **Why both?** The startup command does the initial `cd`.
> The Initial directory setting is a fallback — iTerm2 window arrangement
> restore doesn't always re-run the startup command, but it does respect the
> Initial directory setting. Role detection relies on `$ITERM_PROFILE`
> (auto-set by iTerm2 on every session), not the startup command.

> **Why `exec zsh`?** This replaces the subshell with an interactive zsh.
> Without it, the pane closes when you exit any command launched inside it.

---

## Step 6 — Shell Snippet

Append `zshrc-snippet.sh` (from this repo) to your `~/.zshrc`:

```bash
cat zshrc-snippet.sh >> ~/.zshrc
```

The snippet provides:
- `$PANE_ROLE` and coloured prompt per profile
- Title-lock so the pane title stays fixed (won't flip to `-zsh`)
- `cc` alias — launches Claude with the correct model/effort/permissions per pane
- `gate` and `ship` aliases (IMPL pane only)
- Ollama env vars and llm-* aliases (uncomment your tier's block)
- `llm-smart` router function

After appending, activate it:

```bash
source ~/.zshrc
```

### Verify the setup

Open a new iTerm2 pane using the **CC-IMPL** profile, then:

```bash
echo $PANE_ROLE        # should print: IMPL
echo $ITERM_PROFILE    # should print: CC-IMPL
```

If `$PANE_ROLE` is empty, the pane was not opened with a CC-* profile — open
it via **Profiles → CC-IMPL** in the menu bar.

**Key design decisions in the snippet:**
- Uses `$ITERM_PROFILE` (auto-set by iTerm2 on every session, including
  arrangement restores) instead of a custom env var from the startup command.
- Uses `precmd_functions+=()` array instead of overwriting `precmd()` directly,
  so pyenv/fnm/conda hooks aren't clobbered.
- The `cc` alias launches Claude with the correct flags for whichever pane
  you're in — no need to remember the commands.

---

## Step 7 — Window Layout & Arrangement

### Create the 2×2 split

1. Open a new window with the **CC-AUDIT** profile.
2. `⌘D` — split right. Right-click the new pane → **Edit Session** → change
   profile to **CC-PROMPT**.
3. Click back on the left pane (AUDIT). `⌘⇧D` — split down. Change the new
   bottom-left pane to **CC-IMPL**.
4. Click on the right pane (PROMPT). `⌘⇧D` — split down. Change the new
   bottom-right pane to **CC-PLAN**.

Result:
```
┌─────────────────┬──────────────────┐
│   AUDIT (Opus)  │  PROMPT (Sonnet) │
│   purple bg     │  cyan bg         │
├─────────────────┼──────────────────┤
│   IMPL (Sonnet) │  PLAN (Sonnet)   │
│   green bg      │  amber bg        │
└─────────────────┴──────────────────┘
```

### Save and set as default

5. **Save:** `Window → Save Window Arrangement` → name it (e.g. your project name).
6. **Set startup policy:** Go to `iTerm2 → Settings → General → Startup`
   → set to **"Open Default Window Arrangement"**.
7. **Save again as default:** `Window → Save Window Arrangement` → select the
   same name.

Now iTerm2 opens your 4-pane layout automatically on launch.

### Option B: Separate windows (dual monitor)

```
Monitor 1: AUDIT + PLAN
Monitor 2: IMPL + PROMPT
```

Switch between macOS Spaces with `ctrl+1/2/3/4`.

---

## Step 8 — Launch Claude Code

Type `cc` in each pane. That's it.

> **Note on the `cc` alias:** On some systems, `cc` is aliased to the C compiler.
> If you work with C/C++, rename the alias to `cl` or `claude-go` in your
> `~/.zshrc`.

The alias (set up in Step 6) expands to the correct command per pane:

| Pane   | `cc` expands to                                                  |
|--------|------------------------------------------------------------------|
| AUDIT  | `claude --model opus --effort high --permission-mode plan`       |
| IMPL   | `claude --model sonnet --effort high --permission-mode acceptEdits` |
| PROMPT | `claude --model sonnet --effort medium`                          |
| PLAN   | `claude --model sonnet --effort low`                             |

### Verified CLI flags

| Flag                              | Purpose                                    |
|-----------------------------------|--------------------------------------------|
| `--model opus`                    | Use Opus (aliases: `opus`, `sonnet`, `haiku`, or full ID like `claude-opus-4-6`) |
| `--effort high`                   | Thinking budget: `low` = fast; `medium` = balanced; `high` = extended reasoning; `max` = maximum depth |
| `--permission-mode plan`          | Read-only — Claude can't write files       |
| `--permission-mode acceptEdits`   | Auto-accept file edits without asking      |
| `--append-system-prompt "..."`    | Add custom instructions on top of defaults |
| `--continue`                      | Resume most recent conversation            |
| `--resume`                        | Resume a specific session by ID            |

> **On `--dangerously-skip-permissions`:** `--permission-mode acceptEdits` is
> more targeted — it auto-accepts file edits while still asking before shell
> commands. Only use `--dangerously-skip-permissions` in fully sandboxed
> environments.

> **Version note:** Flags verified against Claude Code v2.1.81 (March 2026).
> CLI tools update frequently — run `claude --help` if a flag isn't recognised.

---

## Step 9 — Keyboard Shortcuts Reference

### iTerm2 navigation

| Shortcut        | Action                              |
|-----------------|-------------------------------------|
| `⌘⌥ ←/→`       | Move between split panes (left/right)|
| `⌘⌥ ↑/↓`       | Move between split panes (up/down)  |
| `⌘D`            | Split pane vertically (right)       |
| `⌘⇧D`           | Split pane horizontally (below)     |
| `⌘⇧↵`           | Maximise/zoom current pane (toggle) |
| `⌘1-4`          | Switch to tab by number             |
| `⌘F`            | Find in terminal output             |
| `⌘M`            | Set mark at current position        |
| `⌘⇧↑`           | Jump to previous mark               |
| `⌘⌥E`           | Broadcast input to all panes (careful!) |
| `⌘K`            | Clear terminal buffer               |

### Claude Code inside the session

| Shortcut / Command | Action                              |
|---------------------|-------------------------------------|
| `Esc`               | Interrupt current generation        |
| `Ctrl+C`            | Cancel and return to prompt         |
| `/clear`            | Clear conversation context          |
| `/compact`          | Compress conversation context       |
| `/model <name>`     | Switch model mid-session            |
| `/effort <level>`   | Switch effort mid-session           |
| `/help`             | Show available commands             |

---

## Step 10 — iTerm2 Triggers (Optional)

Auto-highlight keywords in terminal output.

**Profile → Advanced → Triggers → +**

| Regex                                    | Action         | Colour          |
|------------------------------------------|----------------|-----------------|
| `\b(CRITICAL\|ERROR\|FAIL(ED)?)\b`      | Highlight Text | Red background  |
| `\b(PASS(ED)?\|SUCCESS)\b`              | Highlight Text | Green background|
| `\b(WARNING\|WARN\|TODO)\b`             | Highlight Text | Yellow background|

---

## Step 11 — Cross-Pane Workflow

### The standard change cycle

```
PLAN  → Discuss approach. No file writes. Get architecture sign-off.
IMPL  → Implement. Run tests immediately after (must pass).
AUDIT → Review the changed files (read-only). Feed findings back to IMPL.
PROMPT → (When prompt/content files change) Separate from code changes.
```

### Cross-pane handoff

When AUDIT identifies an issue, copy its output and paste into IMPL with:

```
The AUDIT pane identified: [paste findings here].
Fix this while preserving existing patterns. Do not touch unrelated files.
```

> **Optional:** If you've installed the pane handoff feature (Step 19), the AUDIT pane writes the directive to `~/.claude/handoff/to-impl.<scope>.txt` and the watcher delivers it as a single bracketed paste to the IMPL pane — no manual copy-paste. See Step 19 or `HANDOFF_GUIDE.md` §5.

### Context hygiene

- **Re-anchor on long sessions:** "Before starting, re-read CLAUDE.md and
  confirm the project invariants. Then..."
- **Scope AUDIT context:** "Focus ONLY on src/auth.py and src/middleware.py.
  Do not read any other files unless I explicitly ask."
- **Clear stale context:** `/clear` resets the conversation.
- **Compress instead of clearing:** `/compact` summarises and frees context
  without losing all history.
- **State sync before review:** Always run `/clear` in the AUDIT pane before
  starting a review pass on code that IMPL just wrote. This ensures AUDIT reads
  the current file contents, not stale versions cached in its context.

### Why this split?

| | macOS Terminal | iTerm2 |
|---------|---------------|--------|
| **Split panes** | Tabs/windows only | Unlimited independent panes |
| **Named profiles** | Basic profiles | Auto-sets `$ITERM_PROFILE` per pane — the key to role detection |
| **Visual identity** | Basic themes | Per-profile backgrounds, tab colours, badges |
| **Window arrangements** | No saved layouts | Save & auto-restore multi-pane layouts |

The `$ITERM_PROFILE` variable is especially critical — it lets the `cc` alias
automatically launch the right model and permissions per pane, and it survives
window arrangement restores.

---

## Step 12 — Daily Playbook

### Morning boot

```
1. Open iTerm2 (arrangement auto-restores)
2. Type "cc" in each pane
2.5  AUDIT pane → /clear (ensures fresh context for first review)
3. PLAN pane  → review where you left off (git log --oneline -10)
4. IMPL pane  → quick smoke test (pytest tests/ -x --tb=short)
5. AUDIT pane → review open issues (grep -A2 "TODO" CLAUDE.md)
```

### End of session

```
1. IMPL  → run full test suite
2. IMPL  → stage and commit (git add -p && git commit)
3. Compress long contexts → type /compact inside Claude Code
4. Save arrangement if layout changed
   (Window → Save Window Arrangement → overwrite)
```

---

## Step 13 — Adapt for Other Projects

To adapt this setup for a different project:

1. **Rename profiles:** `CC-AUDIT` → `MYPROJECT-AUDIT`, etc.
2. **Update Initial directory** in each profile to the new project path.
3. **Update `~/.zshrc`** — add new `case` entries matching the new profile
   names.
4. **Add project-specific slash commands** to `.claude/commands/`.
5. **Save a project-specific arrangement** named after the project.

---

## Step 14 — Two-Tier Hook Architecture

Claude Code hooks run scripts before and after tool use to enforce safety
invariants that prompt instructions alone cannot guarantee.

### Two tiers

| Tier | Event | Purpose |
|------|-------|---------|
| **PreToolUse** | Before the tool executes | Block dangerous actions before they happen |
| **PostToolUse** | After the tool returns | Observe outcomes; trip circuit-breaker on repeat failures |
| **SessionStart** | When a new session opens | Reset counters; validate session state |

### Setup

1. Copy the hook scripts to `~/.claude/hooks/`:
   ```bash
   mkdir -p ~/.claude/hooks
   cp hooks/protect-env.py ~/.claude/hooks/
   cp hooks/protect-git-push.py ~/.claude/hooks/
   cp hooks/circuit-breaker.py ~/.claude/hooks/
   cp hooks/session-start-reset.py ~/.claude/hooks/
   cp hooks/version-check.py ~/.claude/hooks/
   ```

2. Merge the hooks block into `~/.claude/settings.json`:
   - Open (or create) `~/.claude/settings.json`.
   - Copy the `"hooks"` block from `hooks/settings.json.example` into the top
     level of the JSON object.
   - All `"command"` values use `$HOME` — Claude Code does not expand `~`.
   - The example also includes `"env": {"CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "50"}`.
     This tells Claude Code to auto-compact the conversation context when it
     reaches 50% of the context window. Set to `"0"` to disable.

### What each hook does

| Hook | Tier | Blocks when |
|------|------|------------|
| `protect-env.py` | PreToolUse | Edit/Write/MultiEdit targets any `.env` file |
| `protect-git-push.py` | PreToolUse | Bash command matches `git … push` (any flag order) |
| `circuit-breaker.py` | PostToolUse | 3 consecutive tool failures in a session |
| `session-start-reset.py` | SessionStart | (resets failure counter — never blocks) |
| `version-check.py` | SessionStart | (never blocks — prints update checklist when Claude Code version changes) |

> **Platform note:** Hook scripts use `fcntl` and run on macOS and Linux only.

---

## Step 15 — gate Workflow

The `gate` alias in the IMPL pane runs your pytest suite and confirms all tests
pass before you hand work to the AUDIT pane.

| Alias | What it runs | When to use |
|-------|-------------|-------------|
| `gate` | pytest suite (tests/); exits non-zero on failure | Before handing off to AUDIT |
| `ship` | `gate` + interactive `git add -p` + `git commit` | When tests pass and work is commit-ready |

### Usage in the IMPL pane

```bash
# After making changes:
gate
# → ... pytest output ...
# → ✅ GATE PASSED

# When ready to commit:
ship
# → runs gate, then prompts for staged hunks + commit message
```

`gate` and `ship` are defined only when `$ITERM_PROFILE == CC-IMPL`. Running
them in other panes is a harmless no-op.

### The IMPL → AUDIT handoff rule

```
IMPL → implement → gate (must pass) → AUDIT → findings → IMPL → fix → gate → AUDIT
```

Never send work to AUDIT until `gate` passes.

> **Graduating to a full gate:** Once the project matures, you may want `gate`
> to also run lint, type checking, and a docker build. That's a deliberate
> upgrade — don't add it on day one. Start with pytest-only; add gates when
> you know they're load-bearing.

---

## Step 16 — SESSION_LOG Pattern

### The problem

When an IMPL session starts with an empty or missing `SESSION_LOG.md`, Claude
has no prior context. It begins cold — asking for a project overview rather
than resuming from where the last session ended.

### The fix

1. Keep a `SESSION_LOG.md` in your project root. Append a new entry at the
   end of every session; never overwrite old entries.
2. Instruct Claude (in your `CLAUDE.md`) to read the last 60 lines of
   `SESSION_LOG.md` at session start and surface the most recent "Next:" items.

### Minimal SESSION_LOG.md format

```markdown
### YYYY-MM-DD — one-line task summary
- **Done**: what was completed this session
- **Decisions**: any architectural choices made
- **Next**: open items or follow-ups for the next session
```

Real example:

```markdown
### 2026-03-22 — Add rate-limit retry to API client
- **Done**: Implemented exponential backoff in api_client.py. All 24 tests pass.
- **Decisions**: Max 3 retries, 2s base delay. Errors logged with context, not raised.
- **Next**: AUDIT review of api_client.py. Then wire retry into pipeline scheduler.
```

---

## Step 17 — CLAUDE.md Split Pattern

### Why it's needed

A single `CLAUDE.md` grows with both global rules (coding style, error handling,
tool preferences) and project-specific decisions (architecture, sprint context).
Mixing the two means every project's Claude session reads noise from unrelated
projects, and global rules must be duplicated per repo.

### The pattern

| File | Location | Committed? | Contains |
|------|----------|------------|---------|
| Global rules | `~/.claude/CLAUDE.md` | No — personal | Coding conventions, error-handling policy, tool preferences |
| Project rules | `.claude/CLAUDE.md` (repo) | Yes | Project architecture, active constraints, session continuity |

Claude Code automatically merges both — global first, project-specific second.

### Using the templates

Two starter templates are included in this repo:

- **`CLAUDE.md.template`** — copy to `~/.claude/CLAUDE.md`, fill in each
  section with your own rules. Do not commit this file.
- **`REFERENCE.md.template`** — copy to `.claude/REFERENCE.md` inside your
  project repo and commit it. The AUDIT pane uses it for sprint context and
  known issues.

> **Tip:** Start `~/.claude/CLAUDE.md` with a one-line role statement so every
> session starts with the right frame.

---

## Step 18 — MCP Server, Slash Commands & Skills

### GitHub MCP Server

Claude Code registers MCP servers via `claude mcp add`, not by reading a
config file from disk. The included `.mcp.json.example` is reference JSON
if you need `claude mcp add-json` instead.

**Setup:**

1. Install the binary:
   ```bash
   brew install github-mcp-server
   ```
   Or see [github.com/github/github-mcp-server](https://github.com/github/github-mcp-server) for other install methods.

2. Register with Claude Code (user-scope — available in every project):
   ```bash
   claude mcp add github -s user \
     -e GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_readonly_token \
     -- $(which github-mcp-server) stdio
   ```
   Generate a read-only PAT at <https://github.com/settings/tokens> with scope
   `public_repo` (or `repo` for private-repo access). Recommended expiry: 90 days.

3. Verify: `claude mcp list | grep github`

> **Scope:** `-s user` registers the server globally (all projects). Omit
> `-s user` to restrict to the current project.

---

### /reflect Command

`commands/reflect.md` defines a `/reflect` slash command. Run it at the end of
any IMPL or AUDIT session to extract project-specific learnings and get
structured suggestions for updating CLAUDE.md.

**Install:**
```bash
mkdir -p ~/.claude/commands
cp commands/reflect.md ~/.claude/commands/reflect.md
```

**Use:** Type `/reflect` at the end of a session. Claude reads the recent git
log and diff, then outputs a formatted table of suggested CLAUDE.md additions.

> `/reflect` never edits CLAUDE.md directly. You review and decide what to
> incorporate.

---

### Contextual Skills

The `skills/` directory contains three skills that add relevant instructions
when Claude is doing review or testing work:

| Skill | When it activates | What it adds |
|-------|------------------|--------------|
| `code-review` | Code review tasks (AUDIT pane) | Project-specific review conventions |
| `security-audit` | Security review tasks (AUDIT pane) | Security checklist and vulnerability patterns |
| `testing` | Writing/reviewing tests (IMPL pane) | pytest conventions matching the project |

**Install:**
```bash
cp -r skills/ ~/.claude/skills/
```

Skills are loaded automatically by Claude Code when the task matches the
skill's trigger description — no manual invocation needed.

---

## Step 19 — Pane Handoff (AUDIT ↔ IMPL)

The cross-pane workflow (Step 11) has one manual chore left: copying AUDIT's
findings into the IMPL pane, and IMPL's hand-back into AUDIT. This optional
add-on removes it — one pane writes a file, a background watcher delivers it
into the other pane as a single paste.

**The problem it solves.** Every AUDIT → IMPL round-trip means selecting a
multi-line directive, switching panes, and pasting it — and multi-line pastes
into a terminal normally submit on the first newline, mangling code blocks and
blank lines. Do that ten times a day and it's the slowest, most error-prone
link in the loop.

**How it works.** A tiny file-based message bus. Each pane binds itself to a
role (IMPL or AUDIT) and a project scope. To send work, Claude writes a file
into `~/.claude/handoff/`; an `fswatch`-based watcher (a launchd daemon,
running 24/7) picks it up, wraps the content in bracketed-paste escape codes,
and types it into the bound iTerm pane — where the receiving Claude sees it as
one fresh user message, every line preserved. On success the watcher truncates
the file to 0 bytes as its delivered-marker.

```
 AUDIT pane                     Watcher                         IMPL pane
  (Claude)                 (pane-handoff.sh)                     (Claude)
cat > to-impl.myapp.txt ──>  fswatch fires, reads file
                             wraps in bracketed paste
                             osascript → bound pane UUID   ──>  arrives as one
                             truncates file to 0 bytes          user message
                             logs to /tmp/handoff.log
```

**Scoped filenames are the routing table.** Every file is keyed by a
per-project scope: `to-impl.<scope>.txt` routes to that scope's IMPL pane,
`to-audit.<scope>.txt` to its AUDIT pane, and `HALT.<scope>` pauses that scope
only. Two projects run side by side with zero cross-talk. Unscoped writes
(`to-impl.txt`) are refused on purpose.

> **Optional add-on** — macOS + iTerm2 only, ~3 minute install. Everything in
> Steps 1–18 works without it; this just removes the copy-paste tax from the
> AUDIT ↔ IMPL loop.

### 1. Install the watcher

```bash
brew install fswatch    # required dependency
./handoff/install.sh    # from the repo root
```

The installer verifies `fswatch`, `osascript`, and iTerm2 are present; copies
`pane-handoff.sh` (the watcher) and `enforce-handback.py` (a Stop hook) to
`~/.claude/hooks/`; copies the `/start-impl` and `/start-audit` commands to
`~/.claude/commands/`; installs a launchd agent at
`~/Library/LaunchAgents/com.user.handoff.plist` (auto-starts at login,
restarts on crash); and arms routing.

```bash
# Verify:
launchctl list | grep handoff   # → "<PID>  0  com.user.handoff"
tail /tmp/handoff.log           # → "[handoff] Watching ~/.claude/handoff"
```

To uninstall: `./handoff/install.sh --uninstall`

### 2. Add the shell functions

```bash
cat handoff/zshrc-handoff.sh >> ~/.zshrc
source ~/.zshrc
```

This defines the user-facing API, available in every pane:

| Command | What it does |
|---------|--------------|
| `handoff-use <scope>` | Set this pane's `HANDOFF_SCOPE` — once per pane open, before any scoped command |
| `handoff-claim-impl` / `handoff-claim-audit` | Bind this pane as the IMPL or AUDIT target for the current scope |
| `handoff-on` / `handoff-off` / `handoff-status` | Arm / disarm / check routing (global flag file `~/.claude/handoff/active`) |
| `handoff-halt` / `handoff-resume` | Pause / resume the loop for this scope only (writes / removes `HALT.<scope>`) |
| `handoff-targets` | List all current pane bindings |
| `send-impl` / `send-audit` | Pipe stdin to the scoped inbox (one-liners) |
| `handoff-scope` | Print this pane's current scope |

### 3. Bind the panes to a project scope

Pick a scope name per project (lowercase, no spaces — e.g. `myapp`). In the
IMPL pane, inside Claude:

```bash
handoff-use myapp
handoff-claim-impl
# → [handoff] IMPL scope=myapp bound to <UUID>
```

In the AUDIT pane, inside Claude: `handoff-use myapp`, then the `/start-audit`
slash command, then `handoff-claim-audit`. Confirm both bindings and
smoke-test:

```bash
handoff-targets    # → audit-target.myapp / impl-target.myapp with live UUIDs
echo "smoke test $(date +%s)" > ~/.claude/handoff/to-impl.myapp.txt
# within ~1s the IMPL pane shows the text as a single paste
```

> **Re-claim after every iTerm restart.** iTerm assigns a new session UUID
> each time a pane opens, so yesterday's bindings point at panes that no
> longer exist. After a reboot or iTerm restart, re-run `handoff-use` +
> `handoff-claim-*` in each pane. The watcher itself needs nothing — launchd
> keeps it alive.

### 4. Send work between panes

**AUDIT → IMPL** — the AUDIT pane writes a directive (via its Bash tool) and
ends it with the confirmation line `→ handed off`:

```bash
cat > ~/.claude/handoff/to-impl.myapp.txt << 'HANDOFF'
Fix HIGH finding 2 — unvalidated path join in api_client.py:88

Acceptance:
- input validated against allowlist
- pytest tests/test_api_client.py passes
→ handed off
HANDOFF
```

**IMPL → AUDIT** — after `gate` passes, IMPL hands back, ending with
`→ handed back`:

```bash
cat > ~/.claude/handoff/to-audit.myapp.txt << 'HANDOFF'
=== HAND-BACK ===
Step: finding 2
Gate: PASS
Surface assessment: allowlist added, no new deps
→ handed back
HANDOFF
```

The confirmation lines are load-bearing: the `enforce-handback.py` Stop hook
blocks IMPL from *claiming* "→ handed back" in chat without actually writing
the file — the failure mode that otherwise leaves AUDIT waiting forever on a
loop that silently broke.

> **Three details that trip people up:** (1) Multi-line content survives —
> bracketed paste preserves code blocks, blank lines, and indentation.
> (2) Don't add a trailing Enter — the watcher submits the paste itself.
> (3) A 0-byte inbox file is *success*, not failure — it's the
> delivered-marker. The file is transport, not state; receiving panes should
> never pre-flight read it.

### 5. HALT — the human-in-the-loop brake

Either pane can pause its own project's loop by writing the scoped sentinel.
Contents must name the trigger and the human action required:

```bash
handoff-halt <<'EOF'
Trigger: gate failure on tests/test_api_client.py
Human action required: review failure, decide rollback vs fix-forward
EOF
```

This writes `~/.claude/handoff/HALT.myapp`. The watcher logs
`⛔ HALT scope=myapp`, fires a macOS notification, and both panes in that
scope stop before doing anything else. Other projects keep flowing — HALT is
per-scope, there is no global pause. Only a human resumes it:

```bash
handoff-resume    # or: rm ~/.claude/handoff/HALT.myapp
```

### 6. Troubleshooting

If a paste doesn't arrive, ask three questions in order — then read
`/tmp/handoff.log`:

```bash
launchctl list | grep handoff   # 1. watcher running? PID must be a number, not "-"
ls ~/.claude/handoff/active     # 2. routing armed? missing = disarmed → handoff-on
handoff-targets                 # 3. pane still bound? stale UUID → re-claim (step 3)
```

| Log pattern | Meaning |
|-------------|---------|
| `-> IMPL scope=X` then `delivered to IMPL/X — file truncated to 0 bytes` | Success |
| `-> IMPL scope=X` then `WARN: delivery failed — file NOT truncated` | Stale binding (re-claim), no binding for that scope, or macOS Automation permission denied for iTerm/osascript |
| No `-> IMPL scope=X` line at all | Watcher not running, routing disarmed, or wrote to the wrong path |
| `WARN: refusing unscoped to-impl.txt` | You forgot the scope in the filename — use `to-impl.<scope>.txt` |

Edited the watcher script? It does not hot-reload — `pkill -f pane-handoff.sh`
and launchd respawns it within ~1s.

That's the full daily loop. For multi-project isolation probes, the complete
command and path reference, and the under-the-hood details, see the
[Pane Handoff operator guide](HANDOFF_GUIDE.md).

---

## Step 20 — Persistent Memory (Sigil) (Optional)

Every pane in this setup is a separate Claude Code session — and every session
starts with amnesia. Close a pane and the decisions, preferences, and project
facts you spent an hour establishing are gone.
[Sigil](https://github.com/Anmol-Srv/sigil) — an open-source, local-first
memory system by [Anmol Srivastava](https://github.com/Anmol-Srv) — fixes
this: one shared, persistent memory that all four panes read from and write to
automatically, across sessions and across projects.

### Why the 4-pane setup needs it

The SESSION_LOG pattern (Step 16) carries context *forward in time* within one
project. It does not carry context *sideways* — AUDIT never learns what you
told IMPL, and nothing crosses project boundaries. In practice that means
re-explaining "we use pnpm, not npm" or "never run db:reset against staging"
in every pane, every session.

Sigil closes that gap with hooks that run inside every Claude Code session,
regardless of pane, model, or permission mode:

| Hook | Fires | What it does |
|------|-------|--------------|
| `UserPromptSubmit` | Every prompt you type | Searches memory and injects the top-K relevant facts before Claude sees your prompt |
| `Stop` | End of each turn | Classifies what you said and auto-captures memorable facts (preferences, decisions, corrections) |
| `SessionEnd` | Session close | Summarizes the session into durable memory |
| Hot context | Session start | A snapshot of your most-used facts, loaded via an `@import` in `~/.claude/CLAUDE.md` |

Because memory lives in a local database rather than in any one session, all
four panes share it — and it is MCP-native, so the same memory is available to
other MCP clients (Cursor, Codex CLI) if you use them alongside this setup.

### Install from the Sigil repo

Installation is a one-liner, then an interactive wizard. Follow the upstream
README at [github.com/Anmol-Srv/sigil](https://github.com/Anmol-Srv/sigil) for
current instructions; as of this writing:

```bash
# Install (clones to ~/.sigil/app, adds to PATH, starts the daemon)
curl -fsSL https://raw.githubusercontent.com/Anmol-Srv/sigil/master/install.sh | sh

# Configure — interactive wizard with live connection tests
sigil init
```

The `sigil init` wizard walks you through four choices: a **database**
(Postgres — local or managed), an **LLM provider** for fact classification
(OpenRouter, OpenAI, Anthropic, Ollama, or your Claude subscription), an
**embedding provider** (OpenAI, Voyage, or Ollama), and **hook wiring** — it
auto-detects Claude Code, installs its hooks into `~/.claude/settings.json`,
and registers MCP servers for other clients. It merges alongside the hooks
from Step 14 without touching them.

> **⚠️ Pick a fast, local LLM provider — this is the one setting that can ruin
> the whole experience.** Claude Code runs `UserPromptSubmit` hooks
> synchronously on *every prompt you type*, with a ~10-second budget. A
> provider that shells out to `claude -p` takes ~16 seconds per call — every
> single prompt then shows `UserPromptSubmit hook timed out after 10s` and you
> get no memory injection at all. Fact classification is a routing job, not a
> reasoning job: point Sigil's LLM provider at a small local Ollama model (you
> already have Ollama from Step 3) and keep the hook path well under budget.

Verify the loop end-to-end: open any pane with `cc`, submit a prompt, and
confirm memory search fires without a timeout warning. Then check
`claude mcp list` shows Sigil connected.

### The 3 commands you'll use daily

The hooks do the routine work unprompted. Manual interaction comes down to
three commands, runnable from any pane (or inside Claude Code with `!`
shell-exec):

| Command | What it does |
|---------|--------------|
| `sigil facts` | List everything stored, with IDs. Your spot-check that memory contains what you think it does. |
| `sigil remember "..."` | Save a fact explicitly. Sigil classifies it, extracts atomic facts, and embeds them — write natural language. |
| `sigil search "..."` | Semantic search over memory. This is the same path the prompt hook uses — run it to debug what Claude is actually seeing. |

> **Tip — the "teach once, recall everywhere" rule:** If you catch yourself
> telling Claude the same thing in two different sessions, that's the signal
> to make it a `sigil remember`. From then on, every pane knows.

### Where it fits in each pane

The hooks fire identically everywhere, but there's a natural division of labor:

| Pane | What shared memory changes |
|------|----------------------------|
| `AUDIT` | Recalls past findings and ratified decisions — stops re-flagging issues you already resolved. Best pane for saving durable facts after a review: Opus synthesis is worth keeping. |
| `IMPL` | Stack choices, conventions, and constraints inject automatically — no more re-explaining the package manager or test layout every session. Add tactical facts as you discover them. |
| `PLAN` | Prior architectural decisions surface during planning, so new plans build on old ones instead of contradicting them. |
| `PROMPT` | Natural home for memory housekeeping — reviewing `sigil facts`, pruning stale entries, bulk ingestion. |

### Seeding memory: new vs. existing projects

**New project** — spend two minutes on day 1 telling Sigil what the project
is. Every later prompt, in every pane, has it on tap:

```bash
sigil remember "myproject: Next.js + Postgres app for X audience, target launch March"
sigil remember "myproject: hard constraint — no auth provider lock-in"
```

**Existing project** — no migration needed; the hooks fire regardless. Teach
it project specifics as you hit them, and optionally bulk-seed from the docs
you already maintain:

```bash
sigil ingest ./ARCHITECTURE.md
sigil ingest ./SESSION_LOG.md
sigil ingest "./docs/**/*.md"
```

Sigil extracts atomic facts and de-duplicates against existing memory. Run
`sigil facts` afterward to spot-check what landed. Your SESSION_LOG (Step 16)
and CLAUDE.md files (Step 17) keep working exactly as before — Sigil owns the
cross-session, cross-project layer; it doesn't replace either.

> **Privacy note:** Sigil is local-first — facts live in your own Postgres,
> and with Ollama providers nothing leaves the machine. If you handle client
> work, keep client facts out of the default namespace: store them under a
> per-client namespace (`sigil remember --namespace=client-a "..."`) so they
> never auto-inject into unrelated projects — or keep client data out of Sigil
> entirely and rely on per-project CLAUDE.md files. Never store secrets or
> credentials: the database is local but not encrypted at rest.

---

## Step 21 — Draw Things (Optional — Creative AI)

<details>
<summary>Creative AI — skip if not interested</summary>

Draw Things is a free macOS app for local image generation. It runs entirely
on your machine using Core ML — no API calls, no sign-up required.

**Install:**
1. Download from the Mac App Store: search "Draw Things AI Image Generator."
2. Open the app and let it download a base model (~2–4 GB).

**Usage:**
- Drag and drop an image to use as a reference.
- Prompt directly in the app's text field.
- Models are downloaded in-app; no terminal commands needed.

**Recommended starting model:** SDXL Turbo (fast) or Flux Schnell (higher quality).

> Draw Things does not interact with Claude Code or Ollama — it is a standalone
> tool. This step is entirely optional and has no bearing on any other step.

</details>

---

## Troubleshooting

### T1 — `$ITERM_PROFILE` is empty, `cc` launches with wrong model

**Symptom:** `echo $ITERM_PROFILE` returns nothing. The `cc` alias falls through with no model flags.

**Cause:** Old iTerm2 version (< 3.3) or the pane was opened before the profile was applied.

**Fix:**
- Update iTerm2 to 3.3+ (Help → Check For Updates).
- Reopen the pane via **Profiles → [your profile name] → Open in current tab**.
- Confirm: `echo $ITERM_PROFILE` should print `CC-AUDIT`, `CC-IMPL`, etc.

---

### T2 — `cc` launches the C compiler instead of Claude

**Symptom:** `which cc` shows `/usr/bin/cc`. Typing `cc` outputs compiler error messages.

**Fix:** Rename the alias in `~/.zshrc`. Replace all 4 `alias cc=` occurrences with `alias cl=` (or any name), then `source ~/.zshrc`.

---

### T3 — Hooks not firing

**Symptom:** `.env` edits or `git push` commands are not blocked by Claude.

```bash
# Check 1 — files exist
ls ~/.claude/hooks/
# Expected: protect-env.py  protect-git-push.py  circuit-breaker.py  session-start-reset.py  version-check.py

# Check 2 — python3 available
which python3  # must return a path; if missing: brew install python3

# Check 3 — settings.json is valid
python3 -m json.tool ~/.claude/settings.json  # prints formatted JSON on success
```

---

### T4 — Circuit-breaker stuck after tool failures

**Symptom:** Claude is blocked and won't proceed.

**Fix A:** Press `Ctrl+C`, then `cc`. The `session-start-reset.py` hook fires on session start and resets the counter automatically.

**Fix B:** Delete the state file:
```bash
rm -f ./circuit-breaker-state.json
# Then /clear inside Claude Code to reset conversation context.
```

---

### T5 — `gate` fails with "pytest not found" or 0 tests collected

- Activate your venv first: `source venv/bin/activate` (or `.venv/bin/activate`).
- Verify: `which pytest` should point inside your venv. If not: `pip install pytest`.
- If there are no test files yet, add a placeholder: `touch tests/test_placeholder.py`.

---

### T6 — Need to push to git — hook is blocking it

The `protect-git-push.py` hook blocks Claude from pushing autonomously. You can always push from a regular shell prompt — hooks only intercept tool calls inside a Claude Code session.

```bash
# Open a new tab (not inside a Claude session) and run:
git push
```

---

### T7 — Claude CLI update broke the `cc` alias

**Symptom:** After `npm update -g @anthropic-ai/claude-code`, `cc` errors with an unknown flag.

1. Run `claude --help` to see current supported flags.
2. Update the alias block in `~/.zshrc` to match, then `source ~/.zshrc`.
3. Run `claude --version` to confirm your installed version. This guide was verified against v2.1.81 (March 2026).

> **Tip:** The `version-check.py` hook (Step 14) detects version changes
> automatically and prints this checklist at session start.

---

### T8 — Ollama: model not found or server not running

**Symptom:** `ollama run qwen3:8b` hangs or returns "model not found."

```bash
# Check 1 — server is running
curl http://localhost:11434/      # should return "Ollama is running"

# Check 2 — model is pulled
ollama list                       # lists all downloaded models

# If server is not running:
ollama serve &

# If model is missing:
ollama pull qwen3:8b              # (or whichever model)
```

---

## Quick Reference — read as needed

```
┌──────────────────────────────────────────────────────────┐
│  LAUNCH                                                  │
├──────────────────────────────────────────────────────────┤
│  Type "cc" in any pane — alias handles the rest.         │
│                                                          │
│  AUDIT:  opus   · high effort · plan (read-only)         │
│  IMPL:   sonnet · high effort · acceptEdits              │
│  PROMPT: sonnet · medium effort                          │
│  PLAN:   sonnet · low effort                             │
├──────────────────────────────────────────────────────────┤
│  LOCAL AI                                                │
├──────────────────────────────────────────────────────────┤
│  llm-fast "..."     → qwen3 (general)                    │
│  llm-code "..."     → qwen3-coder (code)                 │
│  llm-reason "..."   → deepseek-r1 (reasoning, 32GB+)     │
│  llm-smart "..." [fast|code|reason|embed]  → router      │
│  ollama list        → show downloaded models             │
├──────────────────────────────────────────────────────────┤
│  NAVIGATION                                              │
├──────────────────────────────────────────────────────────┤
│  ⌘⌥ arrows  = switch panes    ⌘⇧↵ = zoom pane          │
│  ⌘D = split right             ⌘⇧D = split down          │
│  Esc = stop generation         /clear = reset context    │
├──────────────────────────────────────────────────────────┤
│  WORKFLOW                                                │
├──────────────────────────────────────────────────────────┤
│  PLAN → discuss approach (no writes)                     │
│  IMPL → implement + gate (must pass) → ship to commit    │
│  AUDIT → review changed files (read-only)                │
│  /clear AUDIT before review (state sync)                 │
│  PROMPT → prompt/content changes (separate from code)    │
│                                                          │
│  gate = run pytest suite    ship = gate + git add -p     │
└──────────────────────────────────────────────────────────┘
```
