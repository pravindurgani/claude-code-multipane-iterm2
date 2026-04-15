# CLAUDE.md — claude-code-multipane-iterm2

**Weight Class: Tool** — public repo, external users read and install the hooks/skills/commands verbatim, but this is a setup guide / scaffold, not a shipped product with a runtime. Treat changes with Tool-level rigour (BaseLLMClient-style abstraction not required, audit on every change, CI optional for a docs-only scaffold, monitoring optional).

Project-specific invariants for working on this repo.
Global conventions live in ~/.claude/CLAUDE.md.

---

## Repo Structure

- guide.md and index.html are parallel documents — the same content must appear in both.
  When adding a section to one, add the equivalent to the other.
  Section numbering in index.html uses three coupled values that must stay in sync:
  the id="sN" anchor, the <span class="section-num"> display label, and the TOC href.
  When adding a section, update all three together.

- guide.md `## Overview` is intentionally rendered as the index.html hero block, not a
  numbered section. This divergence is ratified — do not re-flag as a parity issue.

- step_guide.md is gitignored and local-only. Append new ╔══╗ phase blocks after each
  phase commit — they persist locally as a running implementation log but never appear
  in git status.

- index.html callout divs use class="callout tip" with inner <span class="callout-icon">
  + <div> for body text. Code-block divs use class="code-block" with nested <div> per
  line. Read the surrounding section before editing — guide.md alone is not sufficient
  to infer the exact HTML structure.

---

## Hooks

- protect-env.py blocks writes to ~/.claude/hooks/ at the tool level. Hook templates
  must be created in the project repo (hooks/) and installed via a manual cp command.
  Never attempt to Write or Edit directly to ~/.claude/hooks/.

- ~/.claude/settings.json contains # comment lines and is not valid JSON. Any
  verification script that parses it must strip comment lines first:
  json.loads(''.join(l for l in open(path) if not l.strip().startswith('#')))

- SessionStart hooks must always exit 0. Print to stdout for informational output but
  never raise an uncaught exception or call sys.exit() with a non-zero code — doing so
  blocks every Claude Code session from starting.

---

## Version String

Two different version-string semantics live in this repo — don't conflate them.
See ARCHITECTURE.md §3 for the full rationale.

- **Current-version marker (1 place): index.html footer (line ~2024).**
  Bumps on every Claude Code release. AUDIT treats drift here as HIGH — a stale
  footer shows the reader the wrong current-state claim in the first second on
  the page.

- **Last-verified-against markers (4 places): guide.md:368
  flag-compatibility note, guide.md:836 T7 troubleshooting, index.html:1239
  flag-compatibility note, index.html:1906 T7 mirror.** Bumps only when someone
  actually re-walks the guide against a new Claude Code version. AUDIT treats
  drift here as LOW staleness, not a correctness bug.

- `hooks/version-check.py` fires a SessionStart reminder when `claude --version`
  changes — the default response is a footer bump. Re-verify is a separate,
  deliberate session.

---

## Public Repo Hygiene

- Before any git push, check .mcp.json.example for personal paths (/Users/username/...)
  and PAT placeholders that match real token format and length — both trigger GitHub
  push protection and will block the push.
  Use clearly fake placeholders like YOUR_USERNAME and YOUR_READONLY_PAT_HERE.