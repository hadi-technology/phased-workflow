---
name: phased-implement
description: "Execute an approved phased plan as an implementation-slice owner using TDD, checkpointed probes, targeted diagnostics, a verification pyramid, process cleanup, evidence fingerprints, and formal routing statuses. Use for phased-implement or /implement requests."
---

# Phased Implement

**Suite contract:** 4.2.0

## Overview

Execute an approved plan phase by phase. The plan tells you what to build — your job is to build it, verify it, and report honestly.

**Core principle:** Evidence before claims. Run the check, read the output, then report the result. Never say "should pass," "looks correct," or "I believe this works."

## When to use

Use when you have an approved plan to execute.

Trigger phrases: `phased-implement`, `/implement`

---

## The Process

### Step 1 — Load and review the plan

1. Read the plan file.
2. Review critically — does anything look wrong now that you're about to implement it? If you see a problem the review didn't catch, raise it before starting.
3. Extract the file list across all phases — this is your scope tracker.
4. Extract approval scope, main/branch policy, commit boundaries, check classifications, slice budget, and parallel-safety contract.
5. For external/native/long-running work, read the discovery receipt before editing. Missing load-bearing evidence returns `NEEDS_CONTEXT`.
6. Load the decision and evidence manifest. Confirm every decision ID used by the slice. Record compliance or deviation; a manifest never authorizes unreviewed scope.
7. Read the dispatched implementation tier and qualification evidence. Apply the same plan, DoD, verification, and reporting contract at every tier. If bounded evidence shows this tier cannot reliably execute the slice, return `CAPABILITY_ESCALATION`; do not lower the quality bar or continue speculative retries.

### Step 2 — Execute each phase

For each phase, follow this cycle:

**2a. Review the phase scope**

Read the phase's "Files changed" list. These are the files you will touch — no more, no less (unless you discover something, see 2c).

**2b. Implement as slice owner**

- Follow the plan's approach and precision tier. Apply Exact-tier code/contracts literally unless live evidence proves an `EMPIRICAL_DELTA`. For Structured/Intent steps, preserve pinned signatures, invariants, patterns, tests, and acceptance behavior without speculative expansion.
- Track which files you've changed. Every file in "Files changed" must be touched before the phase is done.
- If the plan's code snippets don't match what's in the codebase (e.g., line numbers shifted, function signatures changed), adapt — but stay within the plan's intent.

**2b.1 — Test-first discipline (when the phase calls for TDD)**

If the plan's phase specifies a "write failing test" step, follow the red-green discipline literally — don't shortcut to writing the implementation first.

| Step | Required action | Trap to avoid |
|---|---|---|
| RED | Write the test. Run it. Watch it fail. | Skipping the run — "I'm sure it'd fail." |
| Verify RED | Confirm the failure message matches what you expected (e.g., "function not defined" if testing a missing function). | Test errors (typo, wrong import) ≠ test fails (feature missing). If error not feature-missing, fix the test until it fails for the right reason. |
| GREEN | Write minimal code to make it pass. Run the test. Confirm it passes. | Over-engineering — adding options/flags/branches not required by the failing test. |
| REFACTOR (optional) | Clean up duplication. Re-run the test, confirm still green. | Adding behavior in refactor — keep behavior frozen, change shape only. |

If the test passes immediately on RED, you wrote it against existing behavior — fix the test, don't proceed. A test that never failed proves nothing.

For non-TDD phases (refactors, type-only changes, copy/UI tweaks where the plan doesn't specify a test), skip 2b.1 and just implement.

**2c. Handle discoveries**

When implementation reveals something the plan didn't anticipate:

| Discovery | Action |
|-----------|--------|
| Small fix, clearly in scope (e.g., adjacent import needs updating) | Fix it. Note the deviation in your phase report. |
| Related issue, out of scope (e.g., nearby function has same problem) | Document as NTH. Don't fix. Don't silently ignore. |
| Local path/signature/detail drift with unchanged architecture | Adapt, verify, report `IMPLEMENTATION_DETAIL`, continue. |
| Observed external behavior differs but architecture remains valid | Record probe evidence, return `EMPIRICAL_DELTA`, obtain plan delta, resume this slice. |
| Approved architecture cannot satisfy the objective | Stop affected slice. Return `ARCHITECTURE_WRONG`. Preserve completed independent slices. |
| Assigned model tier repeatedly fails the same reasoning/tool contract, cannot interpret verification evidence, or discovers a high-risk surface outside its qualification | Stop after bounded diagnostics. Return `CAPABILITY_ESCALATION` with failure receipts and unverified work clearly marked. |
| Credentials, dependency, service, permission, or host state blocks work | Run bounded diagnostics. Return `ENVIRONMENT_BLOCKED` with exact unblock requirement. |

**Never silently deviate from the plan.** Every deviation is either documented (small fix, NTH) or escalated (plan wrong, blocker).

**2d. Verify — classification, pyramid, and evidence gate**

Classify each plan check before running it:
- `REQUIRED` — must pass for the slice/milestone to complete.
- `CONDITIONAL` — must pass when its documented trigger applies; record N/A evidence otherwise.
- `ADVISORY` — collect when budget permits; failure or resource ceiling cannot block completion.

Use this verification pyramid:
1. **Edit loop:** smallest affected test/check after each logical edit.
2. **Slice gate:** affected subsystem tests plus relevant type/lint/behavioral checks.
3. **Milestone gate:** full suite once after slice findings close.

Do not run the full suite after every small edit. Do not downgrade a required check because it is expensive.

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

**The Iron Law:** No completion claims without valid verification evidence. Fresh execution is the default. Reuse only same-owner evidence when commit, diff, plan, tool version, configuration, inputs, and probe ID all match. Agent prose is never evidence. Cross-stage receipts never substitute for fresh QA release evidence.

Persist reusable receipts under the stable workflow run directory. Write raw output and metadata into a sibling staging directory, record command, exit code, timestamps, byte count, fingerprint, and SHA-256, verify the hash, then atomically rename to the final path. Before reuse, require the receipt and every payload to exist and reverify hashes. Missing, moved, truncated, or mismatched receipts invalidate reuse and force a rerun.

**Checkpoint expensive matrices:** assign stable probe IDs, persist one receipt per probe, support `--only <probe-id>` or equivalent, resume/replay completed probes, and run one final full matrix after targeted failures close. Never rerun a whole matrix solely to inspect one stable failure.

**Red-green for bug-fix phases**

If the phase fixes a bug, the regression test must have been red before being green. Run this sequence and record the output at each step:

```
1. With the fix applied:    <test command>            → expected PASS, record output
2. Revert the fix locally:  git stash                 (or undo the diff)
3. Run the test:            <test command>            → expected FAIL, record output
4. Restore the fix:         git stash pop
5. Run the test:            <test command>            → expected PASS, record output
```

A test that has only ever shown green is not a regression test. Skipping this means the bug was not actually proven fixed.

**Rationalization prevention** — if you catch yourself thinking any of these, stop and run the command:

| Excuse | Reality |
|--------|---------|
| "Should pass now" | Run it |
| "I'm confident it works" | Confidence ≠ evidence |
| "Same pattern as Phase 1, so it's fine" | Check it independently |
| "I'll commit and verify after" | Verify before claiming, then commit |
| "I'm tired, the test usually passes" | Exhaustion ≠ excuse |
| "Linter passed" | Linter ≠ compiler ≠ tests |
| "Partial check is enough" | Partial proves nothing |
| "The previous-phase output is right there" | Run it fresh |
| "It's obvious — the code is right there" | Obvious things break too |

**Forbidden phrases** before running verification: "should pass", "looks correct", "probably works", "all good", "should be fine", "great", "perfect", "done". Every one of these without command output in this session is a violation. State the verified result with evidence — not satisfaction.

**2e. Cleanliness self-check — MANDATORY before declaring any phase done**

Before claiming a phase is complete, run BOTH the mechanical scan (2e.1) and the conceptual checks (2e.2). If either fails, fix in this same phase before declaring done.

> **Orchestrated by Hashus — trust the row's pinned rigor, don't re-derive it.** When your dispatch carries a CSV row's `notes` with `Pattern scan:` / `Blast radius:` sections (the Hashus path), those investigations were already done and reviewed upstream by Zayneb. The self-checks below become **compliance confirmations, not fresh investigations**: for "Existing patterns reused?" (2e.2), confirm you used the reuse target the row's `Pattern scan` already pinned (`reuse <X> at file:line`) — don't go re-search the codebase for a different equivalent. For the enumeration check (2e.1.5), the row's `Blast radius` already lists the sibling sites — confirm you touched each listed sibling rather than re-deriving the set from scratch. You still fix any real miss (a pinned sibling you didn't touch); you just don't repeat the upstream search. In direct `/implement` and redha runs there's no upstream pin, so run the searches in full.

**2e.1 — Mechanical scan (run these grep commands, paste results in the phase report):**

Each is one tool call. Run all of them; paste the output. Any non-zero hit must be fixed before claiming done — this catches the obvious-class issues that QA always reports if not caught upstream.

Before running, find the right scope and commands for this project:
- **Source path glob:** check the repo's project-instructions file (`CLAUDE.md`, `AGENTS.md`, or equivalent) for the canonical source root (e.g. `app/src/`, `src/`, `packages/*/src/`). If none documented, use `git diff` unscoped and let the grep filter the noise.
- **Typecheck command:** use the command the project's instructions / `package.json` scripts / Makefile specify (e.g. `npx tsc --noEmit`, `pnpm typecheck`, `cargo check`, `mypy .`). If absent, skip the typecheck row and note "no project typecheck defined".

Scans (substitute `<src-glob>` and `<typecheck>` from above):

- `git diff` — read your own diff end-to-end
- `git diff -U0 -- '<src-glob>' | grep -nE '#[0-9A-Fa-f]{3,8}\b'` → 0 hits expected (raw hex bypasses design tokens)
- `git diff -U0 -- '<src-glob>' | grep -nE '(margin|padding|fontSize|borderRadius|gap|width|height):\s*[0-9]'` → must use design tokens / constants, not raw numbers (skip if not a styled-UI codebase)
- `git diff -U0 -- '<src-glob>' | grep -nE 'console\.log|// TODO:|// eslint-disable|debugger'` → 0 hits expected. If the project documents a separate `// DEFERRED:` (or equivalent) prefix as the legitimate backlog marker, that prefix is exempt from this scan.
- `<typecheck>`: run it. You own this whole wave's diff and there are no other implement agents in the tree (one implement agent per wave under Hashus; waves run sequentially, earlier waves already committed) — so a whole-project typecheck reflects your own work on top of committed waves, with no in-flight sibling diffs to produce false positives. A whole-project typecheck is appropriate here (in direct `/implement` and redha runs too). Wave QA re-runs whole-system checks after the wave, so this is a fast upstream catch, not the only gate.

**2e.1.5 — Enumeration check for finding-class-specific patterns (mandatory)**

The generic scans above catch raw values + dead code, but they don't catch the most common upstream-miss class: implementer touched only the cited `scope_candidates` and missed sibling sites that share the same pattern. Three finding-classes have specific enumeration requirements — run the applicable greps and paste results in the phase report.

| Finding-class trigger | Enumeration check (run before claiming DONE) | Rationale |
|---|---|---|
| **Type / interface / shape change** (you added a field, narrowed a type, renamed a property, changed a discriminated union variant) | `grep -rn '<type-name>' <src-glob>` AND `grep -rn '<changed-field-name>' <src-glob>` — read every match. For each match, verify the constructor / usage was updated. List unchanged-but-affected sites in the report. | The most common fix-loop trigger: 3 cited files updated, 13 sibling constructors silently bypass type narrowing via `Record<string, unknown>` or `as any`. Catching this upstream eliminates a 7-min fix loop. |
| **Instrumentation / observability / error-path / 4xx-5xx-status-code addition** (you added a log, metric, error handler, status-code path) | `grep -rn '<sibling-symbol>' <src-glob>` for every sibling call site of the function/handler you instrumented — e.g. if you added a 429 handler at `consumeGenerationCredit`, grep for every other place that consumes credits or hits the cap. Confirm the sibling site is either (a) already-instrumented OR (b) explicitly out-of-scope with a one-line `notes`-style reason. | The 2nd most common miss: implementer instruments one entry path, misses the read-only / preview / cache-validation entry. |
| **First-time vendor / SDK API call** (you wrote a call to an external library you haven't touched before in this codebase) | Read the SDK's type definition (or docstring) for the function. Paste the exact signature in the phase report. Verify your call site's argument order, optional params, and return-type handling match. | Catches "I wrote the args from memory" — e.g. reversed `posthog.alias(distinctId, alias)` vs `posthog.alias(alias, distinctId)`. SDK signatures aren't intuitive and shouldn't be guessed. |

If your diff has none of the three triggers, note `Enumeration check: N/A (no type / instrumentation / new-vendor-API change)` in the report. If a trigger fires and you skip the check, your phase fails the self-check.

If running in disk-first mode under Hashus / Redha orchestration, the contract pasted into your dispatch may include additional or modified scans — follow the dispatch contract verbatim.

**2e.2 — Conceptual checks**

Re-scan your own diff and answer each of these out loud in the phase report. If you haven't answered them, the phase is not done. This is the single most common source of rework — the question "is this clean, maintainable, and using existing patterns without hardcoding?" gets asked later and finds real issues. Catch them here first.

- [ ] **Existing patterns reused?** For every new component, hook, utility, constant, or helper I introduced — did I first check whether one already exists in the codebase? List the 1–3 searches you ran (`grep`, `Glob`, or file reads) and what you found. If a parallel implementation exists, replace your new one with the existing one.
- [ ] **Design tokens / constants used for every value the project centralizes?** No raw hex colors, raw spacing numbers, raw border radii, raw font sizes, raw durations, raw shadow values — wherever the project defines tokens / constants for these. If a token exists, it must be used. Document any exception with a one-line justification.
- [ ] **No hardcoded strings, numbers, or paths that belong in config/constants?** User-facing strings, magic numbers, API paths, storage keys, feature flags — check that each one lives in its canonical location, not inlined.
- [ ] **Naming matches peer conventions?** Read 2–3 nearest peer files (same directory or same type of file) and confirm your naming (component names, file names, hook names, storage keys, constant names) matches their style.
- [ ] **Minimum diff?** Every line I touched is required to meet the phase objective. No drive-by refactors, no "while I'm here" additions, no speculative abstractions for hypothetical future needs.
- [ ] **No dead leftovers?** No commented-out code, no unused imports, no stray `console.log`, no `// TODO:` (or the project's equivalent backlog marker) added to touched files, no half-finished branches.
- [ ] **No duplicated logic?** If I wrote the same thing twice (in this phase or as a copy of code elsewhere), extract or reuse.

If any check fails, fix it **before** running the DoD and declaring the phase done. Record the self-check results — pass or with-fix-applied — in the phase report.

**2f. Confirm file coverage**

Before declaring the phase done, check: was every file in "Files changed" actually changed? Missing a file means the phase is incomplete.

**2g. Phase complete**

Only after all DoD items pass with evidence. Report:
- What was changed (actual, not planned — note any deviations)
- DoD verification results with evidence
- Any NTH items discovered
- Any plan deviations and why

### Step 3 — Handle failures with bounded diagnosis

When something goes wrong during implementation:

**Test failure after your change:**
1. Read the error message completely — it often contains the answer.
2. Check what you changed against what the plan specified — did you deviate?
3. If the plan's approach caused the failure, the plan is wrong — stop and update it.
4. Fix the issue. Re-run verification. Do not move on until the phase passes.

**Same failure twice:** stop full reruns and repeated fixes. Record the stable failure signature and a falsifiable hypothesis. Run the root-cause checklist before another edit:

1. **Re-read the failure end-to-end** — the error message often names the cause. Have you actually read every line, or only skimmed the headline? Read the stack trace top-to-bottom.
2. **Trace the data path** — what runs before this? What state is set? What is *actually* being passed in vs. what the code assumes? Add a single targeted log if needed to confirm.
3. **Check the original code** — has the file changed since the plan was written? Different line numbers, signatures, or structure? Route local drift as `IMPLEMENTATION_DETAIL`; route invalidated assumptions as `EMPIRICAL_DELTA`.
4. **Bisect your change** — revert your last edit. Does the failure go away?
   - YES → the last edit caused it. Look at it again with fresh eyes.
   - NO  → the failure precedes your changes. The bug is upstream of this phase.
5. **Search for the pattern elsewhere** — has someone already solved a similar failure in this codebase? `grep` for the error message, key symbol, or stack frame. Reuse the existing solution.
6. **Re-read the assumption** — the plan's approach assumed something. Is that assumption actually true in this code? (Type shape, async ordering, lifecycle, cache invalidation, etc.)

If the checklist disproves the architecture, return `ARCHITECTURE_WRONG`. If live behavior only changes a plan assumption, return `EMPIRICAL_DELTA`. If external state blocks progress, return `ENVIRONMENT_BLOCKED`. Never repeat an unchanged full command hoping for a different result.

**Never:**
- Add a quick hack to make a test pass without understanding why it failed
- Disable or skip a failing test
- Move to the next phase with a failing DoD item
- Retry the same fix hoping for a different result

---

## Red Flags — Stop Implementing

| Red flag | What to do |
|----------|-----------|
| Plan references a file that doesn't exist | Stop. Plan is stale — needs update. |
| Code at the specified line numbers doesn't match the plan | Adapt if minor. Stop if the structure is fundamentally different. |
| A phase's approach creates a new problem in another phase's scope | Stop. Phases have a dependency the plan didn't document. |
| You're about to claim "done" but haven't run the DoD checks | Run them. Evidence before claims. |
| You're about to claim "done" but haven't run the Cleanliness self-check | Run it. This is the question that always comes back later. |
| You're tempted to skip a "trivial" DoD item | Check it. Trivial items break too. |
| You used a raw number, hex, or string where a token/constant exists | Replace it with the token. No exceptions without a documented reason. |
| You wrote a new helper/component without searching for an existing one | Stop. Search first. Reuse what's there. |
| Same failure twice | Stop full reruns. Write a hypothesis and run a targeted diagnostic. |

---

## Output Contract

Every phase report and the final report must commit to one status code. Use the codes the orchestrator's phased-workflow expects:

| Code | When to use |
|------|------------|
| `DONE` | All DoD items verified PASS with fresh evidence; cleanliness self-check passed |
| `DONE_WITH_CONCERNS` | DoD passed but you flagged scope creep, risk, file size, or other observations the orchestrator should see |
| `NEEDS_CONTEXT` | Cannot complete without information not in the plan |
| `ARCHITECTURE_WRONG` | Approved approach cannot meet the objective. Propose architecture correction and stop affected slice |
| `EMPIRICAL_DELTA` | Live evidence changes a plan assumption without invalidating architecture. Record receipt and proposed delta |
| `IMPLEMENTATION_DETAIL` | Local implementation detail drifted. Adapted and verified without changing architecture |
| `CAPABILITY_ESCALATION` | The dispatched implementation tier cannot reliably finish after bounded diagnostics. Preserve diff/receipts and identify every unverified claim |
| `ENVIRONMENT_BLOCKED` | External environment prevents progress after bounded diagnostics. State exact unblock requirement |

A report without a status code is not a valid report — pick one.

**Per-phase report:**
- **Status code** (one of the above)
- What was changed (files touched, approach taken — actual, not planned)
- Deviations from plan, with reasons
- DoD verification results — each item with command, exit code, result counts, duration, fingerprint, durable receipt path, byte count, and SHA-256. Include complete output in report for failures; store successful raw output once in its receipt
- Red-green regression evidence (bug-fix phases only) — the stash/restore output sequence
- Cleanliness self-check results — each item answered with `PASS` or `FIXED-WITH: <what you fixed>`
- NTH items discovered
- Decision-manifest compliance and deviations
- Dispatched implementation tier, runtime-resolved model ID, qualification source, and any capability-escalation evidence

**Final summary:**
- **Overall status code** (the worst code across phases — e.g., one `ENVIRONMENT_BLOCKED` phase ⇒ overall `ENVIRONMENT_BLOCKED`)
- Per-phase status codes
- Plan deviations summary
- Cleanliness fixes applied during self-check
- Unresolved items (zero on overall `DONE`; documented otherwise with the reason)
- **Auto-decisions made during execution** (any non-trivial choice between two valid implementations — option chosen + reasoning + risk taken; empty if none)
- Evidence fingerprints and checkpoint receipts
- Budget: estimated vs actual time/tool calls, plus strategy changes
- Process cleanup result for external/native commands
- Finding lifecycle: every assigned QA finding reaches `REMEDIATED`; none may be silently deferred because severity is low
- Successful-command summaries with durable receipt path/hash; full raw output once in receipt, full inline output only for failures
- Machine-readable stage telemetry required by `phased-workflow/references/execution-controls.md`

---

## Disk-first mode

When the dispatch prompt provides a `report-target=<path>` directive (or any equivalent — e.g., "Disk report path: ...", "write your full report to ..."), the **Output Contract above describes the report on disk**, not the return message.

**Behavior in disk-first mode:**

1. Write the full per-phase report and final summary to `<path>`. Store successful raw command output once in durable receipts and put evidence summaries plus receipt hashes in the report. Include complete failing output, every cleanliness check, and every NTH item. The disk report remains the index and source of truth for claims; receipts are source of truth for raw successful output.

2. Your final return message contains ONLY:

   ```
   STATUS=<code>
   report=<path>
   tldr: <≤200 token summary — what was built, key evidence pointer, file count touched>
   ```

   For non-`DONE` statuses (`ARCHITECTURE_WRONG`, `EMPIRICAL_DELTA`, `CAPABILITY_ESCALATION`, `ENVIRONMENT_BLOCKED`, `NEEDS_CONTEXT`, `DONE_WITH_CONCERNS`), include one extra line:

   ```
   concerns: <N> findings, see report     # or: blocked: <one-line cause>
   ```

3. Returning more than ~300 tokens of inline text is a contract violation. The disk file is the source of truth; the return message is just the index. The orchestrator (Hashus) has its own context to protect — dumping the full report inline AND on disk doubles its context cost without adding any auditable value.

**Verifying disk-first mode is in effect:** if the dispatch prompt mentions a path under `plans/run-reports/` or instructs you to write a report to a specific file, you are in disk-first mode. When in doubt, the orchestrator checks `test -s <path>` after your return — an empty or missing file is treated as `ENVIRONMENT_BLOCKED` regardless of your status code.

**When disk-first mode is NOT in effect** (no `report-target` directive in the dispatch prompt): use the inline format described in the **Output Contract** above. This is the default for direct user invocations of `/implement`.

---

## Process lifecycle and pre-authorization

For commands that can spawn workers, servers, sockets, or child processes:
- Record command, PID/process group, temporary paths, sockets, and cleanup owner before waiting.
- On cancellation, send interrupt to the process group, wait a bounded interval, escalate termination only for owned processes, then verify no owned process/socket/temp secret remains.
- Never kill unrelated processes by name alone.
- Preserve an interruption receipt so the slice can resume without repeating completed work.

Honor recorded execution policy. If main and milestone commits were pre-authorized, continue and commit at those boundaries without reopening approval. Never infer push, PR, force-push, destructive reset, or external publication authority.

For work lasting more than 30 minutes, report current slice, elapsed time, completed gates, stable blocker if any, and next action. Exceeding the slice budget triggers strategy reassessment, not silent continuation.

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
