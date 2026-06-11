# Phased Review — Pass 1
**File:** `plans/backlog-2026-06-12-topdown-car-demo.csv`
**Date:** 2026-06-12
**Reviewer:** phased-review subagent v2.3.0
**Status:** DONE_WITH_CONCERNS

---

## Plan Review Summary

**Path reviewed:** `/Users/Baba/hadi-phased-workflow/Test2/plans/backlog-2026-06-12-topdown-car-demo.csv`

**Restated intent:**
7-row serial backlog builds a single `index.html` greenfield top-down car demo. Rows scaffold from canvas boilerplate (CAR-1) through camera/grid (CAR-2), arcade physics (CAR-3), keyboard input (CAR-4), obstacles/walls (CAR-5), skid marks (CAR-6), to HUD (CAR-7). Each row depends on the prior. No build step, no external deps, runs via file:// open.

**Overall readiness:** not-ready

**Top risks (high to low):**
1. [HIGH] CAR-3 physics model description has a sign bug: steering formula uses `sign(forwardVelocity)` which flips steer direction in reverse — non-standard and not clearly intentional; no AC tests reverse-steer direction.
2. [HIGH] CAR-6 depends_on = CAR-5, but skid marks only need the lateral-slip value from CAR-3 and the render pipeline from CAR-2; depends_on CAR-5 forces obstacles before skids, but notes say "reuse lateral-slip from CAR-3" — depends_on is defensible but the notes create an inconsistency (skid needs CAR-3 output, not CAR-5 output).
3. [MEDIUM] CAR-3 is sized "medium" but covers heading + velocity decomposition + forward/lateral projection + GRIP friction + DRAG + steer-rate scaling + handbrake flag — easily 8–10 distinct logic units. Split risk: implementer may get most right and one subtly wrong with no sub-task to isolate it.
4. [MEDIUM] CAR-7 AC grep for `save/restore` is incorrect: the AC text says `grep -E 'setTransform|resetTransform|save/restore'` — `save/restore` is not a valid regex pattern (forward slash is not a metacharacter but `save/restore` won't match `ctx.save()` + `ctx.restore()` as written). Notes correctly say `ctx.setTransform(1,0,0,1,0,0)` — AC grep should target that.
5. [MEDIUM] Spec requires "richer HUD" but CAR-7 AC does not verify a lap-time or score field. If the original spec meant speed + indicators + legend only, this is fine — but the phrase "richer HUD" is ambiguous and not resolved in notes.
6. [LOW] CAR-1 tunable list in notes omits SKID_THRESHOLD and SKID_MAX that CAR-6 requires. If implementer adds tunables only from CAR-1's list, CAR-6 implementer must add them separately — no row assigns that responsibility.
7. [LOW] CAR-2 notes describe a "car placeholder (colored rect)" as optional, but CAR-3 replaces the car draw. No row explicitly removes the placeholder. CAR-3 notes do not mention updating the draw; implementer may have two car draw calls after CAR-3.
8. [LOW] CAR-4 AC grep for R-reset uses `grep -E "'r'|KeyR|82"` — the `82` (legacy keyCode) is deprecated; acceptable but mixing event.key and keyCode in AC is confusing. Notes say to use event.key/event.code, so `82` match in AC is misleading.
9. [LOW] CAR-5 collision AC grep uses `grep -E 'RESTITUTION|WALL_BOUNCE|reflect|-=|\*= -'` — the pattern `\*= -` contains a space and would match any `*= -` assignment, not specifically velocity reflection. Overly broad; could pass with unrelated code.

**Confidence level:** high — all 7 rows fully read, physics model analyzed in detail, all AC greps evaluated.

**Unresolved findings count:** 9

---

## Per-Row Review

---

### CAR-1 — Scaffold index.html: boilerplate, full-window canvas, tunables block, game loop

**Strengths:**
- Tunable list in notes is comprehensive: ACCEL, REVERSE_ACCEL, TOP_SPEED, TOP_REVERSE_SPEED, FRICTION/DRAG, STEER_RATE, GRIP, HANDBRAKE_GRIP, OBSTACLE_COUNT, ARENA_SIZE, WALL_BOUNCE. Implementer has a concrete checklist.
- dt clamping requirement is explicit ("cap at ~33ms") — prevents physics explosion on tab-switch.
- AC greps are specific and executable: `grep -c 'requestAnimationFrame'`, canvas count, resize handler, dt clamp.
- Foundation row correctly sets up the `depends_on` chain.

**Findings:**

F-CAR1-01 [LOW] Tunable list incomplete for downstream rows.
- Evidence: CAR-6 notes require `SKID_THRESHOLD` and `SKID_MAX`. Neither appears in CAR-1 notes' tunable list.
- Required doc edit: Add `SKID_THRESHOLD` and `SKID_MAX` to CAR-1 notes tunable list so the implementer creates them in the constants block from the start. No implementer reads ahead to CAR-6 when executing CAR-1.
- Code guidance: In the constants block, add e.g. `const SKID_THRESHOLD = 80; // px/s lateral slip to start marking` and `const SKID_MAX = 300; // max segments`.

**Blast radius:** None — foundation only.

**Verdict:** pass (F-CAR1-01 is low; implementer can add missing tunables in CAR-6 execution, but clean-from-start is better)

---

### CAR-2 — World-space camera + tiled grid floor

**Strengths:**
- Camera formula stated explicitly: `cameraX = car.x - canvas.width/2`. No ambiguity on implementation.
- Viewport-clipped grid draw (modulo offset) is the correct optimization — avoids iterating 4000x4000 arena cells.
- AC greps cover `translate(`, `GRID_SIZE`, and `%` near grid — all verifiable.

**Findings:**

F-CAR2-01 [LOW] "Car placeholder" in notes is optional but removal not assigned.
- Evidence: CAR-2 notes: "A car placeholder (colored rect rotated to heading) may be drawn here as a stub; real physics arrives in CAR-3." CAR-3 notes and AC are silent on removing or replacing the placeholder draw.
- Required doc edit: Either (a) make placeholder mandatory in CAR-2 notes and add "replace placeholder car draw with physics-based draw" to CAR-3 notes, or (b) remove the placeholder suggestion and draw nothing until CAR-3. Ambiguity risks two car draw calls post-CAR-3.
- Code guidance: Simplest fix: CAR-2 draws a temporary rotated rect; CAR-3 notes say "replace the placeholder rect draw block from CAR-2 with the physics car draw."

**Blast radius:** CAR-3 inherits the draw structure from CAR-2.

**Verdict:** pass (F-CAR2-01 is low; demo still works with a duplicate draw, just visually odd)

---

### CAR-3 — Car arcade physics: momentum, friction, lateral grip/drift, speed-scaled steering

**Strengths:**
- Velocity-vector model with forward/lateral decomposition is the correct approach for drift.
- Explicit formula for GRIP application: `lateral *= (1 - GRIP*dt)` — mathematically produces partial slide, not full grip. Correct.
- FRICTION/DRAG decays forward speed when coasting — standard arcade feel.
- Handbrake drops effective grip to HANDBRAKE_GRIP — correct mechanism.
- qa_tier override to critical is appropriate and justified.
- ACs cover: trig functions, GRIP in update, TOP_SPEED clamp, manual drift and handbrake tests.

**Findings:**

F-CAR3-01 [HIGH] Steering formula `sign(forwardVelocity)` causes reverse-steer flip but is not tested.
- Evidence: CAR-3 notes: `car.heading += STEER_RATE * steerInput * (speed/TOP_SPEED clamp) * sign(forwardVelocity) * dt`. The `sign(forwardVelocity)` term flips steer direction when reversing (forwardVelocity < 0 → sign = -1 → A key steers right instead of left). This is realistic (car steers opposite when in reverse) but is non-obvious, may confuse players, and is not tested in AC or notes. No AC verifies "A steers left in forward AND right in reverse" vs "A always steers left."
- Required doc edit: Add to CAR-3 notes: "sign(forwardVelocity) is intentional — steering inverts in reverse gear so turning feels natural when backing up. Acceptable alternative: clamp sign to [0,1] to disable reverse-steer flip." Choose one and record it. Add to AC: "manual: reverse and steer — confirm steer behavior matches intent."
- Code guidance: If inversion is desired: keep `sign(forwardVelocity)`. If same-direction steer is desired: use `Math.max(0, Math.sign(forwardVelocity))` to only steer forward. Decision must be locked before execution.

F-CAR3-02 [MEDIUM] Sizing: "medium" effort covers ~8 distinct physics units with no sub-milestones.
- Evidence: notes describe heading, vx/vy accumulation, forward/lateral decomposition, GRIP decay, DRAG, steer scaling, handbrake flag, speed clamp — 8 interacting pieces in one row.
- Required doc edit: Optionally split into CAR-3a (velocity + throttle + friction) and CAR-3b (lateral grip + steer scaling + handbrake). If kept together, add a sub-checklist in notes so implementer verifies each piece: (1) throttle adds ACCEL along heading, (2) DRAG decays speed, (3) lateral decomposition, (4) GRIP applied, (5) steer scaled by speed, (6) sign(forwardVelocity) intentional, (7) handbrake grip override, (8) TOP_SPEED clamp.
- Code guidance: No code change required if kept as one row — sub-checklist in notes is sufficient mitigation.

**Blast radius:** CAR-4 reads car.vx/vy/heading. CAR-5 uses car position. CAR-6 reads lateral slip value (needs to be exposed on car object or accessible variable). CAR-7 reads speed magnitude.

**Verdict:** revise — F-CAR3-01 (HIGH) requires steering intent to be locked in notes before execution.

---

### CAR-4 — Keyboard input: WASD/arrows throttle-brake-steer, Space handbrake, R reset

**Strengths:**
- Held-state map pattern is correct — forces applied in physics loop, not in event handler.
- preventDefault on Arrow*/Space to prevent page scroll — explicitly required.
- R-reset specification is complete: zero vx, vy, heading rate, recentered to ARENA_SIZE/2.
- AC greps cover keydown/keyup listeners, key map, preventDefault, R-reset near velocity zero.

**Findings:**

F-CAR4-01 [LOW] AC grep for R-reset mixes `event.key` and deprecated `keyCode` (82).
- Evidence: acceptance_criteria: `grep -E "'r'|KeyR|82"`. Notes say "Use event.key or event.code". The `82` is `event.keyCode` which is deprecated. AC grep that matches `82` could pass with legacy code that contradicts notes.
- Required doc edit: Remove `82` from the AC grep pattern. Keep `'r'|'R'|KeyR`. Avoids confusing the implementer into using deprecated API.
- Code guidance: No code change — just AC edit. Implementation should use `event.key === 'r' || event.key === 'R'` or `event.code === 'KeyR'`.

**Blast radius:** CAR-3 physics reads the key-state map each frame — map variable name must match between CAR-4 and CAR-3.

**Verdict:** pass (F-CAR4-01 is low)

---

### CAR-5 — Bounded arena walls + ~10 scattered obstacles with bounce collision

**Strengths:**
- Push-out + velocity reflect is the correct collision resolution order (position fix before velocity fix).
- RESTITUTION as tunable is correct — makes bounce feel adjustable.
- ARENA_SIZE bounds check approach stated explicitly.
- Obstacle spawn avoids center spawn point — good player experience detail.
- qa_tier override to critical is appropriate.

**Findings:**

F-CAR5-01 [MEDIUM] AC grep `\*= -` is overly broad.
- Evidence: acceptance_criteria: `grep -E 'RESTITUTION|WALL_BOUNCE|reflect|-=|\*= -' in collision block`. The pattern `\*= -` (note: space before minus) matches any compound multiplication-assignment followed by minus, e.g. `opacity *= -fade` in unrelated code. This AC grep could produce false positives.
- Required doc edit: Tighten the AC grep to target the specific velocity-reflection pattern: `grep -E 'vx\s*\*=\s*-|vy\s*\*=\s*-|RESTITUTION|WALL_BOUNCE'`. This matches actual velocity-axis inversion.
- Code guidance: Implementation should use explicit patterns like `car.vx *= -RESTITUTION` or `car.vy *= -RESTITUTION` for wall bounce — makes the grep reliable.

**Blast radius:** CAR-6 draws skid marks — obstacles drawn in CAR-5 must appear in render order before the car (skid marks go between grid and obstacles/car as per CAR-6 notes).

**Verdict:** pass (F-CAR5-01 is medium but does not break implementation; just makes AC grep unreliable)

---

### CAR-6 — Skid marks painted to the ground on drift / handbrake

**Strengths:**
- World-space storage of skid segments is correct — trails stay fixed under camera movement.
- Capped array (shift/slice) prevents unbounded memory growth.
- Draw order specified: grid → skids → obstacles/car — correct layering.
- Reuse of lateral-slip from CAR-3 avoids double computation.
- SKID_THRESHOLD and SKID_MAX named as tunables — implementation can find them if added to constants.

**Findings:**

F-CAR6-01 [MEDIUM] depends_on = CAR-5 but skid marks only need CAR-3 (lateral slip) and CAR-2 (world-space render).
- Evidence: CAR-6 notes: "Reuse lateral-slip value computed in CAR-3 rather than recomputing." The dependency is on the lateral-slip value (CAR-3) and the render loop (CAR-2), not on obstacles (CAR-5). depends_on = CAR-5 is defensible for serial ordering and for ensuring draw-order context exists, but the technical dependency is CAR-3.
- Required doc edit: Add to CAR-6 notes: "depends_on CAR-5 for serial ordering only — technical dependency is lateral-slip from CAR-3. Implementer must ensure lateral slip value is accessible (car object property or module-scoped variable) after CAR-3." This prevents an implementer from thinking CAR-5's obstacle code is needed for skids.
- Code guidance: In CAR-3 implementation, store lateral slip as `car.lateralSlip` or a scoped variable `latSlip` that CAR-6 can read.

F-CAR6-02 [LOW] SKID_THRESHOLD and SKID_MAX not in CAR-1 constants block (see F-CAR1-01).
- This is the downstream consequence of F-CAR1-01. If CAR-1 is executed without these constants, CAR-6 implementer must insert them mid-file rather than at the top-of-script constants block.
- Required doc edit: Addressed by F-CAR1-01 fix.

**Blast radius:** Draw order established here (grid → skids → obstacles/car → HUD). CAR-7 must draw HUD after this sequence — already handled by CAR-7 AC (transform reset).

**Verdict:** pass (F-CAR6-01 and F-CAR6-02 are medium/low; do not block implementation)

---

### CAR-7 — HUD: speed readout + input/handbrake state + controls legend

**Strengths:**
- `ctx.setTransform(1,0,0,1,0,0)` for screen-space HUD is the correct pattern for canvas — fully resets matrix without needing save/restore.
- AC includes manual tests: speed reads ~0 at rest, handbrake indicator toggles.
- Speed as velocity magnitude is correct: `Math.sqrt(vx*vx + vy*vy)`.
- Controls legend enumerated in AC grep: WASD/Arrows, Space, Reset.

**Findings:**

F-CAR7-01 [MEDIUM] AC grep `save/restore` is not a valid pattern for what it tests.
- Evidence: acceptance_criteria: `grep -E 'setTransform|resetTransform|save/restore'`. The string `save/restore` in a regex matches the literal sequence `save/restore` — it will not match `ctx.save()` followed by `ctx.restore()` (different lines). In practice `save/restore` never appears as a single string in canvas code.
- Required doc edit: Remove `save/restore` from the AC grep. Replace with `grep -E 'setTransform\(1' index.html >=1` to specifically verify the identity-matrix reset that notes mandate. If save/restore pattern is also acceptable, add it as a separate grep: `grep -c 'ctx\.save\(\)' index.html >=1`.
- Code guidance: Implementation should use `ctx.setTransform(1,0,0,1,0,0)` as notes specify. That grep pattern is unambiguous.

F-CAR7-02 [MEDIUM] "Richer HUD" requirement from locked extras is not fully specified.
- Evidence: Dispatch prompt states locked extras include "richer HUD." CAR-7 desired_outcome lists "numeric speed, live throttle/brake/handbrake state, and a small controls legend." No row covers lap time, drift score, or any other "richer" metric beyond speed + state + legend. If "richer" only means speed + indicators + legend, the term should be defined in CAR-7 notes.
- Required doc edit: Add to CAR-7 notes: "'Richer HUD' = speed + throttle/brake/handbrake live indicators + controls legend. No lap timer or score required for this demo." Locks the scope of "richer" so implementer does not under- or over-deliver.
- Code guidance: No code change — scope clarification only.

**Blast radius:** Final row. No downstream dependencies.

**Verdict:** revise — F-CAR7-01 (MEDIUM) makes the primary AC grep untestable for save/restore path. F-CAR7-02 (MEDIUM) leaves "richer HUD" ambiguous.

---

## Spec Coverage Audit

Original requirements mapped to rows:

| Requirement | Row | Covered |
|---|---|---|
| Top-down car on HTML5 canvas | CAR-1 | YES |
| Arcade physics WASD/arrows | CAR-3 + CAR-4 | YES |
| Steering only works while moving | CAR-3 (speed-scaled steer) | YES |
| Momentum + friction, coasts | CAR-3 | YES |
| Can drift | CAR-3 (GRIP < 1) | YES |
| Space = handbrake | CAR-4 + CAR-3 | YES |
| Camera follows car | CAR-2 | YES |
| ~10 static obstacles with bounce collision | CAR-5 | YES |
| Speed shown in HUD corner | CAR-7 | YES |
| Runs by opening file | CAR-1 | YES |
| All tunables in UPPER_SNAKE_CASE constants at top | CAR-1 | PARTIAL (SKID_THRESHOLD/SKID_MAX missing per F-CAR1-01) |
| Bounded walled arena | CAR-5 | YES |
| Tiled grid floor | CAR-2 | YES |
| Skid marks on drift | CAR-6 | YES |
| R-to-reset | CAR-4 | YES |
| Richer HUD | CAR-7 | PARTIAL (term undefined — see F-CAR7-02) |

No requirement is fully missing. 2 requirements are partially covered with ambiguity.

---

## Codebase Analysis

**Existing patterns to reuse:** Greenfield — none. All patterns are new.

**Affected components:** Single file `index.html`. No external files.

**Dependency / integration risks:**
- CAR-3 must expose lateral slip value for CAR-6 — no explicit contract specified in either row (see F-CAR6-01).
- CAR-2's car placeholder draw conflicts with CAR-3's car draw — no explicit handoff (see F-CAR2-01).
- CAR-1 constants block is the single source of truth for all tunables — missing tunables from later rows break the "all tunables at top" spec.

---

## Physics Correctness Analysis

**Model:** velocity-vector, heading angle, forward/lateral decomposition. Correct for arcade drift.

**GRIP formula:** `lateral *= (1 - GRIP*dt)` where GRIP ∈ (0, 1]. At GRIP=1, dt=0.016: lateral *= 0.984. Lateral velocity decays by 1.6% per frame. Low GRIP values let most lateral velocity persist — produces visible drift. Mathematically stable for dt < 1/GRIP.

**Steer formula:** `car.heading += STEER_RATE * steerInput * (speed/TOP_SPEED) * sign(forwardVelocity) * dt`. Issues:
1. At rest: speed=0, term=0. Correct — car does not rotate at rest.
2. At TOP_SPEED: multiplier=1. Full steer rate. Correct.
3. In reverse (forwardVelocity < 0): sign=-1, heading changes opposite direction. See F-CAR3-01.
4. Speed scaling uses `speed/TOP_SPEED` not `forwardVelocity/TOP_SPEED` — if car slides sideways (high lateral), speed is high but forward component is low. Steer rate remains high during slides. This may feel overly responsive during drift but is acceptable for arcade.

**dt stability:** CAR-1 clamps dt at ~33ms. At dt=0.033, GRIP=0.95: lateral *= (1 - 0.95*0.033) = lateral *= 0.969. Stable. No physics explosion risk.

**Handbrake:** drops effective GRIP to HANDBRAKE_GRIP (expected near 0.1–0.2 based on tunable name). Lateral velocity preserved → rear slides. Correct mechanism.

**Overall physics model:** sound. One signed decision (reverse steer) needs explicit locking per F-CAR3-01.

---

## Final Recommendation

**Go / No-go:** NO-GO until F-CAR3-01 (steering intent in reverse) is resolved. All other findings can be fixed without blocking.

### Required Changes Table

| Severity | Row | Finding | Required Edit |
|---|---|---|---|
| HIGH | CAR-3 | F-CAR3-01: reverse-steer sign not locked | Add note: "sign(forwardVelocity) is intentional — steer inverts in reverse" OR change to clamp-to-0. Add manual AC test for reverse steer. |
| MEDIUM | CAR-3 | F-CAR3-02: 8-unit row with no sub-checklist | Add ordered sub-checklist to notes (8 items). Optional: split into CAR-3a/CAR-3b. |
| MEDIUM | CAR-5 | F-CAR5-01: AC grep `\*= -` too broad | Replace with `grep -E 'vx\s*\*=\s*-|vy\s*\*=\s*-|RESTITUTION|WALL_BOUNCE'` |
| MEDIUM | CAR-6 | F-CAR6-01: depends_on implies obstacle dependency | Add note: "depends_on CAR-5 for serial ordering only; expose car.lateralSlip in CAR-3." |
| MEDIUM | CAR-7 | F-CAR7-01: save/restore regex matches nothing | Replace with `grep -E 'setTransform\(1'` |
| MEDIUM | CAR-7 | F-CAR7-02: "richer HUD" scope undefined | Define in notes: "richer = speed + indicators + legend, no lap timer." |
| LOW | CAR-1 | F-CAR1-01: SKID_THRESHOLD/SKID_MAX absent from tunable list | Add both constants to CAR-1 tunable list in notes. |
| LOW | CAR-2 | F-CAR2-01: placeholder removal not assigned | Assign placeholder removal to CAR-3 notes. |
| LOW | CAR-4 | F-CAR4-01: keyCode 82 in AC grep | Remove `82` from AC grep pattern. |

### Updated DoD Additions

CAR-3: Add AC: `manual: reverse (hold S past stop) and steer — confirm steer direction matches notes intent.`
CAR-6: Add note: `lateral slip exposed as car.lateralSlip (or equivalent scoped var) in CAR-3 implementation.`
CAR-7: Add note: `"Richer HUD" scope = speed + live indicators + legend. No additional metrics.`

---

*9 total findings: 0 critical / 1 high / 5 medium / 3 low*
