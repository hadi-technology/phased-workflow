---
name: phased-implement
version: "1.1.0"
description: "Execute an approved phased plan. Follow the plan, track files, verify each phase, run cleanliness self-check before declaring done. Evidence before claims. Triggers: phased-implement, /implement"
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

**2c. Handle discoveries**

When implementation reveals something the plan didn't anticipate:

| Discovery | Action |
|-----------|--------|
| Small fix, clearly in scope (e.g., adjacent import needs updating) | Fix it. Note the deviation in your phase report. |
| Related issue, out of scope (e.g., nearby function has same problem) | Document as NTH. Don't fix. Don't silently ignore. |
| Plan is wrong (e.g., approach won't work, file doesn't exist) | **Stop.** Update the plan file with what you found. Then continue from the updated plan. Call out the delta in the final report. |
| Blocker (e.g., missing dependency, unclear requirement, persistent failure) | **Stop.** Report the blocker. Do not guess or force through. |

**Never silently deviate from the plan.** Every deviation is either documented (small fix, NTH) or escalated (plan wrong, blocker).

**2d. Verify — evidence before claims**

After implementing a phase, run every DoD check:

```
FOR each DoD item:
  1. IDENTIFY what command or code read proves this
  2. RUN the command (fresh — not from a previous session)
  3. READ the full output — exit code, counts, errors
  4. COMPARE: does output confirm the DoD item?
     - YES → record as pass WITH the evidence
     - NO → record as fail WITH the evidence
```

**Verification anti-patterns** (these are not verification):
- "Should pass now" — run it
- "I changed it, so it works" — verify it
- "Same pattern as phase 1, so it's fine" — check it independently
- Citing output from a previous phase — run it fresh
- Skipping a DoD item because "it's obvious" — obvious things break too

**2e. Cleanliness self-check — MANDATORY before declaring any phase done**

Before claiming a phase is complete, re-scan your own diff and answer each of these out loud in the phase report. If you haven't answered them, the phase is not done. This is the single most common source of rework — the question "is this clean, maintainable, and using existing patterns without hardcoding?" gets asked later and finds real issues. Catch them here first.

- [ ] **Existing patterns reused?** For every new component, hook, utility, constant, or helper I introduced — did I first check whether one already exists in the codebase? List the 1–3 searches you ran (`grep`, `Glob`, or file reads) and what you found. If a parallel implementation exists, replace your new one with the existing one.
- [ ] **Theme tokens used for every visual value?** No raw hex colors, raw spacing numbers, raw border radii, raw font sizes, raw durations, or raw shadow values. If a token exists, it must be used. Document any exception with a one-line justification.
- [ ] **No hardcoded strings, numbers, or paths that belong in config/constants?** User-facing strings, magic numbers, API paths, storage keys, feature flags — check that each one lives in its canonical location, not inlined.
- [ ] **Naming matches peer conventions?** Read 2–3 nearest peer files (same directory or same type of file) and confirm your naming (component names, file names, hook names, storage keys, constant names) matches their style.
- [ ] **Minimum diff?** Every line I touched is required to meet the phase objective. No drive-by refactors, no "while I'm here" additions, no speculative abstractions for hypothetical future needs.
- [ ] **No dead leftovers?** No commented-out code, no unused imports, no stray `console.log`, no `// TODO:` / `// DEFERRED:` added to touched files, no half-finished branches.
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

**Multiple fix attempts failing (3+):**
- Stop trying the same approach. Something fundamental is wrong.
- Re-read the original code the plan was based on — has it changed since planning?
- Report the situation honestly rather than continuing to guess.

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

After all phases are complete, report:

**Per-phase:**
- What was changed (files, approach)
- Deviations from plan (with reasons)
- DoD verification results (with evidence — command output, not claims)
- Cleanliness self-check results (each item answered — pass or with-fix-applied)
- NTH items discovered

**Summary:**
- All phases: pass/fail status
- Plan deviations summary
- Cleanliness: any fixes applied during self-check
- Unresolved items (should be zero — if not, explain why)
