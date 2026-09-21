#!/usr/bin/env bash
# pane-logging.sh — enable/disable iTerm2 automatic session logging for the
# multipane DEV-* profiles.
#
#   ./pane-logging.sh enable    turn automatic logging on
#   ./pane-logging.sh disable   turn it back off
#   ./pane-logging.sh status    show current state (safe while iTerm2 runs)
#   ./pane-logging.sh prune     delete logs older than RETENTION_DAYS
#
# enable/disable REQUIRE iTerm2 to be quit: iTerm2 holds prefs in memory and
# flushes them on exit, silently overwriting anything written underneath it.

set -euo pipefail

PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
LOG_DIR="$HOME/Library/Logs/claude-panes"
PROFILES=(DEV-AUDIT DEV-IMPL DEV-PROMPT DEV-PLAN)
RETENTION_DAYS=14

# iTerm2 filename tokens: \(profileName) plus strftime. Keep it flat —
# iTerm2 does not create intermediate directories.
FILENAME_FORMAT='\(profileName)_%Y-%m-%d_%H%M%S.log'

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# pgrep cannot see the iTerm2 GUI process (its argv is not readable), so match
# on the accounting name via ps instead.
# ps pads ucomm to a fixed width, so the trailing-space tolerance is required.
iterm_running() { ps -Ao ucomm= | grep -qE '^iTerm2[[:space:]]*$'; }

require_iterm_quit() {
  if iterm_running; then
    die "iTerm2 is running. Quit it completely (Cmd+Q), then re-run from Terminal.app.
       iTerm2 flushes its preferences on quit and would overwrite these changes."
  fi
}

backup_plist() {
  local stamp backup
  stamp=$(date +%Y%m%d-%H%M%S)
  backup="${PLIST}.bak-${stamp}"
  cp -p "$PLIST" "$backup"
  printf 'backed up prefs -> %s\n' "$backup"
}

# Apply a key/value to every DEV-* profile in the "New Bookmarks" array.
apply() {
  local enabled="$1"
  LOG_DIR="$LOG_DIR" ENABLED="$enabled" FILENAME_FORMAT="$FILENAME_FORMAT" \
  PLIST="$PLIST" PROFILES="${PROFILES[*]}" python3 - <<'PY'
import os, plistlib, sys

plist_path = os.environ["PLIST"]
wanted = set(os.environ["PROFILES"].split())
enabled = os.environ["ENABLED"] == "1"

with open(plist_path, "rb") as fh:
    prefs = plistlib.load(fh)

bookmarks = prefs.get("New Bookmarks")
if not isinstance(bookmarks, list):
    sys.exit("error: 'New Bookmarks' missing or malformed — aborting, prefs untouched")

touched = []
for profile in bookmarks:
    name = profile.get("Name")
    if name not in wanted:
        continue
    profile["Automatically Log"] = enabled
    if enabled:
        profile["Log Directory"] = os.environ["LOG_DIR"]
        profile["Log Filename Format"] = os.environ["FILENAME_FORMAT"]
        # True = strip ANSI/control sequences, leaving greppable text.
        profile["Plain Text Logging"] = True
    touched.append(name)

missing = wanted - set(touched)
if missing:
    sys.exit(f"error: profile(s) not found: {', '.join(sorted(missing))} — prefs untouched")

with open(plist_path, "wb") as fh:
    plistlib.dump(prefs, fh, fmt=plistlib.FMT_BINARY)

print(f"{'enabled' if enabled else 'disabled'} logging on: {', '.join(touched)}")
PY
}

cmd_enable() {
  require_iterm_quit
  [[ -f "$PLIST" ]] || die "prefs not found at $PLIST"
  backup_plist
  mkdir -p "$LOG_DIR"
  chmod 700 "$LOG_DIR"
  apply 1
  killall cfprefsd 2>/dev/null || true
  cat <<EOF

log directory: $LOG_DIR (mode 700)
filename:      ${FILENAME_FORMAT}

Relaunch iTerm2. Verify in Settings > Profiles > <profile> > Session >
"Automatically log session input to files in:".

Logs are plaintext and capture everything the pane renders, including any
secret echoed to screen. They are outside the git repo by design — keep them
there. Run './pane-logging.sh prune' periodically, or install the LaunchAgent.
EOF
}

cmd_disable() {
  require_iterm_quit
  [[ -f "$PLIST" ]] || die "prefs not found at $PLIST"
  backup_plist
  apply 0
  killall cfprefsd 2>/dev/null || true
  printf '\nRelaunch iTerm2. Existing logs in %s were left in place.\n' "$LOG_DIR"
}

cmd_status() {
  PLIST="$PLIST" PROFILES="${PROFILES[*]}" python3 - <<'PY'
import os, plistlib

wanted = set(os.environ["PROFILES"].split())
with open(os.environ["PLIST"], "rb") as fh:
    prefs = plistlib.load(fh)

for profile in prefs.get("New Bookmarks", []):
    name = profile.get("Name")
    if name in wanted:
        state = "on " if profile.get("Automatically Log") else "off"
        where = profile.get("Log Directory", "-")
        print(f"  {name:<12} logging={state}  dir={where}")
PY
  if [[ -d "$LOG_DIR" ]]; then
    printf '\n  %s: %s across %s file(s)\n' \
      "$LOG_DIR" \
      "$(du -sh "$LOG_DIR" | cut -f1)" \
      "$(find "$LOG_DIR" -type f -name '*.log' | wc -l | tr -d ' ')"
  fi
  if iterm_running; then
    printf '\n  note: iTerm2 is running — on-disk prefs may lag the live settings.\n'
  fi
}

cmd_prune() {
  [[ -d "$LOG_DIR" ]] || die "no log directory at $LOG_DIR"
  local count
  count=$(find "$LOG_DIR" -type f -name '*.log' -mtime "+${RETENTION_DAYS}" | wc -l | tr -d ' ')
  find "$LOG_DIR" -type f -name '*.log' -mtime "+${RETENTION_DAYS}" -delete
  printf 'pruned %s log(s) older than %s days from %s\n' "$count" "$RETENTION_DAYS" "$LOG_DIR"
}

case "${1:-}" in
  enable)  cmd_enable  ;;
  disable) cmd_disable ;;
  status)  cmd_status  ;;
  prune)   cmd_prune   ;;
  *) die "usage: $(basename "$0") {enable|disable|status|prune}" ;;
esac
