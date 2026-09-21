# Pane Handoff — Operator Guide

File-based bracketed-paste routing between iTerm panes. Each project has its own scope (e.g. `myproject`). **Scope is mandatory** — set per pane via `handoff-use <scope>`. Unscoped sends are refused by the watcher; HALT is per-scope and does not bleed between projects.

> **Who is this for?** You're running the [4-pane Claude Code setup](README.md) and you want AUDIT-to-IMPL handoffs to happen without copy-paste. The watcher delivers a directive written to a file as a single bracketed paste into the receiving pane — the receiving Claude sees it as a fresh user message, every line preserved.

---

## ⚡ Quick start — daily cheat sheet

**Memorise these four commands. They cover 95% of day-to-day usage.**

```bash
handoff-on                      # ARM routing (touches ~/.claude/handoff/active)
handoff-off                     # DISARM routing (rm ~/.claude/handoff/active)
handoff-use <project>           # Set THIS PANE's scope (do once per pane open)
handoff-claim-impl              # OR handoff-claim-audit — bind this pane to its role
```

**Mental model — two independent switches**:

| Switch | Scope | Set by | State lives in |
|---|---|---|---|
| **Watcher running** | Global (whole Mac) | `launchd` (auto, 24/7) | OS process table |
| **Routing armed** | Global | `handoff-on` / `handoff-off` | `~/.claude/handoff/active` flag file |
| **Pane bound to scope** | Per pane | `handoff-use` + `handoff-claim-*` | `~/.claude/handoff/*-target.<scope>.id` files |

If a paste doesn't arrive, ask the three questions in order:

1. Is the watcher running? — `launchctl list | grep handoff`
2. Is routing armed? — `ls ~/.claude/handoff/active`
3. Is the target pane still bound? — `handoff-targets`

The most common failure is #3 — after an iTerm restart, UUIDs change and you must re-claim.

---

## TL;DR — section index

| You want to... | Do this |
|---|---|
| Install for the first time | §1 — run `./handoff/install.sh` |
| Add the shell functions | §2 — append `handoff/zshrc-handoff.sh` to `~/.zshrc` |
| Activate a **new** project | §3 — claim each pane with `handoff-use <name>` + `handoff-claim-{impl,audit}` |
| Resume an **existing** project after iTerm/Mac restart | §4 — re-claim each pane (UUIDs change every session) |
| Arm or disarm routing globally | `handoff-on` / `handoff-off` (no scope needed) |
| Send a directive AUDIT → IMPL | §5 — write to `~/.claude/handoff/to-impl.<scope>.txt` |
| Hand back IMPL → AUDIT | §5 — write to `~/.claude/handoff/to-audit.<scope>.txt` |
| Pause one project's loop | §6 — `handoff-halt` in that pane |
| Something broke | §7 — Troubleshooting |
| Verify isolation across projects | §9 — five probes |

**Reading the examples**: every command has a header tag showing where to run it.
- `[IMPL pane]` = the pane where Claude does implementation work
- `[AUDIT pane]` = the pane where Claude does adversarial review (read-only)
- `[Any pane]` = doesn't matter where, file-only operation
- `[Mac terminal]` = a plain Terminal/iTerm window outside Claude (e.g. for `launchctl`)

---

## 1. Install

From the repo root:

```bash
brew install fswatch           # dependency — required
./handoff/install.sh
```

The installer:
1. Verifies `fswatch`, `osascript`, and iTerm2 are present
2. Copies `pane-handoff.sh` → `~/.claude/hooks/pane-handoff.sh`
3. Copies `enforce-handback.py` → `~/.claude/hooks/enforce-handback.py`
4. Copies `start-impl.md` and `start-audit.md` → `~/.claude/commands/`
5. Renders the launchd plist with your `$HOME` and installs it to `~/Library/LaunchAgents/com.user.handoff.plist`
6. Loads the launchd agent (auto-starts on every login, restarts on crash)
7. Arms routing (`touch ~/.claude/handoff/active`)

Verify:

```bash
launchctl list | grep handoff   # → "<PID>  0  com.user.handoff"
tail /tmp/handoff.log           # → "[handoff] Watching ~/.claude/handoff"
```

To uninstall: `./handoff/install.sh --uninstall`

---

## 2. Add the shell functions

Append the handoff functions block to your `~/.zshrc` (or copy from [`handoff/zshrc-handoff.sh`](handoff/zshrc-handoff.sh)):

```bash
cat handoff/zshrc-handoff.sh >> ~/.zshrc
source ~/.zshrc
```

You now have:
- `handoff-use <scope>` — set this pane's `HANDOFF_SCOPE`
- `handoff-claim-impl` / `handoff-claim-audit` — bind this pane as the IMPL or AUDIT target
- `handoff-on` / `handoff-off` / `handoff-status` — arm / disarm / check routing
- `handoff-halt` / `handoff-resume` — pause / resume the scoped loop
- `handoff-targets` — list all current bindings
- `send-impl` / `send-audit` — pipe stdin to the scoped inbox
- `handoff-scope` — print current scope

---

## 3. Activate a NEW project

Example uses scope name `myapp`. Substitute your project name (lowercase, no spaces — e.g. `clientx`, `acme_api`).

**Watcher**: you don't start it. It's a launchd daemon (`com.user.handoff`) running 24/7 since first install. You only define scopes and claim panes.

### Step 3.1 — Open the IMPL pane and claim it

Open iTerm, open a new pane in the `CC-IMPL` profile, `cd` to the project, start Claude (`cc`).

```bash
# [IMPL pane]
cd ~/Desktop/myapp
cc
```

Then **inside Claude in that pane**, set the scope once and claim:

```bash
# [IMPL pane — inside Claude]
handoff-use myapp
handoff-claim-impl
```

You should see:
```
[handoff] scope set: myapp (pane: <UUID>)
[handoff] IMPL scope=myapp bound to <UUID>
```

### Step 3.2 — Open the AUDIT pane and claim it

Open another iTerm pane in the `CC-AUDIT` profile, start Claude there, then activate the AUDIT skill:

```bash
# [AUDIT pane]
cd ~/Desktop/myapp
cc
```

Inside Claude in that pane, set the scope:

```bash
# [AUDIT pane — inside Claude]
handoff-use myapp
```

Then type the slash command at the Claude prompt (not in a shell):

```
/start-audit
```

Then claim the pane:

```bash
# [AUDIT pane — inside Claude]
handoff-claim-audit
```

Expected:
```
[handoff] AUDIT scope=myapp bound to <UUID>
```

### Step 3.3 — Confirm both bindings

```bash
# [Any pane]
handoff-targets
```

Expected output includes:
```
audit-target.myapp -> <AUDIT pane UUID>
impl-target.myapp  -> <IMPL pane UUID>
```

### Step 3.4 — Smoke test (delivers a paste to IMPL)

```bash
# [Any pane]
echo "smoke test $(date +%s)" > ~/.claude/handoff/to-impl.myapp.txt
```

Within ~1 second, the IMPL pane should show `smoke test <timestamp>` as a single paste.

Verify the file was drained AND the watcher logged the delivered-marker:
```bash
# [Any pane]
wc -c < ~/.claude/handoff/to-impl.myapp.txt    # → 0 means delivered (this is the delivered-marker, NOT a failure)
tail -3 /tmp/handoff.log
# Expected — TWO adjacent lines per delivery:
#   [handoff] -> IMPL scope=myapp (1 lines)
#   [handoff]    delivered to IMPL/myapp — file truncated to 0 bytes (delivered-marker)
```

> **Important:** the `delivered to ...` line is the ground-truth confirmation. A `-> IMPL scope=...` line WITHOUT a following `delivered to ...` line means delivery was attempted but the bracketed-paste step failed — check the line above for a `WARN: delivery failed` entry.

If the paste didn't appear → §7 Troubleshooting.

Done. The project is live.

---

## 4. Resume an EXISTING project (after reboot or iTerm restart)

**Why this is needed**: iTerm assigns a new session UUID every time a pane is opened. The bindings in `~/.claude/handoff/*.id` from yesterday point at UUIDs that no longer exist. The watcher will log `bound session not found` if you try to send.

**Do I need to start the watcher first?** No. The watcher is a launchd daemon (`com.user.handoff`) that auto-starts at login and self-restarts on crash. It's already running before you open any pane. You only need to re-claim the panes.

### Step 4.0 — (Optional) Confirm the watcher is alive

Only needed if you suspect something is off. Skip this on a fresh boot where everything else looks normal.

```bash
# [Mac terminal]
launchctl list | grep handoff
```

Expected: a line like `44993  0  com.user.handoff` — the first column is the PID (a number, not `-`), the second is the last exit code (must be `0`).

If the PID column shows `-` or the line is missing entirely, load the daemon:

```bash
# [Mac terminal]
launchctl load -w ~/Library/LaunchAgents/com.user.handoff.plist
```

### Step 4.1 — Open both panes for the project

In iTerm, open the IMPL pane and the AUDIT pane for `myapp`. Start Claude in each.

```bash
# [IMPL pane]
cd ~/Desktop/myapp && cc

# [AUDIT pane]
cd ~/Desktop/myapp && cc
# then inside Claude: /start-audit
```

### Step 4.2 — Re-claim the IMPL pane

```bash
# [IMPL pane — inside Claude]
handoff-use myapp
handoff-claim-impl
```

### Step 4.3 — Re-claim the AUDIT pane

```bash
# [AUDIT pane — inside Claude]
handoff-use myapp
handoff-claim-audit
```

### Step 4.4 — Verify

```bash
# [Any pane]
handoff-targets
```

You should see updated UUIDs for `audit-target.myapp` and `impl-target.myapp`.

That's it — no other state to reset. Pre-existing inbox files are already drained from the prior session.

---

## 5. Sending work between panes

All examples below use scope `myapp` — change to your scope.

### AUDIT → IMPL (issue a directive)

The AUDIT skill writes the directive to a file; the watcher delivers it as a single bracketed paste.

```bash
# [AUDIT pane — inside Claude, via the Bash tool]
cat > ~/.claude/handoff/to-impl.myapp.txt << 'HANDOFF'
Step 4.2 — implement Pydantic contract for User

Acceptance:
- src/contracts/user.py defines model
- pytest tests/contracts/test_user.py passes
- Gate clean

Begin now.
HANDOFF
```

Within ~1s, the IMPL pane receives the full multi-line text as one paste.

### IMPL → AUDIT (hand back)

```bash
# [IMPL pane — inside Claude, via the Bash tool]
cat > ~/.claude/handoff/to-audit.myapp.txt << 'HANDOFF'
=== HAND-BACK ===
Step: 4.2
Merged SHA: abc1234
Gate: PASS
Surface assessment: contract is minimal, no external deps added
→ handed back
HANDOFF
```

### Convenience aliases (one-liners)

For short single-line messages:

```bash
# [Any pane]
echo "ping" | HANDOFF_SCOPE=myapp send-impl
echo "ping" | HANDOFF_SCOPE=myapp send-audit
```

### Important notes

- **Multi-line content is preserved** — code blocks, blank lines, and indentation all survive the paste because the watcher wraps the content in bracketed-paste escape codes.
- **Don't add a trailing Enter** — the watcher adds the final newline that submits the paste in the receiving Claude.
- **Filenames are load-bearing** — always use `to-impl.<scope>.txt` and `to-audit.<scope>.txt`. Never write to `to-impl.txt` (no scope) — that's refused with a WARN.

---

## 6. Pause the loop (HALT) — per scope

HALT is **scoped**. A halt in `myapp` does not block any other project. The sentinel filename is `HALT.<scope>`.

Either pane can stop its own project's loop by writing the scoped sentinel. The convenience helper reads the reason from stdin:

```bash
# [Any pane in the affected project]
handoff-halt <<'EOF'
Trigger: gate failure on tests/contracts/test_user.py
Human action required: review failure, decide rollback vs fix-forward
EOF
```

This writes `~/.claude/handoff/HALT.$HANDOFF_SCOPE` (the pane's bound scope). Equivalent explicit form:

```bash
# [Any pane]
cat > ~/.claude/handoff/HALT.myapp << 'EOF'
Trigger: gate failure
Human action required: ...
EOF
```

Effect:
- Watcher echoes `⛔ HALT scope=myapp` + contents to `/tmp/handoff.log`
- Fires a macOS notification (Basso sound) tagged with the scope
- AUDIT and IMPL pre-flight in **that scope** see the sentinel and stop before doing anything
- Other scopes are unaffected — their panes continue to send/receive normally

**Resume** (after a human resolves the issue):

```bash
# [Any pane in the affected project]
handoff-resume
# or explicit:
rm ~/.claude/handoff/HALT.myapp
```

---

## 7. Troubleshooting

### "Inbox file shows 0 bytes — is that a failure?" (FAQ)

**No.** The `~/.claude/handoff/to-{impl,audit}.<scope>.txt` files are *transport, not state*. The watcher truncates them to 0 bytes immediately after successful bracketed-paste delivery as its "delivered-marker." The content is already inside the receiving pane's transcript at that point.

**How to tell success from failure** (since the file looks the same in both cases — empty or freshly written):

```bash
tail -10 /tmp/handoff.log
```

| Log pattern | Meaning |
|---|---|
| `-> IMPL scope=X (N lines)` followed by `delivered to IMPL/X — file truncated to 0 bytes (delivered-marker)` | ✅ Success |
| `-> IMPL scope=X (N lines)` followed by `WARN: delivery failed for to-impl.X.txt — file NOT truncated; inspect and retry` | ❌ Failure (file left intact for inspection) |
| No `-> IMPL scope=X` line at all after your write | Watcher is not running, or routing is disarmed, or write happened to wrong path |

### "Delivery failed — file NOT truncated" in /tmp/handoff.log

Three causes, in order of likelihood:

1. **Stale binding** (most common after reboot): the bound pane no longer exists. Re-claim from the live pane (§4).
2. **No binding for that scope**: you tried to send `to-impl.foo.txt` but `impl-target.foo.id` doesn't exist. Run `handoff-claim-impl` with `HANDOFF_SCOPE=foo` from the intended pane.
3. **iTerm AppleScript permission denied**: macOS → Settings → Privacy & Security → Automation → grant access to iTerm/osascript.

### Watcher not running — check + recover

```bash
# [Mac terminal]
launchctl list | grep handoff       # PID column should be a number, not "-"
launchctl load -w ~/Library/LaunchAgents/com.user.handoff.plist   # if missing/dead
```

### Force-restart the watcher (rarely needed — only after editing pane-handoff.sh)

The watcher does NOT hot-reload. After any edit to `~/.claude/hooks/pane-handoff.sh`, you must restart it:

```bash
# [Mac terminal]
pkill -f pane-handoff.sh        # launchd will respawn within ~1s
pgrep -fl pane-handoff.sh       # confirm fresh PIDs appeared
handoff-on                      # re-arm routing (touch the active flag — safe to run even if already armed)
```

**Expected steady state after restart:** 2 × `pane-handoff.sh` (main + fswatch subshell) + 1 × `fswatch`. If `pgrep` shows more (e.g. 5 PIDs from a prior unclean shutdown), `pkill` again — duplicates cause double-delivery.

### Routing disarmed (paste doesn't arrive, no log lines at all)

```bash
ls ~/.claude/handoff/active     # if missing, routing is OFF
handoff-on                      # re-arm
```

### "Why does pgrep show 2 pane-handoff.sh processes?"

That's correct. The watcher uses `fswatch | while ...`, which forks a subshell. Steady state under launchd is **3 processes total**: 2 × `pane-handoff.sh` (main + while-subshell) + 1 × `fswatch`. Anything more or fewer is a problem.

### Pause routing globally without removing bindings

This is the **clean way to deactivate** the entire system while keeping pane bindings + scope + watcher process intact. Use it when you want to stop file→pane delivery temporarily (e.g. taking a break, swapping projects, debugging).

```bash
# [Any pane]
handoff-off       # rm ~/.claude/handoff/active — disarmed (writes accumulate in inbox, no delivery)
handoff-on        # touch the flag — re-armed (queued inbox entries deliver on next fswatch tick)
```

**What `handoff-off` does NOT do:**
- Does not stop the watcher process (it keeps running, just skips delivery)
- Does not remove pane bindings (your `handoff-claim-*` state survives)
- Does not delete `HANDOFF_SCOPE` in any pane

To fully **deactivate everything** (rare — usually only for OS troubleshooting):

```bash
handoff-off                                                           # disarm routing
launchctl unload ~/Library/LaunchAgents/com.user.handoff.plist        # stop watcher daemon
```

To **fully reactivate**:

```bash
launchctl load -w ~/Library/LaunchAgents/com.user.handoff.plist       # start watcher
handoff-on                                                            # arm routing
# then re-claim panes if any iTerm restart happened in between
```

### Don't put archives inside the watched dir

The watcher matches `to-{impl,audit}*.txt` **recursively**, so files under `~/.claude/handoff/archive/old.txt` will be picked up and routed (as scope `old`, which usually doesn't exist → WARN spam). Always archive to the sibling dir `~/.claude/handoff_archive/`.

---

## 8. Reference

### Common commands

| Command | Run from | What it does |
|---|---|---|
| `handoff-use <scope>` | Any pane (once per open) | Set this pane's `HANDOFF_SCOPE`. Required before any *scoped* command (claim, halt, send). The unscoped commands (`handoff-on`, `handoff-off`, `handoff-status`) do not need it. |
| `handoff-claim-impl` | IMPL pane | Bind this pane as the IMPL target for the current scope |
| `handoff-claim-audit` | AUDIT pane | Bind this pane as the AUDIT target for the current scope |
| `handoff-halt` | Any pane in affected scope | Write `HALT.<scope>` (reason from stdin) — pauses only this scope |
| `handoff-resume` | Any pane in affected scope | Remove `HALT.<scope>` |
| `handoff-targets` | Any pane | List all current bindings |
| `handoff-on` / `handoff-off` | Any pane | Arm / disarm routing |
| `handoff-status` | Any pane | Print ARMED or DISARMED |
| `handoff-scope` | Any pane | Print this pane's current scope |
| `send-impl` / `send-audit` | Any pane | Pipe stdin to the scoped inbox |
| `tail -f /tmp/handoff.log` | Any pane | Live event stream |
| `launchctl list \| grep handoff` | Mac terminal | Watcher health under launchd |

### Critical paths

| Path | What it is |
|---|---|
| `~/.claude/hooks/pane-handoff.sh` | The watcher script |
| `~/.claude/hooks/enforce-handback.py` | Stop hook — blocks IMPL from claiming `→ handed back` without writing the file |
| `~/.zshrc` (handoff block) | Defines `handoff-*` and `send-*` shell functions |
| `~/Library/LaunchAgents/com.user.handoff.plist` | launchd config — runs watcher on login, restarts on crash |
| `/tmp/handoff.log` | Watcher stdout + stderr |
| `~/.claude/handoff/active` | Flag — must exist for routing to work |
| `~/.claude/handoff/HALT.<scope>` | Per-scope pause sentinel — its scope's loop is paused while it exists; other scopes unaffected |
| `~/.claude/handoff/{impl,audit}-target.<scope>.id` | Binding files (one UUID per scope per role) |
| `~/.claude/handoff/to-{impl,audit}.<scope>.txt` | Inbox files (auto-truncated on delivery) |
| `~/.claude/handoff_archive/` | **Sibling** dir for old hand-backs — never inside the watched dir |

### Scope rules

- One scope per project. Lowercase, project-name-like (`myapp`, `acme_api`).
- The name `meta` is reserved for cross-project planning/orchestration.
- Unscoped sends (`to-impl.txt` with no `.<scope>`) are refused on purpose.
- HALT is per-scope: `HALT.<scope>` pauses only its scope. There is no global pause.

---

## 9. Multi-project isolation — end-to-end verification

When running two (or more) projects concurrently, each project gets its own iTerm window with its own IMPL/AUDIT panes. Scope is the binding key — set per pane via `handoff-use <scope>`. The five probes below prove isolation holds.

### Pane choreography

Four surfaces total:

- **Window M** — plain Mac Terminal, no Claude. Used for `tail -f /tmp/handoff.log` and for probe injection (direct file writes — see "Why direct `>` writes from M" below).
- **Window A** — iTerm. Two panes: `proj_a` IMPL + AUDIT (split or two tabs, doesn't matter).
- **Window B** — iTerm. One pane: `meta` IMPL.

### Step 0 — Open the live log (M)

```bash
# [Window M — Mac Terminal]
tail -f /tmp/handoff.log
```

Leave it visible throughout. Every probe should produce a log line; silence = something is wrong.

### Step 1 — Open and claim the panes

**1a — `proj_a` IMPL** (Window A, IMPL pane):

```bash
cd ~/Desktop/proj_a && cc
```

Inside Claude:

```bash
handoff-use proj_a
handoff-claim-impl
```

**1b — `proj_a` AUDIT** (Window A, AUDIT pane):

```bash
cd ~/Desktop/proj_a && cc
```

Inside Claude:

```bash
handoff-use proj_a
/start-audit
handoff-claim-audit
```

**1c — `meta` IMPL** (Window B):

```bash
cd ~/Desktop && cc
```

Inside Claude:

```bash
handoff-use meta
handoff-claim-impl
```

**1d — Verify bindings** (any pane):

```bash
handoff-targets
```

Three live UUIDs expected: `audit-target.proj_a`, `impl-target.proj_a`, `impl-target.meta`.

### Why direct `>` writes from M

Probes 1–3 use direct file writes (`echo … > ~/.claude/handoff/to-impl.<scope>.txt`) rather than `send-impl`. This is intentional:

- Window M has no `HANDOFF_SCOPE` set, so `send-impl` would refuse (correctly — that's Probe 4's job to test).
- Direct writes bypass the zshrc guard cleanly and test the watcher's filename-based routing directly, which is the actual integrity-critical path.

### Probe 1 — Scoped delivery isolation

```bash
# [Window M]
echo "ping A $(date +%s)"    > ~/.claude/handoff/to-impl.proj_a.txt
echo "ping META $(date +%s)" > ~/.claude/handoff/to-impl.meta.txt
```

Pass criteria:
- Window A IMPL pane shows only `ping A …`
- Window B IMPL pane shows only `ping META …`
- Log shows **two separate lines**: `-> IMPL scope=proj_a (1 lines)` and `-> IMPL scope=meta (1 lines)`
- No WARN
- Both files drained: `wc -c < ~/.claude/handoff/to-impl.proj_a.txt` → 0

### Probe 2 — Unscoped writes refused

```bash
# [Window M]
echo "should not arrive" > ~/.claude/handoff/to-impl.txt
```

Pass criteria:
- Log shows `WARN: refusing unscoped to-impl.txt — write to to-impl.<scope>.txt instead`
- `wc -c < ~/.claude/handoff/to-impl.txt` → 0 (file drained)
- Neither IMPL pane received the text

### Probe 3 — HALT isolation

```bash
# [Window M]
cat > ~/.claude/handoff/HALT.proj_a << 'EOF'
Reason: isolation probe
Human action needed: rm HALT.proj_a to resume
EOF
```

Log shows `⛔ HALT scope=proj_a` + contents. macOS notification fires.

Then prove `meta` is not blocked:

```bash
# [Window M]
echo "meta still flows $(date +%s)" > ~/.claude/handoff/to-impl.meta.txt
```

Pass criteria: meta paste delivers to Window B normally. Then cleanup:

```bash
# [Window M]
rm ~/.claude/handoff/HALT.proj_a
```

### Probe 4 — Missing scope refused

```bash
# [Window M]
unset HANDOFF_SCOPE
echo "x" | send-impl
```

Pass criteria: shell prints `ERROR: HANDOFF_SCOPE is not set`. No file written.

Note: `unset HANDOFF_SCOPE` is shell-local to Window M. Your claimed panes in Windows A and B keep their bound scopes — they are unaffected.

### Probe 5 — `/start-audit` cold-start sees only its own scope

In Window A AUDIT pane, exit Claude (Ctrl-D) and restart:

```bash
cc
```

Then:

```bash
handoff-use proj_a
/start-audit
```

Pass criteria: `/start-audit` does NOT pre-flight read the inbox file (it is 0 bytes by design after watcher delivery), only checks the scoped HALT (`HALT.proj_a` — absent, you cleaned it up in Probe 3), and stops cleanly because there is no fresh hand-back in the chat transcript yet. **No foreign-project content surfaces.**

Then re-claim:

```bash
handoff-claim-audit
```

### Three log signals that signal full pass

Watch `/tmp/handoff.log` for these signals across the run:

1. **Probe 1** — per scope, TWO adjacent lines:
   - `-> IMPL scope=proj_a (1 lines)` followed by `delivered to IMPL/proj_a — file truncated to 0 bytes (delivered-marker)`
   - `-> IMPL scope=meta (1 lines)` followed by `delivered to IMPL/meta — file truncated to 0 bytes (delivered-marker)`
2. **Probe 2** — `WARN: refusing unscoped to-impl.txt`
3. **Probe 3** — `⛔ HALT scope=proj_a` followed by a successful `-> IMPL scope=meta` + `delivered to IMPL/meta ...` pair

If all three are present and Probes 4–5 stop where expected, isolation is verified end-to-end.

---

## 10. How it works (under the hood)

```
 AUDIT pane                          Watcher                       IMPL pane
  (Claude)                       (pane-handoff.sh)                  (Claude)
     │                                  │                              │
     │  Bash tool:                      │                              │
     │  cat > to-impl.myapp.txt         │                              │
     │  ─────────────────────────────►  │                              │
     │                            fswatch fires                        │
     │                            reads file                           │
     │                            wraps content in                     │
     │                            bracketed-paste escapes              │
     │                            osascript writes to                  │
     │                            bound iTerm session id ─────────────►│
     │                            ◄───  ok                             │
     │                            truncates file to 0 bytes            │
     │                            (delivered-marker)                   │
     │                            logs ✓ to /tmp/handoff.log           │
```

**Why bracketed paste?** Without it, multi-line content with blank lines or code blocks would submit on the first `\n`. Bracketed paste tells the terminal "this is paste content" — the receiving Claude sees it as a single fresh user message.

**Why scope-keyed filenames?** So two projects can run side-by-side. `to-impl.proj_a.txt` routes to `impl-target.proj_a.id`; `to-impl.meta.txt` routes to `impl-target.meta.id`. No cross-talk possible.

**Why a Stop hook on IMPL?** Without it, the model can claim "→ handed back" in chat without actually writing the file — leaving AUDIT idle and the loop silently broken. The hook detects this exact failure mode and forces the model to either write the file or remove the marker.

---

## 11. Changelog

| Date | Change |
|---|---|
| 2026-06-05 | Integrated into the `claude-code-multipane-iterm2` repo. Public installer + sanitised file paths. Security hardening: AppleScript injection fix (file path + session id passed as `osascript` argv), symlink refusal in watcher, scope regex tightened to `^[A-Za-z0-9_-]+$`. Installer auto-cleans legacy `*handoff*` launchd labels and auto-merges the Stop hook into `~/.claude/settings.json`. |
| 2026-05-15 | watcher logs `delivered to {IMPL,AUDIT}/<scope>` after each successful bracketed-paste + file-truncation. Closes the false-alarm vector where receiving panes saw a 0-byte inbox and misdiagnosed it as a write failure. |
| 2026-05-15 | `/start-audit` no longer pre-flight-reads `to-audit.<scope>.txt`. The hand-back arrives via bracketed paste in the chat transcript; the file is transport, not state. |
| 2026-05-13 | Initial scope-keyed handoff. Per-scope HALT sentinels. Multi-project isolation probes. |
