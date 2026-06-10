# Getting Started

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) installed and configured
- A project repository to work in

## Installation

Clone the repo and copy the skills into your Claude Code configuration:

```bash
git clone https://github.com/hadi-technology/phased-workflow.git
cp -r phased-workflow/skills/* ~/.claude/skills/
```

Verify the skills are installed:

```bash
ls ~/.claude/skills/phased-*/SKILL.md
```

You should see five files:
```
~/.claude/skills/phased-implement/SKILL.md
~/.claude/skills/phased-plan/SKILL.md
~/.claude/skills/phased-qa/SKILL.md
~/.claude/skills/phased-review/SKILL.md
~/.claude/skills/phased-workflow/SKILL.md
```

## Your First Run

Open Claude Code in your project directory and trigger the workflow:

```
pw: Add input validation to the user registration form
```

### What Happens Next

**Stage 1 — Planning.** Claude dispatches a planning agent. It reads your codebase, maps the files it needs to change, and writes a detailed implementation plan with exact code snippets. This takes a few minutes depending on project size.

**Stage 2 — Review.** A different agent reviews the plan against your actual codebase. It verifies file paths, checks that code snippets match reality, and flags issues. The orchestrator fixes any findings.

**Stage 3 — Approval.** Claude presents you with:
- The plan file path
- A summary of each phase
- What the review caught and fixed

It then asks for your explicit approval. This is your chance to:
- Read the plan file in detail
- Ask questions about the approach
- Request changes
- Approve and proceed

**Stage 4 — Implementation.** On approval, a fresh agent executes the plan phase by phase. Each phase is verified against its Definition of Done before moving to the next.

**Stage 5 — QA.** A different agent verifies all completed work against the plan. It runs checks, reads the code, and reports findings. Any issues are fixed before the final report.

## Triggers

| Trigger | Effect |
|---------|--------|
| `pw:` | Start the full pipeline |
| `/pw` | Same as `pw:` |
| `phased-workflow:` | Same as `pw:` |
| `/plan` | Run only the planning stage |
| `/prv` | Run only the review stage (provide a plan path) |
| `/implement` | Run only the implementation stage (provide an approved plan path) |
| `/pqa` | Run only the QA stage (provide a plan path) |

## The Approval Gate

The approval gate is the most important part of the workflow. Here's how it works:

| What you say | What happens |
|-------------|-------------|
| "approved", "go ahead", "lgtm", "do it" | Implementation begins |
| "what about X?", "can we change Y?" | Plan is updated, re-presented |
| Nothing | Pipeline waits |

You can also ask Claude to show you the plan file directly — it's a markdown file in your `plans/` directory that you can read, edit, or share.

## Plan Files

Plans are saved to `plans/<date>-<slug>.md` in your project. They're version-controllable, shareable, and human-readable. Each plan includes:

- Objectives and architecture
- Phase-by-phase implementation steps with exact code
- Definition of Done for each phase
- Cleanliness self-check criteria
- Risks and NTH notes

Large tasks are split into multiple plan files (`-phase-1.md`, `-phase-2.md`) — each self-contained and independently executable.

## Tips

- **Be specific in your trigger.** "pw: Add caching" is vague. "pw: Add Redis caching to the /api/users and /api/posts endpoints with a 5-minute TTL" gives the planner what it needs.
- **Read the plan.** The approval gate exists for a reason. The plan shows every file that will change and every line of code that will be written. Review it.
- **Use individual skills when appropriate.** You don't always need the full pipeline. `/plan` is useful for planning without auto-implementing. `/pqa` is useful for verifying existing work.
