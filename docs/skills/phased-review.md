# phased-review

Reviews a plan against the actual codebase before implementation. Verifies every claim the plan makes by reading the source.

## Triggers

`/prv`, `prv:`, `phased-review`

## What It Does

1. Loads and parses the plan file
2. Reads every file listed in the plan's "Files changed" sections
3. Verifies plan claims against actual code
4. Evaluates plan quality (objectives, DoD, sequencing, maintainability, blast radius)
5. Writes findings with severity and evidence

## Inputs

A plan file path (asks if not provided).

## Outputs

- Per-phase review with strengths, findings, and blast radius assessment
- Overall readiness: `ready` or `not-ready`
- Required changes table with severity, phase, and exact plan edit needed
- Codebase analysis: existing patterns to reuse, affected components, risks

## What It Checks

**Numeric constants** — traces every value to source code. Flags values asserted without evidence or fixed constants used for variable-sized content.

**Code completeness** — verifies every snippet is copy-pasteable. Flags placeholders, incomplete dependency arrays, missing type parameters, shell commands without working directory.

**Optimization preconditions** — checks that `React.memo`, `useCallback`, virtualization, and lazy loading will actually be effective given the surrounding code.

**Adjacent code** — scans 20 lines around each change site for related issues the plan missed.

**Breaking changes** — checks that test files are included when interfaces change.

**Hook migrations** — verifies Rules of Hooks compliance at each migration site.

## Severity Levels

- **Critical** — plan will fail or produce broken code
- **High** — plan will produce suboptimal or incorrect results
- **Medium** — plan misses something that should be addressed
- **Low** — minor improvement or NTH item
