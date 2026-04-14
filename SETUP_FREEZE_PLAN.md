# Setup Freeze Plan — Finish the Multipane Setup, Then Build

**Date:** 2026-04-14
**Goal:** Close out the multipane setup in one focused session, then stop touching it for 90 days.

---

## The honest read

You are not missing tools. You are missing a stopping rule.

Your current infrastructure already exceeds what those Reddit posts describe:

| Reddit pattern | What you already have |
|---|---|
| **three-man-team** (Architect/Builder/Reviewer, markdown handoffs) | AUDIT/IMPL/PLAN/PROMPT panes with `SESSION_LOG.md` as the handoff artifact, **plus** adversarial Opus-reviews-Sonnet, **plus** hook-enforced invariants (`protect-env`, `protect-git-push`, `circuit-breaker`). Three-man-team is a lighter, less rigorous subset of your setup. |
| **MCP Code Mode** (`defer_loading=True` + `tool_search`) | You use a handful of MCP servers, not 500. The 92% headline only kicks in at scale. Worth knowing; not worth rebuilding around. |
| **RAG Techniques book** (chunking, HyDE, CRAG) | Not in your stack. `reddit-harvest` is a keyword/signal pipeline, not a RAG system. Ignore. |

**Adopting any of these would be a sideways move, not forward motion.** The things you actually have open and unfinished are small and specific. Finish those and declare the setup frozen.

---

## What's actually left to close

Three buckets. Time-boxed. After this, no more setup work for 90 days.

### Bucket 1 — Execute the approved IMPL plan (~30 min)

This is already planned, already approved (`~/.claude/plans/adaptive-percolating-sphinx.md`). Just run it:

1. Fix H1 in `hooks/version-check.py` (wrap `read_text` + both `write_text` calls in `try/except OSError`, cp to `~/.claude/hooks/`).
2. `git init` the multipane repo, initial commit.
3. Create `SESSION_LOG.md` at repo root with the seed entry.
4. Run the four verification commands from the plan.

**Done = `/start-audit` re-run returns clean on H1.**

### Bucket 2 — Close the structural gaps the "situational picture" flagged (~45 min)

These came up in the earlier gap analysis and are the *real* unfinished items, but they're tiny. Do them in the same IMPL session:

1. **Weight Class declaration in `.claude/CLAUDE.md`** — add one line at the top: `Weight Class: Tool` (public repo, external users, not a product). Global CLAUDE.md mandates this per-project; it's a 30-second fix.

2. **`ARCHITECTURE.md` at repo root** — one page. Document the four things that matter and are non-obvious:
   - `guide.md` ↔ `index.html` parallel-sync constraint (section numbering is coupled)
   - Hook install pattern: templates in `hooks/`, installed via `cp` to `~/.claude/hooks/`, never edited in place
   - Version-string triad: `guide.md` intro, `guide.md` T7, `index.html` footer — change all three together
   - `SESSION_LOG.md` as the cross-pane handoff artifact (what each pane reads, what each pane writes)

3. **Populate `.claude/REFERENCE.md` from the template** — the AUDIT-pane/IMPL-pane split is only useful if they load different context. Fill in the template with:
   - AUDIT section: security checklist, invariants from CLAUDE.md, "do not approve with HIGH unresolved"
   - IMPL section: hook install pattern, schema drift awareness, git push requires approval
   - PLAN section: scope boundaries, "defer MEDIUM/LOW to follow-up session"

**Done = next session, every pane has the context it actually needs on load.**

### Bucket 3 — Defer the AUDIT M1–M4 / L1–L4 findings to *one* follow-up session (~60 min, separate day)

Schedule it once, in the calendar, for next weekend. Single session. Fix all eight. Don't touch them before then and don't touch them after.

- **M1** — `protect-git-push.py` command-substitution bypass → document as known limitation in the hook docstring. (Do not expand the tokeniser. Out of scope for this project.)
- **M2** — `_THRESHOLD = 3` → read from `CLAUDE_CB_THRESHOLD` env var with fallback to 3.
- **M3** — reset-on-trip semantics → keep current behaviour, update the comment to say "intentional forgive-and-forget; sticky block would block useful retries across sessions."
- **M4** — state file under `Path.home() / ".claude"` not `Path.cwd()`. Fix both writers.
- **L1** — schema drift on `reset_at` → make `circuit-breaker.py` preserve `reset_at` on updates.
- **L2/L3/L4** — document or close as "working as designed."

**Done = one commit, one log entry, gate closed.**

---

## What to explicitly NOT do

To protect your focus:

- **Do not adopt three-man-team.** You'd be wiring a less rigorous version of what you already run across your panes. Net negative.
- **Do not rebuild your MCP layer for Code Mode / `tool_search`.** You don't have 500 tools. The break-even is ~50+ tools; you're nowhere near it. Revisit only if you add 5+ more MCP servers.
- **Do not read the RAG book.** It's not in your stack. `reddit-harvest` is a signal scorer over keyword taxonomy, not semantic retrieval.
- **Do not add an ARCHITECTURE.md to reddit-harvest or AgentSutra this session.** Separate repos, separate plans, separate days. Scope discipline is the whole point.
- **Do not push the multipane repo public yet.** That's a marketing decision, not a setup decision. Decide it after you've shipped Issue #2 of Unbuilt.

---

## The freeze

After Bucket 1 + 2 ship today and Bucket 3 ships next weekend:

> **No further changes to the multipane setup, hooks, skills, slash commands, or global CLAUDE.md until 2026-07-14 (90 days), barring a genuine blocker that prevents shipping.**
>
> "I saw a cool Reddit post" is not a genuine blocker. Add the link to a `backlog/setup-ideas.md` file, close the tab, go back to Unbuilt or AgentSutra.

The test for "genuine blocker": *has this bug/gap stopped me from completing a real work task twice this week?* If no, it goes in `backlog/setup-ideas.md` and waits until 2026-07-14.

**Override log:**
2026-04-14 21:XX — FREEZE OVERRIDDEN. Reason: friend-install rewrite of M5 Max workstation guide. New freeze begins when rewrite ships. Tracked in SESSION_LOG.md.

---

## What to build instead

You already know. In rough priority:

1. **Unbuilt Issue #2** — you sent #1 to friends. The pipeline works. Ship #2 on schedule. Every week you don't ship #2, the project dies a little.
2. **First paying subscriber for Unbuilt** — the monetization strategy is written. Pick *one* path (sponsorship outreach, B2B intelligence report, or white-label retainer) and do it this month.
3. **AgentSutra v8.5.1 remediation** — 20 fixes planned, 15 failures in the Telegram suite. Close the loop and cut a release.
4. **Clarion role negotiation** — live conversation with Matt. Don't let it drift.

The multipane setup exists to make 1–4 faster. It is not the work. It is the scaffold.

---

## Execution order today

```
# IMPL pane, in ~/Desktop/claude-code-multipane-iterm2

# Bucket 1
# (follow the adaptive-percolating-sphinx.md plan — already approved)

# Bucket 2 (same session)
# 1. Add "Weight Class: Tool" to .claude/CLAUDE.md
# 2. Create ARCHITECTURE.md
# 3. Populate .claude/REFERENCE.md from template

# Then commit as a third commit:
git add .claude/CLAUDE.md ARCHITECTURE.md .claude/REFERENCE.md
git commit -m "docs: weight class, architecture, per-pane reference"

# Append to SESSION_LOG.md:
#   2026-04-14 — IMPL (continued)
#   - Added Weight Class, ARCHITECTURE.md, REFERENCE.md
#   - Setup frozen until 2026-07-14
#   Next: ship Unbuilt Issue #2
```

Then close the pane and open the reddit-harvest repo. Different project, different SESSION_LOG, different work.

---

## One-line version

**Fix H1, git init, write three small docs, freeze the setup for 90 days, go ship Unbuilt Issue #2.**
