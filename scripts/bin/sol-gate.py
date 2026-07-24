#!/usr/bin/env python3
"""Sol-gate v2 for ~/.claude/rules/orchestration.md — Codex Sol is the DEFAULT executor.

Wired via ~/.claude/settings.json hooks:
  PreToolUse (matcher Task|Agent) -> `sol-gate.py`

v2 changes (2026-07-24, after self-issued-marker recurrence):
  1. Structured markers with evidence, replacing bare `SOL-FALLBACK: <reason>`:
       SOL-FALLBACK(a): <failing omx/codex command + its error output, quoted>
       SOL-FALLBACK(b): <verbatim user quote in quotation marks>
     Bare/legacy markers are rejected — the evidence IS the audit trail.
  2. Coverage extended: generalist agents (general-purpose / claude / default)
     are also gated when the prompt reads as implementation work. Escape hatch
     for analysis dispatches: include READ-ONLY (or "do not edit") in the prompt.
Exit 2 = block (stderr goes back to the model). Fails open on parse errors.
"""
import json
import re
import sys

GATED = {
    "oh-my-claudecode:executor",
    "oh-my-claudecode:debugger",
    "oh-my-claudecode:test-engineer",
}
HEURISTIC = {"general-purpose", "claude", ""}

IMPL_PAT = re.compile(
    r"(\bimplement\b|make (the )?tests? pass|fix (the |this )?bug|write (the )?code"
    r"|\brefactor\b|apply (the )?(fix|patch)|add (a |the )?(feature|test)"
    r"|구현(해|하)|버그를? 고쳐|고쳐\s*줘|패치(를|해)|리팩터|코드를 (작성|수정)"
    r"|테스트를 (작성|추가))",
    re.IGNORECASE,
)
READONLY_PAT = re.compile(
    r"(read[- ]only|do not (edit|write|modify)|no file (edits|writes)"
    r"|수정 금지|읽기 전용)",
    re.IGNORECASE,
)
MARKER_PAT = re.compile(r"SOL-FALLBACK\((a|b)\):\s*(.+)")


def marker_verdict(prompt: str):
    m = MARKER_PAT.search(prompt)
    if not m:
        if "SOL-FALLBACK" in prompt:
            return False, (
                "legacy bare 'SOL-FALLBACK:' markers are no longer accepted — "
                "use the structured v2 format below."
            )
        return False, "no SOL-FALLBACK marker present."
    kind, body = m.group(1), m.group(2).strip()
    if kind == "a":
        if ("omx" in body or "codex" in body) and len(body) >= 40:
            return True, ""
        return False, (
            "(a) must quote the failing omx/codex command AND its actual error "
            "output from THIS turn (>=40 chars). Run the probe first; paste what it printed."
        )
    quoted = re.search(r"[\"“'‘]([^\"”'’]{10,})[\"”'’]", body)
    if quoted:
        return True, ""
    return False, (
        "(b) must contain the user's directive as a verbatim quote in quotation "
        "marks (>=10 chars). Paraphrase is not evidence."
    )


def main() -> None:
    try:
        payload = json.load(sys.stdin)
        tool_input = payload.get("tool_input") or {}
        subagent = (tool_input.get("subagent_type") or "").strip()
        prompt = tool_input.get("prompt") or ""
    except Exception:
        return  # fail open — never break a session on hook malfunction

    hard_gated = subagent in GATED
    heuristic_gated = (
        subagent in HEURISTIC
        and IMPL_PAT.search(prompt)
        and not READONLY_PAT.search(prompt)
    )
    if not hard_gated and not heuristic_gated:
        return

    ok, why = marker_verdict(prompt)
    if ok:
        return

    lane = subagent or "(default)"
    escape = (
        "" if hard_gated else
        "\nIf this dispatch is actually analysis/research (no file edits), add "
        "READ-ONLY to the prompt instead of a marker.\n"
    )
    sys.stderr.write(
        "[sol-gate v2] BLOCKED: '%s' looks like an implementation-lane dispatch, "
        "and rules/orchestration.md makes Codex Sol the DEFAULT executor for "
        "implementation/tests/debugging.\n"
        "Route via OMX instead:\n"
        "  omx --worktree=sol/<task> [--xhigh]   (ultra: omx exec -w sol/<task> -p ultra)\n"
        "Marker rejected: %s\n"
        "Accepted fallback markers (the evidence IS the audit trail):\n"
        "  SOL-FALLBACK(a): <failing omx/codex command + its error output, this turn>\n"
        "  SOL-FALLBACK(b): <the user's Claude-side directive as a verbatim \"quote\">\n"
        "%s" % (lane, why, escape)
    )
    sys.exit(2)


main()
