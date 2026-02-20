#!/bin/bash
# PreToolUse hook: ensures Co-Authored-By trailer in git commit commands.
#
# The Co-Authored-By trailer is a system prompt instruction, but the model
# often forgets it at high context (post-pipeline). This hook catches it.

input=$(cat)

command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Only check commands that contain "git commit"
if ! echo "$command" | grep -q 'git commit'; then
    exit 0
fi

# Skip if the command doesn't use -m or --message (e.g., git commit-tree)
# Matches: git commit -m, git commit -am, git commit -a -m, git commit --no-verify -m
if ! echo "$command" | grep -qE '\s-[a-zA-Z]*m\s|--message'; then
    exit 0
fi

# Check if Co-Authored-By is already present
if echo "$command" | grep -qi 'Co-Authored-By'; then
    exit 0
fi

echo >&2 "[Hook] git commit missing Co-Authored-By trailer."
echo >&2 "[Hook] Append to commit message: Co-Authored-By: Claude <noreply@anthropic.com>"
echo >&2 "Commit message must include Co-Authored-By trailer. Append this to your commit message (after a blank line): Co-Authored-By: Claude <noreply@anthropic.com>"
exit 2
