# Security Guidelines

## Before any commit
- No hardcoded secrets (keys, passwords, tokens) — use env vars; fail loudly if missing.
- Validate untrusted input; parameterize SQL; sanitize HTML (XSS); keep CSRF protection, auth/authz, and rate limits intact.
- Error messages must not leak secrets or internal detail.

## Secret pattern
Never inline secrets. Read from `process.env` / equivalent and throw a clear error when a required var is absent.

## If a security issue is found
1. Before continuing that change, run the native `/security-review` command on the pending diff (or the `security-reviewer` agent for a deeper pass) and fix CRITICAL findings; other work continues.
2. Rotate any exposed secret.
3. Grep the codebase for the same class of bug.

## Standing denies whose cause was not recorded
- `Bash(sudo:*)`, `Bash(ssh localhost:*)` and `Bash(ssh 127.0.0.1:*)` in settings: there is no record of why they were added. Presumed cause (a guess of the 11-18 audit): they keep a session from stepping around the permission checks through a second shell, and `sudo` cannot take a password in a session. The owner kept them on 2026-11-19. They go when a task needs one of them and the owner agrees.
