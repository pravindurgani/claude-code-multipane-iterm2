# REFERENCE.md — Per-Pane Quick Reference

Read at session start by the pane indicated. Update at end of session alongside `SESSION_LOG.md`.

---

## AUDIT pane (Opus, read-only)

Adversarial review. Never edit files from this pane.

- Read the last 60 lines of `SESSION_LOG.md` for what IMPL just changed.
- Read `.claude/CLAUDE.md` for project invariants — specifically:
  - SessionStart hooks must always exit 0 (unhandled `OSError` = HIGH finding).
  - Hook templates live in `hooks/`, installed copies in `~/.claude/hooks/` — diverged copies = HIGH finding.
  - Current-version marker: `index.html:1818` footer only — bumps every release. AUDIT drift = HIGH.
  - Last-verified markers (5 places): `guide.md:4`, `guide.md:249`, `guide.md:692`, `index.html:1074`, `index.html:1803` — bump only on re-verification. AUDIT drift = LOW. See `ARCHITECTURE.md §3`.
  - `guide.md` ↔ `index.html` parallel content; section numbering triad in HTML (`id`, `section-num`, TOC href) must stay coupled.
  - `.mcp.json.example` must use placeholders (`YOUR_USERNAME`, `YOUR_READONLY_PAT_HERE`) — real tokens trigger GitHub push protection.
- Review **only** files changed in the last IMPL session (diff-scope against `git log`).
- Output severity-ranked findings: CRITICAL / HIGH / MEDIUM / LOW.
- **Do not approve anything with CRITICAL or HIGH unresolved.**
- Append findings to `SESSION_LOG.md` with a `Next:` line for IMPL.

---

## IMPL pane (Sonnet)

Implementation only. Don't re-audit; don't re-plan.

- Read the last 60 lines of `SESSION_LOG.md` — work from the most recent `Next:` line.
- Hook install pattern: edit templates in `hooks/`, then `cp hooks/<name>.py ~/.claude/hooks/<name>.py`. Never `Edit`/`Write` into `~/.claude/hooks/` — blocked by `protect-env.py` and diverges from the repo template.
- Schema drift awareness: `circuit-breaker-state.json` has fields written by both `session-start-reset.py` and `circuit-breaker.py` — if you touch one writer, check the other.
- `git push` requires **explicit human approval** (enforced by `protect-git-push.py`). Commit locally, then ask.
- `.env` edits are blocked at the tool level (`protect-env.py`). If you need to change one, ask the user.
- End the session by appending an IMPL block to `SESSION_LOG.md` with a `Next:` line for AUDIT.

---

## PLAN pane (Opus)

Architecture and scope decisions.

- Read the last 60 lines of `SESSION_LOG.md` and the latest AUDIT findings.
- Scope boundary: this repo is a **Tool weight class** setup scaffold. No runtime monitoring, no LLM caching, no CI required for doc changes — but all hook changes pass through audit.
- **Defer MEDIUM/LOW AUDIT findings to a dedicated follow-up session.** Bundle them into one commit when fixing. Don't interleave M/L fixes with new feature work.
- Reddit posts, blog articles, and "cool new framework" links go into `backlog/setup-ideas.md` — they are not blockers and do not justify breaking the freeze. Freeze ends 2026-07-14.
- End with a plan file in `~/.claude/plans/` and a `SESSION_LOG.md` block with `Next:` for IMPL.

---

## Current Sprint

**Sprint goal (2026-04-14):** Close Bucket 1 + Bucket 2 of `SETUP_FREEZE_PLAN.md` — resolve H1, bootstrap git + `SESSION_LOG.md`, land `Weight Class`, `ARCHITECTURE.md`, `REFERENCE.md` docs.

**Freeze starts:** 2026-04-14 after Bucket 2 commit.
**Freeze ends:** 2026-07-14 (90 days). Only genuine blockers justify reopening.

**Real work to ship during freeze:** Unbuilt Issue #2, first paying subscriber, AgentSutra v8.5.1, Clarion negotiation. See `SETUP_FREEZE_PLAN.md` §"What to build instead".

---

## Known Issues

- **[DEFERRED to 2026-07-14+]** AUDIT M1 — `protect-git-push.py` does not recurse into `$(...)` / backtick command substitution. Documented as known limitation; not expanding the tokeniser.
- **[DEFERRED]** AUDIT M2 — `circuit-breaker.py` hardcodes `_THRESHOLD = 3`. Plan: env var `CLAUDE_CB_THRESHOLD` with fallback.
- **[DEFERRED]** AUDIT M3 — circuit-breaker resets on trip instead of sticky-blocking. Intentional (forgive-and-forget across sessions); comment needs clarification.
- **[DEFERRED]** AUDIT M4 — circuit-breaker state file written under `Path.cwd()`. Plan: move to `Path.home() / ".claude"`.
- **[DEFERRED]** AUDIT L1 — `reset_at` schema drift between `session-start-reset.py` and `circuit-breaker.py` writers.
- **[CLOSED as working-as-designed]** AUDIT L2/L3/L4 — no specific action required; behavior is correct and intended. Original findings in plan archive (`~/.claude/plans/adaptive-percolating-sphinx.md`).

All deferred items get one focused session on the weekend after 2026-07-14.

---

## Decisions Log

- **Weight Class = Tool** · 2026-04-14 · Public repo with external readers but no product runtime; hooks/skills are copied-and-used, not imported · Prototype ruled out (public consumption), Product ruled out (no shipped runtime).
- **Setup freeze 2026-04-14 → 2026-07-14** · 2026-04-14 · Infrastructure already exceeds Reddit patterns (three-man-team, MCP Code Mode); further setup work is sideways motion displacing real product work (Unbuilt, AgentSutra) · Accepting new Reddit-inspired ideas ruled out: add to `backlog/setup-ideas.md` instead.
- **`SETUP_FREEZE_PLAN.md` checked in, not gitignored** · 2026-04-14 · Freeze rationale is project context future-me needs to read · Keeping it local ruled out: the commitment needs to be visible to AUDIT pane next session.

---

## External References

- Global Claude Code config: `~/.claude/CLAUDE.md` (Build Process 8-step, Weight Classes, LLM Routing).
- Plan archive: `~/.claude/plans/` — most recent relevant plan is `adaptive-percolating-sphinx.md`.
- Anthropic changelog: https://docs.claude.com/en/docs/claude-code/overview — consult when `version-check.py` fires the update reminder.
- The parallel reddit-harvest / Unbuilt / AgentSutra repos have their own `SESSION_LOG.md` and `REFERENCE.md`. Do not cross-pollinate work here.
