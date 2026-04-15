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

---

## 2026-04-15 — AUDIT (post-c4a56e7: orphan-docs cleanup + Ollama persistence + hero ratification)

Scope: two unaudited IMPL commits landed after round-2 closure — `9c6c154` (orphan docs untracked + .gitignore + CHANGELOG update) and `6dafe5b` (Ollama persistence callout in guide.md §3.1 + index.html mirror + `.claude/CLAUDE.md` hero-as-Overview ratification line).

### Verification of prior-item closure

| Item | Expected | Verified |
|---|---|---|
| Orphan cleanup | 3 files untracked, local copies retained, .gitignore extended, CHANGELOG accurate | ✓ `ls` shows all 3 present on disk; `git ls-files \| grep m5-max\|cheatsheet` returns empty; `.gitignore` has 3 new lines; `m5-max-quick-reference.html` confirmed absent (no git history, not on disk) — CHANGELOG "fully deleted" claim accurate |
| Ollama persistence — guide.md | Old Tip block at :116-117 replaced with "Make it persistent" callout pointing to `brew services start ollama` | ✓ guide.md:116-122 correct; wording matches user's supplied text |
| Ollama persistence — index.html | Mirror callout inserted after the `ollama serve &` code block in §3 step 3.1; inline comment removed | ✓ index.html:717-724 correct; inline `# or: brew services start ollama (auto-start on login)` comment removed from line 715 |
| Callout HTML structure | `<div class="callout tip">` + `<span class="callout-icon">` + body `<div>` per `.claude/CLAUDE.md` | ✓ matches; embedded `<div class="code-block" style="margin-top:8px">` pattern idiomatic (also used at index.html:1694, :1742) |
| Hero ratification | `.claude/CLAUDE.md` §Repo Structure declares the Overview→hero divergence is ratified | ✓ new bullet at lines 18-19 reads verbatim as agreed |

All three items cleanly landed. No regressions in s1–s21 IDs, TOC, or footer.

### Findings

#### CRITICAL
None.

#### HIGH
None.

#### MEDIUM
None.

#### LOW

**L1 — `llm-*` parity drift inside the new "Make it persistent" callout**

The callout body has perfect content parity in both docs, but one token formats inconsistently:

- `guide.md:117`: `(so \`cc\` and llm-* aliases work...)` — `cc` in markdown code, `llm-*` unquoted.
- `index.html:719`: `(so <span class="mono">cc</span> and <span class="mono">llm-*</span> aliases work...)` — both in mono.

Cosmetic only — renders fine in both formats — but the parallel-doc invariant in `.claude/CLAUDE.md` §Repo Structure calls for the same content in both docs, and "formatting" is reasonably part of content here. Low blast radius; fix is one-character: change `llm-*` → `` `llm-*` `` in guide.md:117.

### Observations (not findings)

- `git status` clean on main ✓
- Working tree matches HEAD ✓
- `m5-max-quick-reference.html` correctly absent (neither in working tree nor in git history at HEAD) — CHANGELOG accurate
- Local copies of the 3 gitignored files still present and usable ✓
- Footer at index.html still reads `v2.1.109` (current-marker, no drift) ✓
- No CLAUDE.md.template changes, no hook/skill changes, no parity regressions elsewhere

### Verdict

**Approve.** No CRITICAL/HIGH/MEDIUM findings. L1 is ship-when-convenient polish — does not block anything.

### Verification commands used

```
git log --oneline -10
git show --stat 9c6c154
git show --stat 6dafe5b
git show 9c6c154 -- .gitignore CHANGELOG.md
git show 6dafe5b -- guide.md index.html .claude/CLAUDE.md
git ls-files | grep -iE 'm5-max|cheatsheet'
ls m5-max-ai-workstation-setup.md m5-max-quick-reference.md ai-workstation-cheatsheet.html
ls m5-max-quick-reference.html   # expect: not found
grep -n 'Make it persistent' guide.md index.html
grep -n 'ollama serve' guide.md index.html
grep -n 'llm-\*' guide.md index.html
grep -n 'code-block" style="margin-top' index.html
```

Next: IMPL pane — L1 one-character fix (guide.md:117 wrap `llm-*` in backticks). Optional; ship on next unrelated edit. Otherwise, all three changes approved — safe to hand to user for real-world friend test.

---

## 2026-04-15 — AUDIT (setup-vs-docs alignment + setup health)

Scope: broad, two-pass adversarial review.
- **Pass 1 — Docs ↔ Reality:** verify that what guide.md / index.html / CLAUDE.md.template / zshrc-snippet.sh / hooks/ / skills/ / commands/ describe matches what's installed and running on this machine.
- **Pass 2 — Setup health:** find defects in the running setup independent of docs.

Read-only. No filesystem or `~/.claude/` modifications. Findings only.

### Pass 1 results (docs ↔ reality)

| Check | Artifact | Result |
|---|---|---|
| A. iTerm2 profiles | `defaults read com.googlecode.iterm2 "New Bookmarks"` | **Drift** — 4 installed profiles are `DEV-AUDIT/IMPL/PLAN/PROMPT`; repo now teaches `CC-*` (CHANGELOG 2026-04-15). See M1. |
| B. ~/.zshrc snippet | grep + compare vs `zshrc-snippet.sh` | **Drift** — case block uses `DEV-*`; has 8 `llm-*` aliases + 6 `cc-local-*` + `llm-eval`; repo canonical has 4 aliases + `llm-smart` router. See M2. |
| C. Installed hooks | `diff -q hooks/*.py ~/.claude/hooks/*.py` | **Match** — all 5 `.py` byte-identical. Executable bits set. `settings.json` wiring matches `settings.json.example` structure (5 hooks, correct matchers, correct timeouts). |
| D. Installed skills | `diff -rq skills/ ~/.claude/skills/` | **Match** — `code-review`, `security-audit`, `testing` all identical. `prompt-master` is installed-only (Prav's personal — noted). |
| E. Installed commands | `diff -q commands/reflect.md ~/.claude/commands/reflect.md` | **Match** — `reflect.md` byte-identical. 4 additional installed commands (`start-audit/impl/plan/prompt.md`) are personal, noted as observation. |
| F. CLAUDE.md ↔ template | section audit | **No template-side drift** — every template section (Identity / Stack / Active Constraints / Code Style / Session Continuity / Lessons) has an equivalent in `~/.claude/CLAUDE.md` (some absorbed into `Code Invariants` / `Prompting Conventions`). |
| G. Claude Code version | `claude --version` vs footer + last-verified | Installed `v2.1.109` = footer `v2.1.109` ✓. Last-verified markers (4 sites) still `v2.1.81` — 28 minor versions gap. See M5. |

### Pass 2 results (setup health)

| Check | Result |
|---|---|
| H. Hook execution health | No hook `.log` files (normal — hooks exit clean). No `circuit-breaker-state.json` or `compact-state.json` in `~/.claude/` (lazy creation — not broken). Installed hooks are `+x` and also invoked via `python3` explicitly per `settings.json`. |
| I. Ollama health | Server responds `Ollama is running` on `127.0.0.1:11434` ✓. `brew services list` shows `ollama none` — see M3. 8 models installed totalling 131 GB (`~/.ollama`); 3 of 5 guide-canonical 64 GB-tier model names not installed — see M4. |
| J. SESSION_LOG hygiene | 286 lines — below 500 rotation threshold ✓. Last 3 entries all end with `Next:` line ✓. `SESSION_LOG.archive.md` listed in `.gitignore` but not yet created (acceptable — rotation not due). |
| K. Git repo health | `git status` clean except for this AUDIT's pending SESSION_LOG append ✓. Last 10 commits are meaningful — no WIP/squashable noise. |
| L. State files in repo root | `circuit-breaker-state.json` (27 B) present in working tree. Correctly listed in `.gitignore` line 4 AND `git ls-files --error-unmatch` errors → **not tracked**. Clean. |
| M. README.md sanity | See H1 + L3. |

### Findings

#### CRITICAL
None.

#### HIGH

**H1 — README.md Quick Start step 1 contradicts the CC-* rename**

`README.md:64` reads:
> **Create 4 iTerm2 profiles** — `DEV-AUDIT`, `DEV-IMPL`, `DEV-PROMPT`, `DEV-PLAN` — each with a distinct background colour and tab colour

CHANGELOG.md 2026-04-15 announces the rename as a breaking change; `guide.md`, `index.html`, and `zshrc-snippet.sh` all teach `CC-*`. A friend who reads README first (the usual entry point from GitHub) creates profiles that will not match the `case "$ITERM_PROFILE"` block they paste from `zshrc-snippet.sh` — `cc` alias won't bind, no pane badges. Silent failure mode.

**Fix:** `README.md:64` and line 99 ("rename profiles with a project prefix (e.g. `MYPROJECT-AUDIT`)") — update the Quick Start row to `CC-*`. The `MYPROJECT-AUDIT` example is fine (illustrative), but should be paired with a line like "the default prefix this repo teaches is `CC-*`."

#### MEDIUM

**M1 — Prav's iTerm2 profiles have not migrated DEV-* → CC-***

`defaults read com.googlecode.iterm2 "New Bookmarks" | grep Name` returns `DEV-AUDIT`, `DEV-IMPL`, `DEV-PLAN`, `DEV-PROMPT` (plus `Default`). This AUDIT session is running in a `DEV-AUDIT` profile right now. Prav's personal setup is self-consistent with the OLD naming but drifted from what the repo now teaches.

**Not a friend-install blocker** (friends get a clean `CC-*` install from the repo template). **Is a personal setup drift** that the user explicitly asked this AUDIT to surface.

**Fix:** iTerm2 → Preferences → Profiles → rename DEV-* to CC-*. Paired with M2 (`~/.zshrc`) — do both in one sitting or neither.

**M2 — Prav's ~/.zshrc case block uses DEV-* and has 8+6 aliases where repo canonical has 4+router**

`~/.zshrc` lines 68–91 contain both `case` blocks still keyed on `DEV-*`. Also diverges from `zshrc-snippet.sh`:

| In ~/.zshrc | In repo `zshrc-snippet.sh` |
|---|---|
| 8 `llm-*` aliases (fast/code/reason/plan/embed/classify/vision/heavy) | 4 aliases (fast/code/reason/embed) + `llm-vision` in 64 GB block commented |
| 6 `cc-local-*` aliases (fast/plan/audit/impl/vision/heavy) | Not present |
| `llm-eval` weekly regression function (40+ lines) | Not present |
| `llm-smart` **not present** | Present as router function (5-way case) |
| `llm-reason='ollama run deepseek-r1:32b'` | `:8b` (32 GB tier, commented) |

Personal richness is fine — Prav is 64 GB and has earned his model set — but the repo template is the source of truth for what the guide teaches. Profile-name drift in §1 ("DEV-*") is the blocker; alias-set drift is cosmetic.

**Fix:** at minimum swap DEV- → CC- in both case blocks (lines 68, 86, and the 8 case arms). Alias reconciliation is optional.

**M3 — `brew services list` shows `ollama none`; guide now teaches `brew services start ollama`**

```
$ brew services list | grep ollama
ollama  none
$ curl -sf http://127.0.0.1:11434/
Ollama is running
```

Ollama IS running — but not via brew services (probably `ollama serve &` from an earlier session or a LaunchAgent). The "Make it persistent" callout we just landed in guide.md:116-122 and index.html:717-724 teaches `brew services start ollama` as the canonical path. Prav's setup does not follow the canonical path. Reboot test would reveal whether Ollama actually auto-starts for him.

**Fix:** `brew services start ollama`, then reboot-and-verify (`brew services list` should show `started`).

**M4 — Three of five guide-canonical 64 GB-tier Ollama models not installed**

User's prompt pinned these 5 as the 64 GB-tier set: `qwen3:14b, qwen3-coder:32b, gemma3:27b, deepseek-r1:8b, nomic-embed-text`. Installed:

| Guide | Installed | Verdict |
|---|---|---|
| `qwen3:14b` | `qwen3:14b` (9.3 GB) | ✓ match |
| `qwen3-coder:32b` | `qwen3-coder:latest` (18 GB) | ≈ same (latest tag → coder family, 18 GB ≈ 32b Q4) |
| `gemma3:27b` | **missing** — has `gemma4:26b` (17 GB) + `gemma4:31b` (19 GB) | **different model family** |
| `deepseek-r1:8b` | **missing** — has `deepseek-r1:32b` (19 GB) | bigger variant, different size |
| `nomic-embed-text` | **missing** — has `qwen3-embedding:8b` (4.7 GB) | different embedding family |

Plus 2 personal extras: `llama3.3:70b-instruct-q4_K_M` (42 GB) and `gemma3:12b` (8.1 GB). `~/.ollama` totals **131 GB** against guide's claim of "~55 GB for 64 GB tier" (L2). Prav's setup works for Prav; does not match what `zshrc-snippet.sh` declares as 64 GB canonical.

**Fix:** decide per-model — either (a) pull the guide-canonical models (`ollama pull gemma3:27b deepseek-r1:8b nomic-embed-text`; +~21 GB) so Prav's setup matches what friends will install, or (b) rewrite `zshrc-snippet.sh`'s 64 GB block to use Prav's preferred models (`gemma4`, `qwen3-embedding:8b`) — but only if those models are intentional picks, not just what got pulled. Do not ship (b) silently.

**M5 — Last-verified markers at v2.1.81; installed is v2.1.109 (28 minor versions gap)**

Per `.claude/CLAUDE.md §Version String`, footer v2.1.109 is current-marker ✓ (matches `claude --version` exactly). Last-verified markers (4 sites at guide.md:373, guide.md:841, index.html:1247, index.html:1914) all still say "v2.1.81 (March 2026)". User's AUDIT instruction: "note staleness if gap > ~5 minor versions" — 28 >> 5.

This is **LOW staleness per project CLAUDE.md semantics**, elevated here to **MEDIUM per the user's AUDIT threshold**. Not a correctness bug; it means no one has re-walked the guide's flag-compatibility claims against v2.1.82–v2.1.109. If Claude Code deprecated or renamed any flag in that window, the guide still claims it works.

**Fix:** dedicated re-verify session (scope: re-walk `--permission-mode`, `--model`, `--effort`, `--dangerously-skip-permissions` against v2.1.109, update the 4 sites). Not urgent unless friends start hitting flag-not-recognised errors.

#### LOW

**L1 — `.claude/CLAUDE.md §Version String` has stale line numbers**

CLAUDE.md claims last-verified sites are at lines 368, 836 (guide.md) and 1239, 1906 (index.html). Actual: 373, 841, 1247, 1914. Drift of 5–8 lines each — the Ollama persistence callout added earlier shifted subsequent lines. Not a runtime issue; line-number references in CLAUDE.md decay naturally.

**Fix:** update the 4 line numbers on the next CLAUDE.md edit, or drop the exact line numbers in favour of anchors (`### Flag compatibility` / `T8 troubleshooting`).

**L2 — `~/.ollama` is 131 GB; guide claims "~55 GB" for 64 GB tier**

76 GB of the 131 is accounted for by Prav's personal extras (llama3.3:70b alone is 42 GB, plus gemma4 variants and gemma3:12b). Not a docs bug — Prav's setup carries models the guide doesn't teach. Worth flagging for disk-space awareness during a fresh-install dry-run.

**L3 — README.md predates the RAM-tier-gated rewrite**

README Quick Start (lines 60–71) lists 7 steps that stop at hooks config. Does not mention: Homebrew / Node.js / Xcode CLT prereqs, Claude Code install, Ollama install + RAM-tier selection + model pulls, the 19-step full path, or creative AI options. Prerequisites section (line 50) lists only macOS/iTerm2/Claude Code — pre-rewrite minimum.

The README correctly defers to `index.html` / `guide.md` as "the full guide" — so reader loss is bounded. Still, first impressions matter; the README Quick Start is the 30-second pitch a friend sees on GitHub before clicking through, and it's currently 2026-03 era.

**Fix:** rewrite Quick Start as "Pick your RAM tier, then follow the full guide" with a tier table + a bullet per major step. Or: replace Quick Start with a single paragraph that points at guide.md and explicitly flags the RAM-tier branch.

### Observations (not findings)

- `SETUP_FREEZE_PLAN.md` banner correctly placed at line 1 (`> Freeze overridden 2026-04-14 to rewrite the guide as a friend-install path...`). Banner text matches PLAN L11 recommendation verbatim. Per Q7 derived decisions, "historical retention with banner" is the accepted resolution — no action.
- `.mcp.json.example` uses `/path/to/github-mcp-server` + `YOUR_READONLY_PAT_HERE` — matches `.claude/CLAUDE.md §Public Repo Hygiene` fake-placeholder convention ✓.
- All 3 orphan files (`m5-max-ai-workstation-setup.md`, `m5-max-quick-reference.md`, `ai-workstation-cheatsheet.html`) correctly untracked + local ✓.
- `version-check.py` state file (`~/.claude/.last-known-cc-version`) reads `2.1.109 (Claude Code)` — matches installed — SessionStart hook won't nag.
- Installed-only personal assets (expected): `~/.claude/skills/prompt-master/` (Prav's private skill), `~/.claude/commands/{start-audit,start-impl,start-plan,start-prompt}.md` (Prav's slash commands — one of which triggered this AUDIT). Not in repo, not expected to be.
- CHANGELOG.md 2026-04-15 correctly describes the CC-* rename as a **breaking change** with a migration table ✓.

### Verdict

**Approve with revisions — H1 must be fixed before friend hand-off.**

- **H1** is a single-line README edit; landmine severity but 30-second fix.
- **M1/M2** are Prav's personal setup debt — not blockers for the public repo, but the user explicitly asked this AUDIT to surface them.
- **M3/M4** are "Prav's running setup ≠ what guide teaches" items — do whichever reconciliation direction the user prefers.
- **M5** is a re-verify session — schedule, don't rush.
- **L1/L2/L3** are polish.

### Verification commands used

```
tail -80 SESSION_LOG.md
wc -l SESSION_LOG.md guide.md index.html
git status && git log --oneline -10
ls -la hooks/ skills/ commands/
ls -la ~/.claude/{hooks,skills,commands}/
claude --version
for f in circuit-breaker.py protect-env.py protect-git-push.py session-start-reset.py version-check.py; do diff -q hooks/$f ~/.claude/hooks/$f; done
diff -rq skills/code-review ~/.claude/skills/code-review
diff -rq skills/security-audit ~/.claude/skills/security-audit
diff -rq skills/testing ~/.claude/skills/testing
diff -q commands/reflect.md ~/.claude/commands/reflect.md
defaults read com.googlecode.iterm2 "New Bookmarks" | grep '    Name ='
grep -nE 'ITERM_PROFILE|CC-|DEV-|PANE_ROLE|llm-|alias cc' ~/.zshrc
brew services list | grep ollama
curl -sf http://127.0.0.1:11434/
ollama list
du -sh ~/.ollama
cat ~/.claude/settings.json
cat hooks/settings.json.example
cat zshrc-snippet.sh
cat .gitignore
cat README.md
cat CLAUDE.md.template
cat .mcp.json.example
git ls-files --error-unmatch circuit-breaker-state.json   # expect: error
git check-ignore -v circuit-breaker-state.json
grep -nE 'v?2\.1\.\d+|March' guide.md index.html
grep -nE 'DEV-(AUDIT|IMPL|PLAN|PROMPT)' -r .
awk 'NR==368 || NR==373 || NR==836 || NR==841' guide.md
awk 'NR==1239 || NR==1247 || NR==1906 || NR==1914' index.html
head -5 SETUP_FREEZE_PLAN.md
cat ~/.claude/.last-known-cc-version
```

Next: user decides severity queue. Suggested order: **H1** (README CC-* fix) → **M1+M2 bundle** (Prav's iTerm profiles + ~/.zshrc DEV→CC migration) → **M3** (`brew services start ollama`) → **M4** (pick model reconciliation direction) → **M5** (re-verify flags against v2.1.109 in a dedicated session) → LOWs. H1 is the only item that would burn a friend on first install.
