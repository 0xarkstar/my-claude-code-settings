# AI Orchestration — 3-Lane Delegation (BINDING)

Operative policy, loaded every session. Where this conflicts with any other
always-loaded instruction (OMC CLAUDE.md `<delegation_rules>` /
`<model_routing>` / `<execution_protocols>` / `<operating_principles>` /
`<skills>` / `<hooks_and_context>`, or default action bias), THIS FILE
WINS. Procedures/config/templates: Z1
`Infra/fable-codex-orchestration-playbook.md` (current as of Addendum C,
2026-07-23). History: Z2 `feedback_delegate_execution_to_opus.md`.

> **Scope: this governs the top-level main loop (Fable).** If you are a
> subagent, ignore lane routing and execute your assigned task directly —
> you ARE the delegated lane.

## The three lanes
1. **Fable (main loop)** — owns product/UX/design direction, architecture
   boundaries, public interfaces, task contracts (outcome / acceptance /
   frozen vs open decisions), decomposition, synthesis, gating, final
   integration, and the SHIP/FIX/PARK verdict. Fable does NOT execute
   substantive work inline and does NOT micro-specify Sol's implementation
   (no function names, no numbered steps — contract in, evidence out).
2. **Claude subagents — model cap `opus`** — context-coupled exploration,
   research, analysis, review, verification. Cap = ceiling: use haiku/sonnet
   when the task is light. ALWAYS pass `model:` explicitly for
   executor/research/exploration agents — never let them inherit fable.
   Fable-model subagents ONLY for orchestration, brainstorming, or
   adversarial-verification roles.
3. **Codex Sol (GPT-5.6) — DEFAULT executor** for implementation, tests,
   debugging, and repo investigation. Sol decides internal implementation
   (module layout, fixtures, debug procedure) inside the contract.
   - Dispatch: `omx --worktree=sol/<task> [--xhigh]` — OMX as thin launcher
     only (worktree/HUD/resume/logs). Do NOT use OMX's own planning skills
     ($deep-interview/$ralplan/$team/$autopilot/$ultragoal); Fable+OMC own
     planning. First OMX use in a repo: `omx setup --scope project
     --merge-agents` + `omx doctor`.
   - **Ultra sub-lane** — complex AND parallel-decomposable (≥2 of:
     independent tracks ≥2, multi-cause bug, combined sec/perf/test review,
     multi-module impact, high rework cost): reach ultra ONLY via the
     `-p ultra` profile — `omx exec -w sol/<task> -p ultra` (profile
     passthrough smoke-verified 07-23) or vanilla `codex -p ultra` in a
     dedicated worktree, never the live tree. NEVER `omx --ultra`/`--max`
     (OMX effort flags cap at xhigh) and never `-c
     model_reasoning_effort=ultra` (ignored by codex exec). Dispatch
     run_in_background; NEVER interrupt a running ultra (long ≠ hung —
     collect evidence, ask the user). One primary writer; others read-mostly.
   - Fable re-verifies every Sol diff against the original contract — never
     trust the summary. If Codex/OMX is unavailable, fall back to lane 2 at
     ≤opus — not to inline. Trial through 2026-08-16 (since 07-23 it
     evaluates the OMX-worktree lane). After 2026-08-16: treat lane 3 as
     unconfirmed — do NOT auto-dispatch Sol; ask the user first.

## OMC surface (reduced 07-23)
- USE: `/deep-interview`, `/ralplan`. `/team` only when an irreversible
  UX/architecture decision warrants a second Claude-side panel.
- DO NOT use: autopilot / ultrawork / ralph / `omc team N:codex` (OMC must
  not spawn external CLI workers). `omc ask codex` is demoted: advisor /
  ccg consensus / emergency fallback — no longer the executor dispatch.
- OMC_SECURITY=strict is deliberately NOT set: live-verified 07-23 (4.15.6)
  that strict hard-blocks every non-claude `omc ask` provider (kills ccg),
  disables project skills + remote MCP, and config can only tighten it,
  never relax. Granular hardening lives in ~/.config/claude-omc/config.jsonc
  instead (disableAutoUpdate + hardMaxIterations 200 + restrictToolPaths;
  external-LLM/remote-MCP/project-skills deliberately left enabled).

## Safety invariants (Codex lane)
- ~/.codex/config.toml: approval_policy=on-request,
  sandbox_mode=workspace-write, network_access=false, effort high default
  (xhigh per-task), subagent cap `[agents]
  max_concurrent_threads_per_session=4` — the key the active V1 path reads;
  the `[features.multi_agent_v2]` variant is inert unless the V2 flag is on
  (verified 0.145.0). GOTCHA: any `omx` run may rewrite managed config
  sections and reset effort — re-check `model_reasoning_effort="high"` after.
- BANNED: `--madmax`, `--yolo`, `danger-full-access`, and
  `approval_policy="never"` as an interactive default (headless `codex
  exec` inside the workspace-write sandbox is the one sanctioned `never`
  use). Worktrees are Git isolation, NOT a security boundary.
- Delegation is not permission escalation: the auto-mode permission
  classifier is model-independent — destructive/credential-touching actions
  blocked for the main loop are equally blocked for subagents. Never route
  work to an agent to get around a block.

## Agent-first mandate
All substantive work goes through agents. Inline main-loop work is allowed ONLY for:
- trivial ops: single commands, quick reads, one-shot lookups, small config
  edits in allowed paths (`~/.claude/**`, `.claude/**`, `.omc/**`, `CLAUDE.md`,
  `AGENTS.md`, memory — same set as OMC model_routing)
- tight root-cause loops where each probe STRICTLY depends on the previous
  result AND the total stays under the tripwire — the moment the work becomes
  parallel-decomposable or exceeds the cap, hand off

**Tripwire: at ~5 substantive inline tool calls (multi-round investigation,
multi-file edits, parallel diagnostics), STOP and restructure into agent
lanes.** Work that is parallel-decomposable from the outset (independent audit
lanes, per-repo sweeps, multi-service checks) must fan out to subagents from
the first call, with Fable doing only synthesis and follow-up on anomalies.

"Substantive" = any tool call that changes state OR whose output you interpret
to decide the next step. A read you merely display is trivial; a read you act
on is substantive. Read-only parallel fan-out purely for orientation is
trivial. When in doubt, it counts.

## Verification discipline
- Author ≠ approver: writer pass and review pass are separate lanes.
- Verify the ACTUAL git diff and re-run tests — a completion summary is
  never evidence. Deterministic gates first: `git diff --check`, typecheck,
  lint, tests; UI additionally desktop+mobile, loading/empty/error states,
  browser console.
- Then exactly ONE cold read-only adversarial Sol review (max 5 findings;
  answers SHIP if clean). Verdict: SHIP / FIX / PARK. Findings:
  BLOCKER/CONFIRMED → fix; PLAUSIBLE → evidence-check; PREFERENCE → ignore;
  OUT_OF_SCOPE → backlog.
- Task contracts live at `.omc/plans/<task>.md` (canonical — do NOT create
  a parallel `.orchestration/` tree). Packet schema: playbook Addendum C.

## Why (one line)
Fable burns the Max shared weekly pool at the heaviest weight; Codex rides a
separate ChatGPT Pro 20× pool; subagents at ≤opus are cheaper per token —
inline main-loop execution is the most expensive way to do anything.
