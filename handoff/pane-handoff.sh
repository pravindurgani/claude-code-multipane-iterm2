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

HANDOFF_DIR="$HOME/.claude/handoff"
FLAG="$HANDOFF_DIR/active"

mkdir -p "$HANDOFF_DIR"

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

  local session_id
  session_id=$(tr -d '[:space:]' < "$id_file")
  if [[ -z "$session_id" ]]; then
    echo "[handoff] WARN: $id_file is empty" >&2
    return 1
  fi

  # Write directly to the bound session via iTerm2's API. Bracketed paste
  # markers tell Claude Code to treat embedded newlines as paste content,
  # not submit triggers. No focus, no clipboard, no keystrokes.
  local result
  result=$(osascript <<EOF
set theFile to POSIX file "$file"
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
          if id of s is "$session_id" then
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
# Enumerate all bound targets across all scopes
for id_path in "$HANDOFF_DIR"/*-target*.id; do
  [[ -f "$id_path" ]] || continue
  base=$(basename "$id_path" .id)
  uuid=$(cat "$id_path" 2>/dev/null | tr -d '[:space:]')
  echo "[handoff] Bound: $base -> $uuid"
done

fswatch -0 "$HANDOFF_DIR" | while IFS= read -r -d '' event; do

  if [[ "$event" == *"active"* ]]; then
    echo "[handoff] flag changed -- now $(flag_status)"
    continue
  fi

  if [[ "$event" == *"-target"*".id"* ]]; then
    echo "[handoff] target binding changed: $(basename "$event")"
    continue
  fi

  if [[ "$event" == *"/HALT"* ]]; then
    fname=$(basename "$event")
    if [[ -f "$event" ]]; then
      if [[ "$fname" == "HALT" ]]; then
        scope="(unscoped — legacy)"
      else
        scope="${fname#HALT.}"
      fi
      echo "[handoff] ⛔ HALT scope=$scope"
      echo "[handoff] Contents:"
      cat "$event"
      osascript -e "display notification \"HALT scope=$scope — loop paused for that project.\" with title \"Claude Handoff\" sound name \"Basso\"" 2>/dev/null || true
    fi
    continue
  fi

  if [[ ! -f "$FLAG" ]]; then
    continue
  fi

  # Route to-impl.<scope>.txt — refuse unscoped writes.
  if [[ "$event" == *"to-impl"*".txt"* ]]; then
    fname=$(basename "$event")
    [[ -s "$event" ]] || continue
    if [[ "$fname" == "to-impl.txt" ]]; then
      echo "[handoff] WARN: refusing unscoped $fname — write to to-impl.<scope>.txt instead" >&2
      > "$event"   # drain so we don't loop on it
      continue
    fi
    scope="${fname#to-impl.}"
    scope="${scope%.txt}"
    lines=$(wc -l < "$event" | tr -d ' ')
    echo "[handoff] -> IMPL scope=$scope ($lines lines)"
    if paste_to_iterm_pane "impl" "$scope" "$event"; then
      > "$event"
      echo "[handoff]    delivered to IMPL/$scope — file truncated to 0 bytes (delivered-marker)"
    else
      echo "[handoff] WARN: delivery failed for $fname — file NOT truncated; inspect and retry" >&2
    fi
    continue
  fi

  # Route to-audit.<scope>.txt — refuse unscoped writes.
  if [[ "$event" == *"to-audit"*".txt"* ]]; then
    fname=$(basename "$event")
    [[ -s "$event" ]] || continue
    if [[ "$fname" == "to-audit.txt" ]]; then
      echo "[handoff] WARN: refusing unscoped $fname — write to to-audit.<scope>.txt instead" >&2
      > "$event"
      continue
    fi
    scope="${fname#to-audit.}"
    scope="${scope%.txt}"
    lines=$(wc -l < "$event" | tr -d ' ')
    echo "[handoff] -> AUDIT scope=$scope ($lines lines)"
    if paste_to_iterm_pane "audit" "$scope" "$event"; then
      > "$event"
      echo "[handoff]    delivered to AUDIT/$scope — file truncated to 0 bytes (delivered-marker)"
    else
      echo "[handoff] WARN: delivery failed for $fname — file NOT truncated; inspect and retry" >&2
    fi
    continue
  fi

done
