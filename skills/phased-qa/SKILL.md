---
name: phased-qa
description: "Run post-implementation QA against a phased plan using exhaustive Round 1 review, bounded named-finding closure, risk-based integration checks, evidence fingerprints, checkpointed probes, and process-cleanliness verification. Use for phased-qa, /pqa, or pqa: requests."
---

# Phased QA

**Suite contract:** 4.1.0

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
4. Read `qa-round`. Default to `1`. For Round 2, load Round 1 finding IDs and closure evidence requirements.
5. Load the decision and evidence manifest. Treat it as minimum coverage, not a trust boundary.

### Step 1.5 — Restate the phase intent

Before running a single command, write one sentence per phase capturing what the implementer was supposed to deliver. This is your reference frame for everything that follows — does the actual code match the stated intent?

- If you cannot restate a phase's intent from the plan, the plan was vague. Flag it as a finding (the plan-writing stage failed, not the implementation).
- Carry the restated intent into the per-phase QA section so the orchestrator can see what you reviewed against.

### Step 2 — Run the verification gate

**Round 1 exhaustive-scan principle:** audit the ENTIRE diff. Do not stop at the first findings. Report every verified finding regardless of severity and assign a stable finding ID.

**Round 2 closure principle:** verify named Round 1 finding IDs and their affected regression surface only. Do not restart whole-diff QA. Documentation/format-only remediation with unchanged executable proof may use targeted owner evidence. Executable behavior, test assertions, shared interfaces, public contracts, acceptance evidence, integration paths, and high-risk remediation require two independent targeted closure lenses regardless of severity. Report and fix any new verified defect in that surface. Tag a new critical/high regression `ROUND2-REGRESSION`; a third independent pass is limited to its closure.

In Round 1, scan the entire diff for raw hex/hardcoded style values, dead logging/backlog markers/debuggers, out-of-scope files, dead imports, misplaced constants, and naming drift. Report all severities. Every verified finding must be fixed before final acceptance.

Classify each planned check before execution:
- `REQUIRED` — must pass.
- `CONDITIONAL` — must pass when its trigger applies; otherwise record N/A evidence.
- `ADVISORY` — collect when budget permits; failure or a documented resource ceiling cannot block acceptance.

Use the verification pyramid: smallest affected check during fix loops, affected subsystem gate after a finding batch, and full suite once at the final milestone gate. Do not rerun a full qualification matrix to diagnose one probe.

Before claiming any DoD item passes, run this five-step gate. Skipping any step is not verification — it is a false claim.

```
FOR each DoD item:
  1. IDENTIFY: What command or code read proves this claim?
  2. RUN:      Execute the command, or reuse an exact fingerprint match
  3. READ:     Full output — exit code, count, errors, warnings
  4. COMPARE:  Does the output literally confirm the claim?
                 - YES → record as PASS with the exact output
                 - NO  → record as FAIL with the exact output
  5. THEN:     Make the claim.

Skip any step = false claim.
```

**The Iron Law:** No QA pass claims without valid evidence. Standard QA remains fresh and exhaustive. Implementer reports or receipts never substitute for fresh release-blocking QA evidence. Same-owner checkpoint reuse requires exact commit, diff, plan, tool, configuration, input, and probe fingerprints plus a durable receipt whose payload hashes reverify.

For expensive matrices, use stable probe IDs, per-probe receipts, `--only` or equivalent targeted runs, and resume/replay. Run one final full matrix after targeted failures close.

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

**3j. Behavioral verification for stateful/security DoD — execute, don't grep**

For RLS/auth/migration/runtime DoD, a grep that a symbol/policy exists proves the edit, not the behavior. Run it as the target actor and assert the result:
- RLS: `SET ROLE anon; SELECT …` — confirm rows returned/denied as intended. A GRANT does NOT grant row visibility under RLS; only a POLICY does — verify the policy.
- SECURITY DEFINER guard: call as a non-owner, confirm it raises.
- Also confirm any security fix covered the bug CLASS (grep siblings), not just the cited site.

A DoD that passes when the fix is wrong = vacuous green = high-severity finding.

### Step 4 — Write findings

For every issue:

1. **Phase** — which phase it belongs to
2. **Severity** — critical / high / medium / low
3. **Evidence** — the command output, file path, or code that proves the issue
4. **Remediation** — exact file path + concrete patch suggestion (do NOT implement — report only)
5. **Finding ID** — stable across fix and closure rounds
6. **Lifecycle** — `OPEN`, remediation required, then `CLOSED` only with closure evidence

**Do not fix unless explicitly asked.** Report findings with enough detail that someone else can fix them.

Round 2 reports every Round 1 finding ID as `OPEN`, `REMEDIATED`, or `CLOSED`, with remediation and closure evidence. Severity never makes a verified finding optional. Final acceptance requires zero open findings.

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
- QA round: `1` or `2`
- Total findings by severity
- Named-finding closure table
- Open issues grouped by phase
- Verification evidence summary (test counts, TypeScript result, lint result)
- Evidence fingerprints and checkpoint receipts
- External/native process cleanup audit
- Estimated vs actual time/tool-call budget
- Successful-command summaries: command, exit code, counts, duration, fingerprint, durable receipt path, byte count, and SHA-256. Store raw success output once; retain complete failing output in the report and receipt
- Machine-readable stage telemetry required by `phased-workflow/references/execution-controls.md`

---

## Disk-first mode

When the dispatch prompt provides a `report-target=<path>` directive (or any equivalent — e.g., "Disk report path: ...", "write your full report to ..."), the **Output Contract above describes the report on disk**, not the return message.

**Behavior in disk-first mode:**

1. Write the full Per-Phase QA and Final Summary to `<path>`. Include every Verification Gate row as claim → command → result summary → durable receipt hash/path, and every finding with severity, lifecycle, evidence, and remediation. Store successful raw output once in receipts; include complete failing output in the report and receipt. The Iron Law and remediation rules remain unchanged.

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

**Verifying disk-first mode is in effect:** if the dispatch prompt mentions a path under `plans/run-reports/` or instructs you to write a report to a specific file, you are in disk-first mode. When in doubt, the orchestrator checks `test -s <path>` after your return — an empty or missing file is treated as `ENVIRONMENT_BLOCKED` regardless of your status code.

**When disk-first mode is NOT in effect** (no `report-target` directive in the dispatch prompt): use the inline format described in the **Output Contract** above. This is the default for direct user invocations of `/pqa`.

---

## Wave-mode dispatches (invoked by Hashus orchestrator)

When the dispatch prompt names `mode: wave`, you are the **single fresh QA agent for an entire wave** under Hashus. There is exactly one implement agent and one QA agent per wave — no per-task QA, no second pass coming. You verify **every row in the wave**. The implementer's full report for the wave is at `plans/run-reports/<dir>/wave-<N>/implement.md`; your report goes to `plans/run-reports/<dir>/wave-<N>/qa.md`.

### Trust the upstream plan — verify compliance, don't re-review design

The row was investigated and the plan was reviewed upstream by Zayneb (`phased-review` already validated design quality, pattern choices, and blast radius against live code). In wave mode your job is **build-vs-spec verification + compliance with the row's pinned rigor** — NOT a re-review of whether the plan was good. Concretely, in wave mode:

- **Skip Step 1.5's "flag the plan as vague" finding-class.** Plan quality is Zayneb's domain and already gated. If a row cannot be verified because its `acceptance_criteria` are unrunnable, route `ARCHITECTURE_WRONG` or `EMPIRICAL_DELTA`; do not author an implementation finding.
- **Pattern reuse = compliance check, not a re-search.** The row's `Pattern scan` already decided "reuse `<X>` at `file:line`." Confirm the diff actually used `<X>` (quote the import/call line). Do NOT go re-search the codebase for some *other* equivalent the plan "should have" used — that decision is already made and reviewed.
- **Blast radius = confirm coverage, not re-enumerate from scratch.** The row's `Blast radius` already lists the siblings. Confirm the diff touched each listed sibling; you don't need to re-derive the sibling set.

This removes the triple-derivation (Zayneb planned it, the implementer self-checked it, and a naive QA would re-derive it a third time). You still catch real drift — an implementer who ignored the pinned decision — because that's a *compliance* failure, which you DO report.

### What you verify (every row in the wave)

1. **Acceptance criteria + rigor, per row.** For each row, run its acceptance criteria against the actual code/diff (not the implementer's claim) — lead with the behavioral/observable check, use any grep as a cheap pre-filter — and confirm each rigor section's contract was honored:
   - `Pattern scan: Decision: reuse <X>` → confirm the diff uses `<X>`. Quote the line.
   - `Blast radius: Verdict: systemic` → confirm the diff touches every listed sibling. `git diff --name-only`, cross-reference `scope_candidates`.
   - `Multi-layer:` named layers → grep/read each guard. Paste the line.
   - `Pre-existing state:` named mechanism → confirm migration / recency filter / cleanup-on-read exists. Paste path + line.
   - Rows whose `qa_tier` is `critical` (named by id in the dispatch) get a **deeper re-derivation** of their load-bearing logic — re-run the behavioral check, trace the contract end-to-end, don't accept a passing grep as proof of correctness. `standard` rows get the normal verification above.
2. **Coherence of the assembled wave.** Exercise the integrated behavior as a user would (run it / trace the main path). A wave where each row greps green but the whole feels broken is a `DONE_WITH_CONCERNS`, not a pass. This is the check that catches "works on paper, broken in practice."
3. **Whole-system checks** (once per wave — use the project's actual commands; skip + note any not defined):
   - **Typecheck** — exit 0. If non-zero, identify which row introduced it (correlate touched files to `scope_candidates`) and report under that row's id.
   - **Tests** — pass. Failures routed to the originating row.
   - **Lint** (scoped to the wave's touched files) — exit 0.
   - **Backlog-marker scan** — 0 committed `// TODO:` (or the project's prohibited marker) in the wave's diff. A documented `// DEFERRED:`-style marker is exempt.
4. **Integration across the wave's rows** — interactions a single-row view can't see (a hook from row A consumed by a screen from row B; a provider added by row A that must wrap row B's component).
5. **Cross-wave regression — structured blast-radius re-checking** (this is Hashus wave-QA check 5; a regression here routes to Hashus's cross-wave handling, not the wave fix loop):
   1. List files changed this wave: `git diff --name-only <wave-baseline>..` (working tree — the wave isn't committed yet).
   2. For each changed file F, find every earlier-committed-wave file that imports F or shares a sibling pattern (`grep -r` + earlier rows' Blast-radius notes).
   3. Re-run the DoD command for every dependent. Every dependent, not a sample.
   4. Any dependent whose DoD previously passed but now fails = cross-wave regression.

Row-scoped findings (checks 1–4) route to Hashus's **wave fix loop**. Tag any cosmetic-only finding `[DOC-ONLY]` so Hashus can batch it on the fast path.

### Wave-mode disk report layout

Your `qa.md` disk report sections, in order:

```
# Wave <N> QA Report

## Per-row verification (acceptance + rigor)
<grouped by row id, with command + output snippets; compliance checks for Pattern scan / Blast radius / Multi-layer / Pre-existing state>

## Coherence of the assembled wave
<what you exercised end-to-end; pass or DONE_WITH_CONCERNS with what felt broken>

## Whole-system check results
<typecheck / tests / lint / backlog-marker grep — full output paste of any failure, summary if all pass>

## Integration across the wave's rows
<cross-row interactions checked; N/A — solo wave if wave-size 1>

## Cross-wave regression (structured blast-radius re-checking)
<per-dependent DoD command + result>

## Findings summary
<all findings by severity, each tagged with row id and route (wave fix loop / cross-wave handling); [DOC-ONLY] tags where applicable>
```

The inline return follows the disk-first format (STATUS + report path + tldr + concerns count). All evidence and findings live on disk.

---

## Operational boundaries

- Verify owned child processes, sockets, temporary credentials, and qualification artifacts were cleaned up or intentionally retained with an owner.
- Never kill unrelated processes by broad name matching.
- After two identical failures, stop full reruns. Record failure signature, write a hypothesis, and run a targeted diagnostic.
- Exceeding the QA budget triggers narrower evidence collection or targeted replay, not silent open-ended execution.
- For QA lasting more than 30 minutes, report current gate, elapsed time, completed finding IDs, blocker, and next action.

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
