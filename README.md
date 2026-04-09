# HADI Phased Workflow

A set of Claude Code skills that enforce a structured development workflow: plan, review, approve, implement, and QA. Each stage runs as a separate sub-agent with fresh context.

## How It Works

```
PLAN ──▶ REVIEW ──▶ APPROVE ──▶ IMPLEMENT ──▶ QA
 │          │          │            │           │
 │          │          │            │           │
 Agent A    Agent B    User        Agent C     Agent D
 writes     verifies   reviews     executes    verifies
 the plan   plan vs    and gives   the plan    work vs
            codebase   approval    phase by    plan
                          │        phase
                          │
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

Each stage uses a different agent. The planner doesn't review its own plan. The implementer doesn't QA its own code.

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

- **Fresh agents per stage** — each stage gets a new agent with no context from previous stages, ensuring independent review
- **Evidence-based verification** — every claim must be backed by command output or code reads, not assertions
- **User approval gate** — the pipeline stops after planning and review, and waits for explicit user approval before writing any code
- **Plans as code** — plans include exact file paths, line numbers, and copy-pasteable code snippets

## Documentation

- [Methodology](docs/methodology.md) — principles and rationale
- [Getting Started](docs/getting-started.md) — installation and first run
- [Workflow Stages](docs/workflow-stages.md) — detailed stage breakdown
- [Skill Reference](docs/skills/) — per-skill documentation

## License

MIT — see [LICENSE](LICENSE)

---

[HADI Technology](https://haditechnology.com)
