#!/usr/bin/env python3
"""Sol-gate for ~/.claude/rules/orchestration.md — Codex Sol is the DEFAULT executor.

Wired via ~/.claude/settings.json hooks:
  PreToolUse (matcher Task|Agent) -> `sol-gate.py`

Hard-blocks dispatches of the Claude implementation lane
(executor/debugger/test-engineer) unless the prompt carries an explicit
`SOL-FALLBACK: <reason>` marker. Valid reasons: Codex/OMX verified
unavailable, or the user explicitly directed a Claude-side pass.
Exit 2 = block (stderr goes back to the model). Fails open on parse errors.
"""
import json
import sys

GATED = {
    "oh-my-claudecode:executor",
    "oh-my-claudecode:debugger",
    "oh-my-claudecode:test-engineer",
}
MARKER = "SOL-FALLBACK:"


def main() -> None:
    try:
        payload = json.load(sys.stdin)
        tool_input = payload.get("tool_input") or {}
        subagent = (tool_input.get("subagent_type") or "").strip()
        prompt = tool_input.get("prompt") or ""
    except Exception:
        return  # fail open — never break a session on hook malfunction

    if subagent not in GATED:
        return
    if MARKER in prompt:
        return

    sys.stderr.write(
        "[sol-gate] BLOCKED: '%s' is an implementation-lane dispatch, and "
        "rules/orchestration.md makes Codex Sol the DEFAULT executor for "
        "implementation/tests/debugging.\n"
        "Route via OMX instead:\n"
        "  omx --worktree=sol/<task> [--xhigh]   (ultra: omx exec -w sol/<task> -p ultra)\n"
        "The Claude lane is the fallback ONLY when Codex/OMX is unavailable or "
        "the user explicitly directed a Claude-side pass. If that genuinely "
        "applies, re-dispatch with 'SOL-FALLBACK: <one-line reason>' in the "
        "prompt — the marker is the audit trail.\n" % subagent
    )
    sys.exit(2)


main()
