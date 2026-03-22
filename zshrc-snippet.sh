# ── Multi-pane Claude Code workflow: title locking + prompt colours ──
# Uses $ITERM_PROFILE (auto-set by iTerm2) instead of custom env vars
# so it works reliably with Window Arrangement restore.
#
# Usage: Append this block to the bottom of your ~/.zshrc
# Docs:  https://pravindurgani.github.io/claude-code-multipane-iterm2/

case "$ITERM_PROFILE" in
  DEV-AUDIT)
    PANE_ROLE="AUDIT"; PROMPT="%F{magenta}[AUDIT]%f %~ %# " ;;
  DEV-IMPL)
    PANE_ROLE="IMPL"; PROMPT="%F{green}[IMPL]%f %~ %# " ;;
  DEV-PROMPT)
    PANE_ROLE="PROMPT"; PROMPT="%F{cyan}[PROMPT]%f %~ %# " ;;
  DEV-PLAN)
    PANE_ROLE="PLAN"; PROMPT="%F{yellow}[PLAN]%f %~ %# " ;;
esac

if [[ -n "$PANE_ROLE" ]]; then
  echo -ne "\033]0;${PANE_ROLE}\007"
  _pane_title_precmd() { echo -ne "\033]0;${PANE_ROLE}\007"; }
  precmd_functions+=(_pane_title_precmd)
fi

# ── Claude Code launch aliases (role-aware) ──
# Type "cc" in any pane to launch with the correct model/effort/permissions.
# Note: "cc" may conflict with the C compiler on some systems.
#       Rename to "cl" or "claude-go" if needed.
case "$ITERM_PROFILE" in
  DEV-AUDIT)  alias cc='claude --model opus --effort high --permission-mode plan' ;;
  DEV-IMPL)   alias cc='claude --model sonnet --effort high --permission-mode acceptEdits' ;;
  DEV-PROMPT) alias cc='claude --model sonnet --effort medium' ;;
  DEV-PLAN)   alias cc='claude --model sonnet --effort low' ;;
esac

# gate/ship only meaningful in IMPL pane; harmless elsewhere
if [[ "$ITERM_PROFILE" == "DEV-IMPL" ]]; then
  # gate: run full test suite; exits non-zero if any test fails
  # Exit code 5 = no tests collected — show helpful hint instead of cryptic error
  alias gate='python3 -m pytest tests/ -x --tb=short && echo "✅ GATE PASSED" || { _rc=$?; [ $_rc -eq 5 ] && echo "No tests found — add tests/test_placeholder.py to get started" || false; }'
  # ship: gate + interactive stage + commit
  alias ship='gate && git add -p && git commit'
fi
