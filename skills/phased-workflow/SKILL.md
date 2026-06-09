---
name: phased-workflow
version: "3.2.0"
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
Stage 0: SCOPE CHECK (optional) → clarify with user if request is vague
Stage 1: PLAN                   → sub-agent writes the plan (phased-plan skill)
Stage 2: REVIEW                 → sub-agent reviews the plan (phased-review skill)
         FIX                    → orchestrator fixes review findings, updates plan
         (re-review if fixes were substantial)
Stage 3: APPROVE                → present to user, STOP, wait for explicit approval
Stage 4: IMPLEMENT              → sub-agent executes the plan (phased-implement skill)
Stage 5: QA                     → sub-agent verifies the work (phased-qa skill)
         FIX                    → orchestrator fixes QA findings
         REPORT                 → present final report to user
Stage 6: FINISH (optional)      → commit / PR / merge handoff
```

Stages 1–5 are mandatory. Stages 0 and 6 are conditional and only invoked when the signals below apply. No shortcuts on the mandatory stages.

---

## Sub-agent status codes

Every sub-agent reports back with one of these codes plus evidence. Branch on the code, not on prose interpretation. If a sub-agent's report doesn't carry one of these, ask it to commit to one before acting.

| Code | Meaning | Orchestrator action |
|------|---------|---------------------|
| `DONE` | All objectives met, all DoD verified with evidence | Proceed to next stage |
| `DONE_WITH_CONCERNS` | Completed, but flagged doubts (scope creep, risk, file size, observation) | Read concerns. If correctness/scope: address before proceeding. If observation: note and proceed |
| `NEEDS_CONTEXT` | Sub-agent missing information that wasn't provided | Provide the missing context, re-dispatch the same sub-agent |
| `BLOCKED` | Cannot complete — environment problem, fundamental gap, or unclear requirement | Assess: context gap → re-dispatch with more context. Reasoning gap → re-dispatch with more capable model. Plan wrong → handle via `PLAN_WRONG`. Environment → escalate to user |
| `PLAN_WRONG` | The plan contains an error that prevents implementation | Stop. Update the plan. Re-dispatch the implementer for remaining phases. Note delta in final report |

---

## Stage 0 — Scope check (optional)

Before dispatching the planner, judge whether the request is concrete enough to plan. Skip when the request is already well-formed.

| Signal | Action |
|--------|--------|
| Clear acceptance criteria, named files or features, the user has done the thinking | Skip Stage 0, go to Stage 1 |
| Vague ("improve X", "make Y better"), conflicting signals, unclear scope | Run a brief brainstorm with the user — clarify intent, scope, success criteria — before Stage 1 |
| Multiple independent subsystems in one request | Tell the user. Propose splitting into separate phased-workflow runs, one per subsystem |
| Request asks for something the user has already approved a plan for (path provided) | Skip to Stage 4 — see "Shortcut" in Stage 3 |

A vague task at Stage 0 produces a vague plan at Stage 1, which produces wasted work at Stage 4. Clarify upstream — never plan around ambiguity.

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

**Restate before fixing.** For each finding, follow this discipline (do not jump straight to a code edit):

1. **Read** the finding completely without reacting.
2. **Restate** the issue in your own words — what is the reviewer claiming, and why?
3. **Verify** against the actual codebase — is the claim correct? If you cannot easily verify it, say so before deciding.
4. **Decide:** if correct, apply the fix to the plan. If wrong, push back with technical reasoning — do not blindly implement.

Fix every verified finding regardless of severity. Update the plan file.

**Forbidden:** "You're absolutely right" / "Great point" / "Excellent feedback" / blind implementation. State the fix in the plan, not gratitude — actions on the plan show you heard the feedback.

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

**Proxy approval:** When phased-workflow is invoked by another orchestrator, the calling agent acts as the approval authority on behalf of the user. The calling agent's approval is treated the same as direct user approval.

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

**Restate before fixing.** Same discipline as Stage 2:

1. Read the finding completely.
2. Restate it in your own words.
3. Verify against the actual codebase — is the claim correct?
4. Decide: fix, push back with reasoning, or escalate.

Fix every verified finding, regardless of severity. After fixing, re-run tests and type checks to verify no regressions — fresh runs, not cached output.

**Forbidden:** "You're absolutely right" / "Great catch" / blind implementation. State the fix, not gratitude.

### Present final report

This is the last output the user sees. Include:

- Per-phase: what changed, verification evidence, pass/fail
- QA sub-agent's original findings (all severities)
- Fixes applied for each finding
- Final verification results (test count, TypeScript errors, ESLint warnings)

---

## Stage 6 — Finish (optional)

After the final report, decide on integration. Skip when the user has already taken delivery, when there's nothing to commit, or when the plan explicitly handles its own commits.

| Situation | Stage 6 action |
|-----------|---------------|
| Uncommitted changes from the implement stage and the plan said "commit at end" | Confirm scope with the user, then commit. Use HEREDOC for the message |
| Work is on a feature branch and the user wants integration | Offer: merge to main, open PR, or leave for review. Wait for explicit choice |
| Work is on `main` | Stop. Work shouldn't have been on main. Flag and ask the user how to proceed |
| The user has already said "I'll handle the commit" | Skip. Stop at the QA report |

**Never** push, force-push, merge, or create a PR without explicit user approval at this stage. The QA report is a valid stopping point — ending there is the default unless the user pre-authorized the next step.

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

| Stage | Skill | What to provide | What to expect back | Valid status codes |
|-------|-------|----------------|---------------------|--------------------|
| 1. Plan | `phased-plan` | Task requirements, project context | Plan file path, phase summary | `DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED` |
| 2. Review | `phased-review` | Plan file path | Findings with severity, go/no-go, restated intent | `DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` |
| 4. Implement | `phased-implement` | Plan file path | Per-phase results, deviations, fresh verification evidence | `DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED` / `PLAN_WRONG` |
| 5. QA | `phased-qa` | Plan file path | Findings with severity, per-phase pass/fail, fresh verification evidence | `DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` |

If a sub-agent's report doesn't carry a valid status code, ask it to commit to one before acting on the report.

---

## Style Contract — caveman prose (applies to dispatch prompts and orchestrator artifacts)

Dispatch prompts and orchestrator artifacts are operational, not narrative. Every line carries a fact.

**Rules:**
- No articles ("the", "a", "an") — drop them
- No hedging ("might", "could", "appears", "seems", "likely", "probably") — assert or omit
- No filler ("simply", "just", "essentially", "in order to", "successfully", "basically", "actually")
- No transitions ("furthermore", "additionally", "moreover", "however")
- No restatement of the prompt or task
- Sentence fragments OK. Imperative or past-tense verbs.
- One fact per line. No paragraphs of prose.
- `path:line` for every claim. No prose pointers.
- Numbers and counts beat adjectives ("3 errors" not "several errors")

**Carve-outs (keep verbatim — do NOT cavemen):**
- Verbatim contract blocks pasted into dispatch prompts (Investigation rigor, Verification Gate, Hypothesis Discipline) — paste as-written
- Sub-agent return text — relay verbatim, do not paraphrase
- Status codes and structured fields — exact

**Self-check before submitting:**
- Any sentence with 2+ commas → rewrite
- Any paragraph with 3+ sentences → split into bullets, drop filler
- Sub-agents inherit their own Style Contract from their SKILL.md — orchestrator does not need to repeat the rules in the dispatch prompt
