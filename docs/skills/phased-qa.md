# phased-qa

Verifies completed work against the plan's objectives and Definition of Done. Reports findings — does not fix them.

## Triggers

`/pqa`, `pqa:`, `phased-qa`

## What It Does

1. Loads the plan and extracts all DoD criteria
2. Runs every verification command fresh (never uses cached results)
3. Reads every changed file and checks for quality issues
4. Writes findings with severity and evidence

## Inputs

A plan file path (asks if not provided).

## Outputs

Per-phase QA report:
- Objectives from plan
- DoD items with pass/fail status and evidence
- Findings with severity, evidence, and remediation suggestions
- Phase status: `pass` or `fail`

Final summary:
- Overall QA status
- Total findings by severity
- Open issues grouped by phase
- Verification evidence summary

## What It Checks

**DoD verification** — runs every command from the plan's DoD sections. Records output. Compares against expected results.

**Plan compliance** — code matches what the plan specified. No more, no less. Unplanned changes are flagged as scope creep.

**Numeric constants** — verifies introduced constants match actual source values.

**Code completeness** — no placeholders, no stubs, no empty dependency arrays that should have entries.

**Optimization effectiveness** — checks that `React.memo`, `useCallback`, and virtualization preconditions hold in the actual code.

**Adjacent code** — scans 20 lines around each change site for related issues.

**Cleanliness audit** — pattern reuse, theme tokens, hardcoded values, naming conventions, minimum diff, dead code, duplicated logic. Cleanliness findings are reported with the same severity system as functional findings.

## Important

The QA agent does not fix issues. It reports findings with enough detail that someone else can fix them. The orchestrator handles fixes after receiving the QA report.
