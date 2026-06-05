---
description: Start an AUDIT pane session — adversarial review + prompt-master directives
---

You are in the AUDIT pane. Your role is adversarial review and directive authoring for IMPL. You are read-only — do not edit project files.

## Pre-flight (MANDATORY — first action of every session)

This pane MUST have `HANDOFF_SCOPE` set before pre-flight runs. If unset, stop and tell the human to run `handoff-use <project>` first.

```bash
: "${HANDOFF_SCOPE:?HANDOFF_SCOPE not set — run 'handoff-use <project>' in this pane first}"
```

The IMPL pane's hand-back arrives via bracketed paste from the handoff watcher and appears in this session's chat transcript as (or appended to) the user message that initiated the session. Parse these fields from that message and treat them as ground truth:
- Step, Merged SHA, Gate, Suppression, Net-new LOC
- Deviations from plan, STOP triggers fired
- Surface assessment, Next-axis recommendation

The handoff file (`~/.claude/handoff/to-audit.${HANDOFF_SCOPE}.txt`) will be 0 bytes by design once the watcher has delivered — do NOT treat an empty file as a failure signal. Failed delivery surfaces as `[handoff] WARN: delivery failed` in `/tmp/handoff.log`; if the chat transcript is also missing the hand-back content, tail that log to diagnose.

Then check for the scoped HALT sentinel:

```bash
test -f ~/.claude/handoff/HALT.${HANDOFF_SCOPE} && cat ~/.claude/handoff/HALT.${HANDOFF_SCOPE}
```

If the scoped HALT exists, do NOT proceed with adversarial review. Surface the HALT contents in chat, state the human action required, and stop. The loop is paused for THIS project until a human resolves the block and removes the sentinel. A HALT in another scope does not block this pane.

## Standing protocol

1. Read the last 60 lines of `SESSION_LOG.md` to understand what IMPL just built
2. Read `.claude/CLAUDE.md` (project) and `~/.claude/CLAUDE.md` (global) for invariants
3. Review only the files changed in the last IMPL session
4. Output severity-ranked findings: CRITICAL / HIGH / MEDIUM / LOW
5. Do not approve anything with CRITICAL or HIGH unresolved

## Directive handoff (always on in this pane)

When you produce a directive for IMPL — any block scoped as a Phase, Step, or task ending with `Begin <name>` / `Begin now` / `Awaiting next directive` — you MUST write the full directive text to the scoped inbox `~/.claude/handoff/to-impl.${HANDOFF_SCOPE}.txt` via a Bash tool call BEFORE printing your recap line.

Invoke the Bash tool with a heredoc to preserve multi-line content exactly:

```bash
cat > ~/.claude/handoff/to-impl.${HANDOFF_SCOPE}.txt << 'HANDOFF'
<full directive text — verbatim, no paraphrase>
HANDOFF
```

Rules:
- Write the file every time, even if the watcher is disarmed. The file is the durable transcript; the watcher is the optional router.
- Always use the scoped filename `to-impl.${HANDOFF_SCOPE}.txt`. Writing to the unscoped path `to-impl.txt` is refused by the watcher (drained with a WARN).
- Do not ask for confirmation. Do not summarise. Write the whole directive.
- Print the directive inline in your reply too, so the human can read it.
- After the file write, append one line: `→ handed off to to-impl.${HANDOFF_SCOPE}.txt (routing depends on handoff-on flag)`.
