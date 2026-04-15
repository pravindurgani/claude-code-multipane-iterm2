# Changelog

## 2026-04-15 — Guide rewrite (friend-install path)

### Breaking change — iTerm2 profile prefix renamed `DEV-*` → `CC-*`

The four iTerm2 profile names have changed:

| Old | New |
|-----|-----|
| `DEV-AUDIT` | `CC-AUDIT` |
| `DEV-IMPL` | `CC-IMPL` |
| `DEV-PROMPT` | `CC-PROMPT` |
| `DEV-PLAN` | `CC-PLAN` |

**Migration:** In iTerm2 → Preferences → Profiles, rename each profile. The `zshrc-snippet.sh` `case` block and all guide references now use `CC-*`.

**Why:** `CC-` is more descriptive for friends installing from scratch ("Claude Code") and decouples from any existing `DEV-*` profiles a reader may already have.

### New content

- RAM-tier-gated install path (16 GB / 32 GB / 64 GB)
- Prerequisites section (Homebrew, Node.js, Xcode CLT)
- Claude Code install section (browser OAuth primary, API key as alternative)
- Ollama local AI models section (`llm-fast`, `llm-code`, `llm-reason`, `llm-embed`, `llm-smart` router)
- Draw Things optional section

### Removed

- `m5-max-ai-workstation-setup.md` — personal content, moved to private notes
- `ai-workstation-cheatsheet.html`, `m5-max-quick-reference.html`, `m5-max-quick-reference.md` — superseded by new guide

### CLAUDE.md.template

Rewritten as an annotated skeleton with placeholders. Not a clone of the author's personal file — friends should fill in their own stack and constraints.
