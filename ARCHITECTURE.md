# ARCHITECTURE — claude-code-multipane-iterm2

Reference for the four non-obvious structural constraints in this repo. Read before editing anything that crosses file boundaries.

---

## 1. `guide.md` ↔ `index.html` parallel-sync

The two files are the same document in two formats — markdown for readers on GitHub, HTML for readers who open the repo in a browser. When content changes in one, the other must change to match.

**`guide.md` is the source of truth.** It carries no numbering machinery, so it is the safer place to restructure. Change it first, then mirror into `index.html`.

Both use the same four-part structure, adopted 2026-09-21:

| Part | Sections | What belongs there |
|---|---|---|
| I — Install it | 1–7 | Strictly sequential. The reader must not skip. |
| II — Work in it | 8–12 | Working patterns. Order does not matter. |
| III — Optional add-ons | 13–17 | Each independently skippable. |
| IV — Reference | 18–21 | Lookup material. |
| Appendix | 22 | Retired features, pointer only. |

Section numbering in `index.html` uses three coupled values. All three change together whenever a section is added, removed, or renumbered:

- `id="sN"` anchor on the section element
- `<span class="section-num">N</span>` display label
- TOC `<a href="#sN">` link

Each section additionally carries a semantic alias immediately before it —
`<span id="agents-md" class="anchor-alias"></span>` — because answer engines cite
semantic anchors and people already deep-link to the numeric ones. Both must keep
resolving; never remove a numeric id to "tidy up".

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

The `index.html` footer — find it with `grep -n 'class="footer"'`, the version span follows two lines after. States the Claude Code version the site's content was last published alongside. Bumps on **every** Claude Code release, together with a `hooks/version-check.py` SessionStart reminder.

Drift here = **HIGH**: the reader sees a wrong current-state claim in the first second on the page.

### Last-verified-against markers (4 places)

Claims that someone actually walked the guide against a specific Claude Code version — flags, hook behaviour, slash commands, MCP wiring. Bumps **only** when a real re-verification pass happens, not automatically on release.

Find them by content, not by line number — line numbers rot on every edit:

- flag-compatibility note in `guide.md` and `index.html` — `grep -n 'Version note:'`
- T7 troubleshooting in `guide.md` and `index.html` — `grep -n 'guide was verified against'`

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
