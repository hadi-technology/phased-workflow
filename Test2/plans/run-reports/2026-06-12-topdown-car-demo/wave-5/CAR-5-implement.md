STATUS=DONE

# CAR-5 — Bounded arena walls + ~10 scattered obstacles with bounce collision

## Files touched
- index.html (edit in place)

## Approach
3 edits to index.html:
1. Obstacles section inserted after `keys` declaration (line 82 area)
2. Wall bounce + circle collision appended at end of `update()` after position update
3. Obstacle draw block inserted in `draw()` before car draw, inside camera save/restore

## Deviations
None. Code matches spec verbatim.

## DoD Verification

### AC1 — grep -E 'OBSTACLE_COUNT' index.html >=1
IDENTIFY: grep -c
RUN:
```
$ grep -c 'OBSTACLE_COUNT' index.html
2
```
COMPARE: 2 >= 1. PASS.

### AC2 — obstacles generated into array
IDENTIFY: grep -c 'obstacles\b'
RUN:
```
$ grep -c 'obstacles\b' index.html
7
```
COMPARE: 7 >= 1. PASS.

### AC3 — collision push-out AND velocity reflection via RESTITUTION
IDENTIFY: grep -E pattern
RUN:
```
$ grep -E 'car\.vx\s*\*=\s*-RESTITUTION|car\.vy\s*\*=\s*-RESTITUTION' index.html
      if (car.x - CAR_R < 0) { car.x = CAR_R; car.vx *= -RESTITUTION; }
      if (car.x + CAR_R > ARENA_SIZE) { car.x = ARENA_SIZE - CAR_R; car.vx *= -RESTITUTION; }
      if (car.y - CAR_R < 0) { car.y = CAR_R; car.vy *= -RESTITUTION; }
      if (car.y + CAR_R > ARENA_SIZE) { car.y = ARENA_SIZE - CAR_R; car.vy *= -RESTITUTION; }
```
COMPARE: 4 matching lines. PASS.

### AC4 — walls clamp+bounce at ARENA_SIZE bounds
IDENTIFY: grep -E 'ARENA_SIZE' excluding const/assignment
RUN:
```
$ grep -E 'ARENA_SIZE' index.html | grep -v 'const\|ARENA_SIZE\s*=' | head -3
      x: ARENA_SIZE / 2,
      y: ARENA_SIZE / 2,
      if (car.x + CAR_R > ARENA_SIZE) { car.x = ARENA_SIZE - CAR_R; car.vx *= -RESTITUTION; }
```
COMPARE: ARENA_SIZE used in bounds check (line 3 of output). PASS.

### AC5 — manual verification
Covered by code inspection: push-out (`car.x += nx * overlap`) and velocity reflection (`car.vx -= (1+RESTITUTION)*dot*nx`) are both present. Wall clamp sets position then inverts velocity with RESTITUTION. No tunneling risk at typical dt <= MAX_DT=0.033 with speeds <= 600 px/s (max penetration per frame = ~20px, safely caught).

## Cleanliness self-check

Existing patterns reused: PASS. Single-file canvas project; no component/hook system. Obstacle color hex matches peer pattern of all other draw calls in file using raw hex.

Design tokens: PASS with documented exception. Raw hex #8e44ad/#6c3483 used for obstacle colors — consistent with established peer draw calls (#e74c3c car body, #1a1a2e background, #922b21 front stripe, #333 grid). No token system exists in this codebase.

No hardcoded magic numbers: PASS. CAR_R, OBS_RADIUS, MIN_DIST_FROM_CENTER are all locally named constants. OBSTACLE_COUNT/ARENA_SIZE/RESTITUTION consumed from TUNABLES block.

Naming matches peer conventions: PASS. `obstacles`, `CAR_R`, `OBS_RADIUS` match camelCase/SCREAMING_SNAKE conventions used in file.

Minimum diff: PASS. All added lines serve obstacle spawn, wall bounce, obstacle collision, or obstacle draw. No drive-by changes.

No dead leftovers: PASS. No console.log, TODO, debugger. CAR_HALF_W/CAR_HALF_H declared per spec snippet — kept verbatim per task instructions, flagged as NTH for AABB upgrade.

No duplicated logic: PASS. Wall bounce and obstacle collision are distinct code paths with no duplication.

Raw hex scan:
```
$ git diff -U0 -- 'index.html' | grep -nE '#[0-9A-Fa-f]{3,8}\b'
56:+      ctx.fillStyle = '#8e44ad';
57:+      ctx.strokeStyle = '#6c3483';
```
Exception documented above: matches project convention, no token system.

Debug artifacts scan:
```
$ git diff -U0 -- 'index.html' | grep -nE 'console\.log|// TODO:|// eslint-disable|debugger'
(no output)
```
PASS.

Typecheck: N/A — no package.json or tsconfig; plain JS in HTML file.

Enumeration check: N/A — no type/interface/instrumentation/new-vendor-API change.

## NTH items
- CAR_HALF_W/CAR_HALF_H declared but unused — future row could swap circle approximation for AABB collision using these halves for more accurate box-vs-circle
- OBS_RADIUS hardcoded to 30; future row could vary obstacle sizes for visual interest
