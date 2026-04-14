# Setup Ideas — Post-Freeze Backlog

Items deferred until the setup freeze lifts on **2026-07-14**.

Escalation rule: only promote an item ahead of the freeze if it has blocked real work twice in the same week. Otherwise, wait.

---

## Re-verify guide against current Claude Code (~1 hr)

Walk guide sections 1–7 against the currently installed Claude Code — flags (`claude --help`), hook firing behavior, slash commands, MCP wiring. When the walk is complete, bump the four last-verified-against markers:

- `guide.md:4` — intro paragraph
- `guide.md:249` — flag-compatibility note (§5)
- `guide.md:692` — T7 troubleshooting
- `index.html:1074` — flag-compatibility note (mirror of `guide.md:249`; also update `index.html:1803` which mirrors `guide.md:692`)

Commit as `chore: re-verify guide against Claude Code vX.Y.Z`.

While you're there, decide if the footer's "Verified with …" wording should return. Right now `index.html:1818` reads simply `Claude Code vX.Y.Z · Month YYYY` — dropped "Verified with" because ARCHITECTURE.md §3 now defines the footer as a current-state marker, not a verification claim. After a real re-verify pass, "Verified with" becomes accurate again and could be restored.

## Update `hooks/version-check.py` SessionStart checklist wording

The printed checklist currently says:

> 2. Update version in guide.md (intro, T7) and index.html footer

That reflects the old 3-place triad mental model. Update to match the two-semantic split in ARCHITECTURE.md §3:

> 2. Bump footer: index.html:1818 (on every release)
> 3. Bump last-verified markers only on re-verify pass: guide.md:4, guide.md:249, guide.md:692, index.html:1074

Edit the template in `hooks/version-check.py`, then `cp hooks/version-check.py ~/.claude/hooks/version-check.py`. One commit.

## AUDIT M1–M4, L1–L4 bundle (~60 min)

From the audit already on record in `SESSION_LOG.md`:

- **M1** — `protect-git-push.py` `$(...)` / backtick bypass. Document as known limitation in the hook docstring; don't expand the tokeniser.
- **M2** — `circuit-breaker.py` `_THRESHOLD = 3` → read from `CLAUDE_CB_THRESHOLD` env var with fallback.
- **M3** — reset-on-trip semantics → keep behavior, sharpen comment: "intentional forgive-and-forget; sticky block would block useful retries across sessions."
- **M4** — state file from `Path.cwd()` → `Path.home() / ".claude"`. Update both writers.
- **L1** — preserve `reset_at` across `circuit-breaker.py` writes.
- **L2/L3/L4** — document or close as working-as-designed.

One commit: `fix: address AUDIT M1–M4, L1 from 2026-04-14 review`.
