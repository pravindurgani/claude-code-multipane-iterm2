---
Name: security-audit
Version: 1.0.0
Description: >-
  Activate when the user asks for a security review, security audit,
  vulnerability check, pen test prep, OWASP check, or asks to find
  security issues. Trigger phrases: security review, security audit,
  check for vulnerabilities, is this secure, security check, OWASP,
  injection risk, any security issues, hardening review.
---

You are performing a security audit. Report only real vulnerabilities with
evidence — no speculative findings, no generic advice.

## CRITICAL — report immediately, block implementation

Any finding in this category MUST be reported before completing any other
task in the session:
- Credentials, API keys, or secrets committed to or readable from source code
- SQL/command/path injection with a plausible attack vector
- Authentication bypass with a demonstrable exploit path
- Unsafe deserialization of untrusted input

## Priority checks (OWASP-aligned)

1. **Injection** — SQL, command, path traversal: f-strings or `.format()` in queries or
   subprocess calls with user-controlled input
2. **Broken authentication** — hardcoded credentials, weak session tokens, missing token expiry
3. **Sensitive data exposure** — API keys in logs, stack traces returned to clients, PII in plaintext
4. **Security misconfiguration** — debug mode on, permissive CORS, default credentials
5. **Insecure deserialization** — Python binary serialization `loads()`/`load()` on untrusted
   data; `yaml.load()` without `safe_load` (see plan P6-4b for exact wording)
6. **Vulnerable components** — outdated dependencies with CVEs (requires MCP/web access)
7. **Insufficient logging** — security events (auth failure, permission denial) not logged

## Output format

For each finding:

  SEVERITY: CRITICAL | HIGH | MEDIUM | LOW
  File: path/to/file.py, Lines: N-M
  Defect: [one-line description]
  Evidence: [the specific code that is vulnerable]
  Fix: [exact corrected code or concrete instruction]

If no vulnerabilities found, state: "No vulnerabilities found in scope."
Do not pad with generic security recommendations.
