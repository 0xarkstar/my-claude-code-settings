# Engineering Discipline

Behavioral guardrails against common LLM coding mistakes (after Karpathy), plus a
tiered testing policy. Bias toward caution; for trivial tasks use judgment.

## 1. Think before coding
- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.

## 2. Simplicity first
- Minimum code that solves the problem. Nothing speculative.
- No features beyond what was asked; no abstractions for single-use code; no configurability nobody requested; no error handling for impossible scenarios.
- If 200 lines could be 50, rewrite it. "Would a senior engineer call this overcomplicated?" If yes, simplify.

## 3. Surgical changes
- Touch only what the task requires. Don't refactor, reformat, or "improve" adjacent code that isn't broken.
- Match existing style even if you'd do it differently.
- Remove imports/vars YOUR change orphaned; mention unrelated dead code, don't delete it.
- The test: every changed line traces to the request.

## 4. Goal-driven execution
- Turn tasks into verifiable goals: "add validation" → "write tests for invalid inputs, then make them pass"; "fix the bug" → "write a failing test that reproduces it, then make it pass"; "refactor X" → "tests pass before and after."
- For multi-step work, state a brief plan with a verify check per step, then loop until verified.

## 5. Testing policy — by code tier
Match rigor to what the code is, not a blanket rule.

- **Production / infra / anything holding real value or running unattended** (bots on OCI, live services, SDKs others depend on, anything touching money or auth): TDD, meaningful unit + integration coverage (~80% where it buys confidence), E2E on critical flows. Fix the implementation, not the test — unless the test is wrong.
- **Prototypes, research spikes, personal tools, one-off scripts**: judgment. Write the tests that would actually catch a regression you care about; skip ceremony. A failing repro test for a real bug is always worth it; 80%-of-everything is not.

Rule of thumb: the stronger the blast radius (money, unattended runtime, shared dependency), the closer to full TDD+coverage. The more throwaway/experimental, the more Simplicity-First (§2) wins over coverage targets. When unsure which tier, ask.

---
Working if: fewer unnecessary diff lines, fewer overcomplication rewrites, clarifying questions before mistakes rather than after.
