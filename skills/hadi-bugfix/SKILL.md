---
name: hadi-bugfix
description: "Structured bugfix workflow: investigate first, report root cause and solution options, then implement only after approval using clean, maintainable existing patterns. Triggers: hadi-bugfix, /hadi-bugfix"
metadata:
  tags: bugfix, troubleshooting, root-cause, implementation, qa
---

# Bugfix Workflow

## Overview

Investigate first. Fix second. Never the other way around.

**Core principle:** Evidence before claims, always. "It's probably X" is not a root cause. `<src>/stores/someStore.ts:214` — the `setTimer` call fires before the data is persisted — that is a root cause. Every proposed fix must trace back to a specific location in the code. Every claim must be backed by what was actually read.

**The shortsighted fix is a failed fix.** A fix that patches the symptom without finding the original trigger guarantees the bug resurfaces — in the same place, in a sibling component, or in a different flow that shares the same root cause. Every investigation must answer: where did this originate, does it affect other areas, and does the fix hold under all related code paths?

**Every fix must be CLEAN, MAINTAINABLE, and use EXISTING PATTERNS where possible.** This is non-negotiable. Before proposing any solution, confirm — with evidence — that:

1. **Existing patterns are reused.** A new helper / hook / component / constant is acceptable ONLY when no existing one fits. Default answer is "reuse"; "new code" requires a written justification in the report.
2. **The code lives where the codebase already puts that kind of code.** A pure state transition belongs in the existing fold function. A side-effecting handler belongs alongside the existing handlers. Don't invent new locations for old responsibilities.
3. **Naming, file layout, and conventions match the 2-3 nearest examples.** Read peer code first; mirror it.
4. **No abstraction is introduced unless three concrete callers will use it.** Premature abstraction is a maintenance burden, not a fix.
5. **Minimal diff.** No "while I'm here" cleanups. No drive-by refactors. The fix scope equals the root cause scope, no more.

A fix that works but duplicates logic, introduces a parallel pattern, or hides in a non-canonical location is a defect — even if it passes tests. The Step 2 report MUST surface where existing patterns were reused (Investigation Checklist `Pattern scan` row) AND the recommended option block MUST cite the specific peer pattern by `path:line`. Solutions that fail the cleanliness check go back to Phase 3 (Pattern Scan) before being proposed to the user.

## When to use

Use for bug reports, regressions, flaky behavior, production issues, or any troubleshooting request where the user wants investigation before implementation.

Trigger phrases: `/buggy`, `/bw`, `bugfix-workflow`, `troubleshoot-workflow`, `investigate-first-fix`

---

## The Pipeline

```
Step 0: INTAKE       — receive and understand the report
Step 1: INVESTIGATE  — find the root cause with evidence
Step 2: REPORT       — present findings and solution options
Step 3: APPROVE      — wait for user to choose an approach
Step 4: IMPLEMENT    — fix the root cause using existing patterns
Step 5: VERIFY       — run QA, clear errors, confirm the fix
Step 6: CLOSE        — report what changed and why it works
```

---

## Step 0 — Intake

Receive the bug report and fully understand it before touching any code.

**Capture:**
- **Symptom** — what the user sees (from their perspective, not yours)
- **Reproduction steps** — exact steps if provided; flag if missing
- **Context** — device, environment, version, recent changes if mentioned
- **Reporter severity** — did they say "crash", "sometimes", "always"? Note it.

**Do not skim.** Vague reports still contain real signals. Parse what's there; flag what's missing.

**If the report is too vague to investigate** (e.g., "something feels off"), say so explicitly and ask for reproduction steps before proceeding. Don't fabricate specifics.

---

## Step 1 — Investigate (root cause first)

No fixes yet. No guesses. Read the code.

**The iron law: NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.**

If you haven't traced to a specific file and line, you haven't found the root cause.

### Phase 1 — Find the affected code

- Search the codebase for the component, screen, or service mentioned in the report.
- If the report is vague, scan the relevant feature directory.
- Read the affected files — enough to understand the component, not just the suspected line.
- Check `git log` on the files — recent changes may have introduced the bug.

### Phase 2 — Trace to root cause (backward from symptom)

Start at the symptom. Trace backward through the call chain until you find the original trigger — the place where the fix should happen.

```
Symptom → Immediate cause → What called this? → What value was passed? → Where did it originate?
   ↑                                                                              ↑
   └── Don't fix here                                              Fix here ──────┘
```

**Never stop at the symptom.** The line that throws the error is rarely the line that needs to change.

For each step in the trace:
- What code directly produces the behavior the user described?
- What called this? What value was passed? Where did that value come from?
- Keep tracing until you reach the original trigger.

**When you can't trace manually, add diagnostic instrumentation:**

```typescript
// Add BEFORE the problematic operation to capture full context
const stack = new Error().stack;
console.error('DEBUG [location]:', { value, cwd: process.cwd(), stack });
```

Run once to gather evidence showing WHERE it breaks, then analyze, then fix.

**Async/timing trace (mandatory for any fix involving async cleanup):**

If your fix involves cancelling, clearing, or cleaning up an async operation, trace what happens if that operation is _already mid-execution_ when the cleanup runs. `cancelPendingSync()` / `clearTimeout()` / `debounce.cancel()` only stops ops that haven't started. Ask:
- Could the async operation already be in-flight when cleanup runs?
- If yes, does the cleanup also await or block that in-flight promise?
- If not, the write/read/network call will complete _after_ the cleanup — and create a new orphan.

This pattern requires an in-flight tracking mechanism (e.g., a `Map<id, Promise>`) in addition to the cancellation guard.

### Phase 3 — Pattern scan (MANDATORY before proposing any fix)

Before forming a fix approach, scan the codebase for existing patterns the fix must follow or reuse. A fix that duplicates existing logic or ignores existing conventions is a bad fix.

**Check for existing** (search the project's canonical source root — read project instructions / `CLAUDE.md` / `AGENTS.md` for the actual paths):
- **Components / modules** — does a shared component or module already do what the fix needs? Check the project's components / modules directory before creating anything new.
- **Hooks / utilities** — does a hook, helper, or utility already encapsulate the logic? Check the project's hooks / lib / utils directory.
- **Design tokens / constants** — spacing, colors, typography, motion (durations, springs, easing), border widths. Check the project's design-token / theme / constants location before using any raw value. If a token exists, the fix must use it.
- **Constants and config** — shared constants live in a canonical location (e.g. `<src>/constants/`, `<src>/config/`). Check before defining a new constant.
- **Service methods** — does an existing service method handle the operation? Check relevant services before duplicating logic inline.
- **Storage key conventions** — check how existing keys are named and which storage backend they use before adding new keys.

**Ask explicitly:**
- Is there already a component/hook/utility that does this? If yes, use it — don't create a parallel one.
- Is there a design token / constant for the value I'm about to hardcode? If yes, use it.
- Is there an existing naming convention I must follow? If yes, match it exactly.

**Document the pattern check result** in the fix proposal: state what was found (or not found) during the scan.

### Phase 4 — Understand the scope (MANDATORY — no shortcuts here)

This phase is where shortsighted fixes happen. Do not skip it. A fix that ignores this phase will resurface the bug elsewhere.

**4a. Broader impact analysis**

For the root cause you've identified:
- **What other code paths lead to the same root cause?** Search for all callers, all entry points, all flows that could trigger the same broken code. Don't assume the reported path is the only one.
- **What sibling components share the same pattern?** If the bug is in ComponentA, check ComponentB, ComponentC — anything in the same feature area that likely copied the same pattern.
- **What does the fix need to change?** List affected files with exact paths. If fixing only one file when three files share the same bug — that's a shortsighted fix.
- **Could the fix break something else?** What depends on the code being changed? Check callers up the chain.
- **Is this isolated or systemic?** An isolated bug lives in one place. A systemic bug is a pattern — the same mistake repeated across the codebase. Know which one you're dealing with before proposing a fix.

**4b. Multi-layer validation check**

Ask whether validation should be added at multiple layers to make the bug structurally impossible — not just patched at the symptom point:
- **Entry point** — reject invalid input at the API boundary (the first place data enters)
- **Business logic** — ensure data makes sense for this operation at the service/store layer
- **Data layer** — guard at persistence to prevent corrupted writes
- **Debug instrumentation** — add logging at the danger point for future forensics

A single validation point can be bypassed by different code paths, refactoring, or mocks. Multiple layers make the bug impossible.

**4c. Pre-existing state check (mandatory for data/persistence bugs)**

Ask whether the fix handles data _already on the device_, not just future occurrences. A fix that prevents new bad writes does nothing for orphaned records already sitting in the DB from before the fix was deployed. If stale data can exist, the fix must also address it:
- Can old orphans be cleaned up on startup or next read?
- Can a recency filter (e.g., `Q.where('started_at', Q.gt(cutoff))`) exclude them immediately?
- Does the fix need a one-time migration?

If none of these are addressed, the user will still see the bug on devices that had it before the fix shipped.

### Phase 5 — Propose remediation

Think through fix approaches at a guidance level — not implementation-ready code yet, but specific enough that you can defend each option.

For each candidate fix:
- Which files change? (exact paths)
- Which layer does it target?
- Does it address the root cause or just the symptom? (If symptom only — stop and re-investigate)
- What are the risks?
- Does validation need to happen at multiple layers? (entry point, service, data layer)
- Do sibling components need the same fix applied? If yes, include them — don't fix half the problem.

**Hypothesis discipline:** Form one hypothesis at a time. State it explicitly: "I think X is the root cause because Y." Test the smallest possible change to validate it. If the hypothesis is wrong, form a new one — don't pile more fixes on top.

---

## Step 2 — Report findings

Present to the user before writing any code. Use this structure:

---
**Root Cause**

[What's actually wrong — specific file path, line number, and the trace chain]

Trace: [symptom] → [immediate cause at file:line] → [caller at file:line] → [origin at file:line]

**Broader Impact**

- Sibling components with the same bug: [list with file paths, or "none found"]
- Other call paths that trigger the same root cause: [list, or "isolated"]
- Systemic or isolated? [systemic = same pattern repeated / isolated = one-off]
- Pre-existing stale data concern: [yes/no — and how the fix addresses it, or why it doesn't apply]

**Solution Options**

Option A — [name]
- Approach: [what changes]
- Files: [exact paths — ALL affected files, not just the reported one]
- Reused patterns: [for each existing pattern reused, cite `path:line` of the peer. e.g. "fold-level state transition at applyChatEvent.ts:533-552"]
- New code introduced: [list any new helpers/hooks/components/constants AND justify why an existing one didn't fit. If "none", say so.]
- Covers sibling issues: yes | no | partial
- Effort: small | medium | large
- Risk: [what could break]

Option B — [name] *(same structure)*

**Recommendation**

Option [X] because [specific reasoning — not "it's simpler" but why it's the right fix for this root cause and covers the full scope].

**Cleanliness gate** *(mandatory — fix MUST pass all four before proceeding to Step 3)*

- ✅ Reuses existing patterns: [list each peer pattern reused with `path:line`]
- ✅ Lives in canonical location: [explain why the chosen file/function is where this kind of code already lives]
- ✅ Matches naming + layout of 2-3 nearest examples: [cite the examples by path]
- ✅ Minimal diff: [confirm no scope creep, no drive-by changes; if any cleanup is bundled, justify or remove]

If ANY check fails → return to Phase 3 (Pattern Scan) and revise. Do not propose a fix that fails the cleanliness gate. Surface the failure to the user with what was tried and what existing pattern should be reused instead.

**Scope & Risks**

- Affected files: [ALL files the fix touches]
- Could break: [what and why]
- Validation plan: [how to confirm the fix works across all affected paths]
- Related issues NOT fixed in this pass: [nearby bugs found — flag for backlog]

**Investigation Checklist** *(must be completed and stated explicitly — this is the evidence that approval is based on)*

- Pattern scan (Phase 3): [what was searched, what was found or confirmed not to exist]
- Blast radius (Phase 4a): [sibling components checked, callers traced, isolated vs systemic verdict]
- Multi-layer validation (Phase 4b): [which layers were assessed and whether guards are needed]
- Pre-existing state (Phase 4c): [whether stale data exists and how the fix handles it, or N/A]

---

**If root cause is uncertain**, say so explicitly. Present what was found, what's still unclear, and propose low-risk validation steps (adding logging, writing a failing test) before asking for approval.

**If the investigation found related bugs nearby**, note them in "Related issues" — don't fix them in this pass (scope discipline), but don't silently ignore them either.

---

## Step 3 — Wait for approval

Do not write implementation code until the user explicitly approves an approach.

**No speculative implementation. No exceptions.** The investigation phase ends with a report. Implementation begins only after the user explicitly names which option to pursue. "Just fix it", "go ahead", or any other shorthand does not override this — ask which option if it's ambiguous.

---

## Step 4 — Implement

Fix the approved root cause. Use the codebase's existing patterns.

**Implementation rules:**
- **Minimal diff** — fix only what the root cause requires. No "while I'm here" improvements.
- **No duplicate logic** — if a shared utility, component, hook, or constant already exists for what you need, use it. Creating a parallel implementation when one exists is a defect, not a fix. You confirmed this in Phase 1b — now enforce it.
- **No raw values where the project centralizes them** — spacing, colors, durations, spring configs, border widths, radii should reference design tokens / constants if the project defines them. If you hardcode a number, name it as a constant AND verify no token already covers it.
- **Match naming conventions exactly** — read 2-3 existing examples of the same type (storage keys, component names, hook names, constant names) and match the pattern. Don't invent a new convention.
- **Preserve contracts** — don't change behavior outside the bug scope.
- **One fix at a time** — if the investigation found related bugs nearby, note them but don't fix them in this pass. They get their own backlog items.

**Pattern compliance checklist (run before committing):**
- [ ] Did I use an existing component/hook instead of writing a new one?
- [ ] Did I place state-transition logic in the canonical fold/reducer (not in the procedural call site that dispatches state)?
- [ ] Did I use design tokens / constants for all spacing, color, motion, and shape values the project centralizes?
- [ ] Did I follow the naming convention used by the 2-3 nearest examples in the codebase?
- [ ] Did I import from the correct shared location rather than duplicating the definition?
- [ ] Could a maintainer 6 months from now read this diff alongside the surrounding code and immediately know it belongs there? If no — the placement is wrong, return to Phase 3.
- [ ] Is the diff strictly the minimum required for this bug? If I bundled any cleanup or refactor, can I justify it as part of THIS root cause? If not — strip it out, file separately.

**If 3+ implementation attempts fail — question the architecture, don't try fix #4.**

Three failed fixes in a row is the signature of a wrong pattern, not a wrong fix. Specifically:

- Each fix reveals a new problem in a different place (shared state, coupling, or stale assumption)
- Fixes require "while I'm here" cleanup that grows in scope
- Each fix introduces a new symptom you didn't expect

When this happens, STOP. Don't attempt fix #4. Surface to the user with this framing:

> "I've tried 3 fixes. Each one revealed a new issue. This isn't a fix problem — it's an architecture problem. The pattern at `<file:line>` makes the bug fundamentally hard to fix cleanly. I think we need to discuss whether to refactor `<X>` rather than continue patching. Want me to write up the architectural concern as a design note before we decide?"

A failed fourth fix wastes more time than a 5-minute conversation about whether the pattern itself is wrong.

**Diagnostic instrumentation pattern (when the bug spans multiple layers/components):**

For multi-layer bugs (CI → build → signing, API → service → store, hook → reducer → DB), don't guess which layer fails. Add probe logs at each component boundary, run once to gather evidence, then debug the specific layer that's broken.

```bash
# Example: investigating a sync failure
# Layer 1: hook
console.log('[sync.hook] payload:', JSON.stringify(payload))
# Layer 2: service
console.log('[sync.service] received:', JSON.stringify(received))
# Layer 3: store
console.log('[sync.store] persisted:', JSON.stringify(persisted))
# Layer 4: server
console.log('[sync.server] accepted:', JSON.stringify(accepted))
```

Run the broken scenario once. Read the logs. The first layer where input ≠ expected is the failing layer. Investigate THAT layer specifically. Remove probes after fixing.

This beats reading code in 4 layers trying to guess where it breaks.

---

## Step 5 — Verify

Verification is not optional. Evidence before claims — if you haven't run the check, you cannot claim it passes.

**5a. Targeted QA**

Run checks relevant to the bug:
- TypeScript: `npx tsc --noEmit` — must pass with zero errors in touched scope (project-wide when feasible)
- Lint: run the project's lint command — must pass with zero errors/warnings in touched files
- Tests: run tests relevant to the changed area — must pass
- Manual: trace the original reproduction steps mentally against the new code — does the fix actually address the root cause?

**5b. Regression check**

- Does the fix break anything the trace chain identified as a dependent?
- Do any existing tests fail that weren't failing before?

**5c. The verification gate**

| Claim | Requires |
|-------|---------|
| "TypeScript passes" | Run `npx tsc --noEmit`, read the output, confirm 0 errors |
| "Tests pass" | Run the test command, read output, confirm all relevant tests green |
| "Bug is fixed" | Trace original reproduction steps against the changed code |
| "No regressions" | Relevant test suite green, no new errors in touched files |

If QA fails: fix the failure, then re-run the full QA pass. Do not move to Step 6 with open failures.

---

## Step 6 — Close

Report the outcome using this structure:

---
**What Changed**

[File paths and what was changed — specific, not "fixed the bug"]

**Why It Works**

[How the change addresses the root cause — map the fix to the trace chain from Step 1]

**QA Results**
- TypeScript: [pass / N errors]
- Lint: [pass / N warnings]
- Tests: [N/N pass]
- Manual trace: [confirmed / not confirmed + why]

**Residual Risks**

[Anything not fixed in this pass, or known edge cases the fix doesn't cover]

**Related Issues**

[Nearby bugs noticed during investigation that weren't fixed — flag for backlog]

---

## Investigation Red Flags — STOP and Return to Phase 1

If you catch yourself thinking any of these during Step 1, return to Phase 1:

| Thought | Reality |
|---------|---------|
| "It's probably X, let me fix that" | Probably is not evidence. Read the code. |
| "Quick fix for now, investigate later" | Quick fixes become permanent. Find root cause first. |
| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause. |
| "Just try changing X and see if it works" | One variable at a time, after forming a hypothesis. |
| "I don't fully understand but this might work" | Stop. Read more. |
| Fix #3 and still failing | 3+ failed fixes = possible architectural problem. Stop and discuss. |
| "This only affects ComponentA" | Did you check ComponentB, ComponentC, and all callers? |
| "The fix is just this one line" | Did you complete Phase 4 scope analysis? If not, do it first. |
| "I'll create a new component/hook/constant for this" | Did you check if one already exists? Run Phase 3 first. |
| Using a raw number for spacing, duration, color, radius | Did you check the project's design tokens / constants? Raw values are forbidden if a token exists. |
| Naming a key/constant/file without checking conventions | Read 2-3 existing examples of the same type first and match the pattern exactly. |
| "I'll add this in the loop / handler / call site" | Is there a fold function / reducer / state-transition function nearby? State changes belong THERE, not in the procedural call site that consumes them. Choosing the procedural location duplicates dispatch wiring and breaks colocation with related transitions. |
| "It's just a small new helper, easier than reusing X" | Premature parallel implementation. Reuse X unless you can name 3 concrete callers for the new helper. |
| "This could go in either file — I'll pick the one I'm already editing" | The fix should land in the canonical file for the responsibility, not the file open in your editor. Cite peer code for "where this kind of code lives" before placing the diff. |
| "The diff works but it's a bit redundant with existing code" | Redundant = dead code waiting to drift. Either reuse the existing code or delete it. Two paths doing the same thing is a defect. |

---

## Decision Framework

### When to ask vs. proceed

| Situation | Action |
|-----------|--------|
| Root cause is clear, single option obvious | Report findings with full checklist, wait for explicit approval |
| Multiple valid approaches | Report all options with tradeoffs, wait for user choice |
| Root cause is uncertain | Flag uncertainty explicitly — propose validation steps, not a fix — wait for approval |
| Bug is a security vulnerability | Flag immediately before full investigation. Don't just log it. Still wait for approval. |
| Bug traces to a third-party library | Note it — fix may require upstream change or workaround. Flag to user. Wait for approval. |
| 3+ fix attempts failed | Stop. Surface architectural concern to user. Do not attempt fix #4 without approval. |
| Fix requires broad refactoring | Red flag — propose the minimal targeted fix instead. Refactor is a separate item. |

### Scope discipline

The fix scope should match the root cause scope. No more, no less.

| Root cause scope | Fix scope |
|-----------------|-----------|
| Single function in one file | Change that function |
| Interface contract between two files | Change both files + update callers |
| Architectural pattern across many files | Flag — this is a larger item, not a bugfix |

### What this skill does NOT do

- **Does not fix multiple bugs in one pass.** One bug, one fix. Related bugs go to the backlog.
- **Does not refactor.** Clean up is separate work. This skill fixes root causes.
- **Does not skip verification.** Even for "obvious" fixes. Evidence before claims.
- **Does not guess.** If root cause isn't found, say so.

---

## Style Contract — caveman prose

Investigation reports, root-cause docs, and solution options are operational artifacts, not essays. Every line carries a fact.

**Rules:**
- No articles ("the", "a", "an") — drop them
- No hedging ("might", "could", "appears", "seems", "likely", "probably") — assert or omit
- No filler ("simply", "just", "essentially", "in order to", "successfully", "basically", "actually")
- No transitions ("furthermore", "additionally", "moreover", "however")
- No restatement of the bug report or task
- Sentence fragments OK. Imperative or past-tense verbs.
- One fact per line. No paragraphs of prose.
- `path:line` for every claim. No prose pointers.
- Numbers and counts beat adjectives ("3 callers" not "several callers")

**Carve-outs (keep verbatim — do NOT cavemen):**
- Reproduction steps — exact, runnable
- Stack traces and error output — full detail
- Code snippets in fix proposals — verbatim, idiomatic
- Diff snippets quoted as evidence — verbatim
- Solution Machine option blocks — schema is fixed; cavemen the prose inside each field, keep the schema structure intact

**Examples:**

BAD (verbose):
> The root cause appears to be a race condition in the modal dismissal handler that may cause the onPress callback to fire before the dismiss animation has completed.

GOOD (caveman):
> Root cause: race in modal dismiss. onPress fires before dismiss completes. AlertModal.tsx:142.

BAD (verbose):
> The investigation found that several callers of this hook do not handle the loading state properly, which could lead to UI flicker.

GOOD (caveman):
> 3 callers skip loading state. UI flickers. Files: HomeScreen.tsx:45, ProfileScreen.tsx:78, SettingsScreen.tsx:33.

**Self-check before submitting:**
- Any sentence with 2+ commas → rewrite
- Any sentence containing "the/a/an" twice → rewrite
- Any paragraph with 3+ sentences → split into bullets, drop filler
- Any 5-line section where you can't point to which lines carry NEW facts → half is fluff, cut it
