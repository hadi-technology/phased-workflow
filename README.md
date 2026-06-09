# HADI Phased Workflow

A set of [Claude Code](https://claude.ai/claude-code) skills that enforce a structured, multi-agent development workflow — built to deliver high-quality, reliable outputs without burning through your token budget.

Each stage runs as a separate sub-agent with fresh context. Sub-agents spawn their own sub-agents for verification throughout the process — the planner self-checks before handoff, the reviewer verifies claims against the actual codebase, the implementer runs DoD checks per phase. The final QA stage is a dedicated gate that requires all findings to be remediated before the workflow is considered complete.

## Quality and Cost

These skills were designed around one constraint: **Opus where it matters, Sonnet everywhere else.**

Most agent work is mechanical — reading files, running greps, following a plan, writing code to a spec. Sonnet handles all of that. Opus is reserved for the moments where independent design judgment actually changes the outcome: the fresh-eyes review pass that catches what the first reviewer rationalized, the wave-level QA that spots cross-task integration issues, the fix-loop escalation after a first round fails to converge.

A few concrete examples of how cost is controlled without sacrificing quality:

- **Model selection is mechanical, not per-row.** Implementation always runs on Sonnet. Opus fires at specific gates (Pass 2 review, wave QA, final QA, fix-loop Round 2). No per-task "this feels complex, use Opus" leakage.
- **QA tiering cuts dispatch cost on low-risk work.** Rows are classified `standard` or `critical` based on investigation signals (systemic blast radius, schema changes, data-layer involvement, P0 priority). Standard rows skip per-task QA entirely — wave QA absorbs their verification. Critical rows get belt-and-suspenders (per-task QA + independent wave re-verification). The result: the per-task QA budget is spent where it actually reduces risk, not uniformly across every row.
- **Whole-system checks collapse to once per wave.** TypeScript, tests, and lint run once after all wave commits land — not once per task. On a 17-task wave, that's one `tsc` run instead of seventeen.
- **Disk-first subagent reports keep context lean.** Every subagent writes its full report to disk and returns only a short status line (≤300 tokens). This prevents cache-write thrash across long runs — on a 50+ row backlog the difference is the run fitting in one session vs not.
- **Two review passes, not three.** The plan goes through two independent review passes (Sonnet for mechanical verification, Opus for fresh-eyes judgment). After that, it ships to execution. A third pass has steeply diminishing returns; the right fix for a review miss is stronger upstream investigation, not more review cycles.

## How It Works

### Single-task pipeline (`phased-workflow`)

```
PLAN ──▶ REVIEW ──▶ APPROVE ──▶ IMPLEMENT ──▶ QA ──▶ REMEDIATE
 │          │          │            │           │        │
 │          │          │            │           │        │
 Agent A    Agent B    User        Agent C     Agent D  Orchestrator
 writes     verifies   reviews     executes    verifies fixes all
 the plan   plan vs    and gives   the plan    work vs  QA findings,
 + self-    actual     approval    phase by    plan &   re-verifies,
 checks     codebase                phase +    code     reports
                          │        per-phase
                          │        DoD checks
                     ┌────┴────┐
                     │  HARD   │
                     │  GATE   │
                     │         │
                     │ Nothing │
                     │ proceeds│
                     │ without │
                     │ explicit│
                     │ approval│
                     └─────────┘
```

### Backlog pipeline (`hadi-planner` → `hadi-builder`)

For larger features that span multiple tasks, use the two-stage backlog pipeline:

```
hadi-planner                            hadi-builder
────────────────────────────────────    ──────────────────────────────────────
Brainstorm ──▶ Investigate codebase     Read CSV ──▶ Plan waves
     │              │                        │
     ▼              ▼                        ▼
Scaffold CSV ──▶ Review ×2   ──────▶   Wave N: parallel implement + QA
(phased-plan)  (pass 1: Sonnet         per task ──▶ wave QA ──▶ commit
                pass 2: Opus)               │
     │                                      ▼  (repeat per wave)
     ▼                                      │
Lock decisions ──▶ User approves       Final QA ──▶ End-of-run report
                        │                   │
                        └── CSV handed ─────┘
                            to hadi-builder       ▼
                                            Push gate (one approval)
```

`hadi-planner` scopes and decomposes the work into an investigated, decision-locked CSV backlog. `hadi-builder` executes it autonomously — dispatching parallel subagents per wave, committing each wave, and asking for a single push approval at the end.

Each stage uses a different agent. The planner doesn't review its own plan. The implementer doesn't QA its own code. QA findings are not optional — every finding is remediated before the workflow completes.

## Installation

```bash
git clone https://github.com/hadi-technology/phased-workflow.git
cp -r phased-workflow/skills/* ~/.claude/skills/
```

## Usage

Trigger the full pipeline:

```
pw: Add a caching layer to the API endpoints
```

The orchestrator will plan, review, present for approval, implement on approval, and QA the result.

You can also run individual stages:

| Skill | Trigger | What it does |
|-------|---------|--------------|
| [phased-workflow](docs/skills/phased-workflow.md) | `/pw`, `pw:` | Runs the full single-task pipeline |
| [phased-plan](docs/skills/phased-plan.md) | `/plan` | Writes an implementation plan |
| [phased-review](docs/skills/phased-review.md) | `/prv` | Reviews a plan against the codebase |
| [phased-implement](docs/skills/phased-implement.md) | `/implement` | Executes an approved plan |
| [phased-qa](docs/skills/phased-qa.md) | `/pqa` | Verifies completed work against the plan |
| hadi-planner | `/hadi-planner` | Scopes a feature into an investigated, decision-locked CSV backlog |
| hadi-builder | `/hadi-builder` | Executes a CSV backlog autonomously via parallel wave subagents |
| hadi-bugfix | `/hadi-bugfix` | Investigate-first bugfix workflow: root cause → report → approve → fix → verify |

## Key Concepts

- **QA throughout, not just at the end** — the planner self-checks, the reviewer verifies against source, the implementer runs DoD checks per phase, and a final QA agent audits the completed work. The final QA gate requires full remediation before the workflow is done.
- **Fresh agents per stage** — each stage gets a new agent with no context from previous stages, ensuring independent review
- **Evidence-based verification** — every claim must be backed by command output or code reads, not assertions
- **User approval gate** — the pipeline stops after planning and review, and waits for explicit user approval before writing any code
- **Plans as code** — plans include exact file paths, line numbers, and copy-pasteable code snippets
- **Built on Superpowers** — skill instructions follow [Superpowers](https://github.com/anthropics/superpowers) patterns for structured agent behavior, producing more consistent and higher quality outputs

## Documentation

- [Methodology](docs/methodology.md) — principles and rationale
- [Getting Started](docs/getting-started.md) — installation and first run
- [Workflow Stages](docs/workflow-stages.md) — detailed stage breakdown
- [Skill Reference](docs/skills/) — per-skill documentation

## License

MIT — see [LICENSE](LICENSE)

---

[HADI Technology](https://haditechnology.com)
