# Execution controls

Use this reference for long-running workflows, external/native commands, checkpointed qualification, evidence reuse, cancellation, budgets, and local skill synchronization.

## Stage budget

Before each stage record:
- Expected wall time and model/tool-call range
- Expensive commands and expected duration
- Required, conditional, and advisory checks
- Checkpoint/replay support

At each boundary record actual elapsed time/calls, completed gates, open finding IDs, blocker, and next action. A budget overrun triggers strategy reassessment. It does not create a new approval gate when uninterrupted execution was authorized.

Write machine-readable stage telemetry with: stage, risk tier, resolved model tier and runtime model ID, qualification source, escalation reason, seats, start/end timestamps, elapsed seconds, model/tool calls, expensive-command seconds, findings by severity and lifecycle status, reused receipts, reruns, strategy changes, blocker, and next action. Missing required telemetry returns `DONE_WITH_CONCERNS`; open verified findings still block completion.

For work lasting more than 30 minutes, send a status update at least every 30 minutes and after any material strategy change.

## Implementation model routing

Use abstract capability tiers. Resolve concrete provider and model IDs from the current runtime model registry or team configuration at dispatch time. Never encode concrete implementation provider or model names in this routing policy.

- `implementation-standard`: choose the lowest expected-total-cost model that currently clears the implementation capability floor.
- `implementation-premium`: choose the strongest currently qualified implementation model available for high-risk work and capability escalation.

The implementation capability floor requires current evidence of:
- Repository-scale agentic coding, including multi-file edits, terminal/tool use, test execution, and full-output interpretation.
- Reliable adherence to an approved plan, file scope, project conventions, and evidence contract.
- Adequate context and tool support for the slice's language, framework, and integration surface.
- A representative qualification run or recent successful implementation history with acceptable QA rework for the relevant task class.

Do not choose a provider's weakest, entry, or general lightweight model merely because its unit price is lowest. A smaller, faster, or coding-specialized model may qualify when evidence shows it clears the same capability floor. When qualification evidence is missing or stale, use `implementation-premium` until the candidate is qualified outside the live slice.

Choose on expected total cost, not token price alone. Include predicted retries, recovery, context repetition, verification reruns, and escalation probability. Model tier never changes plan fidelity, DoD, test depth, remediation, closure, or fresh independent QA.

Route high-risk slices directly to `implementation-premium`: security/auth/session, money/entitlement, schema migration or irreversible data change, native/permissions, concurrency/process lifecycle, public contracts, or architecture-spanning integration.

Escalate a standard-tier slice when any trigger occurs:
1. The same reasoning, tool-use, or verification-interpretation failure repeats after one targeted correction.
2. The owner proposes an unreviewed architectural deviation or repeatedly invents APIs/evidence.
3. The slice reveals a high-risk surface outside the original classification.
4. Remaining recovery cost is estimated to exceed premium-tier completion cost.

On escalation, stop the current owner, preserve the working diff and evidence receipts, mark all unverified claims, and return `CAPABILITY_ESCALATION`. Resolve `implementation-premium`, transfer ownership once, and reverify all inherited work. Never run competing implementation owners concurrently and never count failed standard-tier attempts as evidence.

## Verification pyramid

1. Edit loop: smallest affected test or probe.
2. Slice gate: affected subsystem tests plus relevant type/lint/behavior checks.
3. Milestone gate: full suite or qualification matrix once after targeted findings close.

Never use a full milestone gate to diagnose a single stable failure.

## Stable failure rule

After two identical failures:
1. Stop unchanged reruns.
2. Record command, exit code, failing assertion/error signature, and receipt.
3. Write one falsifiable hypothesis.
4. Run the smallest diagnostic that can disprove it.
5. Route result as implementation detail, empirical delta, architecture wrong, or environment blocked.

## Checkpoint and replay

Every expensive multi-probe command should support:
- Stable probe ID
- `--only <id>` or equivalent targeted run
- One receipt per probe
- Resume/replay without rerunning completed probes
- One final full matrix after repairs

Receipt fingerprint fields:
- Repository commit and working diff hash
- Plan hash
- Tool/launcher version and relevant binary hashes
- Configuration and environment contract
- Inputs/fixtures and probe ID

Reuse evidence only within the same stage owner on an exact fingerprint match. Agent prose is never evidence. Cross-stage receipts never substitute for fresh review or fresh release-blocking QA. Advisory receipts stopped by a documented resource ceiling remain advisory and cannot block release.

## Durable evidence receipts

Store reusable receipts under a stable workflow run directory, never an ephemeral final path.

For each receipt:
- Write raw output and metadata to a sibling staging directory.
- Record command, exit code, start/end timestamps, byte count, fingerprint, and physical final path.
- Generate SHA-256 hashes for every payload and verify them before publication.
- Atomically rename the staged directory to its final path.
- Retain the receipt through final acceptance.

Before every reuse and final report, require all payloads to exist and reverify hashes plus physical path. A missing, moved, truncated, or mismatched receipt is invalid evidence. Discard the reuse claim and rerun the producer command; never repair evidence manually.

## Active-command lifecycle

Before waiting on a command that can spawn children, record:
- Parent PID and process group
- Owned child discovery method
- Runtime directory, socket paths, temp files, and output files
- Graceful interrupt and forced-termination deadlines

On cancellation:
1. Send interrupt to recorded process group.
2. Wait bounded grace interval.
3. Terminate remaining owned processes only.
4. Verify owned PIDs/process group absent.
5. Verify owned sockets refuse/are absent.
6. Remove owned temporary secrets/state when safe.
7. Write interruption receipt with completed checkpoints.

Never kill unrelated same-name processes. Never claim cleanup from a pathname scan alone when an open file descriptor or detached child can retain access.

## Pre-authorized execution

Record approval scope once: roadmap/plan, uninterrupted execution, branch or main, milestone commit policy, push/PR authority, and destructive-operation authority. Do not reopen an approved gate. Never broaden authorization by inference.

## Local skill parity

Canonical source: tracked `skills/` directory in the phased-workflow Git repository.

Mirror these complete directories to both `${CODEX_HOME:-$HOME/.codex}/skills` and `$HOME/.claude/skills`:
- `phased-workflow`
- `phased-plan`
- `phased-review`
- `phased-implement`
- `phased-qa`

From the Git repository root, run the tracked script twice with explicit roots:

```bash
PHASED_SKILL_SOURCE="$PWD/skills" PHASED_SKILL_TARGET="${CODEX_HOME:-$HOME/.codex}/skills" skills/phased-workflow/scripts/sync-local-copies.sh
PHASED_SKILL_SOURCE="$PWD/skills" PHASED_SKILL_TARGET="$HOME/.claude/skills" skills/phased-workflow/scripts/sync-local-copies.sh
```

The script mirrors full trees, removes stale files only within the five named target directories, validates source and target skills, and checks byte parity. Any mismatch fails the update. Never reverse-sync a mirror into Git.
