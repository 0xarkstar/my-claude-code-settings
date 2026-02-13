#!/bin/bash
# PreToolUse hook: blocks ExitPlanMode and TeamCreate when context > 55%.
#
# Why: At 55%+ context, starting a new implementation phase (which spawns
# agents, generates code, runs tests) will push context past 60-70% where
# the model can enter unrecoverable extended-thinking loops (-ing bug).
#
# Lowered from 65% → 55%: all -ing incidents occurred at 60-64% context.
# Catching at 55% gives enough headroom for the pipeline to finish.
#
# The model should /half-clone BEFORE starting heavy new work.

# Skip for team members (they have short-lived sessions)
if [ "$CLAUDE_AGENT_TEAM_MEMBER" = "1" ]; then
  exit 0
fi

input=$(cat)

# Read transcript path from input
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
if [[ -z "$transcript_path" || ! -f "$transcript_path" ]]; then
    exit 0
fi

# Read context window size
max_context=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
[[ -z "$max_context" || "$max_context" == "null" ]] && max_context=200000

# Calculate context usage from transcript
context_length=$(jq -s '
    map(select(.message.usage and .isSidechain != true and .isApiErrorMessage != true)) |
    last |
    if . then
        (.message.usage.input_tokens // 0) +
        (.message.usage.cache_read_input_tokens // 0) +
        (.message.usage.cache_creation_input_tokens // 0)
    else 0 end
' < "$transcript_path")

if [[ -z "$context_length" || "$context_length" -eq 0 ]]; then
    exit 0
fi

pct=$((context_length * 100 / max_context))

tool_name=$(echo "$input" | jq -r '.tool_name // "unknown"')

if [[ $pct -ge 55 ]]; then
    echo >&2 "[Hook] CONTEXT WARNING: ${pct}% used. ${tool_name} will push context higher."
    echo >&2 "[Hook] Run /half-clone BEFORE starting new heavy work (plan execution, team spawn)."
    echo "{\"decision\": \"block\", \"reason\": \"Context is at ${pct}% — too high to start ${tool_name}. Run /half-clone first to create a fresh session with recent context, then retry.\"}"
fi
