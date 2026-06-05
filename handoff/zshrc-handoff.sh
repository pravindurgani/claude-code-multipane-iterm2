# ── Pane handoff: scope-aware shell functions ────────────────────────────────
# Append this block to ~/.zshrc, then `source ~/.zshrc`.
#
# Requires the launchd watcher (handoff/install.sh installs it). These
# functions are the user-facing API: scope binding, pane claiming, arming,
# halting, and stdin-piped sending.
#
# Mental model:
#   - One HANDOFF_SCOPE per pane (set with `handoff-use <project>`).
#   - One arming flag for the whole Mac (toggle with handoff-on / handoff-off).
#   - One launchd watcher (always running, restarted on crash).
#   - One target binding per (role, scope) pair (set with handoff-claim-*).

handoff() {
  pkill -f '[p]ane-handoff.sh' 2>/dev/null || true
  sleep 0.3
  nohup "$HOME/.claude/hooks/pane-handoff.sh" > /tmp/handoff.log 2>&1 &
  echo "[handoff] watcher pid $!"
}

# Remove any legacy aliases that would shadow these functions
unalias send-impl send-audit handoff-on handoff-off handoff-status \
        handoff-claim-impl handoff-claim-audit handoff-targets \
        handoff-use handoff-halt handoff-resume handoff-scope 2>/dev/null || true

__handoff_validate_scope() {
  local s="$1"
  if [[ -z "$s" || "$s" == *"/"* || "$s" == *".."* ]]; then
    echo "[handoff] ERROR: invalid scope '$s' (no slashes or dotdot allowed)" >&2
    return 1
  fi
  return 0
}

__handoff_require_scope() {
  if [[ -z "$HANDOFF_SCOPE" ]]; then
    echo "[handoff] ERROR: HANDOFF_SCOPE is not set in this pane." >&2
    echo "[handoff]   Fix: run 'handoff-use <project>' before claiming/sending." >&2
    return 1
  fi
  __handoff_validate_scope "$HANDOFF_SCOPE" || return 1
  return 0
}

handoff-use() {
  if [[ -z "$1" ]]; then
    echo "[handoff] usage: handoff-use <scope>" >&2
    return 1
  fi
  __handoff_validate_scope "$1" || return 1
  export HANDOFF_SCOPE="$1"
  echo "[handoff] scope set: $HANDOFF_SCOPE (pane: ${ITERM_SESSION_ID##*:})"
}

handoff-scope() {
  if [[ -z "$HANDOFF_SCOPE" ]]; then
    echo "[handoff] no scope set (run: handoff-use <project>)"
  else
    echo "[handoff] current scope: $HANDOFF_SCOPE"
  fi
}

handoff-halt() {
  __handoff_require_scope || return 1
  local f="$HOME/.claude/handoff/HALT.$HANDOFF_SCOPE"
  if [[ -t 0 ]]; then
    echo "[handoff] reading HALT reason from stdin (Ctrl-D to finish):" >&2
  fi
  cat > "$f"
  echo "[handoff] HALT written: $f"
}

handoff-resume() {
  __handoff_require_scope || return 1
  rm -f "$HOME/.claude/handoff/HALT.$HANDOFF_SCOPE" \
    && echo "[handoff] HALT cleared for scope=$HANDOFF_SCOPE"
}

send-impl() {
  __handoff_require_scope || return 1
  local scope="$HANDOFF_SCOPE"
  local f="$HOME/.claude/handoff/to-impl.${scope}.txt"
  tee "$f" | wc -c | xargs -I{} echo "[handoff] sent {} bytes to IMPL (scope=$scope)"
}

send-audit() {
  __handoff_require_scope || return 1
  local scope="$HANDOFF_SCOPE"
  local f="$HOME/.claude/handoff/to-audit.${scope}.txt"
  tee "$f" | wc -c | xargs -I{} echo "[handoff] sent {} bytes to AUDIT (scope=$scope)"
}

# Handoff arm/disarm (per-session safety gate)
handoff-on()     { mkdir -p "$HOME/.claude/handoff" && touch "$HOME/.claude/handoff/active" && echo "[handoff] ARMED"; }
handoff-off()    { rm -f "$HOME/.claude/handoff/active" && echo "[handoff] DISARMED"; }
handoff-status() { [[ -f "$HOME/.claude/handoff/active" ]] && echo ARMED || echo DISARMED; }

# Bind the current iTerm pane as the IMPL / AUDIT target (run from inside the target pane)
handoff-claim-impl() {
  __handoff_require_scope || return 1
  local scope="$HANDOFF_SCOPE"
  if [[ -z "$ITERM_SESSION_ID" ]]; then
    echo "[handoff] ERROR: \$ITERM_SESSION_ID not set — not running inside iTerm2?" >&2
    return 1
  fi
  local id_file="$HOME/.claude/handoff/impl-target.${scope}.id"
  # Strip iTerm2's "w0t0p0:" prefix to get bare session UUID (focus-independent).
  echo "${ITERM_SESSION_ID##*:}" > "$id_file"
  echo "[handoff] IMPL scope=$scope bound to $(cat "$id_file")"
  # Bootstrap baseline for enforce-handback.py commit-advance trigger.
  local seen_file="$HOME/.claude/handoff/last-seen-sha.${scope}"
  if git rev-parse --verify main >/dev/null 2>&1; then
    git rev-parse main > "$seen_file"
    echo "[handoff] last-seen-sha.${scope} → $(cat "$seen_file" | head -c 8) (commit-trigger armed)"
  elif git rev-parse --verify master >/dev/null 2>&1; then
    git rev-parse master > "$seen_file"
    echo "[handoff] last-seen-sha.${scope} → $(cat "$seen_file" | head -c 8) (master; commit-trigger armed)"
  fi
}

handoff-claim-audit() {
  __handoff_require_scope || return 1
  local scope="$HANDOFF_SCOPE"
  if [[ -z "$ITERM_SESSION_ID" ]]; then
    echo "[handoff] ERROR: \$ITERM_SESSION_ID not set — not running inside iTerm2?" >&2
    return 1
  fi
  local id_file="$HOME/.claude/handoff/audit-target.${scope}.id"
  echo "${ITERM_SESSION_ID##*:}" > "$id_file"
  echo "[handoff] AUDIT scope=$scope bound to $(cat "$id_file")"
}

handoff-targets() {
  local hdir="$HOME/.claude/handoff"
  echo "=== Handoff targets ==="
  for id_path in "$hdir"/*-target*.id; do
    [[ -f "$id_path" ]] || continue
    local base uuid
    base=$(basename "$id_path" .id)
    uuid=$(cat "$id_path" 2>/dev/null | tr -d '[:space:]')
    printf "  %-40s %s\n" "$base" "$uuid"
  done
}
