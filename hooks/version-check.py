#!/usr/bin/env python3
"""SessionStart hook: detect Claude Code version changes and print update checklist.

Compares `claude --version` against a stored value. Prints a reminder
when the version changes; exits silently otherwise.
Exit 0 always (this hook never blocks).
"""
import json
import subprocess
import sys
from pathlib import Path

_VERSION_FILE = Path.home() / ".claude" / ".last-known-cc-version"


def _get_current_version() -> str:
    """Get installed Claude Code version string."""
    try:
        result = subprocess.run(
            ["claude", "--version"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        return result.stdout.strip().splitlines()[0]
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return ""


def main() -> None:
    try:
        json.load(sys.stdin)  # consume stdin; content not needed
    except (json.JSONDecodeError, ValueError):
        pass  # non-critical — proceed regardless

    current = _get_current_version()
    if not current:
        sys.exit(0)  # can't determine version — skip silently

    if _VERSION_FILE.exists():
        try:
            stored = _VERSION_FILE.read_text().strip()
        except OSError as exc:
            print(
                f"[version-check] WARNING: could not read version file: {exc}",
                file=sys.stderr,
            )
            sys.exit(0)
        if stored != current:
            print(f"\n--- Claude Code updated: {stored} -> {current} ---")
            print("Setup update checklist:")
            print("  1. Check cc alias flags:  claude --help | head -20")
            print("  2. Bump footer: index.html:1818 (on every release)")
            print("  3. Bump last-verified markers ONLY on re-verify pass:")
            print("       guide.md:4, guide.md:249, guide.md:692, index.html:1074, index.html:1803")
            print("  4. Test hooks:  claude --version && echo 'hooks still load'")
            print("  5. Test MCP:    claude mcp list | grep github")
            print("  6. Review changelog for breaking changes")
            print("---\n")
            try:
                _VERSION_FILE.write_text(current)
            except OSError as exc:
                print(
                    f"[version-check] WARNING: could not update version file: {exc}",
                    file=sys.stderr,
                )
    else:
        # First run — store version, no reminder needed
        try:
            _VERSION_FILE.write_text(current)
        except OSError as exc:
            print(
                f"[version-check] WARNING: could not create version file: {exc}",
                file=sys.stderr,
            )

    sys.exit(0)


if __name__ == "__main__":
    main()
