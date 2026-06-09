---
name: phased-implement
version: "1.2.0"
description: "Execute an approved phased plan. Follow the plan, track files, run the verification gate, run cleanliness self-check, report with formal status codes. Evidence before claims. Triggers: phased-implement, /implement"
metadata:
  tags: implementation, execution, verification
---

# Phased Implement

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

### Step 2 — Execute each phase

For each phase, follow this cycle:

**2a. Review the phase scope**

Read the phase's "Files changed" list. These are the files you will touch — no more, no less (unless you discover something, see 2c).

**2b. Implement**

- Follow the plan's approach. The plan has implementation-ready code — use it as your starting point, but adapt to what you actually find in the code.
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
| Plan is wrong (e.g., approach won't work, file doesn't exist) | **Stop.** Update the plan file with what you found. Then continue from the updated plan. Call out the delta in the final report. |
| Blocker (e.g., missing dependency, unclear requirement, persistent failure) | **Stop.** Report the blocker. Do not guess or force through. |

**Never silently deviate from the plan.** Every deviation is either documented (small fix, NTH) or escalated (plan wrong, blocker).

**2d. Verify — the verification gate**

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

**The Iron Law:** No completion claims without fresh verification evidence. If you have not run the command in this session, you cannot claim it passes.

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
- `<typecheck>` → exit 0

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

### Step 3 — Handle failures

When something goes wrong during implementation:

**Test failure after your change:**
1. Read the error message completely — it often contains the answer.
2. Check what you changed against what the plan specified — did you deviate?
3. If the plan's approach caused the failure, the plan is wrong — stop and update it.
4. Fix the issue. Re-run verification. Do not move on until the phase passes.

**Multiple fix attempts failing (3+):** Stop guessing. Run the root-cause checklist before attempt 4:

1. **Re-read the failure end-to-end** — the error message often names the cause. Have you actually read every line, or only skimmed the headline? Read the stack trace top-to-bottom.
2. **Trace the data path** — what runs before this? What state is set? What is *actually* being passed in vs. what the code assumes? Add a single targeted log if needed to confirm.
3. **Check the original code** — has the file changed since the plan was written? Different line numbers, signatures, or structure? If yes, the plan is stale (`PLAN_WRONG`).
4. **Bisect your change** — revert your last edit. Does the failure go away?
   - YES → the last edit caused it. Look at it again with fresh eyes.
   - NO  → the failure precedes your changes. The bug is upstream of this phase.
5. **Search for the pattern elsewhere** — has someone already solved a similar failure in this codebase? `grep` for the error message, key symbol, or stack frame. Reuse the existing solution.
6. **Re-read the assumption** — the plan's approach assumed something. Is that assumption actually true in this code? (Type shape, async ordering, lifecycle, cache invalidation, etc.)

If after the checklist you still can't fix it, escalate with `BLOCKED` and report the findings — never guess past attempt 3.

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
| 3+ fix attempts on the same issue | Stop guessing. Re-analyze or escalate. |

---

## Output Contract

Every phase report and the final report must commit to one status code. Use the codes the orchestrator's phased-workflow expects:

| Code | When to use |
|------|------------|
| `DONE` | All DoD items verified PASS with fresh evidence; cleanliness self-check passed |
| `DONE_WITH_CONCERNS` | DoD passed but you flagged scope creep, risk, file size, or other observations the orchestrator should see |
| `NEEDS_CONTEXT` | Cannot complete without information not in the plan |
| `BLOCKED` | Hit a wall after the root-cause checklist — environment, dependency, or unclear requirement |
| `PLAN_WRONG` | The plan contains an error that prevents implementation. Propose the plan edit and stop |

A report without a status code is not a valid report — pick one.

**Per-phase report:**
- **Status code** (one of the above)
- What was changed (files touched, approach taken — actual, not planned)
- Deviations from plan, with reasons
- DoD verification results — each item with the command run and the full output (not claims, not summaries)
- Red-green regression evidence (bug-fix phases only) — the stash/restore output sequence
- Cleanliness self-check results — each item answered with `PASS` or `FIXED-WITH: <what you fixed>`
- NTH items discovered

**Final summary:**
- **Overall status code** (the worst code across phases — e.g., one `BLOCKED` phase ⇒ overall `BLOCKED`)
- Per-phase status codes
- Plan deviations summary
- Cleanliness fixes applied during self-check
- Unresolved items (zero on overall `DONE`; documented otherwise with the reason)
- **Auto-decisions made during execution** (any non-trivial choice between two valid implementations — option chosen + reasoning + risk taken; empty if none)

---

## Disk-first mode

When the dispatch prompt provides a `report-target=<path>` directive (or any equivalent — e.g., "Disk report path: ...", "write your full report to ..."), the **Output Contract above describes the report on disk**, not the return message.

**Behavior in disk-first mode:**

1. Write the full per-phase report and final summary (everything described in **Output Contract** above) to `<path>` using the Write tool. The disk file is the source of truth — it must contain every command output, every cleanliness check, every NTH item, exactly as the contract above specifies. The Iron Law and verification gate apply to the disk report's content unchanged.

2. Your final return message contains ONLY:

   ```
   STATUS=<code>
   report=<path>
   tldr: <≤200 token summary — what was built, key evidence pointer, file count touched>
   ```

   For non-`DONE` statuses (`BLOCKED`, `PLAN_WRONG`, `NEEDS_CONTEXT`, `DONE_WITH_CONCERNS`), include one extra line:

   ```
   concerns: <N> findings, see report     # or: blocked: <one-line cause>
   ```

3. Returning more than ~300 tokens of inline text is a contract violation. The disk file is the source of truth; the return message is just the index. The orchestrator (Hashus) has its own context to protect — dumping the full report inline AND on disk doubles its context cost without adding any auditable value.

**Verifying disk-first mode is in effect:** if the dispatch prompt mentions a path under `plans/run-reports/` or instructs you to write a report to a specific file, you are in disk-first mode. When in doubt, the orchestrator checks `test -s <path>` after your return — an empty or missing file is treated as `BLOCKED` regardless of your status code.

**When disk-first mode is NOT in effect** (no `report-target` directive in the dispatch prompt): use the inline format described in the **Output Contract** above. This is the default for direct user invocations of `/implement`.

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
