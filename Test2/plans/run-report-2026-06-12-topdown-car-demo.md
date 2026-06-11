# End-of-Run Report — Top-Down Car Demo
**Backlog:** `plans/backlog-2026-06-12-topdown-car-demo.csv`
**Run date:** 2026-06-12
**Deliverable:** `Test2/index.html` (374 lines, inline CSS+JS, zero deps)
**Final status:** DONE — all 7 rows `done`, 1 medium finding fixed, 3 lows logged as NTH

---

## Summary

7-row serial backlog executed over 7 waves. Greenfield single-file project (no existing codebase to explore, all rigor sections honoured with honest N/A justifications). Two pre-implementation review passes caught 9 issues before any code was written; 3 wave-level QA passes caught 5 additional findings at execution time; final QA caught 4 final-state issues. All issues ≥ medium severity were resolved. Deliverable opens by double-click in any browser with no network dependency.

---

## Backlog execution summary

| Row | Title | Status | QA tier | Notes |
|-----|-------|--------|---------|-------|
| CAR-1 | TUNABLES + canvas scaffold | done | standard | Wave 1 |
| CAR-2 | Camera-follow world + tiled grid floor | done | standard | Wave 2 |
| CAR-3 | Velocity-vector arcade physics | done | critical | Wave 3; QA pass after 2 low fixes |
| CAR-4 | Input event listeners + R-reset | done | standard | Wave 4 |
| CAR-5 | Bounded walled arena + obstacle bounce | done | critical | Wave 5; QA pass after 3 low fixes |
| CAR-6 | Skid marks on drift / handbrake | done | standard | Wave 6 |
| CAR-7 | Richer HUD (speed + indicators + legend) | done | standard | Wave 7 |

All 15 spec requirements verified pass in final QA. 18 UPPER_SNAKE tunables in the top block (3 over spec — over-delivery, not a defect).

---

## Issues found and resolved

### Pre-implementation review (Pass 1 — Sonnet)

| ID | Severity | Row | Issue | Fix |
|----|----------|-----|-------|-----|
| F-CAR1-01 | HIGH | CAR-1 | `SKID_THRESHOLD` / `SKID_MAX` missing from tunables notes | Added both to CAR-1 notes and tunables block |
| F-CAR3-01 | HIGH | CAR-3 | Reverse-steer sign not locked in notes | Added explicit `User decision: reverse-steer INVERTS in reverse` to CAR-3 notes |
| F-CAR4-01 | MEDIUM | CAR-4 | AC grep pattern included deprecated `keyCode 82` | Removed `82`; grep uses `e.code === 'KeyR'` only |
| F-CAR5-01 | MEDIUM | CAR-5 | AC grep `\*= -` too broad (matches any multiply-by-negative) | Narrowed to `grep -E 'car\.vx\s*\*=\s*-RESTITUTION\|car\.vy\s*\*=\s*-RESTITUTION'` |
| F-CAR7-01 | MEDIUM | CAR-7 | AC grep `save\|restore` matches nothing (HUD uses setTransform reset) | Changed to `grep -E 'setTransform\(1'` |

### Pre-implementation review (Pass 2 — Opus)

| ID | Severity | Row | Issue | Fix |
|----|----------|-----|-------|-----|
| C1 | CRITICAL | CAR-1 | Tunables grep used `grep -c` (counts lines, not symbols) — false-fail with multi-const lines | Replaced with per-symbol presence loop |
| C2 | CRITICAL | CAR-1 | Clamped-dt grep `Math.min(.*dt` cannot match `const dt = Math.min(0.033,...)` | Changed to `grep -qE 'dt *= *Math\.min'` |
| H1 | HIGH | CAR-3/4/7 | `keys` map name and `car.handbrake` unpinned across consumer/producer/HUD rows | Added `PINNED CONTRACTS` section to CAR-3; standardized greps in CAR-4/CAR-7 |
| H2 | HIGH | CAR-1/5 | `RESTITUTION` vs `WALL_BOUNCE` naming drift (CAR-5 impl literal requires `RESTITUTION`) | Locked single name `RESTITUTION`; removed slash-alternatives from CAR-1 |
| M1 | MEDIUM | CAR-3 | `(1 - GRIP)` lateral scale has no lower clamp — negative factor at high GRIP*dt inverts velocity | Added `Math.max(0, 1 - effectiveGrip)` clamp; documented `GRIP*MAX_DT < 1` invariant |

### Wave-level QA fixes

| Wave | Task | Finding | Fix |
|------|------|---------|-----|
| Wave 3 | CAR-3 | Dead variable `lateralVel` never read | Removed |
| Wave 3 | CAR-3 | Magic literal `1.5` (brake multiplier) | Extracted to `BRAKE_MULTIPLIER = 1.5` in tunables |
| Wave 5 | CAR-5 | Dead local `CAR_HALF_W` / `CAR_HALF_H` variables | Removed |
| Wave 5 | CAR-5 | Local `CAR_R = 18` — should be a tunable | Promoted to `CAR_RADIUS = 18` in tunables block |
| Wave 5 | CAR-5 | Obstacle radius `30` in IIFE only — should be a tunable | Promoted to `OBS_RADIUS_T = 30` in tunables block |

### Final QA fixes

| Finding | Severity | Resolution |
|---------|----------|------------|
| `SKID_MAX` semantically overloaded (px/s opacity scale AND array-length cap — same value 300 coincidentally) | MEDIUM | Added `SKID_POOL_SIZE = 300` to tunables; changed array cap usage to `SKID_POOL_SIZE`; `SKID_MAX` now exclusively = opacity-scale speed threshold |

---

## Risks identified (NTH — not fixed, logged only)

| ID | Severity | Location | Description |
|----|----------|----------|-------------|
| L1 | LOW | index.html:277 | Car body draw uses hardcoded geometry (`fillRect(-20,-10,40,20)`) decoupled from `CAR_RADIUS=18`. Visual/physics mismatch is tolerable but magic. Remediation: derive from `CAR_RADIUS` or add `CAR_W`/`CAR_H` tunables. |
| L2 | LOW | index.html:297 | HUD panel geometry hardcoded (`fillRect(10,10,200,130)`, text coords). Acceptable for single-panel HUD. Optional: add `HUD_X`/`HUD_Y`/`HUD_W` consts. |
| L3 | LOW | index.html:204 | Skid-trigger handbrake speed `> 20` is an inline literal, not a tunable constant. Optional: `const HANDBRAKE_SKID_MIN = 20`. |

---

## Open questions discovered

None. All ambiguities resolved at pre-implementation review time (reverse-steer direction, naming conflicts) or absorbed as NTH.

---

## Final deliverable verification

- **15/15 spec requirements** verified pass (top-down canvas, WASD+Space+R input, momentum+friction+drift, camera-follow, tiled grid, 10 obstacles + walled arena, skid marks, speed HUD, richer HUD, no deps)
- **18 UPPER_SNAKE tunables** in single top block (lines 29–47); all gameplay constants named
- **Zero external dependencies** — single `<script>` block, no `src=`, no `<link>`, opens `file://`
- **Syntax valid** — `node --check` exit 0
- **No debug cruft** — no `console.log`, `// TODO`, `debugger`, `FIXME`
- **Critical contracts consistent** — `keys` / `car.handbrake` / `car.lateralSlip` used consistently across physics, input, skids, HUD
- **Draw order correct** — grid → skids → obstacles → car → HUD (screen-space setTransform reset)

---

## Artifact index

| Artifact | Path |
|----------|------|
| Backlog CSV | `plans/backlog-2026-06-12-topdown-car-demo.csv` |
| Scope exploration | `plans/run-reports/2026-06-12-topdown-car-demo/scope/explore-greenfield.md` |
| Phase plan | `plans/run-reports/2026-06-12-topdown-car-demo/scope/phased-plan.md` |
| Pre-impl review Pass 1 | `plans/run-reports/2026-06-12-topdown-car-demo/scope/review-1.md` |
| Pre-impl review Pass 2 | `plans/run-reports/2026-06-12-topdown-car-demo/scope/review-2.md` |
| Wave reports | `plans/run-reports/2026-06-12-topdown-car-demo/wave-{1..7}/` |
| Final QA | `plans/run-reports/2026-06-12-topdown-car-demo/final-qa.md` |
| **Deliverable** | **`index.html`** |
