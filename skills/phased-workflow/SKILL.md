---
name: phased-workflow
description: "Orchestrate plan → review → approve → sliced implementation → QA with bounded review rounds, empirical discovery for uncertain integrations, risk-adaptive multi-model seats, checkpointed verification, and evidence-backed delivery. Use for phased-workflow, phased workflow, pw:, or /pw requests."
---

# Phased Workflow

**Suite contract:** 4.0.0

## Overview

Orchestrate a structured delivery: plan → review → approve → implement → verify. Each stage is a sub-agent with a fresh perspective. The orchestrator coordinates — it never writes plan content, implements code, or performs QA itself.

**Core principle:** Independent eyes at decision boundaries. Keep one implementation owner per slice. Use separate reviewers and QA agents. Spend parallelism on independent work and correlated-risk reduction, not repeated derivation.

Read these references when their trigger applies:
- External or headless reviewer seat: [references/external-reviewers.md](references/external-reviewers.md)
- Long-running commands, stage budgets, evidence reuse, cancellation, or local skill parity: [references/execution-controls.md](references/execution-controls.md)

## When to use

Use when the user asks for structured multi-phase work with planning, review, and QA.

Trigger phrases: `phased-workflow`, `phased workflow`, `pw:`, `/pw`

---

## The Pipeline

```
Stage 0: SCOPE CHECK (optional) → clarify with user if request is vague
Stage 0.5: DISCOVERY (conditional) → empirical probes before planning uncertain surfaces
Stage 1: PLAN                   → sub-agent writes the plan (phased-plan skill)
Stage 2: REVIEW                 → sub-agent reviews the plan (phased-review skill)
         FIX                    → planner fixes verified findings
         ROUND 2                → named-finding closure only
Stage 3: APPROVE                → present to user, STOP, wait for explicit approval
Stage 4: IMPLEMENT              → one owner executes each independently verifiable slice
Stage 5: QA                     → sub-agent verifies the work (phased-qa skill)
         FIX                    → implementation owner fixes verified findings
         ROUND 2                → named-finding closure only
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
| `ARCHITECTURE_WRONG` | Approved approach cannot satisfy objective or creates an unacceptable design constraint | Stop affected slice. Return to planner/reviewer. Preserve completed independent slices |
| `EMPIRICAL_DELTA` | Live behavior differs from a documented assumption, but objective and architecture remain valid | Record evidence. Patch plan locally. Resume affected slice without restarting completed gates |
| `IMPLEMENTATION_DETAIL` | Local signature, path, or internal detail drifted without changing architecture | Let implementation owner adapt, verify, and record delta |
| `ENVIRONMENT_BLOCKED` | Credentials, service, dependency, permission, or host state prevents progress | Exhaust safe diagnostics, then escalate with exact unblock requirement |

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

### Stage 0.5 — Empirical discovery (conditional)

Run discovery before detailed planning when work touches any of these:
- External/headless CLI or unfamiliar provider API
- Native process, socket, filesystem permission, sandbox, or security boundary
- Long-context, stochastic, timing-sensitive, or resource-limited behavior
- A first-time SDK call whose contract is not already proven in this repository

Discovery produces small, disposable probes and a receipt containing command, environment, observed behavior, constraints, and unresolved unknowns. Probe the load-bearing assumptions only. Do not build production code here.

If a probe invalidates the proposed architecture, return `ARCHITECTURE_WRONG`. If it refines a value or implementation detail, record `EMPIRICAL_DELTA` and continue. Feed the receipt to the planner. Never write an exact-code plan around an untested external assumption.

---

## Stage 1 — Plan (sub-agent)

**Dispatch a sub-agent** to run the `phased-plan` skill.

Provide the sub-agent with:
- The user's task description / requirements
- The project context (working directory, relevant file paths if known)

The sub-agent writes the plan, self-checks it, and returns the plan file path.

### Roadmaps, slices, and multi-file plans

If the task is large, decompose it into independently verifiable slices before implementation. A slice should normally fit 30–90 minutes, leave the tree working, and have its own DoD. Parallelize only slices with disjoint write sets or an explicit integration owner.

The planner may produce multiple plan files with a `-phase-N` suffix. Each file is self-contained and independently executable. When this happens:

- **Run the full pipeline (Stages 2–5) on phase-1 first.** Do not plan phase-2 until phase-1 is implemented and QA'd — later phases may need to adjust based on what was learned.
- After phase-1's QA passes, dispatch a new planner sub-agent for phase-2 (or review the already-written phase-2 plan against the now-changed codebase).
- Repeat until all phase files are complete. Commit each completed milestone when pre-authorized. Do not reopen approval between slices when the user approved uninterrupted execution.

---

## Stage 2 — Review (sub-agent)

**Dispatch a risk-adaptive review panel** in one parallel wave. No seat is the planner.

**Normal-risk plan — two seats:**
- **Verifier** — default `phased-review`: "is each claim correct against the code?"
- **Independent adversary** — different model/provider when available. Combine adversarial and second-order-effect lenses.

**High-risk plan — three seats:** add a domain specialist when the plan touches SQL/migration/RLS, auth/session, money/entitlement, native/permissions, process lifecycle, or irreversible data changes. The specialist also runs the bug-class sweep.

Use at most one external headless reviewer per gate. Prefer qualified Cursor CLI `agent`; use another available provider only as fallback. Review seats are read-only and advisory. Follow [references/external-reviewers.md](references/external-reviewers.md).

**Merge:** dedupe across seats (same file:line + issue = one). A finding from ANY single seat counts — do not require consensus. Conflicts (one seat clears it, another flags) → adjudicate by reading the code yourself.

### Fix review findings

**Restate before fixing.** For each finding, follow this discipline (do not jump straight to a code edit):

1. **Read** the finding completely without reacting.
2. **Restate** the issue in your own words — what is the reviewer claiming, and why?
3. **Verify** against the actual codebase — is the claim correct? If you cannot easily verify it, say so before deciding.
4. **Decide:** if correct, apply the fix to the plan. If wrong, push back with technical reasoning — do not blindly implement.

Fix every verified finding regardless of severity. Route plan edits back to the planner; the orchestrator adjudicates and tracks closure but does not silently author plan content.

**Forbidden:** "You're absolutely right" / "Great point" / "Excellent feedback" / blind implementation. State the fix in the plan, not gratitude — actions on the plan show you heard the feedback.

### Bounded review rounds

- **Round 1:** exhaustive review of the whole plan.
- **Round 2:** verify closure of Round 1 finding IDs and their affected surface only. Do not restart an open-ended review.
- Fix any new verified defect found in the affected surface regardless of severity. Use targeted owner proof for low/medium closure. A third independent round is allowed only for a newly introduced critical/high defect. Record the exception.
- If the same claim fails twice, stop re-running the panel. Run a targeted diagnostic against that claim and evidence.

Minor non-behavioral fixes that do not affect a finding's proof need no Round 2.

---

## Stage 3 — User Approval

Present a concise summary and **STOP**. Include:

- Plan file path
- Phase list with objectives
- What the review caught and fixed (so the user knows it was self-reviewed)
- Explicit request for approval

### Approval gate

**Do not proceed until explicitly approved, unless the caller already provided approval for this plan or roadmap.**

| Caller says | Meaning |
|-------------|---------|
| "approved", "go ahead", "lgtm", "do it", "implement it" | Approval — proceed to Stage 4 |
| Asks questions, gives feedback, suggests changes | NOT approval — update the plan, re-present |
| Silence | NOT approval — wait |

If the caller provides feedback, update the plan and re-present. A re-review is NOT required for caller-driven changes (the caller is the reviewer at this point).

**Proxy approval:** When phased-workflow is invoked by another orchestrator, the calling agent acts as the approval authority on behalf of the user. The calling agent's approval is treated the same as direct user approval.

**Shortcut:** If the user provides a previously-approved plan file path and says to execute it (e.g., "implement plans/foo.md"), skip to Stage 4.

Record pre-authorized policy once: uninterrupted execution, main/branch choice, milestone commits, push/PR authority, and approval scope. Do not ask again for an action already authorized. New authority is still required for destructive or externally visible actions outside that policy.

---

## Stage 4 — Implement (sub-agent)

**Dispatch one implementation owner per slice** to run the `phased-implement` skill against the approved plan file.

- The owner executes the slice end-to-end, handles later QA fixes for that slice, and verifies DoD before proceeding.
- No additional user approval gates between phases.
- The implementer reports back: per-phase results, deviations, verification evidence.
- Use checkpointed probes and the verification pyramid. Do not rerun a full qualification matrix to diagnose one probe.

### If the implementer reports a routing status

- `IMPLEMENTATION_DETAIL` → owner adapts and verifies.
- `EMPIRICAL_DELTA` → planner records the evidence-backed delta; owner resumes affected slice.
- `ARCHITECTURE_WRONG` → stop affected slice and re-plan. Keep independently completed work.
- `ENVIRONMENT_BLOCKED` → escalate only after bounded diagnostics identify the required external change.

---

## Stage 5 — QA (sub-agent)

**Dispatch a fresh QA agent** to run the `phased-qa` skill against the plan file. Optionally run one external read-only seat in the same parallel wave.

- It MUST be a different sub-agent than the implementer — fresh perspective on the completed work.
- The QA agent verifies all phases against the plan's objectives and DoD, runs commands, reads code, and returns findings.

### Fix QA findings

**Restate before fixing.** Same discipline as Stage 2:

1. Read the finding completely.
2. Restate it in your own words.
3. Verify against the actual codebase — is the claim correct?
4. Decide: fix, push back with reasoning, or escalate.

Fix every verified finding, regardless of severity. Route fixes to the slice's implementation owner. After fixing, re-run the affected checks and then the milestone gate. Do not repeat unrelated expensive probes.

### Bounded QA rounds

- **Round 1:** exhaustive diff, DoD, integration, and cleanliness audit.
- **Round 2:** verify named Round 1 finding IDs and affected regression surface only.
- Fix any new verified defect found in that surface regardless of severity. Use targeted owner proof for low/medium closure. A third independent round is allowed only for a newly introduced critical/high regression. Record the exception.
- Evidence may be reused only when its fingerprint matches commit, diff, plan, tool version, configuration, and inputs. Otherwise rerun it.

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
| Work is on `main` and user pre-authorized main | Continue; commit only at the authorized milestone boundary |
| Work is on `main` without authorization | Stop and ask how to proceed |
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
| Repeat a full suite or qualification matrix to diagnose one stable failure | Run the smallest targeted check after two identical failures |
| Leave child processes, sockets, or temporary credentials after cancellation | Follow bounded shutdown and cleanup audit in execution-controls reference |

---

## Sub-Agent Dispatch Reference

| Stage | Skill | What to provide | What to expect back | Valid status codes |
|-------|-------|----------------|---------------------|--------------------|
| 1. Plan | `phased-plan` | Task requirements, project context | Plan file path, phase summary | `DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `ARCHITECTURE_WRONG` / `ENVIRONMENT_BLOCKED` |
| 2. Review | `phased-review` | Plan file path | Findings with severity, go/no-go, restated intent | `DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` |
| 4. Implement | `phased-implement` | Plan file path | Per-phase results, deviations, fresh verification evidence | `DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `ARCHITECTURE_WRONG` / `EMPIRICAL_DELTA` / `IMPLEMENTATION_DETAIL` / `ENVIRONMENT_BLOCKED` |
| 5. QA | `phased-qa` | Plan file path | Findings with severity, per-phase pass/fail, fresh verification evidence | `DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` |

If a sub-agent's report doesn't carry a valid status code, ask it to commit to one before acting on the report.

## Operational control loop

At every stage boundary record elapsed time, model/tool calls, completed gates, open finding IDs, active blocker, and next action. Set an expected time/call budget before dispatch. Exceeding it triggers strategy reassessment, not an approval stop: narrow the scope, switch to targeted diagnostics, replay a checkpoint, or change the model/provider.

For work lasting more than 30 minutes, send periodic status updates with current slice, elapsed time, completed evidence, blocker, and budget deviation. Never leave the user unable to distinguish progress from a stuck command.

Follow active-command cancellation, evidence fingerprinting, verification-pyramid, and local parity rules in [references/execution-controls.md](references/execution-controls.md).

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
