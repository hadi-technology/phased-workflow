# External reviewer seats

Use this reference only when phased-workflow dispatches an external headless plan-review or QA seat.

## Contract

- Use at most one external seat per gate.
- Prefer qualified Cursor CLI `agent`. Fall back to another available provider.
- Run external seat concurrently with internal seats.
- Treat seat as read-only and advisory. Only planner or implementation owner applies fixes.
- Merge every verified finding regardless of source or severity.
- Do not require consensus. Adjudicate conflicting findings against source and executable evidence.
- Check availability once per workflow. One failed call gets no automatic retry unless failure is a transient launch error with no model turn.

## Cursor seat

Availability:

```bash
command -v agent >/dev/null && agent --version
```

Preferred invocation:

```bash
agent --print \
  --output-format json \
  --mode ask \
  --sandbox enabled \
  --trust \
  --model composer-2.5 \
  --workspace <absolute-repo-root> \
  '<prompt requiring JSON findings only>'
```

`ask` is the review mode. Native sandbox reduces risk but is not a hostile-provider containment boundary. The CLI may write same-UID session/runtime state outside the workspace. Use an already-qualified launcher and follow process cleanup in `execution-controls.md`.

Prompt requirements:
- Name plan/diff, base commit, review round, finding IDs when Round 2, and working directory.
- State: do not modify product files, plan files, git state, or external systems.
- Require every finding to include stable ID, file, line, severity, category, summary, failure scenario, and evidence.
- Round 1: scan full requested surface.
- Round 2: verify named findings plus affected surface only.

## Codex fallback

Availability:

```bash
command -v codex >/dev/null && codex login status
```

Invocation:

```bash
codex exec -s read-only -C <absolute-repo-root> \
  --output-schema <skill-dir>/references/findings.schema.json \
  -o <run-dir>/external-findings.json \
  '<review prompt>'
```

Redirect stdin from `/dev/null` for any headless command that can otherwise wait for input.

## Bounded execution

- Set a stage budget before launch. Default external-seat ceiling: 10 minutes.
- Track PID/process group, output path, runtime directory, and cleanup owner.
- Timeout, non-zero exit, empty output, or invalid JSON: record provider unavailable and proceed with internal seats.
- Never block approval solely because an advisory provider is unavailable.
- Never kill processes by broad executable name. Terminate only recorded owned process groups.

## Merge

1. Parse internal and external findings into `findings.schema.json`.
2. Dedupe by affected surface plus defect, not wording.
3. Preserve all source labels on a shared finding.
4. Verify each finding against code/evidence.
5. Route every verified finding for correction regardless of severity.
