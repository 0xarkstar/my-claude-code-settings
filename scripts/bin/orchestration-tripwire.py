#!/usr/bin/env python3
"""Tripwire for ~/.claude/rules/orchestration.md agent-first policy.

Wired via ~/.claude/settings.json hooks:
  UserPromptSubmit                            -> `orchestration-tripwire.py reset`
  PostToolUse (matcher Bash)                  -> `orchestration-tripwire.py count`
  PostToolUse (matcher Edit|Write|MultiEdit)  -> `orchestration-tripwire.py count-edit`

Counts substantive inline calls per session-turn in one shared counter; at 5
(then every 10) injects a reminder into model context via
hookSpecificOutput.additionalContext. count-edit skips the allowed
inline-edit paths (config/memory maintenance per orchestration.md).
"""
import json
import os
import sys
import time

STATE_DIR = os.path.expanduser("~/.cache/claude-tripwire")
HOME = os.path.expanduser("~")

ALLOWED_EDIT_PREFIXES = tuple(
    os.path.join(HOME, p) + os.sep
    for p in (".claude", ".config/claude-omc", ".codex", ".local/bin",
              "Obsidian/Dev/claude-memory")
)
ALLOWED_EDIT_SEGMENTS = (
    os.sep + ".omc" + os.sep,
    os.sep + ".claude" + os.sep,
    os.sep + "memory" + os.sep,
    "scratchpad",
)
ALLOWED_EDIT_BASENAMES = ("CLAUDE.md", "AGENTS.md", "MEMORY.md")


def is_allowed_edit(path: str) -> bool:
    if not path:
        return True  # nothing to judge — don't count
    ap = os.path.abspath(os.path.expanduser(path))
    if ap.startswith(ALLOWED_EDIT_PREFIXES):
        return True
    if any(seg in ap for seg in ALLOWED_EDIT_SEGMENTS):
        return True
    return os.path.basename(ap) in ALLOWED_EDIT_BASENAMES


def cleanup_stale(now: float) -> None:
    for name in os.listdir(STATE_DIR):
        p = os.path.join(STATE_DIR, name)
        try:
            if now - os.path.getmtime(p) > 7 * 86400:
                os.remove(p)
        except OSError:
            pass


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else "count"
    try:
        payload = json.load(sys.stdin)
    except Exception:
        payload = {}
    sid = payload.get("session_id") or "nosession"
    os.makedirs(STATE_DIR, exist_ok=True)
    path = os.path.join(STATE_DIR, sid)

    if mode == "reset":
        with open(path, "w") as f:
            f.write("0")
        cleanup_stale(time.time())
        return

    if mode == "count-edit":
        tool_input = payload.get("tool_input") or {}
        if is_allowed_edit(tool_input.get("file_path") or ""):
            return

    try:
        with open(path) as f:
            n = int(f.read().strip() or 0)
    except (OSError, ValueError):
        n = 0
    n += 1
    with open(path, "w") as f:
        f.write(str(n))

    if n == 5 or (n > 5 and (n - 5) % 10 == 0):
        msg = (
            f"[orchestration tripwire] {n} substantive inline calls this turn "
            "(Bash/Edit/Write) — rules/orchestration.md: restructure into "
            "agent lanes (Codex sol via omx for implementation; subagents "
            "≤opus for analysis) unless each call STRICTLY depends on the "
            "previous result. Subagents executing their assigned task: "
            "ignore this."
        )
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": msg,
            }
        }))


main()
