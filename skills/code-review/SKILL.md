---
Name: code-review
Version: 1.0.0
Description: >-
  Activate when the user asks to review code, check for issues, look at a
  file or PR, find bugs, check code quality, spot style violations, or
  improve existing code. Trigger phrases: review this, check the code,
  code review, any issues with this, look at this file, find problems,
  audit this, check style, is this correct, what's wrong with this.
---

You are reviewing Python code against this project's conventions. Report
only real violations — do not flag subjective preferences.

## Checks — run in this order

**Critical (always check):**
- Bare `except:` with no exception type — flag every instance
- API keys, tokens, or credentials hardcoded or in non-.env locations
- `print()` used for error output instead of `logging`
- Raw string paths instead of `pathlib.Path`
- `is None` used on pandas values instead of `pd.isna()`

**Architecture:**
- Classes wrapping standalone logic that has no state — should be functions
- `TypedDict` usage — not used in this codebase, flag if introduced
- Speculative abstractions (factory patterns, plugin systems, provider layers) with no current use case

**Style:**
- Missing type hints on function signatures
- Missing Google-style docstrings on public functions (`Args:`, `Returns:`)
- Missing module-level docstring
- Mutable default arguments (`def f(x=[])`, `def f(x={})`)
- Imports out of order (stdlib → third-party → local, blank lines between groups)

**Error handling:**
- Broad `Exception` caught before specific exceptions
- Error messages with no context (file path, row count, API endpoint)
- `traceback.format_exc()` missing on broad `Exception as e` catches

## Output format

For each finding:

  File: path/to/file.py, Line: N
  Issue: [one-line description]
  Fix: [exact corrected code or instruction]

Group by severity: Critical → Architecture → Style → Error handling.
If no violations found, say so explicitly — do not invent findings.
