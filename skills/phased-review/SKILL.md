---
name: phased-review
version: "2.2.0"
description: "Pre-implementation plan review. Evaluates a phased plan against the actual codebase — verifies patterns, values, preconditions, and blast radius before any code is written. Triggers: phased-review, /prv, prv:"
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
- Read the actual styles, theme tokens, or layout logic that determine the real value.
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
