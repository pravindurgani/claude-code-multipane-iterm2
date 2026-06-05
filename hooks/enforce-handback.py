#!/usr/bin/env python3
"""Stop hook: enforce IMPL pane hand-back contract.

If the IMPL pane's final assistant message contains the literal marker
"→ handed back", the scoped to-audit.<scope>.txt file MUST have been
written (or drained) during this turn. Otherwise the watcher
(~/.claude/hooks/pane-handoff.sh) was never notified and AUDIT will sit
idle — the loop silently stalls.

Decision:
- Block the turn when the marker is present but the file is missing /
  stale, so the model is forced to run the mandatory heredoc.
- Allow (exit 0) in every other case — including any state we can't
  resolve. Never block on hook bugs.

Pane scope is resolved by matching $ITERM_SESSION_ID against
~/.claude/handoff/impl-target.<scope>.id files. AUDIT/PLAN panes never
match, so the hook silently passes them through.

Stdout contract on block: {"decision":"block","reason":"..."} then exit 0.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import time
import traceback
from pathlib import Path

_HANDOFF_DIR = Path.home() / ".claude" / "handoff"
_LOG = Path("/tmp/handoff.log")
_MARKER = "→ handed back"
_FRESH_SECONDS = 120
# Structured hand-back field names per start-impl.md. If 3+ appear in the
# final message, treat it as a hand-back attempt even without the marker —
# this catches the failure mode where the model strips the marker to dodge
# the hook but still reports the structured fields in chat.
_HANDBACK_FIELDS = (
    "Step:",
    "Merged SHA:",
    "Gate:",
    "Net-new LOC:",
    "Surface assessment:",
    "Next-axis recommendation:",
)
_SIGNATURE_THRESHOLD = 3


def _log(line: str) -> None:
    try:
        with _LOG.open("a") as f:
            f.write(f"{line}\n")
    except OSError:
        pass


def _resolve_scope(iterm_session_id: str) -> str | None:
    if not iterm_session_id:
        return None
    # Real iTerm2 ITERM_SESSION_ID is "wNtNpN:UUID"; pane-handoff.sh stores
    # the bare UUID after `${ITERM_SESSION_ID##*:}`. Match that form here.
    target = iterm_session_id.strip().rsplit(":", 1)[-1].upper()
    for id_file in _HANDOFF_DIR.glob("impl-target.*.id"):
        try:
            uuid = id_file.read_text().strip().upper()
        except OSError:
            continue
        if uuid == target:
            stem = id_file.name[len("impl-target."):-len(".id")]
            return stem or None
    return None


def _read_last_assistant_text(path: Path) -> str:
    """Scan transcript JSONL from the tail, return text of the latest fully-
    written assistant message (with non-empty text content). Skips partial
    or non-JSON lines silently."""
    text = ""
    try:
        with path.open() as f:
            lines = f.readlines()
    except OSError:
        return ""
    for raw in reversed(lines[-200:]):
        try:
            obj = json.loads(raw)
        except json.JSONDecodeError:
            # Partial line at tail-of-file (harness still flushing) — skip.
            continue
        if obj.get("type") != "assistant":
            continue
        msg = obj.get("message") or {}
        content = msg.get("content")
        if isinstance(content, str) and content:
            return content
        if isinstance(content, list):
            parts = [
                c.get("text", "")
                for c in content
                if isinstance(c, dict) and c.get("type") == "text"
            ]
            joined = "\n".join(p for p in parts if p)
            if joined:
                return joined
    return text


def _last_assistant_message_from_transcript(path: str) -> str:
    """Read the latest assistant text from the transcript, tolerating the
    harness's write-then-invoke-hook race. The Stop hook fires immediately
    after the assistant message completes, but the JSONL line may not be
    flushed yet — bounded retry with small sleep covers the gap."""
    if not path:
        return ""
    try:
        p = Path(path)
        if not p.is_file():
            return ""
    except OSError:
        return ""

    last_text = _read_last_assistant_text(p)

    def _looks_like_handback(t: str) -> bool:
        if _MARKER in t:
            return True
        return sum(1 for f in _HANDBACK_FIELDS if f in t) >= _SIGNATURE_THRESHOLD

    # If we already see hand-back signals, no retry needed — the file is
    # current enough. Otherwise re-read up to 2 times if the file is still
    # growing (suggests we caught it mid-flush).
    if _looks_like_handback(last_text):
        return last_text
    try:
        prev_size = p.stat().st_size
    except OSError:
        return last_text
    for _ in range(2):
        time.sleep(0.08)
        try:
            cur_size = p.stat().st_size
        except OSError:
            break
        if cur_size == prev_size:
            break
        prev_size = cur_size
        last_text = _read_last_assistant_text(p)
        if _looks_like_handback(last_text):
            return last_text
    return last_text


def _file_is_fresh_or_pending(path: Path) -> bool:
    try:
        st = path.stat()
    except FileNotFoundError:
        return False
    except OSError:
        return False
    if st.st_size > 0:
        return True
    return (time.time() - st.st_mtime) <= _FRESH_SECONDS


def _short(uuid: str) -> str:
    bare = (uuid or "").rsplit(":", 1)[-1]
    return bare.split("-", 1)[0][:8] or "?"


def _git_main_sha(cwd: str) -> str | None:
    """Resolve `main` (then `master`) SHA in cwd's repo. None if not a repo
    or git unreachable. Two-second timeout so the hook can't hang on a flaky
    filesystem."""
    if not cwd:
        return None
    try:
        p = Path(cwd)
        if not p.is_dir():
            return None
    except OSError:
        return None
    for ref in ("main", "master"):
        try:
            res = subprocess.run(
                ["git", "-C", str(p), "rev-parse", "--verify", ref],
                capture_output=True,
                text=True,
                timeout=2,
            )
        except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
            return None
        if res.returncode == 0:
            sha = res.stdout.strip()
            if sha:
                return sha
    return None


def _last_seen_path(scope: str) -> Path:
    return _HANDOFF_DIR / f"last-seen-sha.{scope}"


def _read_last_seen(scope: str) -> str | None:
    try:
        text = _last_seen_path(scope).read_text().strip()
        return text or None
    except (FileNotFoundError, OSError):
        return None


def _write_last_seen(scope: str, sha: str) -> None:
    try:
        _last_seen_path(scope).write_text(sha + "\n")
    except OSError:
        pass


def _signature_hits(msg: str) -> int:
    if not msg:
        return 0
    return sum(1 for field in _HANDBACK_FIELDS if field in msg)


_HEREDOC_TEMPLATE = (
    "  cat > ~/.claude/handoff/to-audit.${{HANDOFF_SCOPE}}.txt << 'HANDOFF_EOF'\n"
    "  Step: <e.g. 8ac>\n"
    "  Merged SHA: <short sha on main>\n"
    "  Gate: <P/F counts across ruff/mypy/bandit/pip-audit/pytest>\n"
    "  Suppression: <count of # type: ignore + # noqa + # nosec>\n"
    "  Net-new LOC: <added/removed since prior merge>\n"
    "  Deviations from plan: <bullets or 'none'>\n"
    "  STOP triggers fired: <list or 'none'>\n"
    "  Surface assessment: <1-3 sentences>\n"
    "  Next-axis recommendation: <single concrete next step>\n"
    "  HANDOFF_EOF"
)

_REASON_MARKER = (
    "Stop blocked by enforce-handback: your last message contains "
    "'→ handed back' but ~/.claude/handoff/to-audit.${{HANDOFF_SCOPE}}.txt "
    "(scope={scope}) was not written this turn. The AUDIT watcher fires on "
    "file events, not chat output — chat-only hand-backs leave AUDIT idle.\n\n"
    "Fix: run the MANDATORY heredoc from start-impl.md as your final tool "
    "call, then re-emit '→ handed back':\n\n" + _HEREDOC_TEMPLATE + "\n\n"
    "If no merge actually happened this turn, do NOT write the file — "
    "instead remove '→ handed back' from your message and end the turn "
    "normally (partial work stays in chat per start-impl.md rules)."
)

_REASON_COMMIT = (
    "Stop blocked by enforce-handback: `main` advanced from {old} -> {new} "
    "during this turn but ~/.claude/handoff/to-audit.${{HANDOFF_SCOPE}}.txt "
    "(scope={scope}) was not written. Per start-impl.md, every successful "
    "merge to main MUST be reported via the hand-back heredoc — omitting "
    "the '→ handed back' marker is not a valid bypass.\n\n"
    "Fix: run the heredoc now and emit '→ handed back':\n\n"
    + _HEREDOC_TEMPLATE
    + "\n\nIf the commit was a non-seal change (docs-only, WIP, etc.) and "
    "should NOT trigger an AUDIT hand-back, reset the baseline manually "
    "from the shell: `git rev-parse main > "
    "~/.claude/handoff/last-seen-sha.{scope}`. Do this only when you are "
    "certain no AUDIT review is needed."
)

_REASON_SIGNATURE = (
    "Stop blocked by enforce-handback: your last message contains {n} of the "
    "structured hand-back fields ({fields}) but "
    "~/.claude/handoff/to-audit.${{HANDOFF_SCOPE}}.txt (scope={scope}) was "
    "not written. Either your message IS a hand-back (run the heredoc) or "
    "rephrase to remove the hand-back signature.\n\n"
    "Heredoc:\n\n" + _HEREDOC_TEMPLATE
)


def main() -> None:
    try:
        raw = sys.stdin.read()
        if not raw.strip():
            sys.exit(0)
        event = json.loads(raw)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)
    except Exception:
        sys.exit(0)

    try:
        if event.get("stop_hook_active") is True:
            sys.exit(0)

        iterm = os.environ.get("ITERM_SESSION_ID", "")
        scope = _resolve_scope(iterm) if iterm else None
        if scope is None:
            # Not bound as IMPL anywhere — nothing to enforce.
            sys.exit(0)

        try:
            _log(
                f"[enforce-handback] FIRE scope={scope} "
                f"session={_short(iterm)} keys={sorted(event.keys())} "
                f"inline_msg={'last_assistant_message' in event}"
            )
        except Exception:
            pass

        last_msg = event.get("last_assistant_message")
        if not isinstance(last_msg, str) or not last_msg:
            last_msg = _last_assistant_message_from_transcript(
                event.get("transcript_path", "")
            )
        last_msg = last_msg or ""

        cwd = event.get("cwd", "")
        current_main = _git_main_sha(cwd)
        last_seen = _read_last_seen(scope)

        # Three independent triggers — any one fires the file check.
        trigger_marker = _MARKER in last_msg
        trigger_commit = (
            current_main is not None
            and last_seen is not None
            and current_main != last_seen
        )
        sig_hits = _signature_hits(last_msg)
        trigger_signature = sig_hits >= _SIGNATURE_THRESHOLD

        if not (trigger_marker or trigger_commit or trigger_signature):
            if current_main:
                _write_last_seen(scope, current_main)
            sys.exit(0)

        target = _HANDOFF_DIR / f"to-audit.{scope}.txt"
        if _file_is_fresh_or_pending(target):
            try:
                size = target.stat().st_size
            except OSError:
                size = -1
            triggers = ",".join(
                t for t, on in (
                    ("marker", trigger_marker),
                    ("commit", trigger_commit),
                    ("signature", trigger_signature),
                ) if on
            )
            _log(
                f"[enforce-handback] OK scope={scope} "
                f"session={_short(iterm)} size={size} triggers={triggers}"
            )
            if current_main:
                _write_last_seen(scope, current_main)
            sys.exit(0)

        if trigger_commit:
            reason = _REASON_COMMIT.format(
                scope=scope,
                old=(last_seen or "?")[:8],
                new=(current_main or "?")[:8],
            )
            why = f"main advanced {(last_seen or '?')[:8]}->{(current_main or '?')[:8]}"
        elif trigger_marker:
            reason = _REASON_MARKER.format(scope=scope)
            why = "marker present, file missing/stale"
        else:
            reason = _REASON_SIGNATURE.format(
                scope=scope,
                n=sig_hits,
                fields=", ".join(
                    f for f in _HANDBACK_FIELDS if f in last_msg
                ),
            )
            why = f"signature hits={sig_hits}, file missing/stale"

        _log(
            f"[enforce-handback] BLOCKED scope={scope} "
            f"session={_short(iterm)} reason={why}"
        )
        sys.stdout.write(json.dumps({"decision": "block", "reason": reason}))
        sys.stdout.flush()
        sys.exit(0)
    except Exception:
        _log(
            "[enforce-handback] ERROR (bowing out, not blocking): "
            + traceback.format_exc().splitlines()[-1]
        )
        sys.exit(0)


if __name__ == "__main__":
    main()
