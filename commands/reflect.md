---
description: >-
  Session knowledge extraction. Run at the end of any IMPL or AUDIT session
  to capture what Claude learned about this codebase and produce structured
  suggestions for updating CLAUDE.md. Trigger phrases: end of session,
  reflect on session, update CLAUDE.md, what did you learn, session
  wrap-up, CLAUDE.md improvements.
---

Review what was discovered during this session and suggest concrete additions
to CLAUDE.md.

Steps:
1. Read the current project CLAUDE.md: `cat CLAUDE.md 2>/dev/null || echo "[no project CLAUDE.md found]"`
2. Read recent git log: `git log --oneline -20`
3. Read current diff: `git diff HEAD`
4. Reflect on: patterns used, conventions encountered, gotchas hit, invariants
   discovered, errors that recurred, decisions made about how this codebase works

Then output suggestions in this exact format — max 5, project-specific only:

---
**CLAUDE.md Suggestions — [project name]**

| # | Section | Add | Why |
|---|---------|-----|-----|
| 1 | [section name] | [exact text ready to paste] | [why — reference something concrete from this session] |

---

Rules:
- Only include learnings specific to THIS project — not general best practices
- "Add" column must be exact text ready to paste, not a description
- "Why" must reference something that happened this session (a file, a bug, a decision)
- Skip anything already present in CLAUDE.md
- If nothing project-specific was learned, say so — do not invent suggestions
- Do NOT edit CLAUDE.md — the user reviews suggestions and decides what to incorporate
