# iTerm2 Multi-Pane Claude Code Setup — Universal Reference

> Corrected, battle-tested version. Implemented and verified on macOS with
> iTerm2 + Claude Code v2.1.81. Reusable for any project. March 2026.

---

## Overview

4 dedicated iTerm2 panes, each running a separate Claude Code session with a
distinct role, model, and visual identity. All panes point at the same project
directory but serve different purposes.

| Pane     | Role                          | Model    | Effort   | Permission Mode |
|----------|-------------------------------|----------|----------|-----------------|
| AUDIT    | Adversarial review, security  | `opus`   | `high`   | `plan` (read-only) |
| IMPL     | Code writing & editing        | `sonnet` | `high`   | `acceptEdits`   |
| PROMPT   | Prompt engineering & content  | `sonnet` | `medium` | default         |
| PLAN     | Architecture, docs, planning  | `sonnet` | `low`    | default         |

**Why this split:**
- Opus is ~15x more expensive than Sonnet — reserve it for review only.
- Separating review from implementation prevents "self-grading" bias.
- Each pane keeps a clean, focused context window.

---

## Why iTerm2 over macOS Terminal?

This workflow relies on features the default Terminal doesn't have:

| Feature | macOS Terminal | iTerm2 |
|---------|---------------|--------|
| **Split panes** | Tabs/windows only — no side-by-side splits | Unlimited independent panes in a single tab |
| **Named profiles** | Basic profiles, no `$ITERM_PROFILE` env var | Auto-sets `$ITERM_PROFILE` per pane — the key to role detection |
| **Visual identity** | Basic themes and transparency | Per-profile backgrounds, tab colours, badges, and 24-bit colour |
| **Window arrangements** | No saved layouts | Save & auto-restore multi-pane layouts on launch |
| **Productivity** | Standard find and copy | Paste history, Instant Replay, triggers, shell integration |

The `$ITERM_PROFILE` variable is especially critical — it lets the `cc` alias
automatically launch the right model and permissions per pane, and it survives
window arrangement restores.

---

## Step 1 — Create 4 iTerm2 Profiles

1. Open **iTerm2 → Settings → Profiles** (`⌘,`).
2. Click **+** four times to create four new profiles.
3. Name them with a short project prefix:

| Profile Name | Background Hex | Tab Colour Hex | Role                   |
|--------------|---------------|----------------|------------------------|
| `DEV-AUDIT`  | `#0d0b18`     | `#a855f7` (purple) | Evaluation / Auditing  |
| `DEV-IMPL`   | `#080f0b`     | `#22c55e` (green)  | Implementation         |
| `DEV-PROMPT` | `#080e10`     | `#06b6d4` (cyan)   | Prompt Engineering     |
| `DEV-PLAN`   | `#0d0b00`     | `#f59e0b` (amber)  | Planning / Architecture|

> **Naming convention for project-specific profiles:** Replace `DEV` with a
> short project prefix (e.g. `PROJ` for your project, `WEB` for a web app).

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
  (leave only "Session Name" checked under "Name"). This prevents the tab title
  from appending `-zsh` or `(claude)` after the role name.
- **Badge:** Set the badge text to the role name:
  ```
  DEV-AUDIT  → AUDIT
  DEV-IMPL   → IMPL
  DEV-PROMPT → PROMPT
  DEV-PLAN   → PLAN
  ```

---

## Step 2 — Profile Startup Commands & Initial Directory

In each profile → **General** tab:

### Command
Change the dropdown from "Login Shell" to **"Custom Shell"** and enter:

```bash
# Same command for all 4 profiles — only the directory changes per project.
# Role detection uses $ITERM_PROFILE (set automatically by iTerm2),
# so the startup command doesn't need to set PANE_ROLE.
/bin/zsh -c 'cd ~/Desktop/your-project; exec zsh'
```

Replace `your-project` with the actual project directory name.

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

## Step 3 — Title Locking, Prompt Colours & Launch Alias

Add to **~/.zshrc** (append at bottom):

```bash
# ── Multi-pane Claude Code workflow: title locking + prompt colours ──
# Uses $ITERM_PROFILE (auto-set by iTerm2) instead of custom env vars
# so it works reliably with Window Arrangement restore.
case "$ITERM_PROFILE" in
  DEV-AUDIT)
    PANE_ROLE="AUDIT"; PROMPT="%F{magenta}[AUDIT]%f %~ %# " ;;
  DEV-IMPL)
    PANE_ROLE="IMPL"; PROMPT="%F{green}[IMPL]%f %~ %# " ;;
  DEV-PROMPT)
    PANE_ROLE="PROMPT"; PROMPT="%F{cyan}[PROMPT]%f %~ %# " ;;
  DEV-PLAN)
    PANE_ROLE="PLAN"; PROMPT="%F{yellow}[PLAN]%f %~ %# " ;;
esac

if [[ -n "$PANE_ROLE" ]]; then
  echo -ne "\033]0;${PANE_ROLE}\007"
  _pane_title_precmd() { echo -ne "\033]0;${PANE_ROLE}\007"; }
  precmd_functions+=(_pane_title_precmd)
fi

# ── Claude Code launch aliases (role-aware) ──
# Type "cc" in any pane to launch with the correct model/effort/permissions.
case "$ITERM_PROFILE" in
  DEV-AUDIT)  alias cc='claude --model opus --effort high --permission-mode plan' ;;
  DEV-IMPL)   alias cc='claude --model sonnet --effort high --permission-mode acceptEdits' ;;
  DEV-PROMPT) alias cc='claude --model sonnet --effort medium' ;;
  DEV-PLAN)   alias cc='claude --model sonnet --effort low' ;;
esac
```

**Key design decisions:**
- Uses `$ITERM_PROFILE` (auto-set by iTerm2 on every session, including
  arrangement restores) instead of a custom env var from the startup command.
- Uses `precmd_functions+=()` array instead of overwriting `precmd()` directly,
  so pyenv/fnm/conda hooks aren't clobbered.
- The `cc` alias launches Claude with the correct flags for whichever pane
  you're in — no need to remember the commands.

---

## Step 4 — Window Layout & Arrangement

### Create the 2x2 split

1. Open a new window with the **DEV-AUDIT** profile.
2. `⌘D` — split right. Right-click the new pane → **Edit Session** → change
   profile to **DEV-PROMPT**.
3. Click back on the left pane (AUDIT). `⌘⇧D` — split down. Change the new
   bottom-left pane to **DEV-IMPL**.
4. Click on the right pane (PROMPT). `⌘⇧D` — split down. Change the new
   bottom-right pane to **DEV-PLAN**.

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
   same name. This time iTerm2 knows it's the default because of step 6.

Now iTerm2 opens your 4-pane layout automatically on launch. No extra
windows or tabs.

### Option B: Separate windows (dual monitor)

```
Monitor 1: AUDIT + PLAN
Monitor 2: IMPL + PROMPT
```

Switch between macOS Spaces with `ctrl+1/2/3/4`.

---

## Step 5 — Launch Claude Code

Type `cc` in each pane. That's it.

> **Note on the `cc` alias:** On some systems, `cc` is aliased to the C compiler.
> If you work with C/C++, rename the alias to `cl` or `claude-go` in your
> `~/.zshrc` to avoid conflicts.

The alias (set up in Step 3) expands to the correct command per pane:

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
| `--effort high`                   | Thinking budget: `low` = fast, minimal reasoning; `medium` = balanced; `high` = extended reasoning, more tokens; `max` = maximum depth. PLAN uses `low` — architectural discussion doesn't need deep reasoning chains. |
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

## Step 6 — Keyboard Shortcuts Reference

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

## Step 7 — iTerm2 Triggers (Optional)

Auto-highlight keywords in terminal output.

**Profile → Advanced → Triggers → +**

| Regex                                    | Action         | Colour          |
|------------------------------------------|----------------|-----------------|
| `\b(CRITICAL\|ERROR\|FAIL(ED)?)\b`      | Highlight Text | Red background  |
| `\b(PASS(ED)?\|SUCCESS)\b`              | Highlight Text | Green background|
| `\b(WARNING\|WARN\|TODO)\b`             | Highlight Text | Yellow background|

---

## Step 8 — Cross-Pane Workflow

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

### Context hygiene

- **Re-anchor on long sessions:** "Before starting, re-read CLAUDE.md and
  confirm the project invariants. Then..."
- **Scope AUDIT context:** "Focus ONLY on src/auth.py and src/middleware.py.
  Do not read any other files unless I explicitly ask."
- **Clear stale context:** `/clear` resets the conversation.
- **Compress instead of clearing:** `/compact` summarises and frees context
  without losing all history.

### Test-before-audit gate

Never send work to AUDIT until tests pass. Use the `gate` alias in the IMPL
pane (see Step 12) to run the full test suite before handing off to AUDIT.

---

## Step 9 — Session Playbook

### Morning boot

```
1. Open iTerm2 (arrangement auto-restores)
2. Type "cc" in each pane
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

## Step 10 — Customising for a Specific Project

To adapt this setup for a different project:

1. **Rename profiles:** `DEV-AUDIT` → `MYPROJECT-AUDIT`, etc.
2. **Update Initial directory** in each profile to the new project path.
3. **Update `~/.zshrc`** — add new `case` entries matching the new profile
   names (e.g. `MYPROJECT-AUDIT`).
4. **Add project-specific slash commands** to `.claude/commands/`.
5. **Save a project-specific arrangement** named after the project.

---

## Step 11 — Two-Tier Hook Architecture

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
   ```

2. Merge the hooks block into `~/.claude/settings.json`:
   - Open (or create) `~/.claude/settings.json`.
   - Copy the `"hooks"` block from `hooks/settings.json.example` into the top
     level of the JSON object.
   - All `"command"` values use `$HOME` — Claude Code does not expand `~`.
   - The example also includes `"env": {"CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "50"}`.
     This tells Claude Code to auto-compact the conversation context when it
     reaches 50% of the context window, instead of waiting until it's nearly
     full. Set to `"0"` to disable, or remove the `"env"` block to use the
     default threshold.

### What each hook does

| Hook | Tier | Blocks when |
|------|------|------------|
| `protect-env.py` | PreToolUse | Edit/Write/MultiEdit targets any `.env` file |
| `protect-git-push.py` | PreToolUse | Bash command matches `git … push` (any flag order) |
| `circuit-breaker.py` | PostToolUse | 3 consecutive tool failures in a session |
| `session-start-reset.py` | SessionStart | (resets failure counter — never blocks) |

> **Platform note:** Hook scripts use `fcntl` and run on macOS and Linux only.

---

## Step 12 — gate/ship Workflow

Two aliases available in the IMPL pane (added to `zshrc-snippet.sh` — see
Step 3 for how to apply the snippet):

| Alias | What it runs | When to use |
|-------|-------------|-------------|
| `gate` | Full pytest suite; exits non-zero on failure | Before handing off to AUDIT |
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

`gate` and `ship` are defined only when `$ITERM_PROFILE == DEV-IMPL`. Running
them in other panes is a harmless no-op.

### The IMPL → AUDIT handoff rule

```
IMPL → implement → gate (must pass) → AUDIT → findings → IMPL → fix → gate → AUDIT
```

Never send work to AUDIT until `gate` passes. Sending failing code to the review
pane wastes its context window on defects the test suite already catches.

---

## Step 13 — SESSION_LOG Cold-Start Fix

### The problem

When an IMPL session starts with an empty or missing `SESSION_LOG.md`, Claude
has no prior context. It begins cold — asking for a project overview rather
than resuming from where the last session ended.

### The fix

Two parts:

1. **`session-start-reset.py` hook** (see Step 11) fires on `SessionStart` and
   resets the circuit-breaker state. It is also the entry point for any
   session-initialisation logic you add later.

2. **CLAUDE.md instruction** (see Step 14): instruct Claude to read
   `SESSION_LOG.md` on session start and surface the most recent "Next:" items
   before doing anything else.

### Minimal SESSION_LOG.md format

Keep a `SESSION_LOG.md` in your project root. Append a new entry at the end of
every session; never overwrite old entries.

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

At the start of every IMPL session, Claude reads the last 60 lines of
`SESSION_LOG.md` to pick up where work stopped.

---

## Step 14 — CLAUDE.md Split Pattern

### Why it's needed

A single `CLAUDE.md` grows with both global rules (coding style, error handling,
tool preferences) and project-specific decisions (architecture, sprint context,
active constraints). Mixing the two means every project's Claude session reads
noise from unrelated projects, and global rules must be duplicated per repo.

### The pattern

| File | Location | Committed? | Contains |
|------|----------|------------|---------|
| Global rules | `~/.claude/CLAUDE.md` | No — personal | Coding conventions, error-handling policy, tool preferences |
| Project rules | `.claude/CLAUDE.md` (repo) | Yes | Project architecture, active constraints, session continuity |

Claude Code automatically merges both — global first, project-specific second.

### Using the templates

Two starter templates are included in this repo:

- **`CLAUDE.md.template`** — copy to `~/.claude/CLAUDE.md`, fill in your
  global rules. Do not commit this file.
- **`REFERENCE.md.template`** — copy to `.claude/REFERENCE.md` inside your
  project repo and commit it. The AUDIT pane uses it for sprint context and
  known issues.

> **Tip:** Start `~/.claude/CLAUDE.md` with a one-line role statement
> ("I am a senior data engineer…") so every session starts with the right frame.

---

## Step 15 — MCP Server, Slash Commands & Skills

### GitHub MCP Server

The included `.mcp.json.example` configures the GitHub MCP server, giving
Claude read access to GitHub issues, PRs, and code search inside any session.

**Setup:**

1. Install the binary — see [github.com/github/github-mcp-server](https://github.com/github/github-mcp-server).

2. Copy and configure:
   ```bash
   cp .mcp.json.example ~/.claude/.mcp.json
   # Edit ~/.claude/.mcp.json:
   #   - Replace /path/to/github-mcp-server with the actual binary path
   #   - Replace ghp_your_readonly_pat_here with a real read-only PAT
   ```

3. Restart Claude Code and run `/mcp` to confirm the server is connected.

> **Scope:** Placing `.mcp.json` in `~/.claude/` makes the server available in
> all projects. For per-project scope, place it in `.claude/.mcp.json` inside
> the repo instead.

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

## Troubleshooting

### T1 — `$ITERM_PROFILE` is empty, `cc` launches with wrong model

**Symptom:** `echo $ITERM_PROFILE` returns nothing. The `cc` alias falls through with no model flags.

**Cause:** Old iTerm2 version (< 3.3) or the pane was opened before the profile was applied.

**Fix:**
- Update iTerm2 to 3.3+ (Help → Check For Updates).
- Reopen the pane via **Profiles → [your profile name] → Open in current tab**.
- Confirm: `echo $ITERM_PROFILE` should print `DEV-AUDIT`, etc.

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
# Expected: protect-env.py  protect-git-push.py  circuit-breaker.py  session-start-reset.py

# Check 2 — python3 available
which python3  # must return a path; if missing: brew install python3

# Check 3 — settings.json is valid
python3 -m json.tool ~/.claude/settings.json  # prints formatted JSON on success
```

---

### T4 — Circuit-breaker stuck after tool failures

**Symptom:** Claude is blocked and won't proceed.

**Fix A:** Press `Ctrl+C`, then `cc`. The `session-start-reset.py` hook fires on session start and resets the counter automatically.

**Fix B:** Delete the state file (it lives in the project root, where Claude Code was launched from):
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

---

## Quick Reference Card

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
│  PROMPT → prompt/content changes (separate from code)    │
│                                                          │
│  gate = run full test suite    ship = gate + git add -p  │
└──────────────────────────────────────────────────────────┘
```
