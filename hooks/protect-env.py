#!/usr/bin/env python3
"""PreToolUse hook: block Edit, Write, and MultiEdit on any .env file.

Checks only the filename component (not the full path) to avoid false positives
on files inside directories whose names contain '.env'.
macOS/Linux only (no Windows dependency).
Exit 2 = block the tool call. Exit 0 = allow.
"""
import json
import sys
from pathlib import Path


def _is_env_path(path: str) -> bool:
    """Match only the filename component to avoid false positives on directory names."""
    name = Path(path).name if path else ""
    return name == ".env" or name.startswith(".env.")


def main() -> None:
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError) as exc:
        print(f"[protect-env] WARNING: failed to parse stdin: {exc}", file=sys.stderr)
        sys.exit(0)

    tool_name = event.get("tool_name", "")
    if tool_name not in ("Edit", "Write", "MultiEdit"):
        sys.exit(0)

    tool_input = event.get("tool_input", {})

    if tool_name == "MultiEdit":
        paths = [edit.get("file_path", "") for edit in tool_input.get("edits", [])]
    else:
        paths = [tool_input.get("file_path", "")]

    blocked = [p for p in paths if _is_env_path(p)]
    if blocked:
        print(
            f"[protect-env] BLOCKED: attempted {tool_name} on .env file(s): {blocked}",
            file=sys.stderr,
        )
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
