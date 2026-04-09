# phased-workflow

The orchestrator. Dispatches sub-agents for each stage and coordinates the pipeline. Never writes plans, implements code, or performs QA itself.

## Triggers

`/pw`, `pw:`, `phased-workflow`

## What It Does

1. Dispatches `phased-plan` sub-agent to write the plan
2. Dispatches `phased-review` sub-agent to review the plan
3. Fixes review findings, re-reviews if substantial
4. Presents the plan to the user and waits for approval
5. Dispatches `phased-implement` sub-agent to execute the plan
6. Dispatches `phased-qa` sub-agent to verify the work
7. Fixes QA findings and presents the final report

## Inputs

A task description. Can be as simple as a sentence or as detailed as a requirements doc.

## Outputs

- A plan file in `plans/`
- Implemented code changes
- A final report with per-phase results, QA findings, and verification evidence

## Approval Gate

The orchestrator stops after Stage 2 (Review) and presents:
- Plan file path
- Phase list with objectives
- Review findings and fixes

It waits for explicit approval before proceeding to implementation. Recognized approval phrases: "approved", "go ahead", "lgtm", "do it", "implement it".

Questions, feedback, or silence are not approval — the plan is updated and re-presented.

## Multi-File Plans

If the planner produces multiple plan files, the orchestrator runs the full pipeline (review → approve → implement → QA) on the first file before proceeding to the next.

## Shortcut

If you have a previously-approved plan file, you can skip directly to implementation:

```
implement plans/2026-04-09-feature.md
```
