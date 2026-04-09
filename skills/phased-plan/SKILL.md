---
name: phased-plan
version: "1.1.0"
description: "Write implementation-ready phased plans as step-by-step checklists with exact code. Maps files, defines phases with DoD, enforces cleanliness self-check. Triggers: phased-plan, /plan"
metadata:
  tags: planning, architecture, design
---

# Phased Plan

## Overview

Write a plan that another agent can implement without asking questions. Every value traced to source code. Every snippet copy-pasteable. Every file path exact.

**Core principle:** The plan is code — not prose. If the implementer has to guess, the plan failed.

**Plans are implementation checklists, not outlines.** Every phase is a sequence of bite-sized steps (2–5 minutes each) an agent can follow exactly. Every step that changes code shows the actual code. Every step that runs a command shows the exact command and expected output. No "do X" without "here's how."

## When to use

Use when you need to produce an implementation plan for a multi-phase task.

Trigger phrases: `phased-plan`, `/plan`

---

## The Process

### Step 1 — Understand scope

Before writing anything:

1. **Read the task requirements** — what needs to change and why.
2. **Scope check** — if the task covers multiple independent subsystems, break into separate plans. Each plan should produce working, testable software on its own.
3. **Read prior plans** in the `plans/` directory to follow established format and conventions.

### Step 2 — Map the codebase

Before defining phases, understand what you're changing:

1. **Read every file** you plan to modify — not just the lines, but enough context to understand the component.
2. **Identify existing patterns** — how does the codebase already solve similar problems? What shared utilities exist? The plan must reuse them.
3. **Map dependencies** — what imports these files? What could break?
4. **Scan ±20 lines** around each change site for related issues worth noting.

This map informs the phase decomposition. Don't write phases until you've read the code.

### Step 3 — Write phases

Save to `plans/<yyyy-mm-dd>-<slug>.md`.

#### Plan file size limit — 500 lines max

A plan file must not exceed ~500 lines. Large implementations must be split into multiple plan files, each self-contained and independently executable. Name related files with a `-phase-N` suffix:

```
plans/2026-04-09-feature-name-phase-1.md   ← foundations, data layer, shared components
plans/2026-04-09-feature-name-phase-2.md   ← screen wiring, UI integration
plans/2026-04-09-feature-name-phase-3.md   ← polish, edge cases, cleanup
```

**Rules for splitting:**
- Each plan file must produce working, testable software on its own — no file should leave the codebase in a broken state.
- Phase 1 is always the foundation (shared types, data layer, utilities). Later phases build on it.
- Each plan file's header must reference its siblings: `**Related plans:** phase-1 (this file), phase-2, phase-3`.
- Dependencies between plan files must be explicit: phase-2's header states `**Depends on:** phase-1 (must be implemented first)`.
- The full pipeline (plan → review → approve → implement → QA) runs once per plan file. Phase-2 is not planned until phase-1 is implemented and QA'd.

**When to split:** If your plan draft crosses ~500 lines, stop and restructure into multiple files. Don't finish writing a 900-line plan and split after — the decomposition is different when you plan for self-contained files from the start.

#### Plan header (required on every plan)

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds or fixes]

**Architecture:** [2–3 sentences about the approach]

**Working directory for all commands:** `<absolute path to project root>`

**Maintainability expectations:**
- Reuse existing components, hooks, utilities, and constants wherever they fit — do not create parallel implementations.
- Use existing theme/design tokens for every spacing, color, radius, duration, font, and shadow value — no raw numbers or hex values unless a token genuinely does not exist (document the exception).
- Match the naming conventions used by 2–3 nearest peer files (storage keys, constant names, component names, hook names).
- No hardcoded strings, numbers, or paths that should live in config, theme, or constants files.
- Every change must leave the codebase cleaner or equally clean — never worse.

---
```

#### Phase structure (required per phase)

Each phase is a checklist of bite-sized steps an agent can follow without guessing.

````markdown
## Phase N — [Short name]

**Objective:** [One sentence, testable]

**Problem:** [What's wrong today — cite file paths and line numbers]

**Files changed:**
- Create: `exact/path/to/new/file.tsx`
- Modify: `exact/path/to/existing/file.tsx:123-145`
- Delete: `exact/path/to/old/file.tsx`
- Test: `exact/path/to/__tests__/file.test.tsx`

### Steps

- [ ] **Step 1: [Action in 2–5 minutes]**

  [One-sentence intent.]

  ```tsx
  // exact file path + line range
  // the actual code change — copy-pasteable, complete, production-ready
  ```

- [ ] **Step 2: Verify the change compiles**

  Run: `cd <working directory> && npx tsc --noEmit`
  Expected: exit 0, zero errors in the touched files.

- [ ] **Step 3: [Next action]**

  ```tsx
  // exact code
  ```

- [ ] **Step N: Commit**

  ```bash
  cd <working directory> && git add <exact files> && git commit -m "<message>"
  ```

### Definition of Done

**Functional DoD** — what the user/system can observe:
- [specific, testable outcome]
- [specific, testable outcome]

**Code DoD** — mechanical verification commands (every one must be runnable and produce a checkable result):

```bash
cd <working directory> && npx tsc --noEmit
cd <working directory> && grep -n "<pattern>" <file>   # expected: N matches / 0 matches
cd <working directory> && git grep -n "TODO:\|DEFERRED:" <touched files>   # expected: 0
```

**Cleanliness self-check** — the implementer must confirm all of these before marking the phase done:
- [ ] No raw numbers/hex/strings where a theme token, constant, or config value exists
- [ ] No duplicated logic — every helper/component/hook I introduced was checked against existing exports first
- [ ] Naming matches the 2–3 nearest peer examples
- [ ] No new file created when an existing file could house the change cleanly
- [ ] No dead code, commented-out code, unused imports, or stray `console.log`s left behind
- [ ] The diff is the *minimum* needed to meet the objective — no scope creep
````

#### Anti-patterns (never write these in a phase)

| Anti-pattern | Why it fails |
|-------------|-------------|
| "Add the handler" (no code) | Implementer has to invent it |
| "Similar to Phase 1" | Implementer may read phases out of order — repeat the code |
| `/* deps */`, `/* TODO */`, `...` | Content is missing |
| "Add appropriate error handling" | Show the actual error handling |
| "Write tests for the above" (no test code) | Show the actual tests |
| Empty dependency arrays `[]` when the closure captures values | Stale closure bug waiting to happen |
| Shell commands without working directory | May run from wrong location |
| Type casts without tracing the type definition | May hide type errors |
| Numeric constants asserted without a source citation | Asserted without evidence |
| Raw hex colors / raw spacing numbers / raw durations | Should be theme tokens |
| "Create a new helper for X" without checking whether one exists | Duplicated logic |

#### Plan-wide sections (append after the last phase)

- **Maintainability summary** — which existing patterns/components/hooks the plan reuses, with file paths
- **NTH notes** — related issues found during codebase mapping that are out of scope
- **Risks** — known unknowns, fragile assumptions, blast-radius concerns

### Step 4 — Self-check (planner verifies the plan document)

Run this checklist before handing off. This is about the plan itself — not the code. (The "Cleanliness self-check" inside each phase template is for the implementer to run on their code later.)

1. **Checklist format** — every phase has at least one `- [ ] **Step N: …**` entry and every code step contains the actual code (not prose).
2. **No placeholders** — scan the plan for the anti-patterns in Step 3. Fix any you find.
3. **Numeric constants** — traced to source code? Read the styles/theme/layout and cite evidence. If the value is variable, document that and choose the right API.
4. **Code snippets** — implementation-ready?
   - Shell commands include the working directory.
   - Type casts traced to actual type definitions — cite location, confirm compatibility.
5. **Optimization preconditions** — verified?
   - `React.memo`: parent prop stability checked. Unstable props documented as known limitations.
   - `useCallback`: exact deps specified with rationale for each.
   - Virtualization: height strategy matches actual layout (fixed vs. variable).
6. **Adjacent code** — ±20 lines around each change site scanned? Related issues documented as NTH notes.
7. **Breaking interface changes** — if a phase makes an optional field required or removes a shared interface field, test files constructing that interface are listed in "Files changed."
8. **Hook migration sites** — if migrating from a direct API call to a React hook, each site verified:
   - No early returns, conditionals, or loops before the hook call.
   - Hook not inside a callback, `useMemo`, `useEffect`, or nested function.
   - Line numbers cited as evidence.
9. **Cleanliness self-check is present on every phase** — every phase's DoD includes the "Cleanliness self-check" block from the phase template.
10. **Type consistency** — types, method signatures, and property names used in later phases match what earlier phases defined. A function called `clearLayers()` in Phase 3 but `clearFullLayers()` in Phase 7 is a bug.

### Step 5 — Handoff

Return the plan file path and a concise summary:
- Phase list with objectives
- Key risks or trade-offs
- Any NTH items found during codebase mapping

---

## Red Flags — Plan Smells

| Smell | What it means |
|-------|--------------|
| Plan file exceeds ~500 lines | Split into multiple `-phase-N` files — each independently executable |
| Phase touches 10+ files | Phase is too large — break it down |
| Phase has no verifiable DoD | Phase will "pass" QA vacuously |
| Phase has no `- [ ]` checklist steps | Plan is an outline, not an implementation checklist |
| Phase missing the "Cleanliness self-check" block | Implementer will skip it — add the block |
| Multiple phases modify the same file | Ordering matters — document the dependency |
| A step says what to do but shows no code | Implementer will have to invent it — show the code |
| Raw numbers / hex / spacing values in code snippets | Should be theme tokens or constants |
| "Files changed" doesn't include test files for interface changes | Tests will break mid-implementation |
| NTH section is empty after scanning ±20 lines | Scanning was probably skipped |
