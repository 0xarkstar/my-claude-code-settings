# Git Workflow

## Prod deploy
- Deploy to prod hosts via `git push` + prod-side `git pull` to a known SHA — never rsync/scp working trees onto prod. Reason: the code on a host is then always a known commit and can be rolled back to one. (The rule had no recorded source; the reason was added in the audit and the owner kept the rule on 2026-11-19.)

## Commit messages
Format: `<type>: <description>` + optional body. Types: feat, fix, refactor, docs, test, chore, perf, ci.
Commit on a non-default branch once the gates pass; merging into a default branch and pushing wait for the owner. If on the default branch, branch first.

## Pull requests
- Base the summary on the full branch history: `git diff <base>...HEAD`, not just the latest commit.
- Include a short test plan. Push a new branch with `-u`.

## Review
- After writing code, get a separate review pass before merge — native `/code-review` for the working diff, or the `code-reviewer` agent. Address CRITICAL/HIGH first.

(Planning and TDD depth are governed by engineering.md — apply them by code tier, not universally.)
