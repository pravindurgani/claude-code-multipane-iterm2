#!/usr/bin/env python3
"""PreToolUse hook: block Bash commands containing a git push subcommand.

Tokenises each shell segment to detect 'push' as the first positional argument
to git, skipping flags and their argument tokens. This avoids false positives on
filenames containing 'push' (e.g. protect-git-push.py, push-notifications.py).

Handles: git push, git -c key=val push, git -C /path push,
         git --no-pager push, git --git-dir=... push, compound commands.

Known git global flags that consume the following token as their argument:
-C, -c, --git-dir, --work-tree, --namespace, --super-prefix.

Exit 2 = block. Exit 0 = allow.
"""
import json
import re
import shlex
import sys

# Git global flags that consume the following token as their argument.
_GIT_ARG_FLAGS = frozenset(
    ["-C", "-c", "--git-dir", "--work-tree", "--namespace", "--super-prefix"]
)


def _segment_has_git_push(segment: str) -> bool:
    """Return True if a single shell segment invokes 'git push' as a subcommand."""
    try:
        tokens = shlex.split(segment)
    except ValueError:
        tokens = segment.split()
    if not tokens or tokens[0] != "git":
        return False
    i = 1
    while i < len(tokens):
        tok = tokens[i]
        if tok in _GIT_ARG_FLAGS:
            i += 2  # skip flag and its argument token
        elif tok.startswith("-"):
            i += 1  # skip standalone flag (--flag=value or -f)
        else:
            # First positional token is the git subcommand.
            return tok == "push"
    return False


def _contains_git_push(command: str) -> bool:
    """Return True if any shell segment in command invokes git push."""
    segments = re.split(r"&&|\|\||;|\|", command)
    return any(_segment_has_git_push(s.strip()) for s in segments)


def main() -> None:
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError) as exc:
        print(
            f"[protect-git-push] WARNING: failed to parse stdin: {exc}",
            file=sys.stderr,
        )
        sys.exit(0)

    if event.get("tool_name", "") != "Bash":
        sys.exit(0)

    command = event.get("tool_input", {}).get("command", "")
    if _contains_git_push(command):
        print(
            f"[protect-git-push] BLOCKED: git push detected in command: {command!r}",
            file=sys.stderr,
        )
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
