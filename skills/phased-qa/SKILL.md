---
name: phased-qa
version: "2.2.0"
description: "Post-implementation QA. Verifies completed work against the plan's objectives and DoD — runs checks, reads code, audits cleanliness. Evidence before claims. Triggers: phased-qa, /pqa, pqa:"
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

### Step 2 — Run verification commands

For each phase, run every verifiable check from the DoD:

```
FOR each DoD item:
  1. IDENTIFY: What command or code read proves this?
  2. RUN: Execute the command (fresh, not cached)
  3. READ: Full output — exit code, counts, errors
  4. COMPARE: Does output confirm the DoD item?
     - YES → record as pass with evidence
     - NO → record as fail with evidence
```

**Common verification commands:**
| DoD type | Verification |
|----------|-------------|
| "No X remains in codebase" | `grep` / `git grep` — show zero hits |
| "TypeScript compiles" | `npx tsc --noEmit` — show exit 0 |
| "Tests pass" | Test runner output — show pass count, zero failures |
| "Component uses pattern X" | Read the file, confirm the pattern |
| "No regressions" | Run full test suite, compare to baseline |

**Never sufficient:**
- "Should pass now" — run it
- "I changed it, so it works" — verify it
- "Same as before" — prove it
- Previous run output — run it fresh

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
- **Theme tokens / constants used everywhere?** Scan the diff for raw hex colors, raw spacing numbers, raw border radii, raw font sizes, raw durations, raw shadow values. If a theme token, constant, or config value covers the same semantic meaning, flag every raw value as medium-severity.
- **No hardcoded strings, numbers, or paths that belong in config/constants?** User-facing strings, magic numbers, API paths, storage keys — check each one lives in its canonical location.
- **Naming matches conventions?** Read 2–3 nearest peer files and compare naming of components, hooks, constants, storage keys, style keys. Flag divergences.
- **Minimum diff?** Are there changes that go beyond the plan's stated objective? Flag scope creep.
- **No dead leftovers?** No commented-out code, no unused imports, no stray `console.log`, no orphaned style keys, no `// TODO:` introduced in touched files.
- **No duplicated logic?** Same pattern written twice (within the diff or as a copy of code elsewhere) should be extracted or reusing an existing abstraction.

Report cleanliness issues as findings with evidence (file path + the offending line), the same as any other QA finding.

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
| "Looks correct" without reading the file | Read the actual changed code |
| Skipping a DoD item because "it's obvious" | Verify every item — obvious things break too |
| Marking pass because tests pass | Tests ≠ QA. Tests pass but DoD may not be met. |
| Omitting low-severity findings | Report everything. Low-severity issues compound. |
| Accepting "close enough" | The DoD says what it says. Met or not met. |

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
