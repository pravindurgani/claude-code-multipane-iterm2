#!/usr/bin/env python3
"""SessionStart hook: reset circuit-breaker state at the start of each session.

Uses naive local datetime (datetime.now()) throughout.
Do NOT mix timezone.utc with naive local dates.
Exit 0 always (this hook never blocks).
"""
import json
import sys
from datetime import datetime
from pathlib import Path

_STATE_FILE = Path.cwd() / "circuit-breaker-state.json"


def main() -> None:
    try:
        json.load(sys.stdin)  # consume stdin; content not needed for reset
    except (json.JSONDecodeError, ValueError) as exc:
        print(
            f"[session-start-reset] WARNING: failed to parse stdin: {exc}",
            file=sys.stderr,
        )
        sys.exit(0)

    state = {
        "consecutive_failures": 0,
        "reset_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    }
    _STATE_FILE.write_text(json.dumps(state))
    sys.exit(0)


if __name__ == "__main__":
    main()
