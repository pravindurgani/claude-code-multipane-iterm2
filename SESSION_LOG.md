# Session Log — claude-code-multipane-iterm2

Append timestamped entries per session. End each block with a `Next:` line that the follow-up pane can read.

---

## 2026-04-14 — IMPL

Resolved HIGH audit finding.

- **H1 fixed:** `hooks/version-check.py` — wrapped `_VERSION_FILE.read_text()` and both `_VERSION_FILE.write_text(current)` calls in `try/except OSError`. Installed copy cp'd to `~/.claude/hooks/version-check.py`.
- **Repo initialised as git.** First commit covers hooks, skills, commands, guide.
- **SESSION_LOG.md created** (this file) so `/start-audit` and `/reflect` have a log to append to.

Deferred (see AUDIT M1–M4, L1–L4 in plan archive): command-substitution bypass in `protect-git-push.py`, hardcoded `_THRESHOLD` in `circuit-breaker.py`, post-trip self-heal semantics, `Path.cwd()` state-file location.

Next: AUDIT pane re-runs `/start-audit` to confirm H1 is resolved and the log is being appended correctly.

---

## 2026-04-14 — IMPL (continued)

Closed Bucket 2 of `SETUP_FREEZE_PLAN.md`.

- **Weight Class declared:** `.claude/CLAUDE.md` now leads with `Weight Class: Tool` per global CLAUDE.md mandate.
- **`ARCHITECTURE.md` created at repo root** — covers the four non-obvious structural constraints: `guide.md` ↔ `index.html` parallel-sync with coupled section-numbering triad, hook install pattern (templates → `cp` → `~/.claude/hooks/`), version-string triad (`guide.md` intro / T7 / `index.html` footer), `SESSION_LOG.md` per-pane handoff contract.
- **`.claude/REFERENCE.md` populated** — AUDIT / IMPL / PLAN pane-specific context, current sprint, deferred AUDIT findings (M1–M4, L1), decisions log.

Side observation from verification 4a: `version-check.py` flagged `claude --version` moved from 2.1.107 → 2.1.108. Version-string triad in `guide.md` intro / T7 / `index.html` footer likely needs updating. **Not in scope for this session** — add to the post-freeze work queue or address in a dedicated 5-minute update commit before the freeze window starts.

**Freeze declared.** No further changes to the multipane setup, hooks, skills, slash commands, or global CLAUDE.md until **2026-07-14** (90 days), barring a genuine blocker (bug/gap that has stopped real work twice in a week). New setup ideas go to `backlog/setup-ideas.md`.

Next: ship Unbuilt Issue #2. The scaffold is done; the real work is 1–4 in `SETUP_FREEZE_PLAN.md` §"What to build instead".

---

## 2026-04-14 — AUDIT

Review of 1d0ab95 + 7f3cead (Bucket 2 close + footer bump).

- **H1 (REFERENCE.md triad contradiction):** reported — old "triad must stay in sync" bullet contradicted new split semantics.
- **M1 (4-vs-5 last-verified places):** reported — `index.html:1803` missing from enumerated list in CLAUDE.md and ARCHITECTURE.md.
- **L1 (CI invariant with no workflow):** reported — Weight Class line claimed "CI + audit on every change" with no `.github/workflows/`.
- **L2 (L2–L4 reference drift):** reported — SESSION_LOG.md referenced L2–L4 but no canonical content existed.
- **L3 (version-check.py old wording):** reported — checklist still reflected old 3-place triad model.

Cannot approve with H1 unresolved.

Next: IMPL fixes H1 + M1 + L1 + L2 + L3 in one commit (b4c886f).

---

## 2026-04-14 — IMPL (audit remediation)

All five findings resolved in commit `b4c886f`.

- **H1:** `.claude/REFERENCE.md:15` — replaced "triad must stay in sync" bullet with two bullets mirroring CLAUDE.md §Version String split (current-version marker vs. last-verified markers).
- **M1:** `.claude/CLAUDE.md` + `ARCHITECTURE.md §3` — "(4 places)" → "(5 places)"; added `index.html:1803` to enumerated list; removed redundant trailing paragraph in ARCHITECTURE.md.
- **L1:** `.claude/CLAUDE.md:3` — "CI + audit on every change" → "audit on every change, CI optional for a docs-only scaffold".
- **L2:** `.claude/REFERENCE.md §Known Issues` — added CLOSED entry for L2/L3/L4 with plan-archive pointer.
- **L3:** `hooks/version-check.py:53` — updated checklist to two-step split (bump footer on every release; bump last-verified markers only on re-verify). Installed copy cp'd to `~/.claude/hooks/`.

Verification: `grep -n "triad" REFERENCE.md` → 0 version-string hits; `grep -c "1803" CLAUDE.md ARCHITECTURE.md` → 1 each; CI qualifier confirmed; diff clean.

Next: AUDIT re-run to confirm clean. Then: ship Unbuilt Issue #2.


---

## 2026-04-15 — IMPL (part 1 of 2)

- Rewrote guide.md, zshrc-snippet.sh, CLAUDE.md.template per plan greedy-sniffing-candy.md
- DEV-* → CC-* profile rename (breaking change, see CHANGELOG.md)
- Bannered SETUP_FREEZE_PLAN.md; created CHANGELOG.md
- .gitignored personal files (m3-coding-quickstart.html, optimal-guide.html, prav_build_process.md)
- Moved old_setup_guide.zip to ~/.claude/backups/

Next: index.html surgical rewrite (commit 2)

---

## 2026-04-15 — IMPL (part 2 of 2)

Surgical 9-stage rewrite of index.html to mirror new guide.md structure.

- **STAGE 1:** DEV-AUDIT/IMPL/PROMPT/PLAN → CC-AUDIT/IMPL/PROMPT/PLAN (4 replace_all edits; 1 intentional DEV-* left in "Adapt for Other Projects" section)
- **STAGE 2:** Footer bumped v2.1.108 → v2.1.109
- **STAGE 3:** Last-verified markers (v2.1.81, 4 sites) left unchanged — no re-verify done
- **STAGE 4:** 5 section h2 renames + 2 TOC text renames (Shell Snippet, Cross-Pane Workflow, gate Workflow, SESSION_LOG Pattern, Quick Reference — read as needed)
- **STAGE 5:** Inserted 4 new sections: Prerequisites (s1), Install Claude Code (s2), Local AI Models/Ollama (s3), Draw Things Optional (s20)
- **STAGE 6:** All 21 section IDs and section-num labels renumbered (s1–s21, 01–21)
- **STAGE 7:** TOC rewritten — 21 entries with correct hrefs and display numbers
- **STAGE 8:** Verify: 21 section IDs ✓, 1 DEV- ✓, 21 CC- ✓, 2025 lines ✓, section-nums 01–21 clean ✓

Commit: feat: rewrite index.html to mirror new guide structure (part 2/2)

Next: AUDIT pane — run /start-audit on updated index.html + guide.md. Confirm CC-* rename, section parity, no orphaned anchors.

---

## 2026-04-15 — IMPL (AUDIT remediation, commit e122509)

Resolved all 6 AUDIT findings against the part-2/2 index.html rewrite.

- **H1:** Tail reordered — Quick Reference moved from s18 to s21 (final); MCP→Draw Things→Troubleshooting→Quick Reference. Physical DOM move + TOC update.
- **M1:** s4 "The 4-pane concept" collapsed into s4 (Create iTerm2 Profiles) — pane grid + 3 callouts merged into s4 body; s5–s21 renumbered s4–s20 (count: 21→20).
- **M2:** Dedicated "iTerm2 Triggers (Optional)" section inserted as s9 between Launch Claude Code and Keyboard Shortcuts; embedded Triggers table removed from Keyboard Shortcuts; s9–s20 renumbered s10–s21 (count: 20→21).
- **L1:** All section comments normalised to `<!-- SECTION sN: Title -->` format (s4–s21).
- **L2:** `guide.md:863` h2 `"Quick Reference — Reference: read as needed"` → `"Quick Reference — read as needed"`.
- **L3:** `.claude/CLAUDE.md §Version String` updated — footer line ~1818→~2024; last-verified places 5→4 (guide.md intro version marker removed in April rewrite); line numbers corrected: guide.md:368/836, index.html:1239/1906.

Verification: 21 section IDs s1–s21 (each unique), 21 TOC entries, 1 DEV- remaining, all TOC hrefs match body IDs, diff clean.

Next: AUDIT pane — re-run /start-audit on commit e122509. Confirm H1/M1/M2/L1/L2/L3 all closed. Check no new findings introduced.

---

## 2026-04-15 — AUDIT (re-audit of commit e122509)

Prior-finding disposition:

| ID | Finding | Verdict |
|---|---|---|
| H1 (prior) | Tail reordered — Quick Ref → s21 | **CLOSED** — body + TOC verified monotonic s1–s21, tail order MCP→Draw→Trouble→Quick Ref confirmed |
| M1 (prior) | s4 "4-pane concept" collapsed | **CLOSED** — content merged into s4 Profiles; count math (21→20) verifiable in diff |
| M2 (prior) | Triggers inserted as dedicated section | **PARTIAL** — section exists, but placed in wrong slot — see new H1 below |
| L1 (prior) | Section comments standardised | **PARTIAL** — s4–s21 normalised; s1–s3 still use string placeholders — see new L1 below |
| L2 (prior) | Quick Ref h2 wording | **CLOSED** — `guide.md:863` matches index.html `s21` |
| L3 (prior) | CLAUDE.md line numbers | **CLOSED** — all 4 last-verified and 1 footer line refs verified against actual positions |

### NEW HIGH

**H1 — Parallel-doc invariant violated: s9/s10 swapped between guide.md and index.html**

- `guide.md:373` Step 9 = **Keyboard Shortcuts Reference**; `guide.md:405` Step 10 = **iTerm2 Triggers (Optional)**
- `index.html:s9` = **iTerm2 Triggers (Optional)**; `index.html:s10` = **Keyboard Shortcuts**

`.claude/CLAUDE.md §Repo Structure` invariant: *"guide.md and index.html are parallel documents — the same content must appear in both. When adding a section to one, add the equivalent to the other."* Ordering is implicitly parallel too — a reader cross-referencing "see Step 9" hits different content in each document.

The M2 remediation was correct in concept but picked an ordering that contradicts guide.md. Needs user decision on canonical ordering, then one doc follows the other.

**Recommended fix** (guide.md is canonical): in index.html, move s9 Triggers block to after s10 Keyboard Shortcuts; swap id/section-num labels (s9↔s10) and the two TOC entries. Pure relabel after the DOM swap — no content change.

### NEW MEDIUM

**M1 — H2 wording drift between guide.md and index.html (4 sections)**

| Step | guide.md | index.html | Drift |
|---|---|---|---|
| 4 | Create **4** iTerm2 Profiles | Create iTerm2 Profiles | "4" dropped |
| 5 | **Profile** Startup Commands & Initial Directory | Startup Commands & Initial Directory | "Profile" dropped |
| 12 | **Session** Playbook | **Daily** Playbook | word swap |
| 18 | MCP Server, **Slash** Commands & Skills | MCP Server, Commands & Skills | "Slash" dropped |

Same invariant as H1 (parallel-doc content parity). L2 fixed one such drift in this commit; 4 others left behind. User should pick canonical wording per row, then sync.

### NEW LOW

**L1 — L1 closure was partial: 3 section comments still use string placeholders**

`index.html:597/651/693` still read:

```
<!-- SECTION s-prereq: Prerequisites -->
<!-- SECTION s-claude: Install Claude Code -->
<!-- SECTION s-ollama: Local AI Models -->
```

IMPL's SESSION_LOG explicitly scoped L1 closure as "s4–s21", which leaves s1–s3 in the original pre-rename placeholder format from the Stage 5 insert in the prior commit. No reader impact (HTML comments), but inconsistent with the rest of the file. Normalise to `s1`/`s2`/`s3`.

**L2 — `guide.md` `## Overview` has no h2 peer in index.html**

`guide.md:21` has an `## Overview` h2. index.html instead has the hero block (H1 + tagline) which functionally serves the same purpose but is not an h2 section and does not appear in the TOC.

Arguably by design — the hero is idiomatic for a single-page HTML doc. Flag only so the user ratifies the divergence; no action required if the hero is accepted as the Overview-equivalent.

### Observations (not findings)

- Body section IDs s1–s21 monotonic, all unique ✓
- TOC has exactly 21 `<li>` entries, all hrefs resolve to existing IDs ✓
- Single intentional `DEV-` remains (Adapt section) per plan ✓
- Footer at index.html:2024 reads `v2.1.109` — matches plan Q2 (current marker) ✓
- 4 last-verified markers still at `v2.1.81` — correct per §Version String semantics (no re-verify done) ✓

### Verdict

**Do not approve.** H1 blocks shipping. M1 should ship in the same commit as H1 (same class of defect — content parity). L1 and L2 are cleanup, ship-when-convenient.

### Verification commands used

```
grep -n '<div class="section" id="s' index.html
grep -n '<h2>' index.html
grep -n '^## ' guide.md
grep -n '<!-- SECTION' index.html
grep -n 'Claude Code v2\.1\.\|v2.1.81' index.html guide.md
```

Next: IMPL pane — fix new H1 (move s9↔s10 in index.html to match guide.md), new M1 (sync 4 h2 titles — user decides canonical wording per row), new L1 (normalise 3 comments). Optionally address new L2 (Overview peer). Commit and hand back to AUDIT for re-check.

---

## 2026-04-15 — IMPL (AUDIT remediation, round 2)

Resolved H1 + M1 + L1 from AUDIT re-review of e122509. L2 ratified as by-design (no edit).

- **H1:** index.html s9↔s10 physically swapped — Keyboard Shortcuts now in s9 slot (line 1246), iTerm2 Triggers in s10 slot (line 1277). Matches guide.md Step 9 / Step 10 order. Both body IDs, section-num spans, section comments, and TOC entries updated.
- **M1:** 4 h2 titles synced. guide.md canonical for three: `Create 4 iTerm2 Profiles` (s4), `Profile Startup Commands & Initial Directory` (s5), `MCP Server, Slash Commands & Skills` (s18). index.html canonical for one: `Daily Playbook` (s12) — guide.md Step 12 updated from "Session Playbook" → "Daily Playbook".
- **L1:** 3 placeholder section comments normalised: `s-prereq`/`s-claude`/`s-ollama` → `s1`/`s2`/`s3`.
- **L2:** Ratified — hero block accepted as Overview-equivalent. No edit.

Verification: 21 section IDs s1–s21 ✓, s9=Keyboard Shortcuts before s10=Triggers ✓, 0 `s-` placeholder comments ✓, all 4 M1 h2 titles correct in both docs ✓.

Next: AUDIT pane — re-run /start-audit. Confirm H1/M1/L1 all closed, L2 ratified. Check no new findings.
