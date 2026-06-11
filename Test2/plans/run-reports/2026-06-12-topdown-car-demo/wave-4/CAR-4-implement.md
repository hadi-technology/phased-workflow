# CAR-4 Implement Report
Status: DONE
Date: 2026-06-12

## Files touched
- index.html (event listeners added after `requestAnimationFrame(loop)`)

## Approach
`keys` object and physics reads already existed from CAR-3 (lines 79, 87-91, 92).
Added 2 event listeners at bottom of script block: keydown populates `keys[e.code]=true`, prevents Arrow*/Space scroll, handles KeyR reset; keyup sets `keys[e.code]=false`.

## Deviations
None. Spec code used verbatim.

## DoD Verification

### AC1: addEventListener('keydown') >= 1
```
$ grep -c "addEventListener('keydown'" index.html
1
```
PASS

### AC2: addEventListener('keyup') >= 1
```
$ grep -c "addEventListener('keyup'" index.html
1
```
PASS

### AC3 [H1]: keys[] keyed by event.code
```
$ grep -E 'keys\[' index.html | head -3
      const throttle   = (keys['KeyW'] || keys['ArrowUp'])    ? 1 : 0;
      const brake      = (keys['KeyS'] || keys['ArrowDown'])  ? 1 : 0;
      const steerInput = ((keys['KeyD'] || keys['ArrowRight']) ? 1 : 0)
```
PASS

### AC4: preventDefault present
```
$ grep -E 'preventDefault' index.html | head -2
        e.preventDefault();
```
PASS

### AC5: R reset via KeyR / 'r' / 'R'
```
$ grep -E "'r'|'R'|KeyR" index.html | head -2
      if (e.code === 'KeyR' || e.key === 'r' || e.key === 'R') {
```
PASS. Zeroes vx/vy/heading/handbrake/lateralSlip, recenters to ARENA_SIZE/2.

### AC6 [H1]: car.handbrake driven by keys['Space']
```
$ grep -E 'car\.handbrake' index.html | head -3
      car.handbrake = !!(keys['Space']);
      const effectiveGrip = car.handbrake ? HANDBRAKE_GRIP : GRIP;
        car.handbrake = false;
```
PASS. Set each frame in update() from keys['Space']; reset to false on KeyR.

## Cleanliness Self-Check

### 2e.1 Mechanical scan

git diff: 26-line addition — event listeners only. No modifications to existing code.

Raw hex in diff: 0 hits. PASS.
Raw spacing numbers in diff: N/A (no styled-UI changes). PASS.
console.log / TODO / eslint-disable / debugger in diff: 0 hits. PASS.
Typecheck: no project typecheck defined (plain HTML/JS, no tsconfig). PASS.

### 2e.1.5 Enumeration check
N/A — no type/interface change, no instrumentation, no new vendor API.

### 2e.2 Conceptual checks
- Existing patterns reused: `keys` object from CAR-3 (line 79). No new data structures. PASS.
- Design tokens: no new values introduced. PASS.
- No hardcoded strings: ARENA_SIZE constant used for reset coordinates. PASS.
- Naming matches peers: `keys`, `car`, event handler pattern matches existing CAR-3 style. PASS.
- Minimum diff: 26 lines added, all required. PASS.
- No dead leftovers: no commented-out code, no TODOs, no stray logs. PASS.
- No duplicated logic: single keydown handler, single keyup handler. PASS.

## NTH items
None discovered.
