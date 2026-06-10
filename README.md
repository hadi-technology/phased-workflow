# HADI Phased Workflow

**A set of [Claude Code](https://claude.ai/claude-code) skills that turn a feature request into a machine-verifiable CSV backlog — then execute it autonomously, with the right model on the right job, so the work ships correctly the first time.**

Most AI coding agents start typing immediately. No plan, no independent review, no structured verification — and no defense against the agent quietly drifting from what you actually asked for. The result is code that *looks* done and needs a second pass to actually be done.

HADI is built around a different idea: **orchestrate a team of specialized agents, make it structurally hard to deviate from intent, and only spend on the expensive model where judgment actually changes the outcome.**

### Watch the 60-second overview

[![HADI — AI Orchestration Tools (watch on YouTube)](https://img.youtube.com/vi/kJf65AYY4JU/maxresdefault.jpg)](https://youtu.be/kJf65AYY4JU)

---

## Why HADI is different

### 1. It's an orchestration layer, not a single agent

HADI isn't one agent doing everything — it's a **two-stage orchestration system** where specialized agents own distinct phases and an orchestrator coordinates them. The two top-level skills divide the job cleanly:

- **`hadi-planner` — the scope owner.** It brainstorms scope with you, dispatches parallel `Explore` agents to map the codebase, scaffolds the CSV backlog, runs two independent review passes, and locks every decision you have a stake in. It produces an approved backlog. It does **not** write product code.
- **`hadi-builder` — the execution owner.** It takes the approved CSV, computes execution waves, dispatches parallel implement + QA subagents per wave, runs the wave gate, commits each wave, and generates an end-of-run report. It runs **fully autonomous** mid-run — one human touchpoint, the final push approval.

The orchestrator's defining rule: **it never does the work itself.** It plans the waves, dispatches the agents, verifies their evidence, and coordinates the next step. The actual reading, writing, and verifying happens in subagents — and the orchestration is **hierarchical**: the builder dispatches wave subagents, and those subagents spawn their *own* verification sub-agents. Implementation, per-task QA, wave QA, and final QA are each a different agent.

This buys two things a single long-running agent can't have:

- **Context isolation as an architecture, not an afterthought.** Every stage gets a *fresh agent with no memory of previous stages*. The planner can't review its own plan. The implementer can't QA its own code. The fresh-eyes reviewer hasn't seen the first reviewer's findings. Independent verification is structural — an agent literally cannot rubber-stamp work it never saw.
- **An orchestrator that stays lean enough to coordinate 50+ rows.** Every subagent writes its full report to disk and returns only a short status line (≤300 tokens). The orchestrator's context never fills with the body of the work, so it can conduct a long backlog end-to-end without losing the thread.

Everything below — the CSV contract, the intent-locking, the wave gates, the model tiering — is *how* this orchestration layer enforces quality at each handoff.

### 2. The CSV backlog is a contract, not a to-do list

The thing that makes HADI unusual is its intermediate representation. Instead of handing the implementation agent a prose plan it can interpret loosely, HADI's planner compiles your intent into a **14-column CSV backlog** — one row per atomic unit of work.

```
id, title, status, priority, qa_tier, effort, impact, grouping, depends_on,
scope_candidates, problem, desired_outcome, acceptance_criteria, notes
```

This isn't a formatting preference. A CSV row is a **constraint surface**. Each field narrows the space the implementer is allowed to operate in:

- **`scope_candidates`** — the exact, pre-verified file paths the row may touch. The planner confirms every path exists with `Read`/`Glob` *before* writing it. The executor's QA then cross-references the actual `git diff --name-only` against this list — touch a file that isn't here and it's flagged as scope creep. This is described internally as "the single most important field."
- **`acceptance_criteria`** — the row's definition of done, expressed as **greppable patterns, exact commands, or observable states** — never "works correctly." At plan time, every `grep`/`git grep` in this field is *run against the live source* and the result count compared to expectation. Vague, prose-only criteria are rejected at scaffolding.
- **`notes`** — carries the row's **locked decisions** and four mandatory rigor checks (see below). Because the executor reads `notes` per row with *no access to the conversation history*, every decision you have a stake in must be unambiguous from the row text alone.
- **`depends_on`** — exact, cycle-checked dependency ids. This is what lets the executor compute a correct execution order mechanically.

**Why a CSV and not a markdown plan?** Because structure buys you guarantees prose can't:

| Property | What it gives you |
|----------|-------------------|
| One row = one atomic unit (5–10 min of work) | Scope that isn't in a row has **nowhere to enter** — there's no narrative seam to smuggle work into. Adding scope means adding a row, which passes the same gates as every other row. |
| Uniform machine-readable columns | The executor runs **deterministic algorithms** over the backlog — topological sort over `depends_on`, parallel-safety by file overlap, mechanical QA-tier dispatch. You can't topologically sort a paragraph. |
| Per-row runnable acceptance criteria | Every row carries **its own verification gate** — a command that either passes or fails. |
| A `status` column committed per wave | Runs are **resumable and diffable**. A halted run picks up from committed state; shipped rows show as line diffs in git. |
| Decisions travel *with* the unit | The locked decision and the rigor evidence are physically attached to the row — readable by an executor with zero chat context. |

The net effect: **intent-to-execution drift is engineered out.** The implementation agent isn't asked to remember what you meant — it's handed a row that already says it, with the files, the done-condition, and the decision baked in.

### 3. Intent is locked *before* a single line is written

Two mechanisms make the rows trustworthy before they reach the executor:

**Investigation-first, evidence-required.** Every row earns four checks during planning, each recorded in `notes` with `file:line` evidence:

- **Pattern scan** — does this already exist? A row that adds a component when one already exists is "a defect, not a feature." The scan is the evidence that no parallel implementation is being created.
- **Blast radius** — what else does this touch? If the verdict is *systemic*, the row's `scope_candidates` must list **all** affected siblings, not just the one you noticed.
- **Multi-layer validation** — which layers (UI / API / data) does the change cross?
- **Pre-existing state** — migrations, recency filters, cleanup-on-read, and other footguns are surfaced with line references.

This is HADI's anti-hallucination layer. The reviewing pass that follows operates on a hard rule: **"Trust nothing in the plan. Read the source."**

**Decision-locking.** Before handoff, the planner finds every row where the executor "could satisfy `acceptance_criteria` two different ways where the user might prefer one" — and surfaces it as an A/B choice *with a mandatory recommendation*. Your answer is written into that row's `notes` as a self-contained `User decision:` line. The contract is explicit:

> Once the planner hands off the CSV, the executor is forbidden from asking you a single question mid-run — except the one push approval at the end. This is the principle that makes 100-item autonomous runs possible.

### 4. Wave execution: verify each milestone before the next

The executor (`hadi-builder`) reads the CSV and computes **waves** — milestone groupings derived from the structure you already encoded:

1. **Topological sort over `depends_on`** — rows with no deps are wave 1; rows depending only on wave 1 are wave 2; and so on.
2. **Parallel-safety by blast radius** — two rows run in parallel *only if* their `scope_candidates` have **zero file overlap**. Even one shared file → serialize. Conservative on purpose.

Every wave passes a **5-check gate before it commits**: acceptance + rigor verification against the actual diff, independent re-verification of critical rows, whole-system checks (typecheck / tests / lint / backlog-marker scan), cross-task integration, and **cross-wave regression** — re-running the done-condition for *every* dependent file, not a spot check. A previously-passing dependent that now fails is the one condition that halts the run.

Because each milestone is verified before the next begins, problems are caught at the wave boundary instead of surfacing as a pile of post-implementation fixes. **Little to no rework after the run.**

### 5. The right model on the right job — quality without the Opus tax

Reliability usually means "use the most powerful model for everything." That's also the fastest way to burn your budget. HADI rejects the trade-off. Its rule, stated near-verbatim in the skills:

> **Opus where it matters, Sonnet everywhere else.**

Most agent work is mechanical — reading files, following an investigated plan, writing code to a spec, running greps to verify. **Sonnet does all of it.** Opus is reserved for the handful of moments where independent design judgment actually changes the outcome:

| Runs on **Sonnet** (mechanical execution) | Runs on **Opus** (judgment that changes the outcome) |
|---|---|
| All implementation | Planner's Pass-2 fresh-eyes review |
| Codebase exploration & CSV scaffolding | Wave QA (cross-task / cross-wave integration) |
| Pass-1 mechanical review | Final end-of-backlog QA |
| Per-task QA verification | Cross-wave regression fixes |
| Fix-loop Round 1 | Fix-loop Round 2 (escalation after Round 1 didn't converge) |

The reasoning is deliberate: *design judgment lives in planning, not execution.* If a row reaches the executor and "needs Opus" to implement, the plan was under-specified — the fix is a better plan, not a model upgrade. Removing per-row model choice eliminated "the largest unintended spend leak in prior runs."

That economy compounds through the rest of the design:

- **Whole-system checks collapse to once per wave.** A 17-task wave used to run `tsc` 17 times; now it runs once after the wave's commits land — same evidence, a fraction of the compute.
- **QA tiering spends verification where risk is.** Rows are mechanically classified `standard` or `critical` from their rigor signals (systemic blast radius, schema/data-layer involvement, P0 priority). `standard` rows skip per-task QA — wave QA absorbs them. `critical` rows get belt-and-suspenders.
- **Disk-first reports keep context lean.** Every subagent writes its full report to disk and returns a status line capped at **≤300 tokens**. On long runs this is the difference between fitting in one session and not — verbose returns are the single largest source of prompt-cache thrash.
- **Two review passes, not three.** A third pass has steeply diminishing returns; the right fix for a review miss is stronger upstream investigation, not more review cycles.

The result is a workflow tuned for **reliable, consistent output at a fraction of the cost of running the top model end-to-end** — without ever under-specifying a complex task to save a dollar.

---

## How it works

### Backlog pipeline (`hadi-planner` → `hadi-builder`)

For features that span multiple tasks:

```
hadi-planner                            hadi-builder
────────────────────────────────────    ──────────────────────────────────────
Brainstorm ──▶ Investigate codebase     Read CSV ──▶ Compute waves
     │              │                        │      (deps + file-overlap)
     ▼              ▼                        ▼
Scaffold CSV ──▶ Review ×2   ──────▶   Wave N: parallel implement + QA
(14 columns)   (pass 1: Sonnet          per task ──▶ 5-check wave gate ──▶ commit
                pass 2: Opus)               │
     │                                      ▼  (repeat per wave)
     ▼                                      │
Lock decisions ──▶ User approves       Final QA ──▶ End-of-run report
                        │                   │
                        └── CSV handed ─────┘
                            to hadi-builder       ▼
                                            Push gate (one approval)
```

`hadi-planner` scopes and decomposes the work into an investigated, decision-locked CSV backlog. `hadi-builder` executes it autonomously — dispatching parallel subagents per wave, committing each wave, and asking for a **single** push approval at the very end. Fully autonomous mid-run; it only halts on a cross-wave regression that survives two fix rounds.

### Single-task pipeline (`phased-workflow`)

For a focused, single change, the lighter orchestrator runs the same separation-of-concerns discipline without the CSV:

```
PLAN ──▶ REVIEW ──▶ APPROVE ──▶ IMPLEMENT ──▶ QA ──▶ REMEDIATE
 │          │          │            │           │        │
 Agent A    Agent B    User        Agent C     Agent D  Orchestrator
 writes     verifies   reviews     executes    verifies fixes all
 the plan   plan vs    + gives     the plan    work vs  QA findings,
 + self-    actual     approval    phase by    plan &   re-verifies,
 checks     codebase                phase +    code     reports
                          │        per-phase
                     ┌────┴────┐    DoD checks
                     │  HARD   │
                     │  GATE   │
                     │ nothing │
                     │ proceeds│
                     │ without │
                     │ approval│
                     └─────────┘
```

Across both pipelines the rule is the same: **each stage gets a fresh agent.** The planner doesn't review its own plan. The implementer doesn't QA its own code. QA findings are not optional — every finding is remediated before the workflow completes.

---

## Installation

```bash
git clone https://github.com/hadi-technology/phased-workflow.git
cp -r phased-workflow/skills/* ~/.claude/skills/
```

## Usage

Run the full backlog pipeline for a multi-task feature:

```
/hadi-planner  Add team workspaces with role-based access
```

The planner brainstorms scope with you, investigates the codebase, scaffolds the CSV, runs two review passes, locks every decision, and presents the backlog for approval. On approval, hand it to the executor:

```
/hadi-builder
```

…which runs the backlog wave by wave and asks for one push approval at the end.

For a single, focused change, use the lighter orchestrator:

```
pw: Add Redis caching to the /api/users and /api/posts endpoints with a 5-minute TTL
```

You can also run individual stages:

| Skill | Trigger | What it does |
|-------|---------|--------------|
| hadi-planner | `/hadi-planner` | Scopes a feature into an investigated, decision-locked CSV backlog |
| hadi-builder | `/hadi-builder` | Executes a CSV backlog autonomously via parallel wave subagents |
| hadi-bugfix | `/hadi-bugfix` | Investigate-first bugfix: root cause → report → approve → fix → verify |
| [phased-workflow](docs/skills/phased-workflow.md) | `/pw`, `pw:` | Runs the full single-task pipeline |
| [phased-plan](docs/skills/phased-plan.md) | `/plan` | Writes an implementation-ready phased plan |
| [phased-review](docs/skills/phased-review.md) | `/prv` | Reviews a plan against the actual codebase |
| [phased-implement](docs/skills/phased-implement.md) | `/implement` | Executes an approved plan with per-phase DoD checks |
| [phased-qa](docs/skills/phased-qa.md) | `/pqa` | Verifies completed work against the plan |

## Key concepts

- **Orchestration, not a lone agent** — `hadi-planner` owns scope, `hadi-builder` owns execution, and the orchestrator coordinates specialized subagents instead of doing the work itself. Each handoff is a quality gate.
- **The CSV is the contract** — one row per atomic unit, with exact file targets, runnable acceptance criteria, and locked decisions. Intent is encoded as structure, not prose, so the implementer has almost no room to deviate.
- **Investigation before implementation** — every row carries pattern-scan, blast-radius, layer, and pre-existing-state evidence with `file:line` citations. New code requires explicit justification that an existing pattern wasn't reused.
- **Decisions locked once, up front** — every user-stake choice is resolved at planning and written into the row. The executor never interrupts you mid-run except for the final push approval.
- **Wave-by-wave verification** — milestones are grouped by dependency and blast radius, and each wave passes a 5-check gate (including cross-wave regression) before the next begins. Little to no post-run rework.
- **Opus where it matters, Sonnet everywhere else** — mechanical work runs on the cheaper model; the expensive model is reserved for integration judgment and fresh-eyes review. Reliable output without the top-model bill.
- **Fresh agents per stage, evidence over assertion** — independent verification at every boundary, every claim backed by command output or a code read.

## Documentation

- [Methodology](docs/methodology.md) — principles and rationale
- [Getting Started](docs/getting-started.md) — installation and first run
- [Workflow Stages](docs/workflow-stages.md) — detailed stage breakdown
- [Skill Reference](docs/skills/) — per-skill documentation

## License

MIT — see [LICENSE](LICENSE)

---

[HADI Technology](https://haditechnology.com)
