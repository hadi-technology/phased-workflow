# Final QA — Top-Down Car Demo

Mode: final. Date: 2026-06-12. Deliverable: single `index.html` (372 lines).
Status: DONE_WITH_CONCERNS (1 medium, 3 low).

## Restated backlog intent
Ship one self-contained `index.html` (inline CSS+JS, zero deps, file:// runnable): top-down arcade car on canvas with velocity-vector drift physics, WASD/arrows+Space+R input, world-space camera follow, tiled grid, ~10 bounce obstacles, walled arena, skid marks, richer HUD. All tunables UPPER_SNAKE at top.

## Verification gate — spec coverage (15 reqs)

| # | Requirement | Evidence | Result |
|---|-------------|----------|--------|
| 1 | Top-down car on canvas | `canvas` getContext('2d') index.html:53-54; car draw 270-280 | PASS |
| 2 | Arcade WASD/arrows accel/brake/reverse/steer | throttle/brake/steerInput 105-108; accel 119-133 | PASS |
| 3 | Steer only while moving | `if (Math.abs(speed) > 1)` 164; steer inside guard 167 | PASS |
| 4 | Momentum + friction + drift | `car.vx*=FRICTION` 136-137; lateral grip 143-152 | PASS |
| 5 | Space = handbrake | `car.handbrake = !!(keys['Space'])` 109; HANDBRAKE_GRIP override 144 | PASS |
| 6 | Camera follows car | cameraX/Y = car - half-canvas 221-222; translate 225 | PASS |
| 7 | ~10 static obstacles bounce | OBSTACLE_COUNT=10 38; spawn 87-97; collision reflect 180-199 | PASS |
| 8 | Speed in HUD corner | `Speed: ${speed}` 304 at (20,34) | PASS |
| 9 | Runs via file:// | no external src/link; inline only (grep below) | PASS |
| 10 | Tunables UPPER_SNAKE at top | block 29-47 | PASS (note T1) |
| 11 | Bounded walled arena | 4 wall clamps + RESTITUTION 175-178 | PASS |
| 12 | Tiled grid floor | GRID_SIZE grid 231-246 | PASS |
| 13 | Skid marks on drift | record 201-216; draw 248-257 | PASS |
| 14 | R-to-reset | KeyR/r/R resets x,y,v,heading,handbrake,slip 356-364 | PASS |
| 15 | Richer HUD | speed+throttle+brake+handbrake+steer+legend 285-317 | PASS |

### no-deps confirm
```
$ grep -nE '<script[^>]*src=|<link|http' index.html
(no hits)
```
Single inline `<script>`; opens file://. PASS.

## Check 2 — tunables completeness
```
$ grep -cE '^\s*const [A-Z][A-Z0-9_]+\s*=' index.html
19
```
Top tunable block 29-47 = 18 consts. 19th = `MIN_DIST_FROM_CENTER` (88, local to spawn IIFE — scoped, not a global tunable). Spec/backlog said "15 tunables"; implementation ships 18. Over-delivery (CAR_RADIUS, OBS_RADIUS_T, BRAKE_MULTIPLIER, HANDBRAKE_GRIP, MAX_DT etc added). All gameplay constants present and named. PASS — see T1.

## Check 3 — physics correctness (update(), 103-217)
- Velocity decomposition: forward `fv2 = vx*cosH+vy*sinH` 140; lateral `lv2 = -vx*sinH+vy*cosH` 141. PASS.
- Partial GRIP damping (drift): `newLateral = lv2 * max(0, 1-effectiveGrip)` 145 — retains (1-GRIP)=15% lateral, rebuilds vx/vy 151-152. Partial kill = drift. PASS.
- Speed-scaled steer zero at rest: guard `abs(speed)>1` 164; `speedFactor=min(speed/TOP_SPEED,1)` 165 → steer→0 as speed→0. PASS.
- Handbrake grip override: `effectiveGrip = handbrake ? HANDBRAKE_GRIP(0.05) : GRIP(0.85)` 144 → near-zero grip = slide. PASS.
- Friction coasting: `vx*=FRICTION; vy*=FRICTION` 136-137 every frame, no input needed. PASS.
- Reverse steer invert: `reverseSign = fv2>=0?1:-1` 166. PASS (correct arcade feel).

## Check 4 — draw order (draw(), 219-318)
```
231 grid → 248 skids → 259 obstacles → 270 car → 286 HUD (setTransform reset)
```
Order grid→skids→obstacles→car correct. HUD after `ctx.setTransform(1,0,0,1,0,0)` 286 = screen-space outside camera. PASS.

## Check 5 — runtime errors / dead code
```
$ node --check <extracted-script>
SYNTAX_OK exit=0
$ grep -nE 'console\.(log|warn|debug)|// TODO|debugger|FIXME' index.html
(no hits)
```
- Syntax valid. No debug/TODO/dead code.
- TDZ check: `skidMarks` declared `const` line 343, referenced in update() 210/215 + draw() 251. Both are function bodies invoked only by rAF loop (queued 338, fires next frame — after module eval reaches 343). No runtime TDZ. PASS.
- Magic numbers in draw (car body, skid offsets, HUD geometry) — see L1/L2/L3.

## Check 6 — cross-row contract integrity
- `keys` map: single object 81; written keydown 350 / keyup 368; read 105-109, 289-293. Consistent. PASS.
- `car.handbrake`: single flag. Set 109, read 144/203/291, reset 362. No alt naming (handBrake/hand_brake absent). PASS.
- `car.lateralSlip`: written 148, read by skid threshold 203 + alpha 213, reset 363. Skid marks consume it. PASS.

## Check 7 — file completeness
```
370  </script>
371  </body>
372  </html>
```
Closes cleanly. PASS.

## Findings

### M1 — medium — `SKID_MAX` overloaded with two semantics
index.html:43 `const SKID_MAX = 300; // lateral speed (px/s) ... max opacity`
- Line 213: `alpha: min(1, car.lateralSlip / SKID_MAX)` — opacity divisor (px/s units). Correct use.
- Line 215: `if (skidMarks.length > SKID_MAX) skidMarks.shift()` — array-length cap (entry count). Wrong unit.
Same constant 300 serves opacity-scale AND ring-buffer length. Coincidental value match. Tuning opacity (e.g. lower SKID_MAX for darker skids sooner) silently shrinks skid-trail history, and vice versa.
Remediation: add `const SKID_BUFFER_MAX = 300;` to tunable block (29-47); change line 215 to use it. Keep SKID_MAX for opacity only.

### L1 — low — car-body draw uses hardcoded geometry
index.html:276 `ctx.fillRect(-20,-10,40,20)`; 279 `ctx.fillRect(10,-10,10,20)`; skid rear-corner offsets 209-212 `15` / `9`. Visual dimensions decoupled from CAR_RADIUS(18). Car body 40x20 vs collision radius 18 — visual/physics mismatch tolerable but magic.
Remediation: derive from CAR_RADIUS or add CAR_W/CAR_H tunables.

### L2 — low — HUD panel geometry hardcoded
index.html:297 `fillRect(10,10,200,130)`; text coords 304-317 (20,34..130). Magic layout numbers. Acceptable for single-panel HUD; flag for completeness.
Remediation: none required; optional HUD_X/HUD_Y/HUD_W consts.

### L3 — low — skid-trigger speed threshold `20` inline
index.html:203 `car.handbrake && skidSpeed > 20`. Bare literal; min handbrake-skid speed not a tunable.
Remediation: optional `const HANDBRAKE_SKID_MIN = 20;`.

### T1 — note (not a defect) — 18 tunables vs spec's 15
Top block holds 18 UPPER_SNAKE consts (29-47); spec said 15. Over-delivery — all 15 conceptual tunables present plus 3 derived (CAR_RADIUS, OBS_RADIUS_T, BRAKE_MULTIPLIER). Req 10 ("all tunables at top") satisfied. No action.

## Final summary
- Overall QA status: PASS WITH CONCERNS.
- 15/15 spec requirements met and greppable.
- Findings: 0 critical, 0 high, 1 medium (M1), 3 low (L1-L3), 1 note (T1).
- Verification: node --check exit 0; no console/TODO/debugger; file closes; all cross-row contracts (keys / car.handbrake / car.lateralSlip) consistent; draw order correct; physics model implements drift+grip+speed-scaled-steer+handbrake-override+friction.
- No regression/test suite (static HTML, no tests defined). No bug-fix rows → no red-green check applicable.
- Recommendation: M1 should be fixed (rename array-cap constant); L1-L3 NTH.
