STATUS=DONE

## Files touched
- Test2/index.html

## Changes made

1. Added `skidMarks` array after game loop + before input event listeners (line ~303).
2. Added skid recording block at end of `update()`, after obstacle collision loop.
   - Used `skidSpeed` (not `speed`) to avoid redeclaring existing `speed` variable.
   - Used `cH`/`sH` (not `cosH`/`sinH`) to avoid redeclaring variables already in scope at top of update().
3. Inserted skid draw block in `draw()` between grid stroke and obstacles draw.

## Deviations from spec
- Variable names `skidSpeed`, `cH`, `sH` instead of `speed`, `cosH`, `sinH` per task note: avoid duplicate const declarations.

## DoD verification

### AC1: grep -E 'SKID_THRESHOLD|skid' index.html >=1
```
$ grep -cE 'SKID_THRESHOLD|skid' index.html
11
```
PASS (11 >= 1)

### AC2: skid marks stored in world-space array with bounded cap
```
$ grep -n 'shift\|slice\|SKID_MAX' index.html
43:    const SKID_MAX          = 300;
213:          alpha: Math.min(1, car.lateralSlip / SKID_MAX)
215:        if (skidMarks.length > SKID_MAX) skidMarks.shift();
```
PASS — array capped at SKID_MAX (300) via shift()

### AC3: skid trigger keyed on car.lateralSlip or car.handbrake
```
$ grep -E 'car\.lateralSlip|car\.handbrake' index.html | grep -iE 'skid|push|isSkid' | head -3
      const isSkidding = (car.lateralSlip > SKID_THRESHOLD) || (car.handbrake && skidSpeed > 20);
          alpha: Math.min(1, car.lateralSlip / SKID_MAX)
```
PASS — isSkidding uses car.lateralSlip and car.handbrake

### AC4 [M2]: draw order grid -> skids -> obstacles -> car
```
$ grep -n 'skidMarks\|obstacle\|car draw\|car\.x' index.html | grep -E 'for|draw|push' | head -8
94:          obstacles.push({ x, y, r: OBS_RADIUS_T });
181:      for (const obs of obstacles) {
210:        skidMarks.push({
251:      for (const s of skidMarks) {
263:      for (const obs of obstacles) {
270:      // --- car draw (physics car — CAR-3) ---
```
PASS — skidMarks draw loop (251) before obstacles draw (263) before car draw (270)

## Cleanliness self-check

- git diff read end-to-end: PASS (diff is minimal, only 3 blocks added)
- Raw hex in diff: PASS (0 hits)
- console.log/TODO/debugger in diff: PASS (0 hits)
- Existing patterns reused: PASS — skidMarks follows same pattern as obstacles array; draw loop follows same ctx pattern as obstacles draw
- Design tokens used: PASS — SKID_THRESHOLD, SKID_MAX from tunables block; raw 15/9 are geometric car dimensions (same class as CAR_RADIUS=18 inline in physics, acceptable)
- No hardcoded strings/paths: PASS
- Naming matches peers: PASS — camelCase, matches obstacles/skidMarks pattern
- Minimum diff: PASS — 3 blocks, each required
- No dead leftovers: PASS
- No duplicated logic: PASS
- Enumeration check: N/A (no type/instrumentation/new-vendor-API change)

## NTH items
- skidSpeed variable is redundant with speed already computed earlier in update(); could reuse speed at that point. Not refactored — minimum diff rule; speed is computed at line 155 before position update, skid recording is at end of function where speed reflects post-clamp velocity. Functionally equivalent but separate computation.
