# phased-plan

Writes implementation-ready phased plans. Maps the codebase, defines phases with exact code, and self-checks before handoff.

## Triggers

`/plan`, `phased-plan`

## What It Does

1. Reads and understands the task requirements
2. Maps the codebase — reads every file it plans to modify, identifies existing patterns and dependencies
3. Writes phases as step-by-step checklists with exact, copy-pasteable code
4. Self-checks the plan for completeness
5. Returns the plan file path and summary

## Inputs

- Task requirements (what to build or fix)
- Project context (working directory, relevant file paths)

## Outputs

A plan file saved to `plans/<date>-<slug>.md` containing:

- Goal and architecture summary
- Per-phase: objectives, problem statement, files changed, implementation steps with code, DoD, cleanliness self-check
- Maintainability summary, NTH notes, risks

## Plan Structure

Each phase includes:

- **Objective** — one testable sentence
- **Problem** — what's wrong today, with file paths and line numbers
- **Files changed** — create/modify/delete/test with exact paths
- **Steps** — checklist items, each 2-5 minutes, with actual code
- **Definition of Done** — functional (observable outcomes) and code (verification commands)
- **Cleanliness self-check** — pattern reuse, theme tokens, naming, minimum diff, no dead code

## Size Limit

Plans are capped at ~500 lines. Larger tasks are split into multiple files with a `-phase-N` suffix, each self-contained and independently executable.

## Self-Check

Before handoff, the planner verifies:
- Every phase has checklist steps with actual code
- No placeholders (`/* TODO */`, `...`, `/* deps */`)
- Numeric constants traced to source
- Shell commands include working directory
- Type casts traced to type definitions
- Cleanliness self-check present on every phase
- Type/function names consistent across phases
