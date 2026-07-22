# Security Guidelines

## Before any commit
- No hardcoded secrets (keys, passwords, tokens) — use env vars; fail loudly if missing.
- Validate untrusted input; parameterize SQL; sanitize HTML (XSS); keep CSRF protection, auth/authz, and rate limits intact.
- Error messages must not leak secrets or internal detail.

## Secret pattern
Never inline secrets. Read from `process.env` / equivalent and throw a clear error when a required var is absent.

## If a security issue is found
1. Stop. Run the native `/security-review` command on the pending diff, or the `security-reviewer` agent for a deeper pass.
2. Fix CRITICAL issues before continuing; rotate any exposed secret.
3. Grep the codebase for the same class of bug.
