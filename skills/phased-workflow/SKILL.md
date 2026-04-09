---
name: phased-workflow
version: "3.1.0"
description: "Orchestrator: plan → review → approve → implement → QA. Dispatches sub-agents for each stage. Never does the work itself. Triggers: phased-workflow, pw:, /pw"
metadata:
  tags: workflow, orchestration, sub-agent
---

# Phased Workflow

## Overview

Orchestrate a structured delivery: plan → review → approve → implement → verify. Each stage is a sub-agent with a fresh perspective. The orchestrator coordinates — it never writes plan content, implements code, or performs QA itself.

**Core principle:** Four-eyes at every stage. The planner doesn't review their own plan. The implementer doesn't QA their own code. Each sub-agent gets the plan file and the codebase — not the previous agent's session context.

## When to use

Use when the user asks for structured multi-phase work with planning, review, and QA.

Trigger phrases: `phased-workflow`, `phased workflow`, `pw:`, `/pw`

---

## The Pipeline

```
Stage 1: PLAN        → sub-agent writes the plan (phased-plan skill)
Stage 2: REVIEW      → sub-agent reviews the plan (phased-review skill)
         FIX         → orchestrator fixes review findings, updates plan
         (re-review if fixes were substantial)
Stage 3: APPROVE     → present to user, STOP, wait for explicit approval
Stage 4: IMPLEMENT   → sub-agent executes the plan (phased-implement skill)
Stage 5: QA          → sub-agent verifies the work (phased-qa skill)
         FIX         → orchestrator fixes QA findings
         REPORT      → present final report to user
```

Every stage is mandatory. No shortcuts.

---

## Stage 1 — Plan (sub-agent)

**Dispatch a sub-agent** to run the `phased-plan` skill.

Provide the sub-agent with:
- The user's task description / requirements
- The project context (working directory, relevant file paths if known)

The sub-agent writes the plan, self-checks it, and returns the plan file path.

### Multi-file plans

If the task is large, the planner may produce multiple plan files with a `-phase-N` suffix (e.g., `feature-phase-1.md`, `feature-phase-2.md`). Each file is self-contained and independently executable. When this happens:

- **Run the full pipeline (Stages 2–5) on phase-1 first.** Do not plan phase-2 until phase-1 is implemented and QA'd — later phases may need to adjust based on what was learned.
- After phase-1's QA passes, dispatch a new planner sub-agent for phase-2 (or review the already-written phase-2 plan against the now-changed codebase).
- Repeat until all phase files are complete.

---

## Stage 2 — Review (sub-agent)

**Dispatch a sub-agent** to run the `phased-review` skill against the plan file.

- It MUST be a different sub-agent than the planner — fresh context, independent perspective.
- The reviewer reads the plan AND the actual codebase, then returns findings with severity.

### Fix review findings

Fix every finding — critical, high, medium, and low. Update the plan file.

**When to re-review:** If fixes are substantial (structural changes, new phases, changed approach), dispatch the review sub-agent again. If fixes are minor (wording, constants, adding NTH notes), no re-review needed.

---

## Stage 3 — User Approval

Present a concise summary and **STOP**. Include:

- Plan file path
- Phase list with objectives
- What the review caught and fixed (so the user knows it was self-reviewed)
- Explicit request for approval

### Approval gate

**Do not proceed until explicitly approved.**

| Caller says | Meaning |
|-------------|---------|
| "approved", "go ahead", "lgtm", "do it", "implement it" | Approval — proceed to Stage 4 |
| Asks questions, gives feedback, suggests changes | NOT approval — update the plan, re-present |
| Silence | NOT approval — wait |

If the caller provides feedback, update the plan and re-present. A re-review is NOT required for caller-driven changes (the caller is the reviewer at this point).

**Proxy approval:** When phased-workflow is invoked by another orchestrator (e.g., builder-hassan), the calling agent acts as the approval authority on behalf of the user. The calling agent's approval is treated the same as direct user approval.

**Shortcut:** If the user provides a previously-approved plan file path and says to execute it (e.g., "implement plans/foo.md"), skip to Stage 4.

---

## Stage 4 — Implement (sub-agent)

**Dispatch a sub-agent** to run the `phased-implement` skill against the approved plan file.

- The implementer executes all phases end-to-end, verifying each phase's DoD before proceeding.
- No additional user approval gates between phases.
- The implementer reports back: per-phase results, deviations, verification evidence.

### If the implementer reports a blocker

- Assess: is it a plan problem or an environment problem?
- If plan problem: update the plan, re-dispatch the implementer for remaining phases.
- If environment problem: escalate to the user.

---

## Stage 5 — QA (sub-agent)

**Dispatch a sub-agent** to run the `phased-qa` skill against the plan file.

- It MUST be a different sub-agent than the implementer — fresh perspective on the completed work.
- The QA agent verifies all phases against the plan's objectives and DoD, runs commands, reads code, and returns findings.

### Fix QA findings

Fix every finding, regardless of severity. After fixing, re-run tests and type checks to verify no regressions.

### Present final report

This is the last output the user sees. Include:

- Per-phase: what changed, verification evidence, pass/fail
- QA sub-agent's original findings (all severities)
- Fixes applied for each finding
- Final verification results (test count, TypeScript errors, ESLint warnings)

---

## Red Flags — Never Do These

| Never | Why |
|-------|-----|
| Write plan content yourself (orchestrator) | The planner sub-agent has the phased-plan skill and self-check |
| Skip the review sub-agent | Four-eyes principle — planner can't review their own plan |
| Implement before explicit user approval | Wastes work if plan is wrong |
| Implement code yourself (orchestrator) | The implementer sub-agent has the phased-implement skill |
| Skip the QA sub-agent | Implementer can't QA their own code |
| Proceed with unfixed findings | Every severity matters |
| Reuse a sub-agent across stages | Fresh context = independent perspective |
| Force through a blocker instead of escalating | Guessing compounds errors |

---

## Sub-Agent Dispatch Reference

| Stage | Skill | What to provide | What to expect back |
|-------|-------|----------------|-------------------|
| 1. Plan | `phased-plan` | Task requirements, project context | Plan file path, phase summary |
| 2. Review | `phased-review` | Plan file path | Findings with severity, go/no-go |
| 4. Implement | `phased-implement` | Plan file path | Per-phase results, deviations, evidence |
| 5. QA | `phased-qa` | Plan file path | Findings with severity, per-phase pass/fail |
