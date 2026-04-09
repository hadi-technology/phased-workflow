# HADI Phased Workflow

A set of [Claude Code](https://claude.ai/claude-code) skills that enforce a structured development workflow with sub-agent QA at every stage. Built on top of [Superpowers](https://github.com/anthropics/superpowers) for higher quality skill instructions and agent outputs.

Each stage runs as a separate sub-agent with fresh context. Sub-agents spawn their own sub-agents for verification throughout the process — the planner self-checks before handoff, the reviewer verifies claims against the actual codebase, the implementer runs DoD checks per phase. The final QA stage is a dedicated gate that requires all findings to be remediated before the workflow is considered complete.

## How It Works

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

Each stage uses a different agent. The planner doesn't review its own plan. The implementer doesn't QA its own code. QA findings are not optional — every finding is remediated before the workflow completes.

## Installation

```bash
git clone https://github.com/hadi-technology/hadi-phased-workflow.git
cp -r hadi-phased-workflow/skills/* ~/.claude/skills/
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
| [phased-workflow](docs/skills/phased-workflow.md) | `/pw`, `pw:` | Runs the full pipeline |
| [phased-plan](docs/skills/phased-plan.md) | `/plan` | Writes an implementation plan |
| [phased-review](docs/skills/phased-review.md) | `/prv` | Reviews a plan against the codebase |
| [phased-implement](docs/skills/phased-implement.md) | `/implement` | Executes an approved plan |
| [phased-qa](docs/skills/phased-qa.md) | `/pqa` | Verifies completed work against the plan |

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
