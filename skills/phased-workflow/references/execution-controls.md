# Execution controls

Use this reference for long-running workflows, external/native commands, checkpointed qualification, evidence reuse, cancellation, budgets, and local skill synchronization.

## Stage budget

Before each stage record:
- Expected wall time and model/tool-call range
- Expensive commands and expected duration
- Required, conditional, and advisory checks
- Checkpoint/replay support

At each boundary record actual elapsed time/calls, completed gates, open finding IDs, blocker, and next action. A budget overrun triggers strategy reassessment. It does not create a new approval gate when uninterrupted execution was authorized.

For work lasting more than 30 minutes, send a status update at least every 30 minutes and after any material strategy change.

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

Reuse evidence only on an exact fingerprint match. Advisory receipts stopped by a documented resource ceiling remain advisory and cannot block release.

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

Canonical local source: `${CODEX_HOME:-$HOME/.codex}/skills`.

Mirror these complete directories to `$HOME/.claude/skills`:
- `phased-workflow`
- `phased-plan`
- `phased-review`
- `phased-implement`
- `phased-qa`

Run `phased-workflow/scripts/sync-local-copies.sh`. It mirrors full trees, removes stale files within those five target directories, validates every skill, and checks byte parity. Any mismatch fails the update.
