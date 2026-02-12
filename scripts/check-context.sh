#!/bin/bash

# Stop hook: suggests /half-clone when context usage exceeds 75%.
# When triggered, it blocks Claude from stopping and tells it to run /half-clone,
# which creates a new conversation with only the later half to continue in.
#
# Lowered from 85% → 75%: at 80%+ the model can enter unrecoverable
# extended-thinking loops, especially after plan rejections or ambiguous states.
# Catching it earlier (75%) gives enough headroom to actually run /half-clone.

# Skip for Pipeline team members (their sessions are short-lived)
if [ "$CLAUDE_AGENT_TEAM_MEMBER" = "1" ]; then
  exit 0
fi

input=$(cat)

# Prevent infinite loops - exit if already triggered by a stop hook
stop_hook_active=$(echo "$input" | jq -r '.stop_hook_active // false')
if [[ "$stop_hook_active" == "true" ]]; then
    exit 0
fi

# --- Retry guard: max 2 blocks per transcript file ---
# Uses transcript path as the unique key (survives resume, PID changes)
# After blocking twice, allow stop to prevent infinite loops
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
if [[ -z "$transcript_path" || ! -f "$transcript_path" ]]; then
    exit 0
fi

BLOCK_KEY=$(echo "$transcript_path" | md5 2>/dev/null || echo "$transcript_path" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "fallback")
BLOCK_COUNTER="/tmp/claude-stop-block-${BLOCK_KEY}"
if [ -f "$BLOCK_COUNTER" ]; then
    prev_count=$(cat "$BLOCK_COUNTER" 2>/dev/null || echo "0")
    if [ "$prev_count" -ge 2 ]; then
        rm -f "$BLOCK_COUNTER"
        echo >&2 "[Hook] check-context: retry guard exhausted (blocked ${prev_count}x). Allowing stop."
        exit 0
    fi
fi

# Read context window size from input, fallback to 200000
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

if [[ $pct -ge 75 ]]; then
    # Increment block counter
    prev_count=0
    [ -f "$BLOCK_COUNTER" ] && prev_count=$(cat "$BLOCK_COUNTER" 2>/dev/null || echo "0")
    echo $((prev_count + 1)) > "$BLOCK_COUNTER"

    echo "{\"decision\": \"block\", \"reason\": \"Context usage is at ${pct}%. Please run /half-clone to create a new conversation with only the later half so a new agent can continue there.\"}"
fi
