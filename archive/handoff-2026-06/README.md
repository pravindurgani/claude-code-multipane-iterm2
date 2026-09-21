# Archived: Pane Handoff (Step 19)

**Retired 2026-09-21.** The author moved to a shared-memory model:
persistent memory (Sigil) plus a shared `AGENTS.md` kernel now cover what
the handoff loop was for. The AppleScript bracketed-paste injection path
this feature relied on is an injection-class risk surface (untrusted text
delivered into a pane's transcript as if typed by the user) not worth
carrying once a simpler alternative existed.

## What's here

- `handoff/` — daemon, install script, LaunchAgent template, zsh glue
- `HANDOFF_GUIDE.md` / `.html` — the full feature guide
- `hooks/enforce-handback.py` — the Stop hook enforcing handback
- `commands/start-audit.md`, `start-impl.md` — pane-start slash commands

Last working state: commit `a706e6b` (live and documented as current).

## Restoring it

`git checkout a706e6b -- handoff HANDOFF_GUIDE.md HANDOFF_GUIDE.html hooks/enforce-handback.py commands/start-audit.md commands/start-impl.md`, move the paths back to repo root, re-run `handoff/install.sh`, and revert the "(retired, archived)" Step 19 edits in guide.md/index.html.
