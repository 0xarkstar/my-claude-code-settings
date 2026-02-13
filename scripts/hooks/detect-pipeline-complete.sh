#!/bin/bash
# Stop hook: detects "Pipeline Complete" in model output and warns user.
# Sets a flag file that PreToolUse hooks check to block further heavy work.
#
# Why: After Pipeline Complete, the session has 60%+ context. If the user
# asks for anything (commit, new feature), the model enters -ing freeze
# (extended thinking loop). This warning tells the user to /half-clone first.

# Skip for team members
if [ "$CLAUDE_AGENT_TEAM_MEMBER" = "1" ]; then
  exit 0
fi

input=$(cat)

transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
if [[ -z "$transcript_path" || ! -f "$transcript_path" ]]; then
    exit 0
fi

# Check last 30 lines of transcript for "Pipeline Complete" in assistant output
# (Checking only tail is much faster than parsing the entire 1MB+ file)
has_pipeline_complete=$(tail -30 "$transcript_path" | jq -s '
    [.[] | select(.type == "assistant" and .message.content)] |
    last |
    if . then
        [.message.content[] | select(.type == "text") | .text] |
        join(" ") |
        test("Pipeline Complete"; "i")
    else false end
' 2>/dev/null)

if [[ "$has_pipeline_complete" == "true" ]]; then
    HASH=$(echo "$transcript_path" | md5 2>/dev/null || echo "$transcript_path" | md5sum 2>/dev/null | cut -d' ' -f1)
    FLAG="/tmp/pipeline-complete-${HASH}.flag"

    if [[ ! -f "$FLAG" ]]; then
        echo "1" > "$FLAG"
        echo >&2 ""
        echo >&2 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo >&2 "  PIPELINE COMPLETE DETECTED"
        echo >&2 "  Run /half-clone BEFORE your next message."
        echo >&2 "  Continuing in this session risks -ing freeze."
        echo >&2 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo >&2 ""
    fi
fi
