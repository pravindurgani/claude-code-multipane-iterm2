#!/usr/bin/env python3
"""PostToolUse hook: trip a circuit-breaker after N consecutive tool failures.

Schema: is_error, error, and tool_error are read from the event root level.
State file: circuit-breaker-state.json in Path.cwd().
TOCTOU fix: fcntl.LOCK_EX wraps the read-modify-write.
Double-write fix: state is computed once and written once per invocation.
macOS/Linux only (fcntl).
Exit 2 = block. Exit 0 = allow.
"""
import fcntl
import json
import sys
from pathlib import Path

_THRESHOLD = 3
_STATE_FILE = Path.cwd() / "circuit-breaker-state.json"


def main() -> None:
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError) as exc:
        print(
            f"[circuit-breaker] WARNING: failed to parse stdin: {exc}",
            file=sys.stderr,
        )
        sys.exit(0)

    # PostToolUse schema: failure fields are at the event root, not nested.
    is_failure = bool(
        event.get("is_error")
        or event.get("error")
        or event.get("tool_error")
    )

    # Open in "a+" so the file is created if absent; seek to start for reading.
    with open(_STATE_FILE, "a+") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        f.seek(0)
        raw = f.read().strip()
        try:
            state = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            state = {}

        failures = state.get("consecutive_failures", 0)
        new_failures = failures + 1 if is_failure else 0

        # Compute final state once; write once.
        if new_failures >= _THRESHOLD:
            new_state = {"consecutive_failures": 0}  # reset so next session starts clean
        else:
            new_state = {"consecutive_failures": new_failures}

        f.seek(0)
        f.truncate()
        json.dump(new_state, f)

    if new_failures >= _THRESHOLD:
        print(
            f"[circuit-breaker] BLOCKED: {new_failures} consecutive tool failures "
            f"(threshold={_THRESHOLD}). Diagnose the root cause before continuing.",
            file=sys.stderr,
        )
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
