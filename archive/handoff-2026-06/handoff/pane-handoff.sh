#!/bin/bash
# AUDIT <-> IMPL handoff watcher with scope-keyed routing, flag gate, bracketed-paste fidelity.
#
# Activate routing: touch ~/.claude/handoff/active   (or: handoff-on)
# Deactivate:      rm   ~/.claude/handoff/active     (or: handoff-off)
#
# Scope-keyed targets:
#   impl-target.<scope>.id  /  audit-target.<scope>.id
#   Fallback for legacy (scope=global): impl-target.id  /  audit-target.id
#
# Set bindings by running, in the target pane:
#   handoff-claim-impl   (uses HANDOFF_SCOPE env)
#   handoff-claim-audit  (same)

set -uo pipefail

HANDOFF_DIR="$HOME/.claude/handoff"
FLAG="$HANDOFF_DIR/active"

mkdir -p "$HANDOFF_DIR"

# Scope must be alphanumeric + underscore/hyphen only. Stops directory
# traversal (..) and shell metacharacters from leaking into AppleScript or
# file-path construction.
_valid_scope() {
  [[ "$1" =~ ^[A-Za-z0-9_-]+$ ]]
}

# Returns the path to the .id file for a given role and scope.
# Falls back to unscoped file when scope=global.
_id_file() {
  local role="$1"   # "impl" or "audit"
  local scope="$2"
  if [[ "$scope" == "global" ]]; then
    echo "$HANDOFF_DIR/${role}-target.id"
  else
    echo "$HANDOFF_DIR/${role}-target.${scope}.id"
  fi
}

# Returns 0 on verified delivery, 1 on any failure.
paste_to_iterm_pane() {
  local role="$1"     # "impl" or "audit"
  local scope="$2"    # e.g. "myproject", "global"
  local file="$3"
  local id_file
  id_file=$(_id_file "$role" "$scope")

  if [[ ! -f "$id_file" ]]; then
    echo "[handoff] WARN: no target bound for $role scope=$scope -- run handoff-claim-$role with HANDOFF_SCOPE=$scope" >&2
    return 1
  fi
  # Refuse to read through a symlink — would leak arbitrary file contents.
  if [[ -L "$id_file" ]]; then
    echo "[handoff] WARN: refusing symlink id-file $id_file" >&2
    return 1
  fi

  local session_id
  session_id=$(tr -d '[:space:]' < "$id_file")
  if [[ -z "$session_id" ]]; then
    echo "[handoff] WARN: $id_file is empty" >&2
    return 1
  fi
  # Bound iTerm2 UUIDs are alphanumeric + hyphen. Reject anything else to
  # close the AppleScript-injection chain.
  if [[ ! "$session_id" =~ ^[A-Za-z0-9-]+$ ]]; then
    echo "[handoff] WARN: $id_file content has unexpected chars — refusing" >&2
    return 1
  fi

  # Pass file path and session id as positional args to osascript (item 1 of
  # argv, item 2 of argv). No shell-level string interpolation into the
  # AppleScript source — eliminates the injection vector that existed when
  # the heredoc embedded "$file" and "$session_id" directly.
  local result
  result=$(osascript - "$file" "$session_id" <<'EOF'
on run argv
  set theFile to POSIX file (item 1 of argv)
  set targetID to (item 2 of argv) as text
  set fh to open for access theFile
  set theContent to read fh as «class utf8»
  close access fh

  set ESC to character id 27
  set startBP to ESC & "[200~"
  set endBP to ESC & "[201~"

  tell application "iTerm2"
    set targetSession to missing value
    repeat with w in windows
      repeat with t in tabs of w
        repeat with s in sessions of t
          try
            if id of s is targetID then
              set targetSession to s
              exit repeat
            end if
          end try
        end repeat
        if targetSession is not missing value then exit repeat
      end repeat
      if targetSession is not missing value then exit repeat
    end repeat
    if targetSession is missing value then
      return "no-match"
    end if
    tell targetSession
      write text startBP & theContent & endBP newline no
      delay 0.15
      write text "" newline yes
    end tell
  end tell
  return "ok"
end run
EOF
)
  if [[ "$result" == "no-match" ]]; then
    echo "[handoff] WARN: bound $role/$scope session ($session_id) not found -- pane may be closed; re-run handoff-claim-$role with HANDOFF_SCOPE=$scope" >&2
    return 1
  fi
  return 0
}

flag_status() {
  if [[ -f "$FLAG" ]]; then echo "ACTIVE"; else echo "INACTIVE"; fi
}

echo "[handoff] Watching $HANDOFF_DIR"
echo "[handoff] Status: $(flag_status) -- toggle with handoff-on / handoff-off"
# Enumerate all bound targets across all scopes.
shopt -s nullglob 2>/dev/null || true
for id_path in "$HANDOFF_DIR"/*-target*.id; do
  [[ -f "$id_path" && ! -L "$id_path" ]] || continue
  base=$(basename "$id_path" .id)
  uuid=$(tr -d '[:space:]' < "$id_path")
  echo "[handoff] Bound: $base -> $uuid"
done

fswatch -0 "$HANDOFF_DIR" | while IFS= read -r -d '' event; do
  fname=$(basename "$event")

  # Refuse to act on symlinks. The watched dir is user-owned but any local
  # process can create a symlink that points outside — following it would
  # leak file contents into iTerm and/or truncate the target on delivery.
  if [[ -L "$event" ]]; then
    echo "[handoff] WARN: refusing symlink event $fname — ignored" >&2
    continue
  fi

  case "$fname" in
    active)
      echo "[handoff] flag changed -- now $(flag_status)"
      continue
      ;;
    *-target.id|*-target.*.id)
      echo "[handoff] target binding changed: $fname"
      continue
      ;;
    HALT|HALT.*)
      if [[ -f "$event" ]]; then
        if [[ "$fname" == "HALT" ]]; then
          scope="(unscoped — legacy)"
        else
          scope="${fname#HALT.}"
        fi
        echo "[handoff] ⛔ HALT scope=$scope"
        echo "[handoff] Contents:"
        cat -- "$event" 2>/dev/null || true
        osascript -e "display notification \"HALT scope=$scope — loop paused for that project.\" with title \"Claude Handoff\" sound name \"Basso\"" 2>/dev/null || true
      fi
      continue
      ;;
  esac

  # Below this point, every branch routes a payload to a pane. Routing
  # requires the active flag.
  if [[ ! -f "$FLAG" ]]; then
    continue
  fi

  case "$fname" in
    to-impl.txt)
      echo "[handoff] WARN: refusing unscoped to-impl.txt — write to to-impl.<scope>.txt instead" >&2
      > "$event"   # drain so we don't loop on it
      continue
      ;;
    to-audit.txt)
      echo "[handoff] WARN: refusing unscoped to-audit.txt — write to to-audit.<scope>.txt instead" >&2
      > "$event"
      continue
      ;;
    to-impl.*.txt)
      [[ -f "$event" && -s "$event" ]] || continue
      scope="${fname#to-impl.}"; scope="${scope%.txt}"
      if ! _valid_scope "$scope"; then
        echo "[handoff] WARN: refusing scope '$scope' (must match ^[A-Za-z0-9_-]+\$)" >&2
        > "$event"
        continue
      fi
      lines=$(wc -l < "$event" | tr -d ' ')
      echo "[handoff] -> IMPL scope=$scope ($lines lines)"
      if paste_to_iterm_pane "impl" "$scope" "$event"; then
        > "$event"
        echo "[handoff]    delivered to IMPL/$scope — file truncated to 0 bytes (delivered-marker)"
      else
        echo "[handoff] WARN: delivery failed for $fname — file NOT truncated; inspect and retry" >&2
      fi
      continue
      ;;
    to-audit.*.txt)
      [[ -f "$event" && -s "$event" ]] || continue
      scope="${fname#to-audit.}"; scope="${scope%.txt}"
      if ! _valid_scope "$scope"; then
        echo "[handoff] WARN: refusing scope '$scope' (must match ^[A-Za-z0-9_-]+\$)" >&2
        > "$event"
        continue
      fi
      lines=$(wc -l < "$event" | tr -d ' ')
      echo "[handoff] -> AUDIT scope=$scope ($lines lines)"
      if paste_to_iterm_pane "audit" "$scope" "$event"; then
        > "$event"
        echo "[handoff]    delivered to AUDIT/$scope — file truncated to 0 bytes (delivered-marker)"
      else
        echo "[handoff] WARN: delivery failed for $fname — file NOT truncated; inspect and retry" >&2
      fi
      continue
      ;;
  esac
done
