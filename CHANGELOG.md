# Changelog

## 2026-06-05 — Pane handoff feature

Optional file-based bracketed-paste routing between AUDIT and IMPL panes. Write a directive to a scope-keyed file in one pane, it arrives as a single paste in the other. Built around a launchd-managed `fswatch` daemon that wraps file content in bracketed-paste escapes and injects it into the bound iTerm session via AppleScript.

### New files

- [`HANDOFF_GUIDE.md`](HANDOFF_GUIDE.md) — operator manual (install, daily ops, troubleshooting, isolation probes)
- [`HANDOFF_GUIDE.html`](HANDOFF_GUIDE.html) — styled visual version of the guide
- [`handoff/pane-handoff.sh`](handoff/pane-handoff.sh) — the watcher
- [`handoff/com.user.handoff.plist.template`](handoff/com.user.handoff.plist.template) — launchd template (installer renders `$HOME`)
- [`handoff/zshrc-handoff.sh`](handoff/zshrc-handoff.sh) — shell functions (`handoff-*`, `send-*`)
- [`handoff/install.sh`](handoff/install.sh) — one-shot installer (idempotent, supports `--uninstall`)
- [`handoff/README.md`](handoff/README.md) — directory overview
- [`hooks/enforce-handback.py`](hooks/enforce-handback.py) — Stop hook that prevents IMPL from claiming "→ handed back" without writing the file
- [`commands/start-impl.md`](commands/start-impl.md) — `/start-impl` slash command (IMPL pane pre-flight + hand-back protocol)
- [`commands/start-audit.md`](commands/start-audit.md) — `/start-audit` slash command (AUDIT pane pre-flight + directive routing)

### Modified

- `README.md` — added a Handoff callout and a Step 8 install line
- `index.html` — added the handoff callout linking to `HANDOFF_GUIDE.html`
- `zshrc-snippet.sh` — added an optional handoff note pointing readers to `handoff/zshrc-handoff.sh`
- `hooks/settings.json.example` — added the Stop hook registration for `enforce-handback.py`

### Dependencies

- `fswatch` (Homebrew) — required for the watcher
- `osascript` (macOS built-in) — for bracketed-paste injection
- iTerm2 — for scriptable session targeting

### Why this lives in this repo

The 4-pane setup is the prerequisite — handoff is meaningless without two panes bound to different roles. Adding handoff here means a single `./handoff/install.sh` step takes the AUDIT↔IMPL workflow from "copy-paste between panes" to "write a file, the other pane sees it instantly".

---

## 2026-04-15 — Guide rewrite (friend-install path)

### Breaking change — iTerm2 profile prefix renamed `DEV-*` → `CC-*`

The four iTerm2 profile names have changed:

| Old | New |
|-----|-----|
| `DEV-AUDIT` | `CC-AUDIT` |
| `DEV-IMPL` | `CC-IMPL` |
| `DEV-PROMPT` | `CC-PROMPT` |
| `DEV-PLAN` | `CC-PLAN` |

**Migration:** In iTerm2 → Preferences → Profiles, rename each profile. The `zshrc-snippet.sh` `case` block and all guide references now use `CC-*`.

**Why:** `CC-` is more descriptive for friends installing from scratch ("Claude Code") and decouples from any existing `DEV-*` profiles a reader may already have.

### New content

- RAM-tier-gated install path (16 GB / 32 GB / 64 GB)
- Prerequisites section (Homebrew, Node.js, Xcode CLT)
- Claude Code install section (browser OAuth primary, API key as alternative)
- Ollama local AI models section (`llm-fast`, `llm-code`, `llm-reason`, `llm-embed`, `llm-smart` router)
- Draw Things optional section

### Removed

- `m5-max-ai-workstation-setup.md` — removed from public repo (local copy retained, gitignored)
- `m5-max-quick-reference.md`, `ai-workstation-cheatsheet.html` — removed from public repo (local copies retained, gitignored)
- `m5-max-quick-reference.html` — superseded by new guide (fully deleted)

### CLAUDE.md.template

Rewritten as an annotated skeleton with placeholders. Not a clone of the author's personal file — friends should fill in their own stack and constraints.
