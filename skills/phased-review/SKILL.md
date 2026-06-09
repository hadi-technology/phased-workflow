---
name: phased-review
version: "2.3.0"
description: "Pre-implementation plan review. Evaluates a phased plan against the actual codebase — verifies patterns, values, preconditions, blast radius, and YAGNI before any code is written. Triggers: phased-review, /prv, prv:"
metadata:
  tags: review, planning, architecture, qa, maintainability
---

# Phased Review

## Overview

Review a plan against the actual codebase before implementation starts. The plan claims things about the code — verify those claims.

**Core principle:** Trust nothing in the plan. Read the source. Every value, every assumption, every "this component does X" — verify it against the actual code before judging the plan.

## When to use

Use when reviewing a proposed implementation plan before code is written.

Trigger phrases: `phased-review`, `phased review`, `/prv`, `prv:`

---

## The Process

### Step 1 — Load and parse

1. Get the plan file path (ask if not provided).
2. Read the plan. Extract per phase: objectives, scope, approach, files changed, DoD (functional + code), and any specified QA/test gates.
3. Note assumptions and dependencies between phases.

### Step 1.5 — Restate the plan's intent

Before reading the codebase, write 1–2 sentences capturing what the plan claims it will achieve and how. This is the lens for everything that follows.

- If you cannot restate the plan in one paragraph, the plan is unclear — flag it as a high-severity finding before proceeding.
- If your restatement diverges from what the plan literally says, you may be assuming. Re-read the plan and reconcile.
- The restatement is your reference point during Steps 2–4: ask "does this code/finding align with the stated intent?" rather than "does it match my assumption of the intent?"
- Carry the restated intent through to the Final Recommendation so the orchestrator and approver can see what you reviewed against.

### Step 2 — Read the codebase (before judging)

Do not evaluate the plan until you've read the impacted code. The plan may describe the codebase incorrectly.

For each phase:
1. **Read every file** listed in "Files changed" — not just the lines mentioned, but enough context to understand the component.
2. **Identify existing patterns** — how does the codebase already solve similar problems? What shared utilities exist? The plan should reuse them.
3. **Identify blast radius** — what other components import, call, or depend on the changed files? Could the change break them?
4. **Read ±20 lines** around each specific change site for related issues the plan may have missed.

### Step 3 — Verify plan claims

Run each check below against the actual source code. A failed check = a finding, regardless of whether the plan's DoD covers it.

**3a. Numeric constants — trace to source**

For any numeric value in the plan (heights, timeouts, thresholds, sizes):
- Read the actual styles, design tokens, or layout logic that determine the real value.
- Flag values asserted without evidence.
- Flag fixed constants used for variable-sized content (e.g., `overrideItemLayout` with a fixed height for a component whose height depends on content).

**3b. Code snippets — check completeness**

Every code block in the plan must be copy-pasteable into the codebase:
- Flag placeholder comments: `/* deps */`, `/* TODO */`, `...`, TBD
- Flag incomplete dependency arrays (empty `[]` when the closure captures values)
- Flag unspecified type parameters
- Flag "similar to Task N" without repeating the code
- Flag shell commands that omit the working directory (must prefix with `cd <dir> &&` when project root differs from where config files like `package.json`, `.eslintrc.js`, `tsconfig.json` live)
- Flag type casts (`as SomeType`, `as unknown as SomeType`) that aren't traced to the actual type definition. The reviewer must read the type definition, confirm the types are compatible without the cast, and cite the definition location.

**3c. Optimization preconditions — verify effectiveness**

When a phase claims a performance improvement, verify the preconditions that make it work:

| Optimization | Verify | Common failure |
|-------------|--------|----------------|
| `React.memo` | Read the parent. Are callback props `useCallback`-wrapped? | Parent passes inline arrows — memo is a no-op |
| `useCallback` | Deps array fully specified? Each dep stable? | Placeholder `[]` with captured state = stale closure |
| `useMemo` | Expensive computation actually re-runs? | Memoizing something React already optimizes |
| List virtualization | Height strategy matches layout? | Fixed height for variable-height content |
| Lazy loading | Component actually heavy? | Lazy-loading a 20-line component adds overhead |

**3d. Adjacent code — scan for related issues**

For each change site, check ±20 lines for issues in the same category the plan missed:
- Another inline function next to one being extracted
- Another unstable prop next to one being stabilized
- Another FlatList in the same file being left unconverted
- Another hardcoded value next to one being extracted

Report as low-severity NTH findings — don't ignore them silently.

**3e. Breaking interface changes**

When a phase makes a previously-optional field required or removes a field from a shared interface:
- Scan `**/__tests__/**` and `**/*.test.*` for literal constructions of that interface.
- Any test file constructing the interface must appear in the plan's "Files changed" list.
- TypeScript will surface these at compile time, but the plan must anticipate them — not discover them mid-implementation. Flag plans that don't account for test file updates.

**3f. Hook migration sites**

When a phase migrates from a direct API call (e.g., `Dimensions.get()`) to a React hook:
- Verify each migration site in the plan:
  - No early returns, conditionals, or loops precede the hook call in the component function (Rules of Hooks violation).
  - The hook is not inside a callback, `useMemo`, `useEffect`, or nested function.
- The plan must cite line numbers of the hook call and the first preceding early return (or "none") as evidence.
- Flag migration sites where the plan doesn't provide this evidence.

**3g. YAGNI — does the plan add anything with no apparent caller?**

For every new public function, hook, component, helper, exported type, or feature flag the plan introduces:

- `grep` the codebase for usage. If nothing calls it (and no later phase introduces a caller), flag it.
- Acceptable: the plan documents *why* the unused symbol exists (e.g., "platform API requires this signature", "shared with another package not in this repo").
- Otherwise: flag as medium severity with the verdict "remove or wire up a caller — speculative scaffolding violates YAGNI."
- Apply the same check to "professional" features the plan adds without a stated requirement (CSV exports, admin-only endpoints, retry layers, abstraction wrappers). If the plan can't name a current caller, it doesn't ship.

**3h. TDD coverage — does the plan have a failing test before each behavioral step?**

For each phase that introduces or changes behavior:
- Verify the phase Steps include a "Step 1 (TDD): write the failing test" before any implementation step.
- Verify the failing-test step shows the **actual test code**, not a description.
- For bug-fix phases, verify a regression-test red-green step (`git stash → fail → restore → pass`) is present.
- Phases that legitimately skip TDD (formatting, type-only changes, dependency upgrades) must say so in the Objective. Otherwise flag as high severity — TDD missing means the implementer may write the wrong code or skip the test.

**3i. Operational rigor — mandatory checks against live code**

Internal-consistency audit (do row claims match each other? do paths exist?) is necessary but not sufficient. These 5 checks verify the plan / row is consistent WITH the current codebase. Each is a tool call. Skipping any is a known Pass-1-miss class — the issue surfaces in Pass 2, in QA, or mid-implementation.

**1. Live-grep verification.** For every `grep` / `git grep` in `acceptance_criteria` (or any DoD command that asserts an expected hit count), run the command against the current source. Compare live count to the row's expected count. If the row says "returns 0 hits AFTER refactor" and live count is N>0, the row MUST classify each of the N matches: preserve / migrate / delete. Unclassified matches → critical finding ("grep over-shoots — would silently kill the surviving N-K matches"). Don't trust the row's expected count — run the command.

**2. File:line semantic verification.** For every "reuse pattern X at file:line" / "matches existing Y in file:line" claim, READ the code at file:line. Verify the pattern at that location actually does what the row says it does. Cited-but-wrong is worse than uncited because it gives the implementer false confidence. Common failures: cited file is the right area but wrong precedent (e.g., row cites a stroke-draw animation but file:line is a bar-reveal); cited line drifted since the row was written.

**3. Whole-repo deletion-impact scan.** For every row that deletes a file, removes an export, or renames a public symbol, run the symbol/filename in **quoted-string form** across the whole repo (not just import-statement form):

```bash
grep -rn '"<filename-or-symbol>"' <source-roots> 2>/dev/null
grep -rn "'<filename-or-symbol>'" <source-roots> 2>/dev/null
```

Match outside `scope_candidates` = critical finding. Filenames survive in non-import data — test registries, doc strings, config arrays, analytics event names, feature-flag keys. Import-grep alone misses these.

**4. Type-constraint verification.** For every row that calls a generic function `fn<T>(...)` or extends a constrained type, trace the constraint on `T` from the function signature (read the signature). Verify the row's call site satisfies it. If existing peer call sites use intersection casts (`as Foo & BarBase`), conditional types, or branded types to satisfy the constraint, the new row must mirror or explain why it doesn't need to. Type errors caught at review = ~1 min; caught at implementation = ~10 min + a re-plan loop.

**5. Domain-noun mapping.** For every domain noun the row uses to describe WHAT to render / build / do (e.g., "main lift", "primary muscle", "active program", "featured item"), verify the noun maps to a concrete schema field / type / enum value. If not, the row MUST define the derivation algorithm in pseudocode in `notes` (e.g., `main lift = item where orderIndex === 1 per dayType`). Domain nouns without schema mapping = critical specificity gap — the implementer will silently pick one of multiple reasonable interpretations and ship the wrong one.

**Cost / payoff.** For a 50-row CSV, these 5 checks add roughly 30–60 tool calls (~10K–20K tokens) and 1–2 min wall clock. They catch the largest known Pass-1 miss class: ~7 of 9 issues that historically only surfaced in Pass 2. Skipping them is the single biggest source of "Pass 1 said clean, Pass 2 found 3 criticals."

### Step 4 — Evaluate plan quality

For each phase, verify:

| Criterion | What to check |
|-----------|--------------|
| Clear objective | One sentence, testable |
| Functional DoD | Specific enough to verify (not "works correctly") |
| Code DoD | Grep commands, type checks, or other automatable checks |
| Sequencing | Does this phase depend on a prior one? Is the order right? |
| Maintainability | Uses existing patterns? No new hardcoded values? No duplicate logic? |
| Blast radius | What else could break? Is it documented? |

**Review for excellence, not minimum viability.** A plan that "barely passes" will produce code that barely works.

### Step 5 — Write findings

For every issue found:
1. **Severity** — critical / high / medium / low
2. **Evidence** — what you read in the code that proves the issue (file path + line)
3. **Plan change required** — exact edit to the plan text
4. **Code change guidance** — if the fix requires different implementation code, provide exact file paths and patch direction

Do not leave any issue unaddressed. Do not omit low-severity findings — they compound.

---

## Red Flags — Stop and Escalate

| Red flag | What it means |
|----------|--------------|
| Plan file exceeds ~500 lines | Must be split into `-phase-N` files — flag as high severity with a proposed split point |
| Plan references files that don't exist | Plan was written without reading the codebase |
| Plan describes component behavior incorrectly | Plan author assumed instead of reading |
| Multiple phases modify the same file with no coordination | Merge conflicts guaranteed |
| DoD says "works correctly" with no verifiable criteria | Untestable phase — will pass QA vacuously |
| Plan introduces a new pattern when an existing one covers the case | Unnecessary divergence |
| Multi-file plan (`-phase-N`) missing dependency/sibling references in header | Implementer won't know execution order |

---

## Output Contract

### Plan Review Summary
- Plan path reviewed
- Overall readiness: `ready` or `not-ready`
- Top risks (highest → lowest)
- Confidence level
- Unresolved findings count (must be `0` for `ready`)

### Per-Phase Review
- Phase name
- Strengths (what the plan gets right)
- Findings (severity + evidence + required plan change + code guidance)
- Blast radius (what else may break)
- Verdict: `pass` or `revise`

### Codebase Analysis
- Existing patterns to reuse (with file paths)
- Affected components and interfaces (with file paths)
- Dependency and integration risks

### Final Recommendation
- Go / no-go
- Required changes table (severity, phase, change) — no issue omitted
- Updated DoD additions the plan should include

---

## Disk-first mode

When the dispatch prompt provides a `report-target=<path>` directive (or any equivalent — e.g., "Disk report path: ...", "write your full review to ..."), the **Output Contract above describes the report on disk**, not the return message.

**Behavior in disk-first mode:**

1. Write the full review (Plan Review Summary + Per-Phase Review + Codebase Analysis + Final Recommendation — everything described in **Output Contract** above) to `<path>` using the Write tool. The disk file is the source of truth — it must contain every finding with severity + evidence + required plan change + code guidance, exactly as the contract above specifies. The "do not omit low-severity findings" rule applies to the disk report's content unchanged. None of the finding detail goes in the return message.

2. Your final return message contains ONLY:

   ```
   STATUS=<DONE | DONE_WITH_CONCERNS>
   report=<path>
   tldr: <≤200 token summary — overall readiness verdict, finding count by severity>
   ```

   For `DONE_WITH_CONCERNS` (any unresolved finding), include one extra line:

   ```
   findings: <N> total (<critical-count> critical / <high-count> high / <medium-count> medium / <low-count> low) — see report
   ```

3. Returning more than ~300 tokens of inline text is a contract violation. The disk file is the source of truth; the return message is just the index. The orchestrator (Zayneb) has its own context to protect — for a CSV with 50 findings, dumping them inline would consume ~10K of orchestrator context per review pass, defeating the optimization.

**Verifying disk-first mode is in effect:** if the dispatch prompt mentions a path under `plans/run-reports/` or instructs you to write a report to a specific file, you are in disk-first mode. The orchestrator checks `test -s <path>` after your return — an empty or missing file is treated as `BLOCKED` regardless of your status code.

**When disk-first mode is NOT in effect** (no `report-target` directive in the dispatch prompt): use the inline format described in the **Output Contract** above. This is the default for direct user invocations of `/prv`.

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
