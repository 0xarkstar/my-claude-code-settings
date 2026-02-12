<!-- AGENT TEAMS: ADAPTIVE MULTI-PHASE PIPELINE -->

## Agent Team Lead Rules (Pipeline Mode)

> When Agent Teams is active and I am the lead, follow all rules below.
> Independent from existing agents/, rules/, skills/ settings.

### Absolute Constraints

- Max **3 simultaneous active teammates** (tmux race condition prevention)
- Lead **never modifies code directly** — delegate mode (Shift+Tab)
- Lead does not substitute for failed teammates — **spawn replacement**
- Default: `write` (1:1); `broadcast` only for direction changes

### Lead Model Strategy

- Lead uses **OpusPlan** (`/model opusplan`) — Opus plans, Sonnet executes tools
- Lead cost reduction: **60-70%** (no quality degradation since lead never touches code)
- Team members use phase-recommended models (see Phase Agent Composition)

### Agent Naming Rules

Pipeline teammates use `p-` prefix. Never spawn standalone agents as pipeline members.

| Standalone (don't use) | Pipeline (use) |
|------------------------|----------------|
| architect | **p-architect** |
| security-reviewer | **p-sec-reviewer** |
| code-reviewer | **p-perf-reviewer**, **p-cov-reviewer** |
| planner | **p-strategist** |

### Phase Transition Protocol

**CRITICAL: Steps 3-5 MUST execute in exact order. Never call TeamDelete before shutdown is confirmed.**

1. `TaskList` — verify all teammates completed
2. Verify output files in `docs/pipeline/`
2.5. Each completing teammate writes a HANDOFF section at the end of their
     output file: what was attempted, what worked, what didn't, and
     remaining work. Format:

     ## Handoff
     - **Attempted**: [list of approaches tried]
     - **Worked**: [what succeeded]
     - **Failed**: [what didn't work and why]
     - **Remaining**: [unfinished items for next phase]
3. `shutdown_request` each teammate → **WAIT for approval response** (do NOT proceed until all confirm)
   - If a teammate doesn't respond within 30s, send `/exit` via tmux pane as fallback
4. `bash ~/.claude/scripts/cleanup-team-panes.sh [team-name]` (kills remaining tmux panes)
5. `cleanup` (TeamDelete) — **only after ALL teammates confirmed or panes killed**
6. `bash ~/.claude/scripts/cleanup-team-panes.sh --orphans` (safety net: catch any leaked agents)
7. `TaskCreate` next phase (`blockedBy` completed IDs)
8. Spawn new teammates (include previous phase output paths)
9. Record in `docs/pipeline/PROGRESS.md`

### Adaptive Phase Selection

**Always active**: P0 (Design) → P1 (Implementation) → P2 (Verification)

| Phase | Condition |
|-------|-----------|
| P-1 Research | New library, unfamiliar tech, migration |
| P0.5 Review | Modifying existing code (not greenfield) |
| P1.5 Integration | 3+ modules changed simultaneously |
| P3 Refactoring | QA_REPORT.md contains FAIL |
| P4 Documentation | Public API surface changed |

### Cost Efficiency Strategy

| Phase | Model | Rel.Cost | Skip? |
|-------|:-----:|:--------:|:-----:|
| P-1 Research | haiku | 5 | Yes |
| P0 Design ★ | opus | 80 | No |
| P0.5 Review | haiku | 5 | Yes |
| P1 Impl ★ | sonnet | 100 | No |
| P1.5 Integration | sonnet | 40 | Yes |
| P2 Verification ★ | sonnet | 60 | No |
| P3 Refactoring | sonnet | 40 | Yes |
| P4 Docs | haiku | 5 | Yes |

Skip optional phases aggressively. Mini (P0→P1→P2) ~240 vs Full ~335. Minimize team size.

### Phase Agent Composition

> `p-` prefix required. Outputs to `docs/pipeline/`. DESIGN.md must include File Ownership Map (agent→directory mapping).

**[P-1] Research (haiku)**: `p-research-best/docs/code` → RESEARCH_*.md (≥500 chars each)
**[P0] Design ★ (opus)**: `p-architect` (plan_mode_required) → DESIGN.md; `p-critic` → DESIGN_CRITIQUE.md; `p-strategist` → TEST_STRATEGY.md
**[P0.5] Review (haiku)**: `p-sec/perf/cov-reviewer` → REVIEW_*.md (read-only phase)
**[P1] Impl ★ (sonnet)**: `p-impl-A/B`, `p-test-writer` — File Ownership Map enforced
**[P1.5] Integration (sonnet)**: `p-integ-tester/fixer`, `p-regression` → INTEGRATION/REGRESSION_REPORT.md
**[P2] Verification ★ (sonnet)**: `p-hypo-A/B` → VERIFY_*.md; `p-qa` → QA_REPORT.md (PASS/FAIL); adversarial debate via `write`
**[P3] Refactoring (sonnet)**: `p-cleaner`, `p-optimizer`, `p-final-review`
**[P4] Docs (haiku)**: `p-api-doc`, `p-changelog`, `p-readme`

### Spawn Prompt Required Items

1. **Read**: previous phase output paths
2. **Write scope**: owned directories only
3. **Focus**: specific task
4. **Done-when**: completion criteria
5. **Output**: "Write to docs/pipeline/[FILE].md and send summary to team-lead"
6. **Boundary**: "Do NOT modify files outside [owned path]"
7. **Model**: use phase-recommended model
8. **Handoff awareness**: "Check the Handoff section at the end of input documents for context from the previous phase"

### Failure Recovery

| Situation | Protocol |
|-----------|----------|
| Teammate crash | PROGRESS.md → spawn replacement ("continue from [state]") |
| Task overdue | Reminder at 2x → 3 reminders → shutdown + replace |
| File conflict | git diff → non-owner reverts → respawn if needed |
| Session crash | Read PROGRESS.md → resume from last completed phase |
| tmux residue | `bash ~/.claude/scripts/cleanup-team-panes.sh [team]` |
| Orphan agents | `bash ~/.claude/scripts/cleanup-team-panes.sh --orphans` |
| Config deleted before shutdown | `cleanup-team-panes.sh` auto-falls back to orphan detection |

### Git Worktree Strategy (Optional)

For tasks involving multiple branches or high file-conflict risk,
the lead can create git worktrees for implementation agents:

1. Before P1, create worktrees:
   `git worktree add ../project-impl-A feature/impl-A`
   `git worktree add ../project-impl-B feature/impl-B`

2. Spawn p-impl-A with cwd set to ../project-impl-A
   Spawn p-impl-B with cwd set to ../project-impl-B

3. After P1, merge worktrees:
   `git merge feature/impl-A`
   `git merge feature/impl-B`

4. Clean up:
   `git worktree remove ../project-impl-A`
   `git worktree remove ../project-impl-B`

Benefits: Zero file ownership violations possible.
Tradeoff: Merge conflicts must be resolved in P1.5 Integration.

### File Handoff

```
docs/pipeline/
├── PLAN.md, PROGRESS.md       ← Lead managed
├── DESIGN*.md, TEST_STRATEGY  ← P0 → P1
├── RESEARCH_*.md              ← P-1 → P0
├── REVIEW_*.md                ← P0.5 → P1
├── INTEGRATION/REGRESSION_*   ← P1.5 → P2
├── VERIFY_*.md                ← P2 → P3 decision
└── QA_REPORT.md               ← P2 → end or P3
```

### Pipeline Termination Protocol

After the **final phase** completes (P2 PASS, or P3/P4 if triggered):

1. Execute Phase Transition Protocol steps 1-6 (TaskList → TeamDelete → orphan check) for the last phase
2. Write final summary to `docs/pipeline/PROGRESS.md` with `## Pipeline Complete` header
3. **STOP making tool calls.** Output the final results as plain text to the user
4. Do NOT spawn new teammates, create new tasks, or start new phases
5. Do NOT attempt to manage or communicate with teammates after TeamDelete

**Shutdown sequence is BLOCKING:** Do not proceed to TeamDelete until all teammates have either:
- Confirmed shutdown (shutdown_response with approve=true), OR
- Been force-killed via tmux pane cleanup

**Resume after session crash:**
- Read `docs/pipeline/PROGRESS.md`
- If it contains `## Pipeline Complete` → report results, do NOT restart pipeline
- If it does NOT contain `## Pipeline Complete` → resume from last completed phase
- If team config no longer exists → do NOT attempt SendMessage to old teammates
- **Always run** `bash ~/.claude/scripts/cleanup-team-panes.sh --orphans` on resume

**Critical:** Once all phases are done, the lead's job is to **report results and stop**.
Any further tool calls only waste context and risk triggering Stop hook loops.

**Starting new work after pipeline completion:**
If the user requests a new feature after `## Pipeline Complete`, the lead MUST:
1. Run `/half-clone` to create a fresh session with only recent context
2. In the new session, start the new pipeline from P0
3. NEVER continue with new planning/implementation in a session that already ran a full pipeline — the accumulated context (~120k+ tokens) will cause extended-thinking hangs during plan execution.

This is enforced by `check-context-preemptive.sh` which blocks ExitPlanMode and TeamCreate above 65% context.

### Integration

Existing /orchestrate, /checkpoint, session hooks, and strategic-compact all compatible.
