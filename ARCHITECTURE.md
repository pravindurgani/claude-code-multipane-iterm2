# ARCHITECTURE — claude-code-multipane-iterm2

Reference for the four non-obvious structural constraints in this repo. Read before editing anything that crosses file boundaries.

---

## 1. `guide.md` ↔ `index.html` parallel-sync

The two files are the same document in two formats — markdown for readers on GitHub, HTML for readers who open the repo in a browser. When content changes in one, the other must change to match.

Section numbering in `index.html` uses three coupled values. All three change together whenever a section is added, removed, or renumbered:

- `id="sN"` anchor on the section element
- `<span class="section-num">N</span>` display label
- TOC `<a href="#sN">` link

`guide.md` uses markdown headings only (no numbering machinery) — so the HTML side always carries more editing risk. Make HTML changes first, then mirror to markdown.

---

## 2. Hook install pattern

Hook templates live in `hooks/` inside this repo. The installed copies that Claude Code actually invokes live in `~/.claude/hooks/`.

The two locations are kept in sync by a manual `cp`:

```bash
cp hooks/<name>.py ~/.claude/hooks/<name>.py
```

Never `Edit` or `Write` directly into `~/.claude/hooks/` — `protect-env.py` blocks those writes at the tool level, and editing the installed copy in place diverges it from the repo template. Always edit the template, then `cp`.

The one-time global install (`~/.claude/settings.json` wiring) is documented in `hooks/settings.json.example`.

---

## 3. Version-string triad

The installed Claude Code version is referenced in three places that must all match:

- `guide.md` intro (near the top)
- `guide.md` troubleshooting section T7
- `index.html` footer

When `claude --version` changes, `hooks/version-check.py` fires a SessionStart reminder that prints an update checklist. Update all three locations in one commit — partial updates are confusing for readers who cross-check between formats.

---

## 4. `SESSION_LOG.md` as cross-pane handoff

`SESSION_LOG.md` is the single source of truth for what each pane has done and what the next pane should pick up. It is checked in (shared across panes), whereas `SESSION_LOG.archive.md` is gitignored (local rotation only).

Per-pane contract:

| Pane | Reads | Writes |
|---|---|---|
| PLAN (Opus) | Last 60 lines — open items, deferred findings | New plan block + `Next:` for IMPL |
| IMPL (Sonnet) | Last 60 lines — plan + any AUDIT findings | Implementation log + `Next:` for AUDIT |
| AUDIT (Opus, read-only) | Last 60 lines — what IMPL just changed | Severity-ranked findings + `Next:` for IMPL |
| PROMPT (Sonnet) | Last 60 lines — CLAUDE.md / prompt changes | Prompt-engineering log + `Next:` for PLAN |

Every entry ends with a `Next:` line. That line is the handoff.
