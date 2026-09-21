# Mac + Claude Code — AI Workstation Setup Guide

> How to run four specialised Claude Code sessions in one iTerm2 window, each
> locked to its own role, model and permission mode — and how to work in that
> setup day to day.

**Who this is for:** tech-literate developers on an Apple Silicon Mac. Every
command block is a literal paste — no substitution required unless noted.

**Estimated time:** about 45 minutes hands-on, or 25 if you already have Homebrew,
Node and iTerm2. Local models (Part III) are optional and add 15–90 minutes of
unattended downloading.

Parts I and II are the setup and the daily loop. Part III is a menu of
independently skippable add-ons. Part IV is reference.

---

## What you are building

Four Claude Code sessions in a 2×2 grid, each with its own iTerm2 profile,
colour, model, effort level and permission mode:

```
┌─────────────────┬──────────────────┐
│   AUDIT (Opus)  │  PROMPT (Sonnet) │
│   purple bg     │  cyan bg         │
├─────────────────┼──────────────────┤
│   IMPL (Sonnet) │  PLAN (Sonnet)   │
│   green bg      │  amber bg        │
└─────────────────┴──────────────────┘
```

One command — `cc` — launches the right configuration in whichever pane you type
it in, because the shell snippet branches on `$ITERM_PROFILE`.

The point of the split is permissions, not tidiness. AUDIT runs in plan mode, so
the pane that reviews your code cannot edit it. IMPL auto-accepts edits, so
implementation is not interrupted at every file write. PLAN and PROMPT are
cheap, low-effort sessions for thinking out loud and for prompt or content work.

What you end up with: a saved window arrangement that restores on launch, a
`gate` command that must pass before anything goes to review, and a review pass
that is genuinely independent of the session that wrote the code.

---

## Part I — Install it

Seven steps, strictly sequential. Do them in order.

### Step 1 — Prerequisites

**Homebrew:**

```bash
# Check if Homebrew is already installed:
command -v brew >/dev/null && echo "Homebrew already installed — skip" || \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to your PATH (Apple Silicon only — skip if already in ~/.zshrc):
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

**Node.js** (required for Claude Code) and **iTerm2**:

```bash
brew install node
brew install --cask iterm2
```

Open iTerm2 once to complete its initial setup, then continue inside it. iTerm2
is required because `$ITERM_PROFILE` is what makes per-pane role detection work.

### Step 2 — Install and authenticate Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

Authenticate with browser OAuth (recommended):

```bash
claude auth login
```

This opens a browser window. Sign in with your Anthropic account (Pro or Max
plan). No API key needed with this method.

<details>
<summary>API key alternative (if you don't have a Pro/Max subscription)</summary>

```bash
export ANTHROPIC_API_KEY="sk-ant-your-key-here"
# Add the above line to ~/.zshrc so it persists across sessions.
```

Get a key at console.anthropic.com → API Keys.
</details>

Verify:

```bash
claude --version
```

### Step 3 — Create four iTerm2 profiles

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

**Colors tab** — click the **Background** swatch (in the "Defaults" row), switch
the picker to **Hex** mode, enter the value. Tick **"Tab color"** and set the
accent. Keep everything else from your base theme.

**Text tab** — **JetBrains Mono 13pt** (or Menlo 13pt).

**General tab** — under **Title**, uncheck **"Job Name"** so only "Session Name"
stays ticked and `-zsh` never appears after the role name. Set the **Badge** to
the short role name:

```
CC-AUDIT  → AUDIT
CC-IMPL   → IMPL
CC-PROMPT → PROMPT
CC-PLAN   → PLAN
```

### Step 4 — Startup command and initial directory

In each profile → **General** tab:

**Command** — change the dropdown from "Login Shell" to **"Custom Shell"** and
enter:

```bash
# Same command for all 4 profiles — only the directory changes per project.
# Role detection uses $ITERM_PROFILE (set automatically by iTerm2),
# so the startup command doesn't need to set PANE_ROLE.
/bin/zsh -c 'cd ~/Desktop/your-project; exec zsh'
```

Replace `your-project` with your project directory name. `exec zsh` keeps the
pane alive after any command exits.

**Initial directory** — change from "Home directory" to **"Directory:"** and
enter the full path:

```
/Users/yourname/Desktop/your-project
```

Set both: arrangement restore re-runs the Initial directory but not always the
startup command.

### Step 5 — Shell snippet

Append `zshrc-snippet.sh` (from this repo) to your `~/.zshrc`:

```bash
cat zshrc-snippet.sh >> ~/.zshrc
source ~/.zshrc
```

The snippet provides:

- `$PANE_ROLE` and a coloured prompt per profile
- a title-lock so the pane title stays fixed (won't flip to `-zsh`)
- the `cc` alias — launches Claude with the correct model, effort and
  permissions for the pane you are in
- `gate` and `ship` aliases (IMPL pane only)
- Ollama env vars and `llm-*` aliases (uncomment your tier's block — Part III)

It keys off `$ITERM_PROFILE` and appends to `precmd_functions` so it won't
clobber pyenv, fnm or conda.

**Verify.** Open a new pane using the **CC-IMPL** profile, then:

```bash
echo $PANE_ROLE        # should print: IMPL
echo $ITERM_PROFILE    # should print: CC-IMPL
```

If `$PANE_ROLE` is empty, the pane was not opened with a CC-* profile — open it
via **Profiles → CC-IMPL** in the menu bar.

### Step 6 — Window layout and saved arrangement

1. Open a new window with the **CC-AUDIT** profile.
2. `⌘D` — split right. Right-click the new pane → **Edit Session** → change
   profile to **CC-PROMPT**.
3. Click back on the left pane (AUDIT). `⌘⇧D` — split down. Change the new
   bottom-left pane to **CC-IMPL**.
4. Click on the right pane (PROMPT). `⌘⇧D` — split down. Change the new
   bottom-right pane to **CC-PLAN**.
5. **Save:** `Window → Save Window Arrangement` → name it (e.g. your project name).
6. **Set startup policy:** `iTerm2 → Settings → General → Startup` → set to
   **"Open Default Window Arrangement"**.
7. **Save again as default:** `Window → Save Window Arrangement` → select the
   same name.

iTerm2 now opens the four-pane layout automatically on launch.

**Dual monitor variant:** AUDIT + PLAN on monitor 1, IMPL + PROMPT on monitor 2.
Switch between macOS Spaces with `ctrl+1/2/3/4`.

### Step 7 — Launch with `cc`

Type `cc` in each pane. That's it. The alias expands per pane:

| Pane   | `cc` expands to                                                  |
|--------|------------------------------------------------------------------|
| AUDIT  | `claude --model opus --effort high --permission-mode plan`       |
| IMPL   | `claude --model sonnet --effort high --permission-mode acceptEdits` |
| PROMPT | `claude --model sonnet --effort medium`                          |
| PLAN   | `claude --model sonnet --effort low`                             |

**Verified CLI flags:**

| Flag                              | Purpose                                    |
|-----------------------------------|--------------------------------------------|
| `--model opus`                    | Use Opus (aliases: `opus`, `sonnet`, `haiku`, or a full ID like `claude-fable-5`) |
| `--effort high`                   | Thinking budget: `low` · `medium` · `high` · `xhigh` · `max` |
| `--permission-mode plan`          | Read-only — Claude can't write files. Full set: `plan`, `acceptEdits`, `auto`, `manual`, `dontAsk`, `bypassPermissions` |
| `--permission-mode acceptEdits`   | Auto-accept file edits without asking      |
| `--append-system-prompt "..."`    | Add custom instructions on top of defaults |
| `--continue`                      | Resume most recent conversation            |
| `--resume`                        | Resume a specific session by ID            |

> **Why Opus only in AUDIT:** Opus costs roughly 15× what Sonnet costs per
> token. Reserve it for the review pass, where a second opinion from a stronger
> model earns the money, and leave the other three panes on Sonnet.

> **On `--dangerously-skip-permissions`:** `--permission-mode acceptEdits` is
> more targeted — it auto-accepts file edits while still asking before shell
> commands. Only use `--dangerously-skip-permissions` in fully sandboxed
> environments.

> **Version note:** Flags verified against Claude Code v2.1.278 (September 2026).
> CLI tools update frequently — run `claude --help` if a flag isn't recognised.

---

## Part II — Work in it

### How work moves between panes

**Work goes round a fixed loop, and you carry it across pane boundaries by hand.**

```
PLAN  → Discuss approach. No file writes. Get architecture sign-off.
IMPL  → Implement. Run tests immediately after (must pass).
AUDIT → Review the changed files (read-only). Feed findings back to IMPL.
PROMPT → (When prompt/content files change) Separate from code changes.
```

When AUDIT identifies an issue, copy its output and paste it into IMPL with:

```
The AUDIT pane identified: [paste findings here].
Fix this while preserving existing patterns. Do not touch unrelated files.
```

**Context hygiene:**

- **Run `/clear` in the AUDIT pane before every review pass.** Otherwise AUDIT
  reviews the versions cached in its context, not what IMPL just wrote.
- **Re-anchor on long sessions:** "Before starting, re-read CLAUDE.md and confirm
  the project invariants. Then…"
- **Scope AUDIT explicitly:** "Focus ONLY on src/auth.py and src/middleware.py.
  Do not read any other files unless I explicitly ask."
- **`/compact`** frees context without losing all history — use it instead of
  `/clear` when the history still matters.

### The gate and ship commands

**Nothing reaches AUDIT until the tests pass.**

| Alias | What it runs | When to use |
|-------|-------------|-------------|
| `gate` | pytest suite (tests/); exits non-zero on failure | Before handing off to AUDIT |
| `ship` | `gate` + interactive `git add -p` + `git commit` | When tests pass and work is commit-ready |

```bash
# After making changes:
gate
# → ... pytest output ...
# → ✅ GATE PASSED

# When ready to commit:
ship
# → runs gate, then prompts for staged hunks + commit message
```

`gate` and `ship` are defined only when `$ITERM_PROFILE == CC-IMPL`. Running them
in other panes is a harmless no-op. The loop is:

```
IMPL → implement → gate (must pass) → AUDIT → findings → IMPL → fix → gate → AUDIT
```

Start pytest-only; add lint, type checking and a docker build to `gate` once you
know they are load-bearing.

### The SESSION_LOG pattern

**A SESSION_LOG gives the next session somewhere to resume from.**

Keep a `SESSION_LOG.md` in your project root. Append a new entry at the end of
every session; never overwrite old entries. Then instruct Claude, in your
`CLAUDE.md`, to read the last 60 lines of it at session start and surface the
most recent "Next:" items.

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

### Splitting rules: CLAUDE.md and AGENTS.md

**Split global rules from project rules so neither leaks into the other.**

| File | Location | Committed? | Contains |
|------|----------|------------|---------|
| Global rules | `~/.claude/CLAUDE.md` | No — personal | Coding conventions, error-handling policy, tool preferences |
| Project rules | `.claude/CLAUDE.md` (repo) | Yes | Project architecture, active constraints, session continuity |

Load order is: managed policy, then user `~/.claude/CLAUDE.md`, then project
`./CLAUDE.md`, then `./CLAUDE.local.md`. They concatenate — later files add to
earlier ones, they do not override them.

`@path` imports pull one rules file into another. Absolute, `~` and relative
paths all work, and imports nest up to four levels deep.

**Sharing one rule set with other agents.** `AGENTS.md` is an open standard
(<https://agents.md/>) supported by roughly 28 tools, including Claude Code,
Codex, Cursor, Copilot, Gemini CLI, Zed and Aider. From v2.1.277, Claude Code
reads `AGENTS.md` only when no `CLAUDE.md` exists in that directory or above it.

So the portable pattern is: put the shared rules in `AGENTS.md`, and make
`CLAUDE.md` a one-line import.

```bash
echo '@AGENTS.md' > CLAUDE.md
```

Every agent then reads the same rules, and you can still append Claude-only
rules underneath the import line.

Two starter templates ship with this repo: **`CLAUDE.md.template`** (copy to
`~/.claude/CLAUDE.md`, do not commit) and **`REFERENCE.md.template`** (copy to
`.claude/REFERENCE.md` and commit — the AUDIT pane uses it for sprint context and
known issues).

**The common mistake:** rules files past roughly 200 lines dilute adherence — the
model reads everything and weights nothing. Prose is a suggestion. Anything that
must be *enforced* belongs in a hook (Part III), not in a rules file.

### Adapting it to another project

1. **Rename profiles:** `CC-AUDIT` → `MYPROJECT-AUDIT`, etc.
2. **Update Initial directory** in each profile to the new project path.
3. **Update `~/.zshrc`** — add new `case` entries matching the new profile names.
4. **Add project-specific slash commands** to `.claude/commands/`.
5. **Save a project-specific arrangement** named after the project.

---

## Part III — Optional add-ons

Each of these is independent. Skip any of them and Parts I and II still work.

### Safety hooks

**Hooks enforce what prompt instructions only request.** Claude Code runs them
before and after tool use, and at session start.

| Tier | Event | Purpose |
|------|-------|---------|
| **PreToolUse** | Before the tool executes | Block dangerous actions before they happen |
| **PostToolUse** | After the tool returns | Observe outcomes; trip circuit-breaker on repeat failures |
| **SessionStart** | When a new session opens | Reset counters; validate session state |

1. Copy the hook scripts to `~/.claude/hooks/`:
   ```bash
   mkdir -p ~/.claude/hooks
   cp hooks/protect-env.py ~/.claude/hooks/
   cp hooks/protect-git-push.py ~/.claude/hooks/
   cp hooks/circuit-breaker.py ~/.claude/hooks/
   cp hooks/session-start-reset.py ~/.claude/hooks/
   cp hooks/version-check.py ~/.claude/hooks/
   ```

2. Merge the `"hooks"` block from `hooks/settings.json.example` into the top
   level of `~/.claude/settings.json`. All `"command"` values use `$HOME` —
   Claude Code does not expand `~`. The example also sets
   `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` to `"50"`, auto-compacting the conversation
   at 50% of the context window; `"0"` disables it.

| Hook | Tier | Blocks when |
|------|------|------------|
| `protect-env.py` | PreToolUse | Edit/Write/MultiEdit targets any `.env` file |
| `protect-git-push.py` | PreToolUse | Bash command matches `git … push` (any flag order) |
| `circuit-breaker.py` | PostToolUse | 3 consecutive tool failures in a session |
| `session-start-reset.py` | SessionStart | (resets failure counter — never blocks) |
| `version-check.py` | SessionStart | (never blocks — prints update checklist when Claude Code version changes) |

> **Platform note:** Hook scripts use `fcntl` and run on macOS and Linux only.

### MCP server, slash commands and skills

**GitHub MCP server.** Claude Code registers MCP servers via `claude mcp add`,
not by reading a config file from disk. The included `.mcp.json.example` is
reference JSON if you need `claude mcp add-json` instead.

```bash
brew install github-mcp-server
```

```bash
claude mcp add github -s user \
  -e GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_readonly_token \
  -- $(which github-mcp-server) stdio
```

Generate a read-only PAT at <https://github.com/settings/tokens> with scope
`public_repo` (or `repo` for private-repo access); recommended expiry 90 days.
Verify with `claude mcp list | grep github`. `-s user` registers the server for
all projects — omit it to restrict to the current one.

**`/reflect` slash command.** `commands/reflect.md` defines a command you run at
the end of an IMPL or AUDIT session: it reads the recent git log and diff, then
outputs a table of suggested CLAUDE.md additions. It never edits the file — you
decide what to incorporate.

```bash
mkdir -p ~/.claude/commands
cp commands/reflect.md ~/.claude/commands/reflect.md
```

**Contextual skills.** The `skills/` directory holds three skills that load
automatically when the task matches their trigger description.

| Skill | When it activates | What it adds |
|-------|------------------|--------------|
| `code-review` | Code review tasks (AUDIT pane) | Project-specific review conventions |
| `security-audit` | Security review tasks (AUDIT pane) | Security checklist and vulnerability patterns |
| `testing` | Writing/reviewing tests (IMPL pane) | pytest conventions matching the project |

```bash
cp -r skills/ ~/.claude/skills/
```

### Local models with Ollama

**Private inference on your own machine, with no API calls.**

Nothing else in this guide requires Ollama — only Sigil (below) does, for its
fact classifier.

| Tier | RAM | What you get |
|------|-----|-------------|
| 🟢 **Base** | 16 GB+ | Claude Code + small local models (fast/code/embed) |
| 🔵 **Mid** | 32 GB+ | Above + reasoning model + larger fast/code models |
| 🔴 **Full** | 64 GB+ | Above + vision model + 32B code model |

```bash
brew install ollama
brew services start ollama
```

Pull the block matching your RAM. Times assume a 100 Mbps connection.

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

Uncomment your tier's block in the Ollama section at the bottom of
`zshrc-snippet.sh` to get `llm-fast`, `llm-code`, `llm-reason` (🔵 32 GB+),
`llm-embed` and the `llm-smart` router.

### Persistent memory with Sigil

**Every pane is a separate session, and every session starts with amnesia.**

[Sigil](https://github.com/Anmol-Srv/sigil) is an open-source, local-first
memory system by [Anmol Srivastava](https://github.com/Anmol-Srv). It runs hooks
inside every Claude Code session that inject relevant stored facts before Claude
sees your prompt, and capture memorable ones afterwards.

Why this setup in particular benefits: the SESSION_LOG pattern carries context
*forward in time* within one project. Sigil carries it *sideways* — across all
four panes and across project boundaries, so you stop re-explaining "we use
pnpm, not npm" in every pane, every session.

```bash
# Install (clones to ~/.sigil/app, adds to PATH, starts the daemon)
curl -fsSL https://raw.githubusercontent.com/Anmol-Srv/sigil/master/install.sh | sh

# Configure — interactive wizard with live connection tests
sigil init
```

> **⚠️ The one setting that matters: point the LLM provider at a local Ollama
> model.** Claude Code runs `UserPromptSubmit` hooks synchronously on *every
> prompt you type*, with a roughly 10-second budget. A provider that shells out
> to `claude -p` takes about 16 seconds per call — every prompt then shows
> `UserPromptSubmit hook timed out after 10s` and you get no memory injection at
> all. Fact classification is a routing job, not a reasoning job.

Everything else — database choice, embedding provider, namespaces, the `sigil
facts` / `remember` / `search` / `ingest` commands, MCP wiring for other
clients — is covered in the upstream README at
<https://github.com/Anmol-Srv/sigil>. Never store secrets in it: the database is
local but not encrypted at rest.

### iTerm2 triggers

**Auto-highlight keywords in terminal output.**

**Profile → Advanced → Triggers → +**

| Regex                                    | Action         | Colour          |
|------------------------------------------|----------------|-----------------|
| `\b(CRITICAL\|ERROR\|FAIL(ED)?)\b`      | Highlight Text | Red background  |
| `\b(PASS(ED)?\|SUCCESS)\b`              | Highlight Text | Green background|
| `\b(WARNING\|WARN\|TODO)\b`             | Highlight Text | Yellow background|

---

## Part IV — Reference

### Agent teams or four panes?

**Claude Code can already spawn teammates into split panes — it solves a
different problem.**

[Agent Teams](https://code.claude.com/docs/en/agent-teams) is a built-in,
experimental feature, off by default. Enable it with
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. iTerm2 split panes additionally need
the `it2` CLI and the iTerm2 Python API enabled.

Teammates run inside one lead session, and that is where the difference bites:

- **Permissions are inherited.** "Teammates start with the lead's permission
  mode," and "you can't set per-teammate permission modes at spawn time." There
  is no way to spawn a teammate that is read-only while the lead writes files —
  which is the whole basis of the AUDIT pane.
- **Tokens.** Teammates use significantly more tokens — one context window each.
- **Durability.** `/resume` and `/rewind` do not restore in-process teammates.

**The verdict.** Use agent teams for short bursts of parallel exploration inside
a single task — several teammates reading different subsystems at once. Use this
four-pane setup when you want durable, separately-permissioned sessions that
outlive a task, and a reviewer that genuinely cannot write files. They are
complementary, not competing; nothing stops you spawning a team inside the IMPL
pane. If Anthropic later adds per-teammate permission modes, agent teams will
cover much of what this setup exists for.

### Common questions

#### Can I run this with tmux instead of iTerm2?

**Partly — you would have to replace the role-detection mechanism.** The snippet
branches on `$ITERM_PROFILE`, which iTerm2 sets for you on every session,
including arrangement restores. In tmux you would set your own per-pane
environment variable and branch on that, and rebuild the layout and colours in
tmux config.

#### Does the reviewer really not write files?

**Yes.** The AUDIT pane launches with `--permission-mode plan`, which is enforced
by Claude Code itself, not by an instruction in a prompt. It can read, search and
report; it cannot edit.

#### How much does running Opus in one pane cost?

**Roughly 15× Sonnet per token, but only on review passes.** AUDIT is idle while
you implement, and a review reads far fewer tokens than an implementation
session writes. The other three panes stay on Sonnet.

#### Can I use fewer than four panes?

**Yes — IMPL plus AUDIT is the pair that earns its keep.** PLAN and PROMPT are
conveniences; drop them and use `/clear` in IMPL when you switch modes. Keep the
separation between the pane that writes and the pane that reviews.

#### Does this work on Linux or Windows?

**Claude Code does; this layout does not.** The profiles, arrangements and
`$ITERM_PROFILE` detection are macOS + iTerm2. The hook scripts use `fcntl`, so
they run on macOS and Linux but not Windows.

#### Do I need Ollama?

**No.** Nothing in Parts I or II touches it. It is only a prerequisite if you
install Sigil and want its classifier to stay inside the hook time budget.

### Troubleshooting

#### T1 — `$ITERM_PROFILE` is empty, `cc` launches with wrong model

**Symptom:** `echo $ITERM_PROFILE` returns nothing; the `cc` alias falls through
with no model flags. **Cause:** iTerm2 older than 3.3, or the pane was opened
before the profile was applied.

**Fix:** update iTerm2 to 3.3+ (Help → Check For Updates), then reopen the pane
via **Profiles → [your profile name] → Open in current tab**.

#### T2 — `cc` launches the C compiler instead of Claude

**Symptom:** `which cc` shows `/usr/bin/cc` — `cc` is the C compiler on many
systems. **Fix:** rename the alias in `~/.zshrc`, replacing all 4 `alias cc=`
occurrences with `alias cl=` (or any name), then `source ~/.zshrc`.

#### T3 — Hooks not firing

**Symptom:** `.env` edits or `git push` commands are not blocked.

```bash
# Check 1 — files exist
ls ~/.claude/hooks/
# Expected: protect-env.py  protect-git-push.py  circuit-breaker.py  session-start-reset.py  version-check.py

# Check 2 — python3 available
which python3  # must return a path; if missing: brew install python3

# Check 3 — settings.json is valid
python3 -m json.tool ~/.claude/settings.json  # prints formatted JSON on success
```

#### T4 — Circuit-breaker stuck after tool failures

**Fix A:** press `Ctrl+C`, then `cc` — `session-start-reset.py` resets the
counter at session start. **Fix B:** delete the state file:

```bash
rm -f ./circuit-breaker-state.json
# Then /clear inside Claude Code to reset conversation context.
```

#### T5 — `gate` fails with "pytest not found" or 0 tests collected

- Activate your venv first: `source venv/bin/activate` (or `.venv/bin/activate`).
- Verify: `which pytest` should point inside your venv. If not: `pip install pytest`.
- If there are no test files yet, add a placeholder: `touch tests/test_placeholder.py`.

#### T6 — Need to push to git, the hook is blocking it

`protect-git-push.py` blocks Claude from pushing autonomously. Hooks only
intercept tool calls inside a session, so push from a regular shell:

```bash
# Open a new tab (not inside a Claude session) and run:
git push
```

#### T7 — Claude CLI update broke the `cc` alias

**Symptom:** after `npm update -g @anthropic-ai/claude-code`, `cc` errors with an
unknown flag.

1. Run `claude --help` to see current supported flags.
2. Update the alias block in `~/.zshrc` to match, then `source ~/.zshrc`.
3. Run `claude --version` to confirm your installed version. This guide was verified against v2.1.278 (September 2026).

> **Tip:** The `version-check.py` hook detects version changes automatically and
> prints this checklist at session start.

#### T8 — Ollama: model not found or server not running

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

### Quick reference

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

**More iTerm2 keys:** `⌘1-4` switch tab · `⌘F` find in output · `⌘M` set mark ·
`⌘⇧↑` jump to previous mark · `⌘K` clear buffer · `⌘⌥E` broadcast input to all
panes (careful).

**More Claude Code keys:** `Ctrl+C` cancel · `/compact` compress context ·
`/model <name>` switch model mid-session · `/effort <level>` switch effort ·
`/help` list commands.

**Morning boot:** open iTerm2 (arrangement auto-restores) → `cc` in each pane →
`/clear` in AUDIT → PLAN reviews `git log --oneline -10` → IMPL smoke test with
`pytest tests/ -x --tb=short`.

**End of session:** IMPL runs the full suite → `ship` to commit → `/compact` any
long contexts → re-save the arrangement if the layout changed.

---

## Appendix — Retired: pane handoff

An automated AUDIT ↔ IMPL pane handoff add-on was **retired on 2026-09-21**. Its
files are archived under `archive/handoff-2026-06/`. Persistent memory plus a
shared `AGENTS.md` replaced it. See `archive/handoff-2026-06/README.md` if you
want to restore it.
