# Scope investigation — top-down car demo (greenfield)

## Context map
- Target dir: /Users/Baba/hadi-phased-workflow/Test2 — EMPTY (no source files, no package.json, no build tooling).
- Deliverable: a single new file `index.html` containing inline CSS + inline JS, zero dependencies, no build step.
- Runtime: opened directly in a browser (file://). Uses Canvas 2D API + requestAnimationFrame. No network, no storage.

## Investigation rigor inputs (apply to every row)
- **Pattern scan:** Greenfield — no existing code to reuse or collide with. Every row introduces new code in the single new file `index.html`. No parallel implementation is possible because there is no prior implementation.
- **Blast radius:** Single standalone file with no importers and no siblings. Verdict: isolated for every row. The only shared surface is `index.html` itself — all rows edit it, hence a strict serial chain (see parallel-safety).
- **Multi-layer validation:** N/A for all rows — no data inputs, contracts, API boundaries, or write paths. All state is in-memory game state mutated by the render loop.
- **Pre-existing state:** N/A for all rows — no schema, no persistence, no migrations, nothing on disk between runs.

## Parallel-safety
Every row edits the same file `index.html`. Concurrent edits would conflict, so the backlog is a strict linear `depends_on` chain (CAR-1 -> CAR-2 -> ... -> CAR-7). Hashus executes one row at a time; no wave parallelism.

## Locked design decisions (from Step 1 brainstorm)
- World: bounded walled arena (finite play area ringed by walls; walls bounce like obstacles).
- Ground: tiled grid floor drawn in world-space (motion/speed reference).
- Extras in-scope: skid marks on drift/handbrake, R-to-reset, richer HUD (speed + input state + controls legend).
- Physics model: velocity-vector arcade model with separate forward traction and lateral grip so the car drifts; steering rate scales with speed and is zero at rest; handbrake cuts lateral grip and adds drag.
