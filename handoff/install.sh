#!/bin/bash
# Installer for the Claude handoff feature.
#
# What this does:
#   1. Verifies dependencies (fswatch, iTerm2, Claude Code CLI)
#   2. Copies pane-handoff.sh to ~/.claude/hooks/
#   3. Copies enforce-handback.py to ~/.claude/hooks/
#   4. Copies start-impl.md and start-audit.md to ~/.claude/commands/
#   5. Renders com.user.handoff.plist with your $HOME and installs it to
#      ~/Library/LaunchAgents/
#   6. Loads the launchd agent (auto-starts on every login)
#   7. Arms routing (touches ~/.claude/handoff/active)
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
PLIST_LABEL="com.user.handoff"
PLIST_PATH="$LAUNCHAGENTS_DIR/${PLIST_LABEL}.plist"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
ok()    { printf '\033[32m✓\033[0m %s\n' "$*"; }
warn()  { printf '\033[33m!\033[0m %s\n' "$*"; }
fail()  { printf '\033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

uninstall() {
  bold "Uninstalling Claude handoff feature..."
  if launchctl list | grep -q "$PLIST_LABEL"; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    ok "Unloaded launchd agent"
  fi
  rm -f "$PLIST_PATH"               && ok "Removed $PLIST_PATH"            || true
  rm -f "$HOOKS_DST/pane-handoff.sh"     && ok "Removed pane-handoff.sh"   || true
  rm -f "$HOOKS_DST/enforce-handback.py" && ok "Removed enforce-handback.py" || true
  rm -f "$COMMANDS_DST/start-impl.md"    && ok "Removed start-impl.md"     || true
  rm -f "$COMMANDS_DST/start-audit.md"   && ok "Removed start-audit.md"    || true
  rm -f "$HANDOFF_DIR/active"            && ok "Disarmed routing"          || true
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
command -v fswatch >/dev/null 2>&1 || fail "fswatch not installed. Run: brew install fswatch"
ok "fswatch"
command -v osascript >/dev/null 2>&1 || fail "osascript not found — this script requires macOS"
ok "osascript (macOS)"
command -v claude >/dev/null 2>&1 || warn "Claude Code CLI not on PATH (continuing anyway)"
[[ -d "/Applications/iTerm.app" ]] && ok "iTerm2 found" || warn "iTerm2 not at /Applications/iTerm.app — install via: brew install --cask iterm2"
echo ""

# ── 2. Create destination directories ────────────────────────────────────────
bold "Creating directories..."
mkdir -p "$HOOKS_DST" "$COMMANDS_DST" "$HANDOFF_DIR" "$LAUNCHAGENTS_DIR"
ok "$HOOKS_DST"
ok "$COMMANDS_DST"
ok "$HANDOFF_DIR"
ok "$LAUNCHAGENTS_DIR"
echo ""

# ── 3. Copy files ────────────────────────────────────────────────────────────
bold "Copying files..."
install -m 755 "$REPO_ROOT/handoff/pane-handoff.sh" "$HOOKS_DST/pane-handoff.sh"
ok "$HOOKS_DST/pane-handoff.sh"
install -m 755 "$REPO_ROOT/hooks/enforce-handback.py" "$HOOKS_DST/enforce-handback.py"
ok "$HOOKS_DST/enforce-handback.py"
install -m 644 "$REPO_ROOT/commands/start-impl.md" "$COMMANDS_DST/start-impl.md"
ok "$COMMANDS_DST/start-impl.md"
install -m 644 "$REPO_ROOT/commands/start-audit.md" "$COMMANDS_DST/start-audit.md"
ok "$COMMANDS_DST/start-audit.md"
echo ""

# ── 4. Render and install launchd plist ──────────────────────────────────────
bold "Installing launchd agent..."
sed "s|{{HOME}}|$HOME|g" "$REPO_ROOT/handoff/com.user.handoff.plist.template" > "$PLIST_PATH"
chmod 644 "$PLIST_PATH"
ok "Rendered $PLIST_PATH with HOME=$HOME"

# Reload if already loaded (covers re-runs after editing pane-handoff.sh)
if launchctl list | grep -q "$PLIST_LABEL"; then
  launchctl unload "$PLIST_PATH" 2>/dev/null || true
fi
launchctl load -w "$PLIST_PATH"
ok "Loaded launchd agent (PID $(launchctl list | awk -v label="$PLIST_LABEL" '$3 == label {print $1}'))"
echo ""

# ── 5. Arm routing ───────────────────────────────────────────────────────────
bold "Arming routing..."
touch "$HANDOFF_DIR/active"
ok "$HANDOFF_DIR/active (routing armed)"
echo ""

# ── 6. Final advice ──────────────────────────────────────────────────────────
bold "Install complete."
echo ""
echo "Next steps:"
echo "  1. Append the handoff functions to your ~/.zshrc (see HANDOFF_GUIDE.md §3)"
echo "  2. Open a fresh iTerm pane and run: handoff-use <project>"
echo "  3. Claim it as IMPL or AUDIT: handoff-claim-impl  OR  handoff-claim-audit"
echo "  4. Smoke-test: echo 'hello' > $HANDOFF_DIR/to-impl.<project>.txt"
echo ""
echo "Watcher live log: tail -f /tmp/handoff.log"
echo "Watcher status:   launchctl list | grep handoff"
echo ""
echo "Read the full guide: HANDOFF_GUIDE.md"
