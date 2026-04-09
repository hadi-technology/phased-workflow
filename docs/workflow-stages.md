# Workflow Stages

The phased workflow runs five stages in sequence. Each stage is a separate sub-agent dispatched by the orchestrator.

## Stage 1 — Plan

**Skill:** `phased-plan`
**Agent:** Fresh sub-agent with no prior context

The planner reads the codebase, maps dependencies, and writes an implementation plan saved to `plans/<date>-<slug>.md`.

The plan contains:
- Phase-by-phase implementation steps
- Exact file paths and line numbers
- Copy-pasteable code snippets
- Definition of Done (DoD) per phase with verification commands
- A cleanliness self-check per phase

If the task is large, the planner splits into multiple plan files (`-phase-1.md`, `-phase-2.md`), each independently executable.

The planner runs a self-check before handing off — scanning for placeholders, missing code, untraced constants, and incomplete dependency arrays.

## Stage 2 — Review

**Skill:** `phased-review`
**Agent:** Different sub-agent from the planner

The reviewer reads both the plan and the actual codebase. It verifies:

- File paths and line numbers exist and match
- Code snippets are complete and copy-pasteable
- Numeric constants are traced to source
- Optimization preconditions hold (e.g., `React.memo` only works if parent props are stable)
- Breaking interface changes account for test files
- Adjacent code (within 20 lines of each change site) doesn't have related issues

Findings are categorized by severity (critical/high/medium/low) with evidence. The orchestrator fixes all findings and updates the plan.

If fixes are substantial (structural changes, new phases), the review runs again. Minor fixes (wording, constants) don't trigger a re-review.

## Stage 3 — User Approval

**Agent:** None — this is a human gate

The orchestrator presents:
- The plan file path
- Phase list with objectives
- What the review caught and fixed

Then it stops and waits.

| You say | What happens |
|---------|-------------|
| "approved", "go ahead", "lgtm" | Proceeds to implementation |
| Questions or feedback | Plan is updated, re-presented |
| Nothing | Pipeline waits |

This is the only point where you can review the full plan before code is written. The plan file is in your `plans/` directory — you can read it, edit it, or share it.

## Stage 4 — Implement

**Skill:** `phased-implement`
**Agent:** Fresh sub-agent, different from planner and reviewer

The implementer executes the plan phase by phase. For each phase:

1. Reviews the phase scope and files to change
2. Implements using the plan's code as a starting point, adapting to actual code state
3. Documents any deviations or discoveries
4. Runs every DoD verification command and records output
5. Runs a mandatory cleanliness self-check (pattern reuse, theme tokens, naming, minimum diff, no dead code)
6. Confirms all files in "Files changed" were touched

The implementer does not move to the next phase until the current one passes all checks.

**Discovery handling:**
- Small in-scope fixes: fixed and documented
- Out-of-scope related issues: documented as NTH (nice-to-have), not fixed
- Plan is wrong: stops, updates plan, continues from updated version
- Blockers: stops and escalates

## Stage 5 — QA

**Skill:** `phased-qa`
**Agent:** Fresh sub-agent, different from the implementer

The QA agent verifies completed work against the plan. It:

1. Extracts all DoD criteria from the plan
2. Runs every verification command fresh (never trusts cached results)
3. Reads every changed file and checks for:
   - Plan compliance (code matches what was specified)
   - Placeholder code or incomplete implementations
   - Numeric constants matching actual source values
   - Optimization effectiveness
   - Adjacent code issues
   - Cleanliness (pattern reuse, hardcoded values, naming, dead code)
4. Reports findings with severity and evidence

The QA agent reports findings but does not fix them. The orchestrator fixes all findings, re-runs verification, and presents the final report.

## Multi-File Plans

For large tasks, the planner produces multiple plan files. When this happens, the full pipeline (stages 2-5) runs on the first plan file before the second is even reviewed. This ensures later phases can adjust based on what was learned during implementation.
