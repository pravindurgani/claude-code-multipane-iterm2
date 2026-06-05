#!/bin/bash
# Installer for the Claude handoff feature.
#
# What this does:
#   1. Verifies dependencies (fswatch, osascript, iTerm2; warns if Claude CLI absent)
#   2. Detects + unloads any legacy launchd label containing "handoff" (other than com.user.handoff)
#   3. Copies pane-handoff.sh to ~/.claude/hooks/
#   4. Copies enforce-handback.py to ~/.claude/hooks/
#   5. Copies start-impl.md and start-audit.md to ~/.claude/commands/
#   6. Renders com.user.handoff.plist with your $HOME and installs to ~/Library/LaunchAgents/
#   7. Loads the launchd agent (auto-starts on every login)
#   8. Verifies the watcher actually started (tails /tmp/handoff.log)
#   9. Merges the Stop hook entry into ~/.claude/settings.json (if present + valid)
#  10. Arms routing (touches ~/.claude/handoff/active)
#
# Idempotent — re-running is safe. Re-loads the launchd agent if it changes.
#
# Run from the repo root:
#   ./handoff/install.sh
#
# Uninstall:
#   ./handoff/install.sh --uninstall

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DST="$HOME/.claude/hooks"
COMMANDS_DST="$HOME/.claude/commands"
HANDOFF_DIR="$HOME/.claude/handoff"
LAUNCHAGENTS_DIR="$HOME/Library/LaunchAgents"
SETTINGS_FILE="$HOME/.claude/settings.json"
PLIST_LABEL="com.user.handoff"
PLIST_PATH="$LAUNCHAGENTS_DIR/${PLIST_LABEL}.plist"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
ok()    { printf '\033[32m✓\033[0m %s\n' "$*"; }
warn()  { printf '\033[33m!\033[0m %s\n' "$*"; }
fail()  { printf '\033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

# Detect ANY currently-loaded launchd label containing "handoff". Echoes
# zero or more labels, one per line.
list_handoff_labels() {
  launchctl list 2>/dev/null | awk '$3 ~ /handoff/ {print $3}'
}

# Unload + delete legacy *handoff* plists other than our own (any label
# containing "handoff" from a prior install with a different name).
remove_legacy_agents() {
  local found=0
  local label plist
  while IFS= read -r label; do
    [[ -z "$label" || "$label" == "$PLIST_LABEL" ]] && continue
    plist="$LAUNCHAGENTS_DIR/${label}.plist"
    warn "found legacy launchd agent: $label"
    launchctl unload "$plist" 2>/dev/null || true
    if [[ -f "$plist" ]]; then
      rm -f "$plist"
      ok "removed $plist"
    fi
    found=1
  done < <(list_handoff_labels)
  [[ $found -eq 1 ]] && echo "" || true
}

uninstall() {
  bold "Uninstalling Claude handoff feature..."
  # Unload our agent AND any legacy *handoff* labels.
  local label plist
  while IFS= read -r label; do
    [[ -z "$label" ]] && continue
    plist="$LAUNCHAGENTS_DIR/${label}.plist"
    launchctl unload "$plist" 2>/dev/null || true
    ok "unloaded $label"
    if [[ -f "$plist" && "$label" == "$PLIST_LABEL" ]]; then
      rm -f "$plist"
      ok "removed $plist"
    fi
  done < <(list_handoff_labels)
  if [[ -f "$HOOKS_DST/pane-handoff.sh" ]];     then rm -f "$HOOKS_DST/pane-handoff.sh"     && ok "removed pane-handoff.sh"; fi
  if [[ -f "$HOOKS_DST/enforce-handback.py" ]]; then rm -f "$HOOKS_DST/enforce-handback.py" && ok "removed enforce-handback.py"; fi
  if [[ -f "$COMMANDS_DST/start-impl.md" ]];    then rm -f "$COMMANDS_DST/start-impl.md"    && ok "removed start-impl.md"; fi
  if [[ -f "$COMMANDS_DST/start-audit.md" ]];   then rm -f "$COMMANDS_DST/start-audit.md"   && ok "removed start-audit.md"; fi
  if [[ -f "$HANDOFF_DIR/active" ]];            then rm -f "$HANDOFF_DIR/active"            && ok "disarmed routing"; fi
  # De-register the Stop hook from settings.json (best effort).
  python3 - "$SETTINGS_FILE" <<'PY' || true
import json, sys, pathlib
p = pathlib.Path(sys.argv[1])
if not p.exists():
    sys.exit(0)
try:
    settings = json.loads(p.read_text())
except Exception:
    sys.exit(0)
hooks = (settings.get("hooks") or {})
stop = hooks.get("Stop") or []
target = "$HOME/.claude/hooks/enforce-handback.py"
new_stop = []
removed = False
for entry in stop:
    hs = entry.get("hooks") or []
    kept = [h for h in hs if target not in (h.get("command") or "")]
    if kept and len(kept) == len(hs):
        new_stop.append(entry)
    elif kept:
        new_stop.append({**entry, "hooks": kept})
        removed = True
    else:
        removed = True
if removed:
    if new_stop:
        hooks["Stop"] = new_stop
    else:
        hooks.pop("Stop", None)
    settings["hooks"] = hooks
    p.write_text(json.dumps(settings, indent=2) + "\n")
    print("✓ removed Stop hook entry from settings.json")
PY
  echo ""
  warn "Left intact (delete manually if desired):"
  echo "    $HANDOFF_DIR (state files, target bindings)"
  echo "    /tmp/handoff.log"
  echo ""
  warn "If you added handoff functions to ~/.zshrc, remove them manually."
  echo "Done."
  exit 0
}

if [[ "${1:-}" == "--uninstall" || "${1:-}" == "-u" ]]; then
  uninstall
fi

bold "Installing Claude handoff feature..."
echo ""

# ── 1. Dependencies ──────────────────────────────────────────────────────────
bold "Checking dependencies..."
command -v fswatch   >/dev/null 2>&1 || fail "fswatch not installed. Run: brew install fswatch"
ok "fswatch"
command -v osascript >/dev/null 2>&1 || fail "osascript not found — this script requires macOS"
ok "osascript (macOS)"
command -v python3   >/dev/null 2>&1 || fail "python3 not found — install Xcode CLT or Homebrew Python"
ok "python3"
command -v git       >/dev/null 2>&1 || warn "git not on PATH — the commit-advance trigger in enforce-handback.py will be disabled in projects without git"
command -v claude    >/dev/null 2>&1 || warn "Claude Code CLI not on PATH (continuing anyway)"
if osascript -e 'id of application "iTerm2"' >/dev/null 2>&1; then
  ok "iTerm2 (by bundle id)"
else
  warn "iTerm2 not registered — install via: brew install --cask iterm2"
fi
echo ""

# ── 2. Detect + unload legacy *handoff* agents ───────────────────────────────
bold "Checking for legacy launchd agents..."
remove_legacy_agents

# ── 3. Create destination directories ────────────────────────────────────────
bold "Creating directories..."
mkdir -p "$HOOKS_DST" "$COMMANDS_DST" "$HANDOFF_DIR" "$LAUNCHAGENTS_DIR"
ok "$HOOKS_DST"
ok "$COMMANDS_DST"
ok "$HANDOFF_DIR"
ok "$LAUNCHAGENTS_DIR"
echo ""

# ── 4. Copy files ────────────────────────────────────────────────────────────
bold "Copying files..."
install -m 755 "$REPO_ROOT/handoff/pane-handoff.sh"     "$HOOKS_DST/pane-handoff.sh"
ok "$HOOKS_DST/pane-handoff.sh"
install -m 755 "$REPO_ROOT/hooks/enforce-handback.py"   "$HOOKS_DST/enforce-handback.py"
ok "$HOOKS_DST/enforce-handback.py"
install -m 644 "$REPO_ROOT/commands/start-impl.md"      "$COMMANDS_DST/start-impl.md"
ok "$COMMANDS_DST/start-impl.md"
install -m 644 "$REPO_ROOT/commands/start-audit.md"     "$COMMANDS_DST/start-audit.md"
ok "$COMMANDS_DST/start-audit.md"
echo ""

# ── 5. Render and install launchd plist ──────────────────────────────────────
bold "Installing launchd agent..."
# Use python3 for the templating substitution — avoids sed metacharacter
# issues if $HOME ever contains | & or \. (rare on macOS but cheap to harden.)
HOME="$HOME" python3 - "$REPO_ROOT/handoff/com.user.handoff.plist.template" "$PLIST_PATH" <<'PY'
import os, sys, pathlib
src, dst = sys.argv[1], sys.argv[2]
content = pathlib.Path(src).read_text().replace("{{HOME}}", os.environ["HOME"])
pathlib.Path(dst).write_text(content)
PY
chmod 644 "$PLIST_PATH"
ok "Rendered $PLIST_PATH (HOME=$HOME)"

# Reload if already loaded (covers re-runs after editing pane-handoff.sh).
if launchctl list 2>/dev/null | awk -v L="$PLIST_LABEL" '$3 == L {found=1} END {exit !found}'; then
  launchctl unload "$PLIST_PATH" 2>/dev/null || true
fi
launchctl load -w "$PLIST_PATH"
sleep 1
pid=$(launchctl list 2>/dev/null | awk -v L="$PLIST_LABEL" '$3 == L {print $1}')
if [[ -z "$pid" || "$pid" == "-" ]]; then
  warn "launchd loaded the plist but the watcher did not stay running"
  warn "check /tmp/handoff.log for errors"
else
  ok "Loaded launchd agent (PID $pid)"
fi
echo ""

# ── 6. Verify watcher banner ─────────────────────────────────────────────────
bold "Verifying watcher startup..."
sleep 1
if tail -20 /tmp/handoff.log 2>/dev/null | grep -q "Watching $HANDOFF_DIR"; then
  ok "watcher banner present in /tmp/handoff.log"
else
  warn "watcher banner not found in /tmp/handoff.log — tail it to diagnose"
fi
echo ""

# ── 7. Merge Stop hook into ~/.claude/settings.json ──────────────────────────
bold "Registering Stop hook (enforce-handback.py)..."
python3 - "$SETTINGS_FILE" <<'PY'
import json, sys, pathlib
p = pathlib.Path(sys.argv[1])
target_cmd = "python3 $HOME/.claude/hooks/enforce-handback.py"
if not p.exists():
    print(f"  note: {p} not found — create it later and add the Stop hook manually.")
    print("  See HANDOFF_GUIDE.md §1 'Manual Stop hook registration' for the JSON snippet.")
    sys.exit(0)
try:
    settings = json.loads(p.read_text())
except Exception as e:
    print(f"  WARN: {p} is not valid JSON ({e}); skipping merge.")
    sys.exit(0)
hooks = settings.setdefault("hooks", {})
stop = hooks.setdefault("Stop", [])
existing = any(
    target_cmd in (h.get("command") or "")
    for entry in stop
    for h in (entry.get("hooks") or [])
)
if existing:
    print("  ✓ already registered in settings.json")
else:
    stop.append({"hooks": [{"type": "command", "command": target_cmd, "timeout": 5}]})
    settings["hooks"] = hooks
    p.write_text(json.dumps(settings, indent=2) + "\n")
    print(f"  ✓ added Stop hook entry to {p}")
PY
echo ""

# ── 8. Arm routing ───────────────────────────────────────────────────────────
bold "Arming routing..."
touch "$HANDOFF_DIR/active"
ok "$HANDOFF_DIR/active (routing armed)"
echo ""

# ── 9. Final advice ──────────────────────────────────────────────────────────
bold "Install complete."
echo ""
echo "Next steps:"
echo "  1. Append handoff functions to your ~/.zshrc (HANDOFF_GUIDE.md §2):"
echo "       cat $REPO_ROOT/handoff/zshrc-handoff.sh >> ~/.zshrc && source ~/.zshrc"
echo "  2. Open a fresh iTerm pane and run: handoff-use <project>"
echo "  3. Claim it as IMPL or AUDIT: handoff-claim-impl  OR  handoff-claim-audit"
echo "  4. Smoke-test: echo 'hello' > $HANDOFF_DIR/to-impl.<project>.txt"
echo ""
echo "Watcher live log: tail -f /tmp/handoff.log"
echo "Watcher status:   launchctl list | grep handoff"
echo ""
echo "Read the full guide: HANDOFF_GUIDE.md"
