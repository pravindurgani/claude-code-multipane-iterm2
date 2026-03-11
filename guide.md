# iTerm2 Multi-Pane Claude Code Setup — Universal Reference

> Corrected, battle-tested version. Implemented and verified on macOS with
> iTerm2 + Claude Code v2.1.72. Reusable for any project. March 2026.

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
> short project prefix (e.g. `SS` for SensiSpend, `WEB` for a web app).

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
6. **Set as default:** `Window → Save Window Arrangement As Default`.
7. **Auto-restore on launch:** Go to `iTerm2 → Settings → General → Startup`
   → set to **"Open Default Window Arrangement"**.

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
| `--effort high`                   | Effort level: `low`, `medium`, `high`, `max` |
| `--permission-mode plan`          | Read-only — Claude can't write files       |
| `--permission-mode acceptEdits`   | Auto-accept file edits without asking      |
| `--append-system-prompt "..."`    | Add custom instructions on top of defaults |
| `--continue`                      | Resume most recent conversation            |
| `--resume`                        | Resume a specific session by ID            |

> **On `--dangerously-skip-permissions`:** `--permission-mode acceptEdits` is
> more targeted — it auto-accepts file edits while still asking before shell
> commands. Only use `--dangerously-skip-permissions` in fully sandboxed
> environments.

> **Version note:** Flags verified against Claude Code v2.1.72 (March 2026).
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

Never send work to AUDIT until tests pass:

```bash
# Add to ~/.zshrc if desired
alias audit-ready='pytest tests/ -v --tb=short && echo "Ready for AUDIT pane"'
```

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

1. **Rename profiles:** `DEV-AUDIT` → `SS-AUDIT` (for SensiSpend), etc.
2. **Update Initial directory** in each profile to the new project path.
3. **Update `~/.zshrc`** — add new `case` entries matching the new profile
   names (e.g. `SS-AUDIT`).
4. **Add project-specific slash commands** to `.claude/commands/`.
5. **Save a project-specific arrangement** named after the project.

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
│  IMPL → implement + run tests (must pass)                │
│  AUDIT → review changed files (read-only)                │
│  PROMPT → prompt/content changes (separate from code)    │
└──────────────────────────────────────────────────────────┘
```
