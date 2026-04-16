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

Never `Edit` or `Write` directly into `~/.claude/hooks/` — editing the installed copy in place diverges it from the repo template. Always edit the template, then `cp`.

The one-time global install (`~/.claude/settings.json` wiring) is documented in `hooks/settings.json.example`.

---

## 3. Version-string markers — two semantics, don't conflate

Version strings in this repo encode two different claims. They bump on different triggers and carry different drift severities.

### Current-version marker (1 place)

`index.html:1818` footer. States the Claude Code version the site's content was last published alongside. Bumps on **every** Claude Code release, together with a `hooks/version-check.py` SessionStart reminder.

Drift here = **HIGH**: the reader sees a wrong current-state claim in the first second on the page.

### Last-verified-against markers (5 places)

Claims that someone actually walked the guide against a specific Claude Code version — flags, hook behavior, slash commands, MCP wiring. Bumps **only** when a real re-verification pass happens, not automatically on release.

- `guide.md:4` — intro paragraph
- `guide.md:249` — flag-compatibility note (§5)
- `guide.md:692` — T7 troubleshooting
- `index.html:1074` — flag-compatibility note (mirror of `guide.md:249`)
- `index.html:1803` — T7 mirror (mirror of `guide.md:692`)

Drift here = **LOW staleness**: the guide may be subtly out of date, but the reader can still run `claude --version` and cross-check. Not a correctness bug.

### In practice

When `version-check.py` fires at SessionStart, the default response is: bump the footer. Only re-walk the guide (and bump the four last-verified markers) in a dedicated re-verification session.

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
