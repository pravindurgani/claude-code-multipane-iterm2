# M5 Max AI Workstation Setup Guide
## Complete Configuration for Planning, Coding, Testing, Auditing & Creative AI

**Hardware:** MacBook Pro M5 Max (64GB RAM, 2TB SSD)  
**Author:** Prav Durgani  
**Last Updated:** April 2026

---

## Executive Summary

This guide transforms your M5 Max into a production AI workstation with:

| Capability | Primary Tool | Fallback | Local/Cloud |
|------------|-------------|----------|-------------|
| **Code Generation** | Claude Code (Opus/Sonnet) | Qwen3 Coder | Cloud → Local |
| **Reasoning/Audit** | Claude Opus | DeepSeek-R1 32B | Cloud → Local |
| **Heavy Reasoning** | Gemma 4 31B | Llama 3.3 70B Q4 | Local |
| **Fast Tasks** | Qwen 3 14B | Gemma 3 12B | Local |
| **Vision/UI Review** | Gemma 4 26B | Claude Opus | Local → Cloud |
| **Classification** | Gemma 3 12B | Qwen 3 14B | Local |
| **Image Generation** | Draw Things | ComfyUI | Local |
| **Transcription** | WhisperKit/whisper.cpp | MacWhisper | Local |
| **Text-to-Speech** | Kokoro ONNX | Say (macOS) | Local |
| **Embeddings/RAG** | Qwen3 Embedding 8B | nomic-embed-text | Local |

**Key insight for M5 Max:** The M5 Max's Fusion Architecture delivers ~614GB/s memory bandwidth — inference speed is memory-bandwidth-bound, so this directly translates to faster local models. MLX framework exploits this fully, benchmarking at 200+ tokens/sec on 14B models vs. significantly slower throughput on standard Ollama/llama.cpp. Use both strategically — MLX for performance-critical tasks, Ollama for compatibility with existing tooling.

---

## Part 1: Foundation Setup (Day 1)

### 1.1 Fresh Install Philosophy

**Do NOT use Migration Assistant for your dev stack.** Fresh installs avoid accumulated cruft. Only migrate:
- `~/.ssh/` (SSH keys)
- `~/.gitconfig` (git identity)
- `~/.zshrc` snippets (review, don't copy wholesale)
- Project repos (re-clone from GitHub)

### 1.2 Core Installation Order

Order matters — later tools depend on earlier ones.

```bash
# 1. Homebrew (package manager)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc

# 2. Core dev tools
brew install git python@3.12 node nvm uv pipx wget jq

# 3. Terminal enhancement
brew install --cask iterm2
brew install starship  # Modern prompt (optional, pairs with your multipane setup)

# 4. Container runtime
brew install --cask docker

# 5. Ollama (local inference — install first, pull models later)
brew install ollama

# 6. MLX framework (Apple-optimized inference)
pip install mlx mlx-lm --break-system-packages

# 7. Claude Code
npm install -g @anthropic-ai/claude-code

# 8. Whisper for transcription
brew install whisper-cpp
```

### 1.3 Environment Configuration

Create `~/.zshrc` additions:

```bash
# ─── AI WORKSTATION CONFIG ───────────────────────────────────────────────────

# Anthropic API (Claude Code)
export ANTHROPIC_API_KEY="sk-ant-..."

# Ollama config
export OLLAMA_HOST="127.0.0.1:11434"
export OLLAMA_KEEP_ALIVE="5m"  # Keep models loaded for 5 minutes

# MLX cache
export HF_HOME="$HOME/.cache/huggingface"

# Python environment
export UV_PYTHON_PREFERENCE="managed"

# ─── CLAUDE CODE ALIASES (from your multipane setup) ─────────────────────────

# Profile-aware Claude Code launcher
case "$ITERM_PROFILE" in
  DEV-AUDIT)
    alias cc='claude --model opus --effort high --permission-mode plan'
    export PS1="%F{red}[AUDIT]%f $PS1"
    ;;
  DEV-IMPL)
    alias cc='claude --model sonnet --effort high --permission-mode acceptEdits'
    export PS1="%F{green}[IMPL]%f $PS1"
    ;;
  DEV-PROMPT)
    alias cc='claude --model sonnet --permission-mode plan'
    export PS1="%F{yellow}[PROMPT]%f $PS1"
    ;;
  DEV-PLAN)
    alias cc='claude --model opus --permission-mode plan'
    export PS1="%F{blue}[PLAN]%f $PS1"
    ;;
  *)
    alias cc='claude'
    ;;
esac

# ─── QUICK ACCESS ────────────────────────────────────────────────────────────

# Local model quick-run (full roster)
alias llm='ollama run'
alias llm-classify='ollama run gemma3:12b'
alias llm-code='ollama run qwen3-coder'
alias llm-embed='ollama run qwen3-embedding:8b'
alias llm-fast='ollama run qwen3:14b'
alias llm-heavy='ollama run gemma4:31b'
alias llm-plan='ollama run llama3.3:70b-instruct-q4_K_M'
alias llm-reason='ollama run deepseek-r1:32b'
alias llm-vision='ollama run gemma4:26b'

# ─── UNIFIED ROUTER ─────────────────────────────────────────────────────────

# Smart model router — picks the right model by task type
# Usage: llm-smart "prompt" --type code|reason|fast|audit
llm-smart() {
  local prompt="$1"
  local task_type="${2:---type fast}"
  local model=""
  
  case "$task_type" in
    --type\ code|code)       model="qwen3-coder" ;;
    --type\ reason|reason)   model="deepseek-r1:32b" ;;
    --type\ audit|audit)     model="deepseek-r1:32b" ;;
    --type\ classify|classify) model="gemma3:12b" ;;
    --type\ vision|vision)   model="gemma4:26b" ;;
    --type\ heavy|heavy)     model="gemma4:31b" ;;
    --type\ plan|plan)       model="llama3.3:70b-instruct-q4_K_M" ;;
    --type\ fast|fast|*)     model="qwen3:14b" ;;
  esac
  
  local start_time=$(date +%s)
  ollama run "$model" "$prompt"
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  # Log usage for observability (append to CSV)
  echo "$(date -Iseconds),$model,$task_type,${duration}s,ok" \
    >> ~/.local/share/llm-usage.csv
}

# Transcribe audio file
transcribe() {
  whisper-cli -m ~/.local/share/whisper-models/ggml-large-v3-turbo.bin -f "$1" -otxt
}

# Start local model server
ollama-serve() {
  ollama serve &
  echo "Ollama server started at http://localhost:11434"
}

# ─── OBSERVABILITY ──────────────────────────────────────────────────────────

# View model usage stats (last 7 days)
llm-stats() {
  local log="$HOME/.local/share/llm-usage.csv"
  if [ ! -f "$log" ]; then
    echo "No usage data yet. Use llm-smart to start logging."
    return
  fi
  echo "=== Model Usage (last 7 days) ==="
  echo "Calls per model:"
  awk -F',' -v cutoff="$(date -v-7d -Iseconds 2>/dev/null || date -d '7 days ago' -Iseconds)" \
    '$1 >= cutoff { count[$2]++ } END { for (m in count) printf "  %-28s %d calls\n", m, count[m] }' "$log"
  echo ""
  echo "Recent 10 calls:"
  tail -10 "$log" | column -t -s','
}

# ─── MODEL EVALS ───────────────────────────────────────────────────────────

# Weekly routing regression check — run after model updates or swaps
# Logs speed + output length as a quality proxy to ~/.local/share/llm-evals.csv
llm-eval() {
  local log="$HOME/.local/share/llm-evals.csv"
  local timestamp=$(date -Iseconds)

  echo "=== Running model evals ==="

  # Fixed test prompts (deterministic, measurable)
  local prompts=(
    "code|Write a Python function that returns the nth Fibonacci number using memoization."
    "reason|A farmer has 17 sheep. All but 9 die. How many sheep are left? Explain step by step."
    "classify|Classify this text as bug/feature/question: 'The login button doesn't work on mobile Safari'"
    "fast|Summarise this in one sentence: The mitochondria is the powerhouse of the cell."
  )

  for entry in "${prompts[@]}"; do
    local task_type="${entry%%|*}"
    local prompt="${entry#*|}"
    local model=""
    case "$task_type" in
      code)     model="qwen3-coder" ;;
      reason)   model="deepseek-r1:32b" ;;
      classify) model="gemma3:12b" ;;
      fast)     model="qwen3:14b" ;;
    esac

    echo -n "  [$task_type] $model... "
    local start=$(date +%s)
    local output=$(ollama run "$model" "$prompt" 2>/dev/null | head -5)
    local elapsed=$(($(date +%s) - start))
    local chars=${#output}

    echo "${elapsed}s, ${chars} chars"
    echo "$timestamp,$model,$task_type,${elapsed}s,$chars" >> "$log"
  done

  echo ""
  echo "Results logged to $log"
  echo "View trends: column -t -s',' $log"
}
```

---

## Part 2: Local Model Roster

### 2.1 Memory Budget for 64GB

| Model | VRAM | Use Case | Alias | Priority |
|-------|------|----------|-------|----------|
| Qwen 3 14B | ~9GB | Daily driver, general tasks | `llm-fast` | Pull first |
| Gemma 3 12B | ~8GB | Classification, fast fallback | `llm-classify` | Pull first |
| Qwen3 Coder | ~10GB | Code generation, debugging | `llm-code` | Pull second |
| Qwen3 Embedding 8B | ~5GB | RAG embeddings | `llm-embed` | Pull second |
| DeepSeek-R1 32B | ~20GB | Structured reasoning | `llm-reason` | Pull third |
| Gemma 4 31B | ~20GB | Heavy reasoning, audit | `llm-heavy` | Pull third |
| Gemma 4 26B | ~16GB | Vision, UI/screenshot review | `llm-vision` | Pull third |
| Llama 3.3 70B Q4 | ~42GB | Heavy planning (solo use) | `llm-plan` | Pull last |

**Constraint:** Don't run 70B + 32B simultaneously. The 70B model uses ~42GB alone; pair it only with small models (14B or below). Similarly, don't run Gemma 4 31B + DeepSeek-R1 32B together (~40GB combined leaves little headroom).

### 2.2 Pull Commands (Priority Order)

```bash
# Start Ollama server
ollama serve &

# Phase 1: Essential (Day 1)
ollama pull qwen3:14b              # ~9GB — fast daily driver
ollama pull gemma3:12b             # ~8GB — classification, fast fallback

# Phase 2: Coding & Embeddings (Day 1-2)
ollama pull qwen3-coder            # ~10GB — code specialist
ollama pull qwen3-embedding:8b     # ~5GB — RAG embeddings

# Phase 3: Reasoning & Vision (Day 2-3)
ollama pull deepseek-r1:32b        # ~20GB — structured reasoning
ollama pull gemma4:31b             # ~20GB — heavy reasoning, audit
ollama pull gemma4:26b             # ~16GB — vision/UI review

# Phase 4: Heavy (overnight)
ollama pull llama3.3:70b-instruct-q4_K_M  # ~42GB — download overnight, solo use
```

### 2.3 MLX Models (20-50% faster on Apple Silicon)

For maximum performance on critical tasks, use MLX-optimized models:

```bash
# Install mlx-lm if not already
pip install mlx-lm --break-system-packages

# Download MLX-optimized models from HuggingFace
python -m mlx_lm.convert --hf-path Qwen/Qwen3-14B -q
python -m mlx_lm.convert --hf-path Qwen/Qwen3-Coder -q
python -m mlx_lm.convert --hf-path deepseek-ai/DeepSeek-R1-Distill-Qwen-32B -q
```

**When to use MLX vs Ollama:**
- **MLX:** Performance-critical pipelines (Unbuilt stages), batch processing, IMPL pane when iteration speed matters (200+ tok/s on 14B models via 614GB/s bandwidth)
- **Ollama:** Interactive chat, compatibility with existing tools, quick tests, any task using `llm-*` aliases

**MLX hot-swap tip:** If a local task in your IMPL pane is taking too long via Ollama, switch to the MLX-converted version of the same model for a 20-50% speed boost:

```bash
# Quick MLX inference (bypasses Ollama, uses Metal directly)
python -m mlx_lm.generate --model ~/.cache/huggingface/mlx/Qwen3-Coder-q4 --prompt "your prompt"
```

---

## Part 3: Claude Code Configuration

### 3.1 Rebuild Your Multipane Setup

Clone your existing setup and install:

```bash
# Clone your multipane repository
cd ~/Projects
git clone https://github.com/pravindurgani/claude-code-multipane-iterm2.git

# Copy iTerm2 profiles
cp claude-code-multipane-iterm2/profiles/*.json ~/Library/Application\ Support/iTerm2/DynamicProfiles/

# Copy hooks
cp -r claude-code-multipane-iterm2/hooks/ ~/.claude/hooks/

# Copy skills
cp -r claude-code-multipane-iterm2/skills/ ~/.claude/skills/

# Copy commands
cp -r claude-code-multipane-iterm2/commands/ ~/.claude/commands/
```

### 3.2 Global CLAUDE.md (~/.claude/CLAUDE.md)

Based on Boris Cherny's recommendation: keep it short (~100 lines), update frequently.

```markdown
# Global Claude Code Configuration

## Identity
- Author: Prav Durgani
- Primary stack: Python (Streamlit, pytest, Pydantic), TypeScript (React), Shell

## Code Style
- Use ES modules (import/export), never CommonJS (require)
- Python: type hints everywhere, Pydantic for contracts
- Always graceful degradation: try/except with context logging
- Never bare excepts

## Workflow Rules
- Run tests before committing: `pytest -q`
- Lint before PR: `ruff check . --fix`
- Never push to main directly — always use branches
- Cross-model audit: IMPL pane writes, AUDIT pane reviews (never self-review)

## LLM Integration Patterns
- SHA1-keyed response caching for all API calls
- Structured output via Pydantic models
- Fallback chain: Claude → Ollama → rule-based

## File Handling
- Never edit .env files autonomously
- Never run git push without explicit human approval
- Copy files before destructive operations

## Session Continuity
- At the start of every session, read the last 60 lines of SESSION_LOG.md and surface the most recent "Next:" items.
- Before ending a session, append a timestamped summary with a "Next:" line for the follow-up pane.

## Lessons (updated by /reflect)
- [Add lessons here as Claude makes mistakes]
```

### 3.3 MCP Servers & Integrations

Claude Code uses MCP (Model Context Protocol) servers for external integrations, not plugins. Configure these in `.mcp.json` at project root:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@anthropic-ai/mcp-playwright"]
    },
    "github": {
      "command": "npx",
      "args": ["@anthropic-ai/mcp-github"],
      "env": { "GITHUB_TOKEN": "YOUR_READONLY_PAT_HERE" }
    }
  }
}
```

For LSP diagnostics, Claude Code reads from your IDE's language servers automatically — no separate installation needed. Ensure `pyright` and `typescript` are in your project dev dependencies.

### 3.4 Claude Code Settings (~/.claude/settings.json)

```json
{
  "cleanupPeriodDays": 365,
  "permissions": {
    "deny": [
      {"tool": "Write", "path": "**/.env*"},
      {"tool": "Write", "path": "**/*.pem"},
      {"tool": "Write", "path": "**/secrets/**"},
      {"tool": "Bash", "command": "git push*"}
    ]
  },
  "hooks": {
    "preWrite": ["~/.claude/hooks/protect-env.py"],
    "preBash": ["~/.claude/hooks/protect-git-push.py"],
    "postWrite": ["~/.claude/hooks/circuit-breaker.py"],
    "sessionStart": ["~/.claude/hooks/session-start-reset.py"]
  }
}
```

> **Note:** `alwaysThinkingEnabled` is no longer needed. Claude 4.6 uses adaptive thinking by default — thinking depth is controlled per-session via the `--effort` parameter in the `cc` aliases above (high/medium/low). Manual `budget_tokens` specification is deprecated.

### 3.5 Pane-Specific Local Model Overrides

When you need zero-latency or are working with sensitive data, swap a pane's intelligence to a local model without leaving the multipane view. Add these to `~/.zshrc` alongside your existing aliases:

```bash
# ─── LOCAL-ONLY PANE OVERRIDES ──────────────────────────────────────────────
# Use these when you want to keep a pane fully local (offline, sensitive data,
# or just faster iteration). Each maps to the best local model for that pane's role.

alias cc-local-fast='ollama run qwen3:14b'                        # Quick local question, any pane
alias cc-local-plan='ollama run llama3.3:70b-instruct-q4_K_M'    # Heavy reasoning for PLAN pane
alias cc-local-audit='ollama run deepseek-r1:32b'                 # Structured reasoning for AUDIT pane
alias cc-local-impl='ollama run qwen3-coder'                      # Code generation for IMPL pane
alias cc-local-vision='ollama run gemma4:26b'                     # UI/screenshot review for AUDIT pane
alias cc-local-heavy='ollama run gemma4:31b'                      # Heavy local tasks (solo, memory-intensive)
```

**Usage pattern:** In any pane, type `cc-local-audit` (or whichever override) instead of `cc` to route that task through a local model. The pane's iTerm2 profile and prompt colour remain unchanged — only the model backend switches.

**Memory constraint reminder:** Don't run `cc-local-plan` (70B, ~42GB) alongside `cc-local-audit` (32B, ~20GB). Pair the 70B model only with small models (14B or below).

### 3.6 SESSION_LOG.md for Cross-Pane Continuity

Because you run four separate Claude sessions, each pane "forgets" what the others decided. A shared `SESSION_LOG.md` at project root bridges this gap.

**Setup:** Create `SESSION_LOG.md` in each project root:

```bash
touch ~/Projects/<project>/SESSION_LOG.md
echo "# Session Log" > ~/Projects/<project>/SESSION_LOG.md
```

**Convention:** Each pane appends a timestamped block before ending work:

```markdown
## 2026-04-03 14:30 — PLAN pane
- Decided to split Stage 3 into two sub-stages for testability
- Architecture: new `StageValidator` class in src/pipeline/validators.py
- Next: IMPL pane should scaffold StageValidator with Pydantic model + pytest stub
```

**Auto-read on session start:** The instruction in your global CLAUDE.md (Section 3.2 above) ensures every new Claude session reads the last 60 lines and surfaces the most recent `Next:` items. This means your IMPL pane automatically knows what PLAN just decided.

---

## Part 4: Task-to-Model Routing

### 4.1 Your Optimal Routing Table

Based on your usage audit, here's the cost-optimized routing:

| Task Type | Model | Rationale |
|-----------|-------|-----------|
| **Problem definition** (Step 1) | Human brain | No AI for core thinking |
| **Architecture docs** (Step 2) | Claude Opus | Complex reasoning, long context |
| **CI/Test setup** (Step 3) | Claude Sonnet | Implementation work |
| **Pipeline implementation** (Step 4) | Claude Sonnet (IMPL pane) | Balanced speed/quality |
| **Audit** (Step 5) | Claude Opus (AUDIT pane) | Never self-review |
| **UI/Visual review** (Step 5b) | Gemma 4 26B (local vision) | Screenshot/UI audit stays local |
| **Monitoring setup** (Step 6) | Qwen 3 14B (local) | Template-based, low complexity |
| **Deploy automation** (Step 7) | Qwen 3 14B (local) | Standard patterns |
| **Bug triage** (Step 8) | Gemma 3 12B (local) | Classification task |
| **Heavy local reasoning** (offline) | Gemma 4 31B (local) | When cloud unavailable, complex tasks |

### 4.2 Default Path (When You're Not Sure)

Most tasks don't need routing decisions. Use this 80/20 rule to avoid decision fatigue:

| Situation | Just Use | Why |
|-----------|----------|-----|
| **Any task, no constraints** | `cc` (Claude Code with pane role) | Highest quality, role-aware |
| **Quick local question** | `llm-fast "..."` (Qwen 3 14B) | Fast, free, private |
| **Client/sensitive data** | `llm-fast "..."` (Qwen 3 14B) | Data never leaves machine |
| **Code generation offline** | `llm-code "..."` (Qwen3 Coder) | Best local code model |
| **Classification/triage** | `llm-classify "..."` (Gemma 3 12B) | Fast structured output |
| **UI/screenshot review** | `llm-vision "..."` (Gemma 4 26B) | Multimodal, stays local |
| **Heavy offline reasoning** | `llm-heavy "..."` (Gemma 4 31B) | When cloud is down or budget tight |

**Escalation triggers** (switch from default to specialized routing):
- Task involves **security review** → Opus (AUDIT pane) or DeepSeek-R1
- Task involves **>50 files or complex refactor** → Opus (long context)
- Task involves **visual/UI review** → Gemma 4 26B (local vision) or Opus
- Task is a **production pipeline stage** → Use the routing tables below
- **API is down or budget is tight** → Fall back to local models (Gemma 4 31B for complex, Qwen 3 14B for simple)

Everything else? `cc` or `llm-fast`. Don't overthink the routing.

### 4.3 Pipeline Optimizations

#### Unbuilt Pipeline

Rewrite your newsletter pipeline to save ~65% API costs:

| Stage | Current | Optimized | Saving |
|-------|---------|-----------|--------|
| Stage 1 (plan signals) | Claude Sonnet | Qwen 3 14B (local) | 100% |
| Stage 2 (pre-audit) | Claude Sonnet | Gemma 3 12B / `llm-classify` (local) | 100% |
| Stage 3 (HTML draft) | Claude Sonnet | **Keep Sonnet** | 0% |
| Stage 3 (plaintext) | Claude Haiku | Gemma 3 12B (local) | 100% |
| Stage 4 (auditor) | Claude Sonnet | Gemma 4 31B / `llm-heavy` (local) | 100% |
| Stage 5 (preview) | Claude Sonnet | Gemma 4 26B / `llm-vision` (local) | 100% |
| Stage 6 (finalize) | Claude Sonnet | **Keep Sonnet** | 0% |

#### AgentSutra Optimization

| Stage | Current | Optimized |
|-------|---------|-----------|
| Classify | Claude Sonnet | Gemma 3 12B / `llm-classify` (local) |
| Plan | Claude Sonnet | Llama 3.3 70B / `llm-plan` (local) |
| Execute | Claude Sonnet | **Keep Sonnet** (tool use critical) |
| Audit | Claude Opus | Gemma 4 31B / `llm-heavy` (local) |
| Deliver | Claude Sonnet | Qwen 3 14B / `llm-fast` (local) |

#### Clarion Work Routing

| Task | Model | Why |
|------|-------|-----|
| LinkedIn demographic analysis | Qwen 3 14B (local) | Client data stays local |
| D365 segment interpretation | Gemma 3 12B / `llm-classify` (local) | Structured, repetitive |
| UTM tracking diagnosis | Claude Sonnet | Needs web search |
| Campaign report drafting | Claude Sonnet | Quality matters for client-facing |
| Visual asset review | Gemma 4 26B / `llm-vision` (local) | Client screenshots stay local |

---

## Part 5: Image Generation Setup

### 5.1 Draw Things (Recommended)

Draw Things is Apple-native, ~20% faster than ComfyUI on M5 Max, and supports Flux, SDXL, and SD 1.5.

```bash
# Install from App Store (free)
# Search: "Draw Things" by Li Liu

# Recommended models to download inside app:
# - Flux.1 [dev] — highest quality
# - SDXL Base — balanced
# - Realistic Vision — photorealistic
```

**Performance on M5 Max 64GB:**
- Flux.1: ~30-50 seconds per 1024×1024 image
- SDXL: ~15-25 seconds per 1024×1024 image
- SD 1.5: ~5-10 seconds per 512×512 image

### 5.2 ComfyUI (Advanced Workflows)

For complex pipelines, ControlNet, or custom workflows:

```bash
# Install via Homebrew
brew install comfyui

# Or via Stability Matrix (manages multiple UIs)
brew install --cask stability-matrix
```

### 5.3 Image Generation in Pipelines

For programmatic image generation (e.g., Unbuilt thumbnails):

```python
# Using Draw Things HTTP API (if enabled)
import requests

def generate_image(prompt: str, output_path: str):
    response = requests.post(
        "http://localhost:7860/sdapi/v1/txt2img",
        json={
            "prompt": prompt,
            "negative_prompt": "blurry, low quality",
            "steps": 25,
            "width": 1024,
            "height": 1024,
            "cfg_scale": 7,
        }
    )
    # Save image from response
```

---

## Part 6: Audio Pipeline Setup

### 6.1 Transcription (Speech-to-Text)

**Primary: whisper.cpp with Metal acceleration**

> **M5 Max note:** Ensure whisper-cpp is compiled with Metal acceleration for the M5's Neural Accelerators. The Homebrew formula includes Metal support by default. If building from source, use `cmake -DWHISPER_METAL=ON` to enable GPU-accelerated inference for near-instant transcription speeds.

```bash
# Install (Homebrew includes Metal support)
brew install whisper-cpp

# Download model (one-time)
mkdir -p ~/.local/share/whisper-models
curl -L -o ~/.local/share/whisper-models/ggml-large-v3-turbo.bin \
  "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"

# Test transcription
whisper-cli -m ~/.local/share/whisper-models/ggml-large-v3-turbo.bin \
  -f audio.wav -otxt
```

**Alternative: MacWhisper (GUI)**

- Download from Gumroad (paid) or App Store
- Supports drag-and-drop, automatic meeting recording
- Integrates with Zoom, Teams, Discord

### 6.2 Text-to-Speech

**Primary: Kokoro ONNX (local, high quality)**

```bash
# Create dedicated environment
python3.12 -m venv ~/kokoro-venv
source ~/kokoro-venv/bin/activate

# Install
pip install kokoro-onnx sounddevice onnxruntime

# Run TTS server
python -c "
from kokoro_onnx import KokoroTTS
tts = KokoroTTS()
audio = tts.synthesize('Hello, this is a test.')
"
```

**Fallback: macOS Say command**

```bash
# Built-in, no setup required
say "Hello world" -o output.aiff
```

### 6.3 Voice-to-Code Workflow

Complete pipeline for voice-driven development:

```bash
#!/bin/bash
# voice-to-claude.sh — Record voice, transcribe, send to Claude Code

# Record until silence detected
ffmpeg -y -f avfoundation -i ":0" \
  -ar 16000 -ac 1 -acodec pcm_s16le \
  -t 30 /tmp/recording.wav 2>/dev/null

# Transcribe
whisper-cli -m ~/.local/share/whisper-models/ggml-large-v3-turbo.bin \
  -f /tmp/recording.wav -otxt > /tmp/transcript.txt

# Send to Claude Code as input
cat /tmp/transcript.txt | pbcopy
echo "Transcript copied to clipboard. Paste into Claude Code."
```

---

## Part 7: RAG & Knowledge Base Setup

### 7.1 Embeddings Model

```bash
# Primary embedding model (Qwen3 — better quality, multilingual)
ollama pull qwen3-embedding:8b

# Lightweight fallback
ollama pull nomic-embed-text
```

### 7.2 Local RAG Stack

For indexing your voice memos, meeting transcripts, and project docs:

```bash
# Create RAG environment
python3.12 -m venv ~/rag-env
source ~/rag-env/bin/activate

pip install langchain langchain-ollama chromadb sentence-transformers
```

**Example: Index your CLAUDE.md files**

```python
from langchain_ollama import OllamaEmbeddings
from langchain_community.vectorstores import Chroma
from langchain_community.document_loaders import DirectoryLoader

# Load all CLAUDE.md files
loader = DirectoryLoader(
    "~/Projects",
    glob="**/.claude/CLAUDE.md",
    recursive=True
)
docs = loader.load()

# Create embeddings (using your installed qwen3-embedding:8b)
embeddings = OllamaEmbeddings(model="qwen3-embedding:8b")
vectorstore = Chroma.from_documents(docs, embeddings, persist_directory="./claude-md-index")

# Query
results = vectorstore.similarity_search("What are the testing conventions?")
```

---

## Part 8: Development Environment

### 8.1 Python Environment (uv)

```bash
# uv is 10-100x faster than pip
pip install uv --break-system-packages

# Create project environment
cd ~/Projects/unbuilt
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

### 8.2 IDE Configuration

**VS Code Extensions:**
- Claude (Anthropic)
- Python (Microsoft)
- Pylance
- Ruff

**Cursor Configuration (if using):**

```json
// .cursor/settings.json
{
  "cursor.cpp.enabled": true,
  "cursor.ai.model": "claude-sonnet-4-6"
}
```

### 8.3 Git Worktrees for Parallel Claude Sessions

From Boris Cherny's workflow — run 10-15 Claude sessions simultaneously:

```bash
# Create worktrees for parallel work
cd ~/Projects/unbuilt
git worktree add ../unbuilt-feature-1 -b feature/stage-optimization
git worktree add ../unbuilt-feature-2 -b feature/beehiiv-integration
git worktree add ../unbuilt-audit -b audit/security-review

# Each worktree gets its own Claude Code session
# Changes don't collide
```

---

## Part 9: Workflow Integration

### 9.1 Daily Startup Sequence

```bash
#!/bin/bash
# ai-workstation-start.sh

# Start Ollama server
ollama serve &

# Pre-warm frequently used models (keeps them loaded for 5m per OLLAMA_KEEP_ALIVE)
ollama run qwen3:14b "Hello" > /dev/null 2>&1 &
ollama run qwen3-coder "Hello" > /dev/null 2>&1 &

# Start Docker (for AgentSutra)
open -a Docker

# Open iTerm2 with multipane layout
osascript -e 'tell application "iTerm2" to create window with profile "DEV-MULTIPANE"'

echo "AI Workstation ready."
echo "Loaded: qwen3:14b, qwen3-coder"
echo "Available: gemma3:12b, deepseek-r1:32b, gemma4:31b, gemma4:26b, llama3.3:70b (load on demand)"
```

### 9.2 Project Initialization Template

When starting a new project, follow your optimal build process:

```bash
#!/bin/bash
# new-project.sh <project-name>

PROJECT_NAME=$1
mkdir -p ~/Projects/$PROJECT_NAME
cd ~/Projects/$PROJECT_NAME

# Initialize git
git init

# Create structure
mkdir -p src tests .claude/commands .claude/skills

# Create CLAUDE.md from template
cat > .claude/CLAUDE.md << 'EOF'
# Project: $PROJECT_NAME

## Problem Statement
[3 sentences: what exists, what's wrong, what success looks like]

## Weight Class
[ ] Prototype — throwaway
[ ] Tool — internal, regular use
[ ] Product — external users

## Commands
- `pytest -q` — run tests
- `ruff check .` — lint
- `uv pip install -e .` — install locally

## Invariants
- [Add project-specific rules here]
EOF

# Create SESSION_LOG.md for cross-pane continuity (see Section 3.6)
echo "# Session Log — $PROJECT_NAME" > SESSION_LOG.md

# Create initial test
cat > tests/test_placeholder.py << 'EOF'
def test_placeholder():
    """Remove when real tests exist."""
    assert True
EOF

# Create pyproject.toml
cat > pyproject.toml << 'EOF'
[project]
name = "$PROJECT_NAME"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []

[tool.ruff]
line-length = 100
select = ["E", "F", "I", "UP"]
EOF

# Initialize environment
uv venv
source .venv/bin/activate
uv pip install pytest ruff

# First commit
git add -A
git commit -m "Initial project structure"

echo "Project $PROJECT_NAME created. Run 'cc' to start Claude Code."
```

### 9.3 Audit Workflow

Before shipping, run through your 8 decision gates:

```bash
# gate — run pre-ship checks (lint + security + tests + type check + deploy)
gate() {
  echo "=== GATE CHECK ==="

  # Gate 1: Lint clean (catches style issues before tests run)
  echo "[1/5] Running linter..."
  ruff check . || { echo "❌ Lint failed — run 'ruff check . --fix' to auto-fix"; return 1; }

  # Gate 2: Security scan (catches secrets, known vulnerabilities)
  echo "[2/5] Running security scan..."
  if command -v bandit &> /dev/null; then
    bandit -r src/ -q -ll 2>/dev/null || { echo "❌ Security issues found"; return 1; }
  elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    echo "  (bandit not installed — run 'pip install bandit' for Python security scanning)"
  fi
  if [ -f "package.json" ]; then
    npm audit --audit-level=high 2>/dev/null || echo "  (npm audit warnings — review before ship)"
  fi

  # Gate 3: Tests pass
  echo "[3/5] Running tests..."
  pytest tests/ -x --tb=short || { echo "❌ Tests failed"; return 1; }

  # Gate 4: Type check (if TypeScript)
  if [ -f "tsconfig.json" ]; then
    echo "[4/5] Running type check..."
    npx tsc --noEmit || { echo "❌ Type check failed"; return 1; }
  else
    echo "[4/5] Type check skipped (no tsconfig.json)"
  fi

  # Gate 5: Can redeploy?
  echo "[5/5] Checking deployment readiness..."
  if [ -f "Dockerfile" ]; then
    docker build -t test-build . --quiet || { echo "❌ Docker build failed"; return 1; }
  fi

  echo "✅ ALL GATES PASSED — LINT, SECURITY, TESTS CLEAR"
}
```

### 9.4 SESSION_LOG.md Inter-Pane Workflow

When running four Claude sessions simultaneously, context bleeds between panes are the biggest productivity killer. The SESSION_LOG.md pattern (configured in Section 3.6) solves this.

**Recommended flow:**

```
PLAN pane decides architecture
  ↓ writes "Next: IMPL should scaffold X" to SESSION_LOG.md
IMPL pane reads SESSION_LOG.md on start
  ↓ implements X, writes "Next: AUDIT should review Y"
AUDIT pane reads SESSION_LOG.md on start
  ↓ reviews Y, writes "Next: IMPL should fix Z"
IMPL pane reads updated log
  ↓ fixes Z, writes "Next: gate + ship"
```

**Tip:** If you use the `/reflect` command at the end of a session, include the SESSION_LOG.md entry as part of the reflection. This ensures lessons flow into both the log and your CLAUDE.md.

---

## Part 10: Fallback Chains

Your guiding principle: **always have Plan B and Plan C.**

### 10.1 LLM Fallback Chain

```python
from typing import Optional
import httpx

class LLMRouter:
    """Route to best available model with automatic fallback."""
    
    def __init__(self):
        self.anthropic_key = os.getenv("ANTHROPIC_API_KEY")
        self.ollama_url = "http://localhost:11434"
    
    async def generate(
        self,
        prompt: str,
        task_type: str = "general",
        require_cloud: bool = False
    ) -> Optional[str]:
        """Try models in order until one succeeds."""
        
        # Route by task type (models match your installed roster)
        if task_type == "code":
            chain = ["claude-sonnet-4-6", "qwen3-coder", "qwen3:14b"]
        elif task_type == "audit":
            chain = ["claude-opus-4-6", "deepseek-r1:32b", "gemma4:31b"]
        elif task_type == "vision":
            chain = ["claude-opus-4-6", "gemma4:26b", "gemma3:12b"]
        elif task_type == "fast":
            chain = ["qwen3:14b", "gemma3:12b", "claude-haiku-4-5"]
        elif task_type == "heavy":
            chain = ["claude-opus-4-6", "gemma4:31b", "llama3.3:70b-instruct-q4_K_M"]
        else:
            chain = ["claude-sonnet-4-6", "qwen3:14b", "gemma3:12b"]
        
        # If require_cloud, filter to API models only
        if require_cloud:
            chain = [m for m in chain if m.startswith("claude")]
        
        for model in chain:
            try:
                if model.startswith("claude"):
                    return await self._call_anthropic(prompt, model)
                else:
                    return await self._call_ollama(prompt, model)
            except Exception as e:
                logger.warning(f"Model {model} failed: {e}, trying next...")
                continue
        
        raise RuntimeError("All models in fallback chain failed")
```

### 10.2 Image Generation Fallback

```python
async def generate_image(prompt: str) -> bytes:
    """Image generation with fallback chain."""
    
    # Try Draw Things first (local, fast)
    try:
        return await draw_things_generate(prompt)
    except Exception:
        pass
    
    # Fall back to ComfyUI
    try:
        return await comfyui_generate(prompt)
    except Exception:
        pass
    
    # Last resort: placeholder image
    return create_placeholder_image(prompt)
```

### 10.3 Transcription Fallback

```python
def transcribe(audio_path: str) -> str:
    """Transcribe with fallback chain."""
    
    # Try whisper.cpp (fastest, local)
    try:
        return whisper_cpp_transcribe(audio_path)
    except Exception:
        pass
    
    # Fall back to MLX Whisper
    try:
        return mlx_whisper_transcribe(audio_path)
    except Exception:
        pass
    
    # Last resort: macOS Speech Recognition
    return apple_speech_transcribe(audio_path)
```

---

## Part 11: Quick Reference Card

### Model Selection Cheatsheet

| Task | Best Model | Alias | Why |
|------|------------|-------|-----|
| Complex architecture | Claude Opus | `cc` (PLAN pane) | Long context, deep reasoning |
| Code implementation | Claude Sonnet / Qwen3 Coder | `cc` / `llm-code` | Balanced speed/quality |
| Code audit | Claude Opus / Gemma 4 31B | `cc` / `llm-heavy` | Never self-review |
| Reasoning/logic | DeepSeek-R1 32B | `llm-reason` | Chain-of-thought specialist |
| Quick classification | Gemma 3 12B | `llm-classify` | Fast, accurate |
| UI/visual review | Gemma 4 26B | `llm-vision` | Multimodal, stays local |
| Heavy offline reasoning | Gemma 4 31B | `llm-heavy` | Cloud-down fallback |
| Planning (offline) | Llama 3.3 70B Q4 | `llm-plan` | Solo use only (42GB) |
| Client data processing | Qwen 3 14B | `llm-fast` | Data never leaves machine |
| Embeddings | Qwen3 Embedding 8B | `llm-embed` | Best quality/size ratio |
| Image generation | Draw Things (Flux) | — | Apple-optimized |
| Transcription | whisper.cpp large-v3-turbo | `transcribe` | Metal acceleration |

### Daily Commands

```bash
# Start workstation
ai-workstation-start.sh

# Quick model access
llm-fast "Summarize this"            # Qwen 3 14B
llm-code "Explain this function"     # Qwen3 Coder
llm-reason "Analyze this approach"   # DeepSeek-R1 32B
llm-classify "Bug or feature?"       # Gemma 3 12B
llm-heavy "Review this architecture" # Gemma 4 31B
llm-vision                           # Gemma 4 26B (interactive, paste screenshots)
llm-plan "Design the migration"      # Llama 3.3 70B (solo use, 42GB)
llm-embed                            # Qwen3 Embedding 8B (for RAG pipelines)

# Local-only pane overrides (swap a pane to local model)
cc-local-impl                        # Qwen3 Coder in IMPL pane
cc-local-audit                       # DeepSeek-R1 in AUDIT pane

# Transcribe
transcribe recording.wav

# Claude Code with role
cc  # Uses profile-aware alias (AUDIT/IMPL/PROMPT/PLAN)

# Pre-ship checks (lint + security + tests)
gate
```

### Key Principles

1. **Pipeline discipline:** Fixed stages, typed boundaries, predictable flow
2. **Trust but verify:** LLM output always validated (tests, schemas, cross-model audit)
3. **Degrade gracefully:** Every feature has a fallback; nothing crashes delivery
4. **Route by complexity:** Cheapest accurate model wins; premium models for critical paths
5. **Local for privacy:** Client data stays on-machine via Ollama

---

## Appendix A: Troubleshooting

### Ollama Model Won't Load

```bash
# Check available memory
ollama ps

# Unload a model to free memory
ollama stop qwen3-coder

# Restart Ollama
ollama serve
```

### MLX Model Errors

```bash
# Clear HuggingFace cache
rm -rf ~/.cache/huggingface/hub/models--*

# Re-download with explicit quantization
python -m mlx_lm.convert --hf-path <model> -q --q-bits 4
```

### Claude Code Permission Issues

```bash
# Check settings are valid JSON
python3 -m json.tool ~/.claude/settings.json

# Reset hooks state
rm -f ./circuit-breaker-state.json

# View hook logs
cat ~/.claude/hook-errors.log
```

### Image Generation Slow

- Close other apps to free unified memory
- Use GGUF quantized models (Flux.1 Q4)
- Lower resolution (768×768) then upscale
- Use LCM models (4-8 steps instead of 25-50)

---

## Appendix B: Cost Tracking

### API Cost Estimation

| Model | Input (per 1M tokens) | Output (per 1M tokens) |
|-------|----------------------|------------------------|
| Claude Opus | $15 | $75 |
| Claude Sonnet | $3 | $15 |
| Claude Haiku | $0.25 | $1.25 |
| Local (Ollama) | $0 | $0 |

> **Long context pricing:** Claude 4.6 supports a 1M-token context window, but requests exceeding ~200K tokens incur higher "long context" pricing. Keep this in mind when injecting large codebases or documentation — your Documentation Freshness Rule (Step 2) and the 10KB doc split rule help keep context lean and costs predictable.

### Weekly Budget Target

Based on your usage patterns:

| Use Case | Est. Tokens/Week | Optimal Routing | Cost |
|----------|------------------|-----------------|------|
| Unbuilt pipeline | ~500K | 30% Sonnet, 70% local | ~$5 |
| AgentSutra | ~200K | 20% Sonnet, 80% local | ~$2 |
| Clarion work | ~300K | 50% Sonnet, 50% local | ~$3 |
| Ad-hoc Claude Code | ~400K | 60% Sonnet, 40% Opus | ~$8 |
| **Weekly Total** | ~1.4M | Mixed | **~$18** |

**Vs. current routing (all cloud):** ~$45/week → 60% savings

---

## Appendix C: First Week Checklist

### Phase 0: Minimal Mode (Days 1–2)

Get productive immediately with only 2 models. No MLX, no RAG, no creative tools. Validate real bottlenecks before adding complexity.

**Day 1 — Foundation**
- [ ] Install Homebrew, dev tools, iTerm2, Docker
- [ ] Install Ollama and Claude Code
- [ ] Pull **Qwen 3 14B** and **Gemma 3 12B** (9GB + 8GB — your two essential local models)
- [ ] Configure `~/.zshrc` with aliases (full roster + `llm-smart` router)
- [ ] Clone multipane repository, install profiles/hooks
- [ ] **Verify Metal acceleration** (catches config issues early):
  ```bash
  # Verify MLX sees unified memory
  python -c "import mlx.core as mx; print(f'Metal available: {mx.metal.is_available()}')"
  python -c "import mlx.core as mx; print(f'Memory limit: {mx.metal.memory_limit() / 1e9:.1f} GB')"
  
  # Verify Ollama uses Metal
  ollama run qwen3:14b "Hello" 2>&1 | grep -i metal
  ```
  If these pass, the workstation is correctly configured. If not, debug now rather than chasing slow inference later.

**Day 2 — Start Working**
- [ ] Clone your active projects, verify they run
- [ ] Pull qwen3-embedding:8b (~5GB — needed if any project uses RAG)
- [ ] Do real work using only `cc` (Claude Code) + `llm-fast` (Qwen 3 14B)
- [ ] Note what feels slow or missing — these are your real bottlenecks

**Minimal Mode gives you:** Claude Code (all 4 panes) + one fast local model + all safety hooks. This covers ~80% of daily work. Stay here for a few days before scaling up.

### Phase 1: Full Mode (Days 3–5)

Add specialised models based on what you actually needed in Phase 0.

**Day 3 — Code & Reasoning Models**
- [ ] Pull Qwen3 Coder (`ollama pull qwen3-coder` — code specialist)
- [ ] Pull DeepSeek-R1 32B (`ollama pull deepseek-r1:32b` — structured reasoning)
- [ ] Pull Qwen3 Embedding 8B (`ollama pull qwen3-embedding:8b` — RAG embeddings)
- [ ] Update pipeline routing in active projects

**Day 4 — Heavy & Vision Models + Creative**
- [ ] Pull Gemma 4 31B (`ollama pull gemma4:31b` — heavy local reasoning)
- [ ] Pull Gemma 4 26B (`ollama pull gemma4:26b` — vision/UI review)
- [ ] Install Draw Things, download Flux model
- [ ] Set up whisper.cpp with large-v3-turbo
- [ ] Set up Kokoro TTS
- [ ] Test voice-to-code workflow

**Day 5 — Scale**
- [ ] Start Llama 3.3 70B download overnight (`ollama pull llama3.3:70b-instruct-q4_K_M`)
- [ ] Install `bandit` for Python security scanning (`pip install bandit`)
- [ ] Set up RAG indexing for project docs (using qwen3-embedding:8b)
- [ ] Create SESSION_LOG.md in active projects
- [ ] Create project templates
- [ ] Run first full audit cycle with new routing
- [ ] Run `llm-stats` to review your first week's model usage patterns

### Week 1 Goal
**First project built entirely on new machine. Review `llm-stats` output to validate whether your routing assumptions match real usage.**

---

*"The M5 Max makes local inference genuinely competitive with API quality for the majority of tasks. The only things that still clearly warrant cloud models are final-stage deliverables and complex novel reasoning. Everything else is now cheaper and more private done locally."*

— From your AI Usage Audit, synthesized into action
