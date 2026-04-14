---
Name: testing
Version: 1.0.0
Description: >-
  Activate when the user asks to write tests, add tests, check test
  coverage, review existing tests, fix failing tests, or asks about
  testing strategy. Trigger phrases: write tests, add tests, test this,
  check coverage, testing strategy, how to test, fix the tests, tests
  for this function, unit test, integration test.
---

You are writing or reviewing pytest tests for this project. Match existing
test conventions before writing new ones.

## Conventions

**Naming:**
- Test files: `tests/test_<module>.py`
- Test functions: `test_should_<behaviour>` (descriptive, not `test_<method_name>`)
- Examples: `test_should_block_rm_rf`, `test_should_return_none_on_empty_input`

**Structure:**
- Arrange / Act / Assert — one blank line between each phase
- One logical assertion per test (multiple `assert` lines checking the same output is fine)
- No test should depend on another test's side effects — each test is independent

**Fixtures:**
- Prefer function-scoped fixtures (default) — use `scope="session"` only for expensive setup
  with no state mutation
- Use `tmp_path` for any file I/O — never write to the real project directory in tests
- Use `monkeypatch` for environment variables and module-level globals

**What to test:**
- Every security-critical path (hook blocks, permission checks, env protection)
- Every blocked and every allowed pattern for hook/regex logic
- Public function contracts — inputs, outputs, error conditions
- Edge cases explicitly: empty input, None, zero, maximum values

**What NOT to test:**
- Private helpers (`_prefix` functions) directly — test through the public interface
- Framework internals (pytest, pathlib, json stdlib)
- Implementation details that will change — test behaviour, not structure
- Anything that requires a live external service — mock at the boundary

**Hook testing pattern:**
When testing hooks that read subprocess output or call external commands,
mock at the `subprocess.run` boundary, not at a higher level. Use
`monkeypatch.setattr(subprocess, 'run', mock_fn)`.

**Coverage priorities:**
1. Security paths — 100% required
2. Error handling branches — 100% required
3. Happy path — 100% required
4. Edge cases — best effort

## Output format

Provide each test function as a copyable block. Prepend with:
- File path the test belongs in
- Any new fixture needed (if not already in `conftest.py`)
