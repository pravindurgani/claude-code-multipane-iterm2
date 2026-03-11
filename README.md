# 4-Pane Claude Code Setup for iTerm2

A step-by-step guide to running 4 dedicated Claude Code sessions in a single iTerm2 window — each with a distinct role, model, effort level, and visual identity.

**[Read the full guide](https://pravindurgani.github.io/claude-code-multipane-iterm2/)**

![4-pane iTerm2 layout with Claude Code running in each pane](screenshots/05-claude-running.png)

## The Setup

| Pane | Role | Model | Effort | Permission |
|------|------|-------|--------|------------|
| **AUDIT** | Code review (read-only) | Opus | high | `plan` |
| **IMPL** | Code writing & editing | Sonnet | high | `acceptEdits` |
| **PROMPT** | Prompt engineering | Sonnet | medium | default |
| **PLAN** | Architecture & planning | Sonnet | low | default |

**Why this split:**
- Opus is ~15x more expensive than Sonnet — reserve it for review only
- Separating review from implementation prevents "self-grading" bias
- Each pane keeps a clean, focused context window
- A `cc` alias launches the right configuration per pane automatically

## What's in this repo

| File | Purpose |
|------|---------|
| [`index.html`](index.html) | Full visual guide (the GitHub Pages site) |
| [`guide.md`](guide.md) | Markdown version for quick reference |
| [`zshrc-snippet.sh`](zshrc-snippet.sh) | Copy-paste block for your `~/.zshrc` |
| [`screenshots/`](screenshots/) | Step-by-step screenshots |

## Quick Start

1. Create 4 iTerm2 profiles (`DEV-AUDIT`, `DEV-IMPL`, `DEV-PROMPT`, `DEV-PLAN`) with distinct background colours
2. Set startup commands and initial directory for each profile
3. Append [`zshrc-snippet.sh`](zshrc-snippet.sh) to your `~/.zshrc`
4. Create a 2x2 pane layout and save as default arrangement
5. Type `cc` in each pane to launch Claude Code

For detailed instructions with screenshots, **[read the full guide](https://pravindurgani.github.io/claude-code-multipane-iterm2/)**.

## Requirements

- macOS
- [iTerm2](https://iterm2.com/)
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (with an active subscription)
- zsh (default macOS shell)

## Adapting for Your Project

The setup is project-agnostic. To use with any codebase:

1. Update the **Initial Directory** in each profile to your project path
2. If you want per-project profiles, use a prefix (e.g. `SS-AUDIT` for SensiSpend) and add matching `case` entries to `~/.zshrc`
3. Save a separate window arrangement per project

## License

MIT
