#!/bin/bash
# verify-phase-output.sh — TaskCompleted hook (v3: absolute paths + glob fix)
# Validates pipeline teammate (p-* names) deliverables on task completion
#
# Exit 0 = approve completion
# Exit 2 = reject completion + feedback
#
# Coexists with existing everything-claude-code hooks

set -uo pipefail

MIN_CHARS=200

INPUT=$(cat 2>/dev/null || echo "{}")
AGENT_NAME=$(echo "$INPUT" | jq -r '.teammate_name // "unknown"' 2>/dev/null || echo "unknown")

# Skip non-pipeline agents (protect existing agents)
if [[ ! "$AGENT_NAME" =~ ^p- ]]; then
    exit 0
fi

# --- Determine DOCS_DIR: absolute path based on git root ---
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -n "$GIT_ROOT" ]; then
    DOCS_DIR="$GIT_ROOT/docs/pipeline"
else
    # Fallback: CWD-based (when running outside git)
    DOCS_DIR="docs/pipeline"
fi

# --- Deliverable file validation ---
check_file() {
    local file="$1"
    local label="$2"
    local min="${3:-$MIN_CHARS}"

    if [ ! -f "$file" ]; then
        echo "[$label] Deliverable not created: $file"
        echo "Write this file before completing the task."
        exit 2
    fi

    local chars
    chars=$(wc -c < "$file" 2>/dev/null || echo "0")
    if [ "$chars" -lt "$min" ]; then
        echo "[$label] $file content insufficient: ${chars} chars (minimum ${min})"
        exit 2
    fi
}

# --- Glob pattern file existence check (empty result prevention) ---
require_glob() {
    local pattern="$1"
    local label="$2"
    local min="${3:-$MIN_CHARS}"
    local found=0

    for f in $pattern; do
        [ -f "$f" ] || continue
        check_file "$f" "$label" "$min"
        found=1
    done

    if [ "$found" -eq 0 ]; then
        echo "[$label] No deliverable files matching: $pattern"
        echo "Write the required file(s) before completing the task."
        exit 2
    fi
}

# --- Per-agent validation (by p- prefix) ---
case "$AGENT_NAME" in
    # P-1 Research
    p-research*)
        require_glob "$DOCS_DIR/RESEARCH_*.md" "Research" 500
        ;;

    # P0 Design
    p-architect*)
        check_file "$DOCS_DIR/DESIGN.md" "Architect" 500
        if ! grep -qi "file ownership\|ownership map" "$DOCS_DIR/DESIGN.md" 2>/dev/null; then
            echo "[p-architect] DESIGN.md is missing the File Ownership Map."
            exit 2
        fi
        ;;
    p-critic*)
        check_file "$DOCS_DIR/DESIGN_CRITIQUE.md" "Critic"
        ;;
    p-strategist*)
        check_file "$DOCS_DIR/TEST_STRATEGY.md" "Strategist"
        ;;

    # P0.5 Review
    p-sec-reviewer*)
        check_file "$DOCS_DIR/REVIEW_SECURITY.md" "Security Review"
        ;;
    p-perf-reviewer*)
        check_file "$DOCS_DIR/REVIEW_PERFORMANCE.md" "Performance Review"
        ;;
    p-cov-reviewer*)
        check_file "$DOCS_DIR/REVIEW_COVERAGE.md" "Coverage Review"
        ;;

    # P1 Implementation
    p-impl*|p-test-writer*)
        # Check PROGRESS.md update
        if [ -f "$DOCS_DIR/PROGRESS.md" ]; then
            last_mod=$(stat -c %Y "$DOCS_DIR/PROGRESS.md" 2>/dev/null || stat -f %m "$DOCS_DIR/PROGRESS.md" 2>/dev/null || echo "0")
            now=$(date +%s)
            diff=$((now - last_mod))
            if [ "$diff" -gt 600 ]; then
                echo "Update docs/pipeline/PROGRESS.md before completing."
                exit 2
            fi
        fi

        # --- File ownership validation (warning only) ---
        # Extracts this agent's owned paths from DESIGN.md File Ownership Map
        # and checks if modified files (via git diff) are within ownership scope
        #
        # Limitation: git diff --name-only HEAD includes all agents' uncommitted changes.
        # Other p-impl agents' changes may cause false positives, so this only warns (not exit 2).
        # Actual blocking is left to the lead's judgment based on the warning message.
        if [ -n "$GIT_ROOT" ] && [ -f "$DOCS_DIR/DESIGN.md" ]; then
            # Extract per-agent paths from "- p-impl-A: src/path1/*, src/path2/*" format
            owned_paths=$(grep -i "^[[:space:]]*-[[:space:]]*${AGENT_NAME}:" "$DOCS_DIR/DESIGN.md" 2>/dev/null | sed 's/^[^:]*://' | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | sed 's/\*$//')
            if [ -n "$owned_paths" ]; then
                violations=""
                while IFS= read -r modified_file; do
                    [ -z "$modified_file" ] && continue
                    is_owned=0
                    while IFS= read -r owned; do
                        [ -z "$owned" ] && continue
                        if [[ "$modified_file" == ${owned}* ]]; then
                            is_owned=1
                            break
                        fi
                    done <<< "$owned_paths"
                    # Files in docs/pipeline/ are always allowed (deliverables)
                    if [[ "$modified_file" == docs/pipeline/* ]]; then
                        is_owned=1
                    fi
                    if [ "$is_owned" -eq 0 ]; then
                        violations="${violations}  - ${modified_file}\n"
                    fi
                done < <(cd "$GIT_ROOT" && git diff --name-only HEAD 2>/dev/null)

                if [ -n "$violations" ]; then
                    # Warning only (may be false positives from other agents' changes)
                    echo "[$AGENT_NAME] WARNING: Changes detected outside ownership scope (may be from other agents):"
                    printf '%b' "$violations"
                fi
            fi
        fi
        ;;

    # P1.5 Integration
    p-integ-tester*)
        check_file "$DOCS_DIR/INTEGRATION_REPORT.md" "Integration"
        ;;
    p-regression*)
        check_file "$DOCS_DIR/REGRESSION_REPORT.md" "Regression"
        ;;

    # P2 Verification
    p-hypo*)
        require_glob "$DOCS_DIR/VERIFY_*.md" "Hypothesis"
        ;;
    p-qa*)
        check_file "$DOCS_DIR/QA_REPORT.md" "QA"
        if ! grep -qiE "\b(PASS|FAIL)\b" "$DOCS_DIR/QA_REPORT.md" 2>/dev/null; then
            echo "[p-qa] QA_REPORT.md is missing a PASS or FAIL verdict."
            exit 2
        fi
        ;;
esac

exit 0
