---
description: Start an IMPL pane session — read context and execute AUDIT directives
---

You are in the IMPL pane. Your role is implementation only. Do not audit your own work.

## Pre-flight (MANDATORY — before any other action)

This pane MUST have `HANDOFF_SCOPE` set. If unset, stop and tell the human to run `handoff-use <project>` first.

```bash
: "${HANDOFF_SCOPE:?HANDOFF_SCOPE not set — run 'handoff-use <project>' in this pane first}"
```

Then check for the scoped HALT sentinel. A HALT in another project's scope does not block this pane.

```bash
test -f ~/.claude/handoff/HALT.${HANDOFF_SCOPE} && cat ~/.claude/handoff/HALT.${HANDOFF_SCOPE}
```

If the scoped HALT exists, do NOT proceed. Surface its contents in chat, state the human action required, and stop.

## Startup
1. Read the last 60 lines of `SESSION_LOG.md`; surface the most recent `Next:` items
2. Read `.claude/CLAUDE.md` and `~/.claude/CLAUDE.md` for invariants
3. Confirm what you are about to build and wait for my go-ahead before writing any code

## Directive intake

When a directive arrives in your prompt (typically pasted from AUDIT — recognisable by the `=== STEP X PHASE Y ===` envelope, GUARDRAILS section, ACCEPTANCE block, and `Begin now` terminator):

1. Echo back ONE LINE: `ACK <phase id> — beginning execution.`
2. Execute the directive VERBATIM. No paraphrase, no scope creep, no "while I'm here" cleanups.
3. On hard stops or guardrail trips, halt at the trip point and print the templated `=== PHASE X HALTED — <reason> ===` block specified by the directive.
4. On completion, print the templated `=== PHASE X COMPLETE ===` report block specified by the directive, then `Awaiting next directive.`

## Done rule
Run `gate` (or the project's equivalent) before marking any task complete.

## Hand-back protocol (MANDATORY — last action of every merge)

After every successful merge to main, before ending your turn, you MUST write the hand-back to disk so the AUDIT watcher fires. Chat-only transcripts are insufficient and will leave AUDIT idle. A Stop hook (`~/.claude/hooks/enforce-handback.py`, installed by `./handoff/install.sh`) mechanically blocks your turn from ending if you print `→ handed back` without writing this file — do not try to work around it, just write the file.

**Step 1.** Run this Bash heredoc. Fill every field. Do not skip fields — write "n/a" if genuinely empty.

```bash
cat > ~/.claude/handoff/to-audit.${HANDOFF_SCOPE}.txt << 'HANDOFF_EOF'
Step: <e.g. 8ac>
Merged SHA: <short sha on main>
Gate: <P/F counts across ruff/mypy/bandit/pip-audit/pytest, e.g. 184P 0F>
Suppression: <count of # type: ignore + # noqa + # nosec, e.g. 20>
Net-new LOC: <added/removed since prior merge>
Deviations from plan: <bullet list or "none">
STOP triggers fired: <list or "none">
Surface assessment: <1-3 sentences on what is now sealed vs still open>
Next-axis recommendation: <single concrete next step for AUDIT to validate or escalate>
HANDOFF_EOF
```

**Step 2.** Self-verify the write landed before claiming completion:

```bash
stat -f '%z bytes, mtime=%Sm' ~/.claude/handoff/to-audit.${HANDOFF_SCOPE}.txt
```

The file must be non-zero AND mtime within the last 60 seconds. If not, you skipped Step 1 — run it now. The Stop hook checks the same invariant and will block the turn otherwise. (Note: once the watcher drains the file the size returns to 0 bytes — that is the success state; only "0 bytes AND stale mtime" indicates a missed write.)

**Step 3.** Print exactly this line as the final line of your chat output:

→ handed back

If any STOP trigger fired, OR human input is required before the next axis can proceed, ALSO write the scoped HALT sentinel as a separate Bash call before the confirmation line:

```bash
cat > ~/.claude/handoff/HALT.${HANDOFF_SCOPE} << 'HALT_EOF'
Reason: <one sentence>
Blocking step: <step id>
Human action needed: <specific ask>
HALT_EOF
```

Rules:
- Never write `to-audit.${HANDOFF_SCOPE}.txt` without a successful merge — partial work stays in chat. If you have no merge to report, end the turn normally without the `→ handed back` line; the hook only enforces the pairing of marker + file.
- Always use the scoped filename `to-audit.${HANDOFF_SCOPE}.txt`. Writing to the unscoped path `to-audit.txt` is refused by the watcher (drained with a WARN).
- Never omit the "→ handed back" line on a real hand-back — the watcher uses the file event but the human uses the line to verify the loop closed.
- Never write to `to-impl.${HANDOFF_SCOPE}.txt` — that filename is reserved for AUDIT→IMPL direction.
- HALT is scoped: `HALT.${HANDOFF_SCOPE}` blocks only this project, not others.
- If the heredoc fails (e.g. ~/.claude/handoff/ missing), create the directory with mkdir -p ~/.claude/handoff and retry once. If it fails twice, surface the error and stop — do not silently swallow.
- If the Stop hook blocks you with a `enforce-handback` reason, comply — write the file (Step 1) and re-emit `→ handed back`. Do not strip the marker from your message to bypass the hook; the hook exists because chat-only hand-backs leave AUDIT stranded.
