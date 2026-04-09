# phased-implement

Executes an approved plan phase by phase. Follows the plan, verifies each phase, and reports honestly.

## Triggers

`/implement`, `phased-implement`

## What It Does

1. Loads the plan and reviews it critically before starting
2. For each phase:
   - Reviews the scope and files to change
   - Implements using plan code as starting point, adapting to actual code state
   - Handles any discoveries (documents, escalates, or fixes as appropriate)
   - Runs every DoD verification command and records output
   - Runs the mandatory cleanliness self-check
   - Confirms all files in "Files changed" were touched
3. Reports per-phase results with evidence

## Inputs

An approved plan file path.

## Outputs

Per-phase report containing:
- What was changed (actual, not planned)
- Deviations from plan with reasons
- DoD verification results with command output
- Cleanliness self-check results
- NTH items discovered

## Discovery Handling

| Discovery | Action |
|-----------|--------|
| Small fix, clearly in scope | Fix it, document the deviation |
| Related issue, out of scope | Document as NTH, don't fix |
| Plan is wrong | Stop, update plan, continue from updated version |
| Blocker | Stop, report, don't guess |

## Cleanliness Self-Check

Mandatory before declaring any phase done:

- Existing patterns reused (with evidence of search)
- Theme tokens used for every visual value
- No hardcoded strings/numbers/paths that belong in config
- Naming matches peer conventions
- Minimum diff — no drive-by refactors
- No dead code, unused imports, stray console.logs
- No duplicated logic

## Failure Handling

- Test failures: read the error, check for plan deviations, fix the root cause
- 3+ failed fix attempts on the same issue: stop and re-analyze or escalate
- Never: hack a test to pass, disable a test, skip a DoD item, move on with a failing phase
