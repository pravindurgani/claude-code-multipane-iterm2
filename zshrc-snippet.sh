# ── Multi-pane Claude Code workflow: title locking + prompt colours ──
# Uses $ITERM_PROFILE (auto-set by iTerm2) instead of custom env vars
# so it works reliably with Window Arrangement restore.
#
# Usage: Append this block to the bottom of your ~/.zshrc
# Docs:  https://pravindurgani.github.io/claude-code-multipane-iterm2/

case "$ITERM_PROFILE" in
  CC-AUDIT)
    PANE_ROLE="AUDIT"; PROMPT="%F{magenta}[AUDIT]%f %~ %# " ;;
  CC-IMPL)
    PANE_ROLE="IMPL"; PROMPT="%F{green}[IMPL]%f %~ %# " ;;
  CC-PROMPT)
    PANE_ROLE="PROMPT"; PROMPT="%F{cyan}[PROMPT]%f %~ %# " ;;
  CC-PLAN)
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
  CC-AUDIT)  alias cc='claude --model opus --effort high --permission-mode plan' ;;
  CC-IMPL)   alias cc='claude --model sonnet --effort high --permission-mode acceptEdits' ;;
  CC-PROMPT) alias cc='claude --model sonnet --effort medium' ;;
  CC-PLAN)   alias cc='claude --model sonnet --effort low' ;;
esac

# gate/ship only meaningful in IMPL pane; harmless elsewhere
if [[ "$ITERM_PROFILE" == "CC-IMPL" ]]; then
  # gate: run pytest suite; exits non-zero if any test fails
  # Exit code 5 = no tests collected — show helpful hint instead of cryptic error
  alias gate='python3 -m pytest tests/ -x --tb=short && echo "✅ GATE PASSED" || { _rc=$?; [ $_rc -eq 5 ] && echo "No tests found — add tests/test_placeholder.py to get started" || false; }'
  # ship: gate + interactive stage + commit
  alias ship='gate && git add -p && git commit'
fi

# ── Local AI models (Ollama) ─────────────────────────────────────────────────
# Requires Ollama installed: brew install ollama
# Start the server with: ollama serve
#
# Uncomment the block that matches your RAM tier.
# Upgrading tiers: replace the smaller-model alias lines with the larger-model lines.

export OLLAMA_HOST="127.0.0.1:11434"
export OLLAMA_KEEP_ALIVE="5m"   # Keep a loaded model in memory for 5 min

# ── 🟢 16 GB+ (all tiers — uncomment these) ──────────────────────────────────
# alias llm-fast='ollama run qwen3:8b'           # ~5 GB
# alias llm-code='ollama run qwen3-coder:7b'     # ~4.5 GB
# alias llm-embed='ollama run nomic-embed-text'  # ~274 MB

# ── 🔵 32 GB+ (replace the 8b/7b lines above with these) ────────────────────
# alias llm-fast='ollama run qwen3:14b'          # ~9 GB
# alias llm-code='ollama run qwen3-coder:14b'    # ~8.5 GB
# alias llm-reason='ollama run deepseek-r1:8b'   # ~5 GB

# ── 🔴 64 GB+ (replace the 14b line above with these, add vision) ───────────
# alias llm-code='ollama run qwen3-coder:32b'    # ~20 GB
# alias llm-vision='ollama run gemma3:27b'       # ~16 GB

# llm-smart: route a prompt to the right model by task type.
# This is a function (not an alias) — it must be defined as a function block.
# Usage: llm-smart "your prompt" [fast|code|reason|embed]
# Defaults to "fast" if no task type given.
llm-smart() {
  local prompt="$1"
  local task="${2:-fast}"
  local model=""
  case "$task" in
    code)   model="qwen3-coder" ;;
    reason) model="deepseek-r1" ;;
    embed)  model="nomic-embed-text" ;;
    *)      model="qwen3" ;;
  esac
  ollama run "$model" "$prompt"
}
