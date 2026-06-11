# Pass-2 Pre-Implementation Review — Top-Down Car Demo CSV

Backlog: /Users/Baba/hadi-phased-workflow/Test2/plans/backlog-2026-06-12-topdown-car-demo.csv
Reviewer: phased-review (Pass 2, fresh eyes, Pass-1 findings unseen)
Date: 2026-06-12

## Restated intent
One greenfield file index.html (inline CSS+JS, zero deps, opens in browser). Top-down arcade car on HTML5 canvas: velocity-vector physics (throttle/brake/reverse along heading, friction coast, partial-lateral-grip drift, speed-scaled steering zero at rest, Space handbrake), camera follows car, tiled world grid, ~10 obstacles + walled arena with bounce collision, skid marks on drift, R reset, HUD (speed + throttle/brake/handbrake + legend), all tunables in one UPPER_SNAKE_CASE constants block. Built as strict serial chain CAR-1->CAR-7, every row edits same file.

## Overall readiness: NOT-READY
Spec coverage: COMPLETE — all 16 ask items + 5 locked extras mapped to rows.
Physics model: sound (velocity-vector, sign(forwardVel) reverse-steer coherent with locked decision).
Decomposition/sizing: appropriate, serial chain intentional, qa_tier overrides (CAR-3/CAR-5 critical) justified.
Blocking issues: 2 critical broken/false-negative greps + 2 high cross-row naming-contract gaps. These pass the row "vacuously fail" or "implementer picks wrong name" test.

## Greenfield context honored
index.html absent confirmed (ls: No such file or directory). CAR-1 creates it. scope_candidates existence N/A — correct.
All Pattern-scan=greenfield, Blast=isolated, Multi-layer=N/A, Pre-existing=N/A notes are HONEST for standalone client-only canvas demo. Not flagged.

---

## FINDINGS

### CRITICAL

**C1 [CAR-1] tunables grep uses `grep -c` (matching-LINES) — false-fail if multiple consts per line.**
AC: `grep -E 'const (ACCEL|TOP_SPEED|FRICTION|GRIP|STEER)' index.html returns >=5 named tunables`.
Evidence (/tmp test): with 2 lines each holding several `const X=...,Y=...` decls, `grep -Ec` returns 2, not 5. grep counts matching lines, and the pattern is anchored to `const ` so only the FIRST const on a line matches. A compact tunables block (`const ACCEL=300, TOP_SPEED=600;`) — common, idiomatic — fails the >=5 check despite all 5 present.
Also: AC checks only 5 of 14 declared tunables; REVERSE_ACCEL, TOP_REVERSE_SPEED, HANDBRAKE_GRIP, OBSTACLE_COUNT, ARENA_SIZE, WALL_BOUNCE, GRID_SIZE, SKID_THRESHOLD, SKID_MAX unverified at CAR-1 despite notes asserting "single source of truth from the start."
Required edit: replace with per-symbol greps OR `grep -oE` + count. Suggested:
`for C in ACCEL REVERSE_ACCEL TOP_SPEED TOP_REVERSE_SPEED FRICTION STEER_RATE GRIP HANDBRAKE_GRIP OBSTACLE_COUNT ARENA_SIZE GRID_SIZE SKID_THRESHOLD SKID_MAX; do grep -qE "\b$C\b *=" index.html || echo "MISSING $C"; done` — expect zero MISSING. Handle FRICTION/DRAG and WALL_BOUNCE/RESTITUTION as either-name (see H2).

**C2 [CAR-1] clamped-dt grep `Math.min(.*dt` cannot match idiomatic `const dt = Math.min(0.033, ...)`.**
AC: `loop uses a clamped dt (grep -E 'Math.min\(.*dt|clamp' index.html >=1)`.
Evidence (/tmp test): for `const dt = Math.min(0.033, (now-last)/1000);` the regex returns 0 — `dt` appears BEFORE `Math.min(`, not after; `.*dt` requires `dt` to follow `Math.min(` on the same line. The cap value (0.033) is a numeric literal, no `dt` substring after the paren. `clamp` alternative only matches a helper named clamp, which a min-cap impl won't have.
Result: correct, stable clamped-dt impl fails the AC. False negative on the single most safety-relevant CAR-1 check (physics stability on slow frames).
Required edit: grep the cap value + assignment instead. Suggested:
`grep -qE 'Math\.min\([^,]*, *[A-Za-z_].*\)|Math\.min\([0-9.]+,' index.html` to assert a min-cap call, plus assert a named MAX_DT/DT_CAP const if the constants block holds the cap. Simpler: `grep -qE 'dt *= *Math\.min'`.

### HIGH

**H1 [CAR-3/CAR-4] handbrake + key-state-map variable names never pinned — input CONSUMER (CAR-3) precedes input PRODUCER (CAR-4) with no shared contract name.**
CAR-3 consumes handbrake "state flag" (notes item 7) and reads per-frame input, but is built BEFORE CAR-4 which creates the key-state map and wires Space->handbrake. CAR-3 names neither the map nor the handbrake var. CAR-4 AC permits 3 map names (`keys[|keysDown|input.`). CAR-7 greps `handbrake`. Three rows reference one flag; none fixes its identifier.
Risk: CAR-3 implementer invents `isHandbrake`; CAR-4 implementer wires `keys['Space']`; CAR-7 greps `handbrake` and the HUD indicator reads a different var than physics consumes. Drift across a serial 3-row handoff with no conversation memory (Hashus reads rows in isolation).
Required edit: pin canonical names in CAR-3 notes and reference from CAR-4/CAR-7. Add to CAR-3: "Input map = `keys` (object, key=event.code). Handbrake flag = `car.handbrake` (bool), set true while `keys['Space']`." CAR-4 and CAR-7 notes must name the same `keys`/`car.handbrake`. Tighten CAR-4 AC grep to the chosen map name.

**H2 [CAR-1/CAR-5] RESTITUTION vs WALL_BOUNCE naming drift — CAR-5 prose+impl literal hard-codes `RESTITUTION` but CAR-1 may declare `WALL_BOUNCE`.**
CAR-1 notes: "WALL_BOUNCE/RESTITUTION" (either name acceptable). CAR-5 notes prescribe literal `car.vx*=-RESTITUTION` / `car.vy*=-RESTITUTION` and [F-CAR5-01] says "Use explicit ... so the AC grep is reliable." If CAR-1 implementer picks `WALL_BOUNCE`, CAR-5's prescribed lines reference an undefined `RESTITUTION` -> ReferenceError at runtime, blank/erroring canvas.
Same latent risk FRICTION vs DRAG (CAR-1 "FRICTION/DRAG").
Required edit: LOCK one name in CAR-1 (recommend `RESTITUTION` to match CAR-5 impl literal; `FRICTION` for drag). Drop the slash-alternatives. Update CAR-1 AC and CAR-5 grep to the single locked name.

### MEDIUM

**M1 [CAR-3] (1 - GRIP*dt) lateral scale has no lower clamp — large GRIP * dt-cap can go negative -> lateral velocity sign-flips each frame (jitter/instability).**
CAR-3 sub-checklist item 4: "scale lateral by (1 - GRIP*dt)". With dt capped 0.033, any GRIP > ~30 yields (1-GRIP*dt) < 0. CAR-1 example GRIP unspecified; "GRIP (lateral)" with no documented range. A tuner raising GRIP for tighter grip silently crosses into instability.
Required edit: CAR-3 notes — clamp factor to >=0: `lateral *= Math.max(0, 1 - GRIP*dt)`. Document GRIP valid range in CAR-1 (`GRIP*MAX_DT < 1`, i.e. GRIP < 30 at 33ms cap).

**M2 [CAR-6/CAR-3/CAR-5] draw-order reorder is implicit — CAR-6 must MOVE the car draw (set in CAR-3) to come after skids, but no row states the final canonical draw sequence.**
CAR-6 declares "grid -> skids -> obstacles/car" and "Draw before the car so the car sits on top." Car draw is established in CAR-2/CAR-3; obstacles in CAR-5. Inserting skids beneath the car requires reordering pre-existing draw calls. "obstacles/car" is grouped/ambiguous (obstacles over or under car unspecified). Serial single-file edits risk leaving car drawn before skids.
Required edit: CAR-6 notes — state explicit final order: `grid -> skids -> obstacles -> car -> (HUD, CAR-7)`. Add AC asserting car draw call appears AFTER skid draw call in source order.

### LOW

**L1 [CAR-7] grep `handbrake|throttle|brake`: `brake` is substring of `handbrake` — count-inflation, passes intent. No action required; note only.**

**L2 [CAR-2] grep `'%'` "near grid draw" matches any literal percent in file — very loose. Only modulo expected in this file, so low false-positive risk. Tighten to `% *GRID_SIZE` if desired.**

**L3 [CAR-7] AC `grep -E 'fillText' with a speed variable` mixes runnable grep with manual judgment ("with a speed variable"). Acceptable (manual observation backs it) but not pure-greppable. Optionally: `grep -E 'fillText\([^)]*[Ss]peed'`.**

**L4 [CAR-1] AC "non-erroring blank canvas (no console errors)" is manual/observational — fine for a visual demo, flagged for completeness.**

---

## CROSS-ROW CONTRACT LEDGER
- car.lateralSlip (CAR-3 -> CAR-6): PINNED exactly. PASS.
- placeholder car draw (CAR-2 -> CAR-3 replace, exactly one draw): PINNED. PASS.
- handbrake flag (CAR-3/CAR-4/CAR-7): UNPINNED. See H1.
- key-state map (CAR-3 consumer / CAR-4 producer): UNPINNED + ordering inversion. See H1.
- RESTITUTION/WALL_BOUNCE (CAR-1 -> CAR-5): NAME-OPTIONAL, impl literal forces one. See H2.
- SKID_THRESHOLD/SKID_MAX (CAR-1 -> CAR-6): single source of truth, CAR-6 forbidden to add tunables. PASS.

## FIX-REGRESSION CHECK (all rows Pass-1-modified)
No [FIX-REGRESSION] found. F-markers (F-CAR1-01, F-CAR2-01, F-CAR3-02, F-CAR4-01, F-CAR5-01, F-CAR6-01, F-CAR7-01/02) are internally consistent. F-CAR6-01 (depends_on CAR-5 = ordering-only; real tech dep is CAR-3 lateralSlip + CAR-2 world render) is correct and does not contradict the serial chain. F-CAR4-01 (event.code KeyR, no deprecated keyCode 82) sound. No renamed-symbol collision, no contradictory grep introduced by fixes. H1/H2 are PRE-EXISTING contract gaps, not fix-induced.

## PHYSICS CORRECTNESS (CAR-3)
- velocity-vector model, forward+lateral decompose via cos/sin: correct for drift.
- sign(forwardVelocity) reverse-steer: reversing -> forwardVel<0 -> sign=-1 -> A/D invert. Coherent with locked reverse-steer-INVERTS decision and the manual AC. PASS.
- steer = STEER_RATE*input*clamp(speed/TOP_SPEED)*sign(fwd)*dt: zero at rest (speed=0). PASS.
- friction coast, TOP_SPEED/TOP_REVERSE_SPEED clamp: present. PASS.
- Only gap: lateral-scale lower clamp (M1).

## SIZING / qa_tier
All rows small/medium, single seam each, <=10 min. CAR-3 (medium) and CAR-5 (medium) bumped standard->critical — justified (physics + collision = top bug-risk surfaces). No row needs further split. Serial chain intentional. PASS.

## FINAL RECOMMENDATION: NO-GO until C1, C2, H1, H2 resolved.

| Sev | Row | Required change |
|-----|-----|-----------------|
| CRITICAL | CAR-1 | Replace tunables `grep -c` with per-symbol presence check (all 13-14 consts); fix false-fail on multi-const lines |
| CRITICAL | CAR-1 | Replace `Math.min(.*dt` clamped-dt grep — cannot match `const dt = Math.min(0.033,...)` |
| HIGH | CAR-3/4/7 | Pin canonical `keys` map name + `car.handbrake` flag across consumer/producer/HUD rows |
| HIGH | CAR-1/5 | Lock RESTITUTION (and FRICTION) single name; drop slash-alternatives; align CAR-5 impl literal |
| MEDIUM | CAR-3 | Clamp lateral scale `Math.max(0, 1-GRIP*dt)`; document GRIP range in CAR-1 |
| MEDIUM | CAR-6 | State explicit final draw order grid->skids->obstacles->car->HUD; add ordering AC |
| LOW | CAR-7 | `brake` substring of `handbrake` — note |
| LOW | CAR-2 | Tighten `'%'` grep to `% *GRID_SIZE` |
| LOW | CAR-7 | `fillText` speed grep is part-manual |
| LOW | CAR-1 | "no console errors" manual-only |

## DoD additions the CSV should include
- CAR-1: assert ALL tunables present (loop or multi-grep), assert dt-cap const present.
- CAR-3: assert single car draw call (already implied) AND lateral clamp non-negative.
- CAR-4/CAR-7: grep the LOCKED map/handbrake identifiers, not alternatives.
- CAR-6: assert car draw call line-number > skid draw call line-number.
