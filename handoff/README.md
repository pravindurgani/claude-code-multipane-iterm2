# `handoff/` — file-based bracketed-paste routing between iTerm panes

This directory contains the implementation of the handoff feature.
See [`../HANDOFF_GUIDE.md`](../HANDOFF_GUIDE.md) for the operator manual.

## Contents

| File | What it is |
|---|---|
| [`pane-handoff.sh`](pane-handoff.sh) | The watcher script. `fswatch` monitors `~/.claude/handoff/`, routes `to-impl.<scope>.txt` and `to-audit.<scope>.txt` to bound iTerm sessions via bracketed paste. Installed to `~/.claude/hooks/`. |
| [`com.user.handoff.plist.template`](com.user.handoff.plist.template) | launchd template. `install.sh` renders it with `$HOME` and installs to `~/Library/LaunchAgents/`. Keeps the watcher alive at login and restarts on crash. |
| [`zshrc-handoff.sh`](zshrc-handoff.sh) | The shell functions (`handoff-*`, `send-*`). Append to `~/.zshrc`. |
| [`install.sh`](install.sh) | One-shot installer. Copies files, renders the plist, loads the launchd agent, arms routing. |

The Stop hook ([`../hooks/enforce-handback.py`](../hooks/enforce-handback.py)) and the slash commands ([`../commands/start-impl.md`](../commands/start-impl.md), [`../commands/start-audit.md`](../commands/start-audit.md)) live in their existing repo locations and are copied by `install.sh`.

## Install

From the repo root:

```bash
brew install fswatch                       # required dependency
./handoff/install.sh                       # copies files, loads launchd agent, arms routing
cat handoff/zshrc-handoff.sh >> ~/.zshrc   # adds the user-facing functions
source ~/.zshrc
```

Then read [`../HANDOFF_GUIDE.md`](../HANDOFF_GUIDE.md) §3 to activate your first project.

## Uninstall

```bash
./handoff/install.sh --uninstall
```

Manually remove the handoff block from `~/.zshrc` if you added it.
