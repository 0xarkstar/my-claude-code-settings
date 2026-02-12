#!/bin/bash
# check-idle-reason.sh — TeammateIdle hook (v6: early exits + shutdown awareness)
# Checks pipeline teammates (p-* names) for deliverables when idle
# + Auto-terminates tmux panes of isActive=false teammates
#
# Exit 0 = allow idle
# Exit 2 = reject idle + feedback
#
# Coexists with existing everything-claude-code hooks

set -uo pipefail

TEAMS_DIR="$HOME/.claude/teams"
LOCK_DIR="/tmp/claude-cleanup-panes.lock.d"

INPUT=$(cat 2>/dev/null || echo "{}")
AGENT_NAME=$(echo "$INPUT" | jq -r '.teammate_name // "unknown"' 2>/dev/null || echo "unknown")

# If no team configs exist, this teammate is an orphan — tell it to shut down
if [ ! -d "$TEAMS_DIR" ] || [ -z "$(ls -A "$TEAMS_DIR" 2>/dev/null)" ]; then
    # If agent name starts with p-, it's a pipeline agent that lost its team
    if [[ "$AGENT_NAME" =~ ^p- ]]; then
        echo "Your team config has been deleted. You are an orphan agent. Please exit immediately."
        exit 2
    fi
    exit 0
fi

# Quick exit: if teammate is already inactive (shutting down), allow idle immediately
# This prevents TeammateIdle event storms during shutdown sequences
for config in "$TEAMS_DIR"/*/config.json; do
    [ -f "$config" ] || continue
    is_active=$(jq -r --arg name "$AGENT_NAME" '.members[] | select(.name == $name) | .isActive' "$config" 2>/dev/null || echo "")
    if [ "$is_active" = "false" ]; then
        exit 0
    fi
done

# --- Determine DOCS_DIR: absolute path based on git root ---
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -n "$GIT_ROOT" ]; then
    DOCS_DIR="$GIT_ROOT/docs/pipeline"
else
    DOCS_DIR="docs/pipeline"
fi

# --- Auto-cleanup inactive teammate panes ---
# Terminates tmux panes of isActive=false teammates
# Uses mkdir atomic lock for single-instance guarantee (race condition prevention)
# macOS lacks flock — using mkdir instead (POSIX atomic)
cleanup_inactive_panes() {
    # mkdir: atomic — fails if already exists (another instance running)
    if ! mkdir "$LOCK_DIR" 2>/dev/null; then
        return 0
    fi
    # Release lock on function exit (normal or abnormal)
    trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

    for config in "$TEAMS_DIR"/*/config.json; do
        [ -f "$config" ] || continue
        jq -r '.members[] | select(.isActive == false and .tmuxPaneId != "" and .tmuxPaneId != null and .name != "team-lead") | [.name, .tmuxPaneId] | join("|")' "$config" 2>/dev/null | while IFS='|' read -r name pane_id; do
            [ -z "$pane_id" ] && continue
            if tmux display-message -t "$pane_id" -p '#{pane_id}' 2>/dev/null >/dev/null; then
                tmux send-keys -t "$pane_id" "/exit" Enter 2>/dev/null || true
                sleep 1
                if tmux display-message -t "$pane_id" -p '#{pane_id}' 2>/dev/null >/dev/null; then
                    tmux kill-pane -t "$pane_id" 2>/dev/null || true
                fi
                echo >&2 "[Hook] Auto-cleaned inactive pane: $name ($pane_id)"
            fi
        done
    done

    rmdir "$LOCK_DIR" 2>/dev/null
}

# Run inactive pane cleanup in background (no impact on hook execution time)
# disown: detach from zsh job table — prevents waiting on this process at session end
cleanup_inactive_panes &
disown

# Skip non-pipeline agents
if [[ ! "$AGENT_NAME" =~ ^p- ]]; then
    exit 0
fi

require_file() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo "$file has not been created yet. Complete your work and mark the task as done."
        exit 2
    fi
}

case "$AGENT_NAME" in
    p-architect*)    require_file "$DOCS_DIR/DESIGN.md" ;;
    p-critic*)       require_file "$DOCS_DIR/DESIGN_CRITIQUE.md" ;;
    p-strategist*)   require_file "$DOCS_DIR/TEST_STRATEGY.md" ;;
    p-sec-reviewer*) require_file "$DOCS_DIR/REVIEW_SECURITY.md" ;;
    p-perf-reviewer*) require_file "$DOCS_DIR/REVIEW_PERFORMANCE.md" ;;
    p-cov-reviewer*) require_file "$DOCS_DIR/REVIEW_COVERAGE.md" ;;
    p-qa*)           require_file "$DOCS_DIR/QA_REPORT.md" ;;
    p-integ-tester*) require_file "$DOCS_DIR/INTEGRATION_REPORT.md" ;;
    p-regression*)   require_file "$DOCS_DIR/REGRESSION_REPORT.md" ;;
    p-impl*|p-test-writer*)
        if [ -f "$DOCS_DIR/PROGRESS.md" ]; then
            last_mod=$(stat -c %Y "$DOCS_DIR/PROGRESS.md" 2>/dev/null || stat -f %m "$DOCS_DIR/PROGRESS.md" 2>/dev/null || echo "0")
            now=$(date +%s)
            diff=$((now - last_mod))
            if [ "$diff" -gt 300 ]; then
                echo "Update docs/pipeline/PROGRESS.md and mark your task as completed."
                exit 2
            fi
        fi
        ;;
esac

exit 0
