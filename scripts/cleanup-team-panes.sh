#!/bin/bash
# cleanup-team-panes.sh — Kill tmux panes for completed/inactive teammates
#
# SCOPE: For /omc-teams (tmux workers) only. Not for /team (native teams).
# Native teams use child_process.fork and are cleaned up by TeamDelete.
#
# Usage:
#   cleanup-team-panes.sh [team-name]    # specific team (works even if config deleted)
#   cleanup-team-panes.sh --all          # all teams
#   cleanup-team-panes.sh --orphans      # find & kill agents whose team config is gone
#   cleanup-team-panes.sh                # interactive: list teams + orphan check
#
# Safe: only kills panes belonging to teammates (p-* or known agent names),
# never touches the team lead pane or non-team panes.

set -euo pipefail

TEAMS_DIR="$HOME/.claude/teams"

# --- Kill orphan agent processes whose team config no longer exists ---
# Scans all running claude processes with --team-name, checks if config exists.
# If not, finds their tmux pane via PID and kills it.
cleanup_orphans() {
    local team_filter="${1:-}"  # optional: only clean orphans for this team name
    local count=0

    echo "[cleanup] Scanning for orphan agent processes..."

    # Find all claude processes with --team-name
    while IFS= read -r line; do
        local pid agent_name team_name
        pid=$(echo "$line" | awk '{print $2}')
        agent_name=$(echo "$line" | grep -oP '(?<=--agent-name )\S+' || echo "")
        team_name=$(echo "$line" | grep -oP '(?<=--team-name )\S+' || echo "")

        [ -z "$team_name" ] && continue
        [ -z "$agent_name" ] && continue

        # If filtering by team, skip non-matching
        if [ -n "$team_filter" ] && [ "$team_name" != "$team_filter" ]; then
            continue
        fi

        # Check if team config still exists
        if [ -f "$TEAMS_DIR/$team_name/config.json" ]; then
            continue  # config exists — not an orphan
        fi

        echo "  [orphan] $agent_name (team=$team_name, pid=$pid) — no config found"

        # Find tmux pane by matching PID to pane_pid
        local pane_id=""
        pane_id=$(tmux list-panes -a -F "#{pane_id} #{pane_pid}" 2>/dev/null | while read -r p_id p_pid; do
            # Check if the agent PID is a child of this pane's process
            if pgrep -P "$p_pid" 2>/dev/null | grep -q "^${pid}$"; then
                echo "$p_id"
                break
            fi
            # Also check if the pane PID IS the agent (direct match)
            if [ "$p_pid" = "$pid" ]; then
                echo "$p_id"
                break
            fi
        done)

        if [ -n "$pane_id" ]; then
            echo "  [exit] $agent_name ($pane_id) — sending /exit..."
            tmux send-keys -t "$pane_id" "/exit" Enter 2>/dev/null || true
            sleep 1
            if tmux display-message -t "$pane_id" -p '#{pane_id}' 2>/dev/null >/dev/null; then
                echo "  [kill] $agent_name ($pane_id) — force killing pane"
                tmux kill-pane -t "$pane_id" 2>/dev/null || true
            fi
        else
            echo "  [kill] $agent_name (pid=$pid) — no pane found, sending SIGTERM"
            kill "$pid" 2>/dev/null || true
        fi

        count=$((count + 1))
    done < <(ps aux | grep '[c]laude.*--team-name' | grep -v 'grep')

    if [ "$count" -eq 0 ]; then
        echo "[cleanup] No orphan agents found"
    else
        echo "[cleanup] Cleaned $count orphan agent(s)"
    fi
}

cleanup_team() {
    local team_name="$1"
    local config="$TEAMS_DIR/$team_name/config.json"

    if [ ! -f "$config" ]; then
        echo "[cleanup] Team config not found: $config"
        echo "[cleanup] Falling back to orphan detection for team '$team_name'..."
        cleanup_orphans "$team_name"
        return 0
    fi

    echo "[cleanup] Team: $team_name"

    local count=0
    local skipped=0

    # Get all non-lead members with tmux pane IDs
    while IFS='|' read -r name pane_id is_active; do
        # Skip empty pane IDs
        if [ -z "$pane_id" ] || [ "$pane_id" = "null" ] || [ "$pane_id" = "" ]; then
            continue
        fi

        # Skip team lead
        if [ "$name" = "team-lead" ]; then
            continue
        fi

        # Check if pane actually exists (display-message works with pane IDs like %179)
        if ! tmux display-message -t "$pane_id" -p '#{pane_id}' 2>/dev/null >/dev/null; then
            echo "  [skip] $name ($pane_id) — pane already gone"
            skipped=$((skipped + 1))
            continue
        fi

        # Try graceful exit first: send /exit to Claude Code
        echo "  [exit] $name ($pane_id, active=$is_active) — sending /exit..."
        tmux send-keys -t "$pane_id" "/exit" Enter 2>/dev/null || true
        sleep 1

        # Check if pane is still alive
        if tmux display-message -t "$pane_id" -p '#{pane_id}' 2>/dev/null >/dev/null; then
            # Still alive — force kill the pane
            echo "  [kill] $name ($pane_id) — force killing pane"
            tmux kill-pane -t "$pane_id" 2>/dev/null || true
        fi

        count=$((count + 1))
    done < <(jq -r '.members[] | select(.name != "team-lead") | [.name, .tmuxPaneId, .isActive] | join("|")' "$config" 2>/dev/null)

    echo "[cleanup] Done: $count pane(s) cleaned, $skipped already gone"
}

# --- Main ---
if [ "${1:-}" = "--all" ]; then
    if [ ! -d "$TEAMS_DIR" ] || [ -z "$(ls -A "$TEAMS_DIR" 2>/dev/null)" ]; then
        echo "[cleanup] No active teams found — checking for orphans..."
    else
        for team_dir in "$TEAMS_DIR"/*/; do
            [ -d "$team_dir" ] || continue
            team_name=$(basename "$team_dir")
            [ "$team_name" = "default" ] && continue
            cleanup_team "$team_name" || true
        done
    fi
    # Always check for orphans (agents whose team config was deleted)
    cleanup_orphans
elif [ "${1:-}" = "--orphans" ]; then
    cleanup_orphans
elif [ -n "${1:-}" ]; then
    cleanup_team "$1"
else
    echo "Available teams:"
    if [ -d "$TEAMS_DIR" ]; then
        for team_dir in "$TEAMS_DIR"/*/; do
            [ -d "$team_dir" ] || continue
            team_name=$(basename "$team_dir")
            [ "$team_name" = "default" ] && continue
            member_count=$(jq -r '.members | length' "$team_dir/config.json" 2>/dev/null || echo "?")
            echo "  - $team_name ($member_count members)"
        done
    else
        echo "  (none)"
    fi
    echo ""
    # Quick orphan check
    orphan_count=$(ps aux | grep '[c]laude.*--team-name' | grep -v 'grep' | wc -l | tr -d ' ')
    if [ "$orphan_count" -gt 0 ]; then
        echo "WARNING: $orphan_count agent process(es) running — some may be orphans"
        echo "  Run: cleanup-team-panes.sh --orphans"
    fi
    echo ""
    echo "Usage: cleanup-team-panes.sh [team-name|--all|--orphans]"
fi
