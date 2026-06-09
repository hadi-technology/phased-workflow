---
name: phased-qa
version: "2.3.0"
description: "Post-implementation QA. Verifies completed work against the plan's objectives and DoD — runs the verification gate, reads code, audits cleanliness, checks regression-test red-green. Evidence before claims. Triggers: phased-qa, /pqa, pqa:"
metadata:
  tags: qa, verification, phased-plan, validation, sub-agent
---

# Phased QA

## Overview

The implementation is done. Now verify it actually works — against the plan, against the codebase, against reality.

**Core principle:** Evidence before claims. Run the command, read the output, check the code. Never say "should pass" or "looks correct." If you haven't verified it in this session, you cannot claim it passes.

**QA is not testing.** Testing checks "does the code execute correctly?" QA checks "did we build what the plan said, does it integrate cleanly, and is it production-ready?" Run both. Report separately.

## When to use

Use after implementation is complete and you need a dedicated QA pass against the plan.

Trigger phrases: `phased-qa`, `/pqa`, `pqa:`

---

## The Process

### Step 1 — Load plan and extract criteria

1. Get the plan file path (ask if not provided).
2. Parse each phase and extract: objectives, functional DoD, code DoD, and any specified verification commands.
3. Build a checklist. Every DoD item becomes a line item to verify.

### Step 1.5 — Restate the phase intent

Before running a single command, write one sentence per phase capturing what the implementer was supposed to deliver. This is your reference frame for everything that follows — does the actual code match the stated intent?

- If you cannot restate a phase's intent from the plan, the plan was vague. Flag it as a finding (the plan-writing stage failed, not the implementation).
- Carry the restated intent into the per-phase QA section so the orchestrator can see what you reviewed against.

### Step 2 — Run the verification gate

**Exhaustive-scan principle:** audit the ENTIRE diff in this single QA pass. Do NOT stop at the first 1-3 issues. The fix loop has a finite budget (typically 2 rounds) — if you surface 5 findings now, the implementer fixes all 5 in one fix dispatch and Round 2 confirms. If you surface only the most obvious 1-2, Round 2 catches the rest, costing extra dispatches and risking abandonment when the budget exhausts.

Beyond the per-DoD verification below, also scan the entire diff for: raw hex / hardcoded numbers in styles, dead `console.log` / `// TODO:` / `// eslint-disable` / `debugger`, files modified outside the plan's scope, dead imports, hardcoded strings/paths that should be constants, naming inconsistencies vs nearest peer files. Report ALL findings, severity-tagged (`high` blocks acceptance; `medium` should be fixed; `low` is NTH).

Before claiming any DoD item passes, run this five-step gate. Skipping any step is not verification — it is a false claim.

```
FOR each DoD item:
  1. IDENTIFY: What command or code read proves this claim?
  2. RUN:      Execute the command (fresh in this session — never cached, never copied from a previous run)
  3. READ:     Full output — exit code, count, errors, warnings
  4. COMPARE:  Does the output literally confirm the claim?
                 - YES → record as PASS with the exact output
                 - NO  → record as FAIL with the exact output
  5. THEN:     Make the claim.

Skip any step = false claim.
```

**The Iron Law:** No QA pass claims without fresh verification evidence in this session. If you have not run the command, you cannot claim it passes — and "looks correct" is not running the command.

**Common verification commands** (use the project's actual commands — read project instructions / `package.json` scripts / Makefile to find them):
| DoD type | Verification |
|----------|-------------|
| "No X remains in codebase" | `grep` / `git grep` — show zero hits |
| "Type check passes" | Project's typecheck command (e.g. `npx tsc --noEmit`, `pnpm typecheck`, `cargo check`, `mypy .`) — show exit 0 |
| "Tests pass" | Project's test runner — show pass count, zero failures |
| "Lint passes" | Project's lint command — show exit 0 |
| "Component uses pattern X" | Read the file, confirm the pattern |
| "No regressions" | Run full test suite, compare to baseline |

**Forbidden phrases** before running the command in this session: "should pass", "looks correct", "probably works", "great", "perfect", "all good", "same as before". These are satisfaction, not verification. State the verified result with evidence — exit code, counts, exact output.

**Rationalization prevention:**
| Excuse | Reality |
|--------|---------|
| "Should pass now" | Run it |
| "I changed nothing, same as before" | Run it fresh |
| "Linter passed" | Linter ≠ compiler ≠ tests |
| "Implementer's report shows it passing" | Re-run independently — agent reports are not evidence |
| "I'm tired, the suite usually passes" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |

### Step 3 — Read the code

Verification commands catch functional issues. Code reading catches quality issues.

For each phase, read every changed file and check:

**3a. Plan compliance**
- Does the code match what the plan said to build? Not more, not less.
- Were the exact patterns specified in the plan followed?
- Are there changes the plan didn't mention? (Scope creep = finding)

**3b. Numeric constants — verify against source**
- For any introduced constant (heights, timeouts, thresholds), read the source that determines the real value.
- Flag constants that don't match actual styles/theme/layout.
- Flag fixed values used for variable-sized content.

**3c. Code completeness — no placeholders**
- No `/* deps */`, `/* TODO */`, `...`, or stub implementations.
- No empty dependency arrays that should have entries.
- Every code change is production-ready.
- Type casts (`as SomeType`, `as unknown as SomeType`) are justified — read the type definition and confirm the types are actually compatible without the cast. Flag unsafe casts that hide errors.

**3d. Optimization effectiveness — verify preconditions**

| Optimization | What to check in the actual code |
|-------------|--------------------------------|
| `React.memo` | Read the parent. Does it pass stable props? Flag inline arrows without `useCallback`. |
| `useCallback` | Deps array correct and complete? Flag missing deps (stale closure) or unnecessary deps. |
| List virtualization | Height strategy matches actual component layout? Flag mismatches. |

**3e. Adjacent code — scan for related issues**
- Check ±20 lines around each change site.
- Flag related issues in the same category (e.g., another inline function the phase should have extracted, another unstable prop nearby).
- Report as low-severity NTH findings.

**3f. Breaking interface changes**
- If a phase made a previously-optional field required or removed a field from a shared interface, check that all test files constructing that interface were updated.
- Scan `**/__tests__/**` and `**/*.test.*` for literal constructions of the changed interface.
- Flag any test file that constructs the interface but wasn't updated (TypeScript may or may not catch this depending on test config).

**3g. Hook migration correctness**
- If a phase migrated from a direct API call to a React hook, verify each migration site:
  - No early returns, conditionals, or loops precede the hook call (Rules of Hooks violation).
  - The hook is not inside a callback, `useMemo`, `useEffect`, or nested function.
  - Flag violations — these will crash at runtime even if TypeScript compiles.

**3h. Cleanliness audit — are changes clean, maintainable, and using existing patterns?**

This is a mandatory QA gate. It catches the issues that always surface when this question is asked later.

For every changed file, verify:

- **Existing patterns reused?** For every new component, hook, utility, constant, or helper the implementation introduced — search the codebase for an existing equivalent. If one exists and wasn't used, flag as high-severity.
- **Design tokens / constants used everywhere the project centralizes them?** Scan the diff for raw hex colors, raw spacing numbers, raw border radii, raw font sizes, raw durations, raw shadow values — wherever the project defines tokens / constants for these. If a token / constant / config value covers the same semantic meaning, flag every raw value as medium-severity.
- **No hardcoded strings, numbers, or paths that belong in config/constants?** User-facing strings, magic numbers, API paths, storage keys — check each one lives in its canonical location.
- **Naming matches conventions?** Read 2–3 nearest peer files and compare naming of components, hooks, constants, storage keys, style keys. Flag divergences.
- **Minimum diff?** Are there changes that go beyond the plan's stated objective? Flag scope creep.
- **No dead leftovers?** No commented-out code, no unused imports, no stray `console.log`, no orphaned style keys, no `// TODO:` (or the project's equivalent backlog marker) introduced in touched files.
- **No duplicated logic?** Same pattern written twice (within the diff or as a copy of code elsewhere) should be extracted or reusing an existing abstraction.

Report cleanliness issues as findings with evidence (file path + the offending line), the same as any other QA finding.

**3i. Regression test red-green verification (bug-fix phases only)**

If the phase fixed a bug, the implementer should have produced evidence the test was red before being green. Verify:

- Look in the implementer's phase report for the `git stash → fail → restore → pass` sequence with output for each step.
- If absent, run it yourself: revert the fix locally (`git stash` or undo), run the test, confirm FAIL output, restore (`git stash pop`), confirm PASS output.
- A regression test that was never red is not a regression test — flag as high severity. The bug was not actually proven fixed.

### Step 4 — Write findings

For every issue:

1. **Phase** — which phase it belongs to
2. **Severity** — critical / high / medium / low
3. **Evidence** — the command output, file path, or code that proves the issue
4. **Remediation** — exact file path + concrete patch suggestion (do NOT implement — report only)

**Do not fix unless explicitly asked.** Report findings with enough detail that someone else can fix them.

---

## Red Flags — Common QA Failures

| Failure | What to do instead |
|---------|-------------------|
| Trusting test output from a prior session | Run tests fresh in this session |
| Trusting the implementer's "DoD passed" report | Re-run the commands independently — agent reports are not evidence |
| "Looks correct" / "should pass" / "great" / "perfect" before running the check | Forbidden vocabulary. State the verified result with evidence — not satisfaction |
| Skipping a DoD item because "it's obvious" | Verify every item — obvious things break too |
| Marking pass because tests pass | Tests ≠ QA. Tests pass but DoD may not be met |
| Marking a bug-fix phase pass without the regression test red-green sequence | Run the stash/restore yourself — a green-only test isn't a regression test |
| Omitting low-severity findings | Report everything. Low-severity issues compound |
| Accepting "close enough" | The DoD says what it says. Met or not met |

---

## Output Contract

### Per-Phase QA

For each phase:
- Phase name
- Objectives (from plan)
- DoD (functional + code)
- Verification commands run + output summary
- Test results (separate from QA)
- Findings (severity + evidence + remediation)
- Phase status: `pass` or `fail`

### Final Summary

- Overall QA status: `pass` or `fail`
- Total findings by severity
- Open issues grouped by phase
- Verification evidence summary (test counts, TypeScript result, lint result)

---

## Disk-first mode

When the dispatch prompt provides a `report-target=<path>` directive (or any equivalent — e.g., "Disk report path: ...", "write your full report to ..."), the **Output Contract above describes the report on disk**, not the return message.

**Behavior in disk-first mode:**

1. Write the full Per-Phase QA and Final Summary (everything described in **Output Contract** above) to `<path>` using the Write tool. The disk file is the source of truth — it must contain every Verification Gate row (claim → command → output snippet), every finding with severity + evidence + remediation, exactly as the contract above specifies. The Iron Law, the verification gate, and the "report findings with enough detail that someone else can fix them" rule all apply to the disk report's content unchanged. None of that detail goes in the return message.

2. Your final return message contains ONLY:

   ```
   STATUS=<code>
   report=<path>
   tldr: <≤200 token summary — what was verified, headline result, finding count by severity if any>
   ```

   For `DONE_WITH_CONCERNS`, include one extra line:

   ```
   concerns: <N> findings, see report
   ```

3. Returning more than ~300 tokens of inline text is a contract violation. The disk file is the source of truth; the return message is just the index. The orchestrator (Hashus) has its own context to protect — dumping the full report inline AND on disk doubles its context cost without adding any auditable value.

**Verifying disk-first mode is in effect:** if the dispatch prompt mentions a path under `plans/run-reports/` or instructs you to write a report to a specific file, you are in disk-first mode. When in doubt, the orchestrator checks `test -s <path>` after your return — an empty or missing file is treated as `BLOCKED` regardless of your status code.

**When disk-first mode is NOT in effect** (no `report-target` directive in the dispatch prompt): use the inline format described in the **Output Contract** above. This is the default for direct user invocations of `/pqa`.

---

## Wave-mode dispatches (invoked by Hashus orchestrator)

When the dispatch prompt names `mode: wave` (or sends a `standard-verify-list` / `critical-reverify-list` / asks for whole-system checks across multiple task ids), you are running **wave-mode QA** for the Hashus orchestrator. This expands the per-phase QA contract above with three additional responsibilities:

### 1. Standard-tier acceptance + rigor verification (the verification — there is no per-task QA for these rows)

The dispatch will provide a `standard-verify-list` of task ids whose per-task QA was skipped because Zayneb classified them `standard` (the default tier — only `critical` rows get per-task QA dispatched). For each row on this list, the wave QA pass IS the verification — there is no second pass coming. Treat it accordingly:

- Read the implementer's disk report (path provided in the dispatch — typically `plans/run-reports/<dir>/wave-<N>/<task-id>-implement.md`).
- Verify each `acceptance_criteria` against the actual code/diff (not the implementer's claim — run the greppable / testable / observable command yourself and paste evidence).
- Verify each rigor section's contract was honored:
  - `Pattern scan: Decision: reuse <X>` → confirm the diff imports/uses `<X>`. Quote the import line.
  - `Blast radius: Verdict: systemic` → confirm the diff touches every sibling listed. Run `git diff --name-only` against the wave's commit, cross-reference to `scope_candidates`.
  - `Multi-layer:` named layers → grep / read each guard. Paste the matching line.
  - `Pre-existing state:` named mechanism → confirm migration / recency filter / cleanup-on-read exists in the diff. Paste the path + line.
- Findings against a standard-tier row are reported under that row's id in your wave report so the orchestrator can route the row back to the per-task fix loop with both rounds of its budget intact.

### 2. Critical-tier independent re-verification (belt + suspenders)

The dispatch will provide a `critical-reverify-list` of task ids whose per-task QA already ran (and passed). For each row on this list:

- Run the per-task Verification Gate independently (acceptance_criteria + rigor sections) **without** reading the per-task QA's report — you are an independent second pair of eyes on the same diff.
- If your independent check disagrees with what the per-task QA concluded, treat the disagreement itself as a finding and report it under that row's id. The orchestrator will route the disagreement back to the per-task fix loop.

### 3. Whole-system checks (always run at wave level)

These checks live exclusively in wave-mode QA — per-task QA does not run them (cost amortization). Run all four for every wave, using the project's actual commands (look up the typecheck / test / lint / backlog-marker commands from project instructions, `package.json` scripts, Makefile, or equivalent):

- **Typecheck** (e.g. `npx tsc --noEmit`, `pnpm typecheck`, `cargo check`, `mypy .`) — must exit 0. If non-zero, identify which task in the wave introduced the type error (read the touched files; correlate with each task's `scope_candidates`) and report the finding under the introducing task's id.
- **Tests** (project's test command, optionally scoped to wave's test files for very large suites — the dispatch prompt may specify scope) — must pass. Failed tests routed to the originating task.
- **Lint** (project's lint command, scoped to wave's touched files) — must exit 0 against the project's lint config.
- **Backlog-marker scan** — per the project's release DoD, scan touched paths for any committed `// TODO:` (or the project's equivalent prohibited backlog marker). Must be 0 hits. Any new `TODO:` in the wave's diff is a finding routed to the introducing task. If the project documents a separate `// DEFERRED:` (or equivalent) prefix as the legitimate post-release backlog marker, that prefix is exempt from this scan.

If the project's instructions don't define one of these commands, note that in the report and skip the check rather than inventing a command.

### Wave-mode disk report layout

Your wave-qa.md disk report sections, in order:

```
# Wave <N> QA Report

## Verification Gate evidence
<per-task acceptance + rigor verification, grouped by task id, with command + output snippets>

## Whole-system check results
<tsc / jest / eslint / TODO grep — full output paste of any failure, summary if all pass>

## Standard-tier verification (from standard-verify-list)
<per-task results — pass or finding-with-route-target>

## Critical-tier independent re-verification (from critical-reverify-list)
<per-task results + any disagreement-with-per-task-QA notes>

## Cross-wave regression (structured blast-radius re-checking per Hashus 4d step 5)
<per-dependent DoD command + result>

## Findings summary
<all findings by severity, each tagged with task id and route target (per-task fix loop / cross-wave fix loop)>
```

The inline return follows the disk-first format (STATUS + report path + tldr + concerns count). All evidence and findings live on disk.

---

## Style Contract — caveman prose

Reports are operational artifacts, not essays. Every line carries a fact. This contract applies to all prose in disk reports, inline reports, tldrs, and findings.

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
- Command output (grep, tsc, jest, lint, git) — paste raw
- Error traces and stack traces — full detail
- BLOCKED context — full detail required for unblocking
- Diff snippets quoted as evidence — verbatim
- Code blocks in plans / fixes — verbatim, idiomatic, with comments only when WHY is non-obvious

**Examples:**

BAD (verbose):
> The implementation successfully reuses the existing `TierConfig` pattern by importing it from the tiers module. This matches the Pattern scan decision noted in the row's notes.

GOOD (caveman):
> Pattern reuse: `TierConfig` from `./tiers`. billing.ts:14.

BAD (verbose):
> The acceptance criterion was verified by running the grep command, which returned the expected output showing the new symbol is present in the file.

GOOD (caveman):
> Acceptance 1: PASS.
> ```
> $ grep 'newSymbol' src/file.ts
> src/file.ts:42:export const newSymbol = ...
> ```

BAD (verbose):
> The TypeScript compilation appears to have completed successfully with no errors detected, suggesting the implementation is type-safe.

GOOD (caveman):
> tsc: 0 errors.

**Self-check before submitting:**
- Any sentence with 2+ commas → rewrite
- Any sentence containing "the/a/an" twice → rewrite
- Any paragraph with 3+ sentences → split into bullets, drop filler
- Any 5-line section where you can't point to which lines carry NEW facts → half is fluff, cut it
