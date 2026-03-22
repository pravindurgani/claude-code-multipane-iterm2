# CLAUDE.md — claude-code-multipane-iterm2

Project-specific invariants for working on this repo.
Global conventions live in ~/.claude/CLAUDE.md.

---

## Repo Structure

- guide.md and index.html are parallel documents — the same content must appear in both.
  When adding a section to one, add the equivalent to the other.
  Section numbering in index.html uses three coupled values that must stay in sync:
  the id="sN" anchor, the <span class="section-num"> display label, and the TOC href.
  When adding a section, update all three together.

---

## Version String

- The installed Claude Code version appears in three places: guide.md intro (top),
  guide.md troubleshooting T7, and the index.html footer.
  Run `claude --version` and update all three together before pushing.

---

## Public Repo Hygiene

- Before any git push, check .mcp.json.example for personal paths (/Users/username/...)
  and PAT placeholders that match real token format and length — both trigger GitHub
  push protection and will block the push.
  Use clearly fake placeholders like YOUR_USERNAME and YOUR_READONLY_PAT_HERE.
