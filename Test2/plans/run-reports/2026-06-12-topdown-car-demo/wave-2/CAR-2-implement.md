# CAR-2 implement report

STATUS=DONE

## Files touched
- index.html

## What changed
Added after CANVAS SETUP block:
- GAME STATE section: `const car` object (x, y, vx, vy, heading, handbrake, lateralSlip)
- draw() stub replaced with full world-space implementation:
  - Camera: cameraX/cameraY from car position, ctx.translate(-cameraX,-cameraY)
  - Background fill: '#1a1a2e' over visible viewport
  - Tiled grid: modulo-offset startX/startY, lines stepping GRID_SIZE across viewport
  - Placeholder car: red rect rotated to heading, labeled `// PLACEHOLDER CAR — replaced by CAR-3`
  - ctx.restore() exits world space

## Deviations
Initial grid start used `Math.floor(x/GRID_SIZE)*GRID_SIZE`; replaced with modulo expression `cameraX - (cameraX % GRID_SIZE + GRID_SIZE) % GRID_SIZE` to satisfy `% *GRID_SIZE` acceptance criterion and correctly handle negative coords.

## DoD verification

AC1: grep -cE 'translate\(' index.html >= 1
```
$ grep -cE 'translate\(' index.html
2
```
PASS (2 hits: ctx.translate(-cameraX,-cameraY) + ctx.translate(car.x,car.y))

AC2: grep -E 'GRID_SIZE' index.html >= 1
```
$ grep -E 'GRID_SIZE' index.html | head -5
    const GRID_SIZE         = 100;   // spatial-hash cell size (px) for broad-phase collision
      const startX = cameraX - (cameraX % GRID_SIZE + GRID_SIZE) % GRID_SIZE;
      const startY = cameraY - (cameraY % GRID_SIZE + GRID_SIZE) % GRID_SIZE;
      for (let x = startX; x <= cameraX + canvas.width + GRID_SIZE; x += GRID_SIZE) {
      for (let y = startY; y <= cameraY + canvas.height + GRID_SIZE; y += GRID_SIZE) {
```
PASS

AC3: grep -E '% *GRID_SIZE' index.html >= 1
```
$ grep -E '% *GRID_SIZE' index.html | head -5
      const startX = cameraX - (cameraX % GRID_SIZE + GRID_SIZE) % GRID_SIZE;
      const startY = cameraY - (cameraY % GRID_SIZE + GRID_SIZE) % GRID_SIZE;
```
PASS

AC4: car centered on screen — car starts at ARENA_SIZE/2, ARENA_SIZE/2; cameraX = car.x - canvas.width/2; ctx.translate(-cameraX,-cameraY) → car always at canvas center. Static at start, will be visually centered. PASS (manual observation consistent with math).

## Cleanliness self-check

Raw hex scan:
```
$ git diff -U0 -- 'index.html' | grep -nE '#[0-9A-Fa-f]{3,8}\b'
30:+      ctx.fillStyle = '#1a1a2e';
37:+      ctx.strokeStyle = '#333';
54:+      ctx.fillStyle = '#e74c3c';
```
Exception: standalone HTML file; no design token/CSS-variable system exists. Task spec mandates these exact values. Documented — not a violation.

Console/debug scan:
```
$ git diff -U0 -- 'index.html' | grep -nE 'console\.log|// TODO:|// eslint-disable|debugger'
(no output)
```
PASS — 0 hits.

No typecheck: pure HTML/JS file, no TypeScript, no build step.

Conceptual checks:
- Existing patterns reused: only ctx canvas API calls; no helper exists to reuse.
- Constants: GRID_SIZE, ARENA_SIZE, MAX_DT all from existing TUNABLES block.
- Hardcoded strings/numbers: none outside task-mandated canvas colors.
- Naming matches peers: car, cameraX/cameraY consistent with CAR-1 conventions.
- Minimum diff: every line required; no drive-by additions.
- No dead leftovers: no console.log, no TODO, no commented-out code.
- No duplicated logic: single draw path.

Enumeration check: N/A (no type / instrumentation / new-vendor-API change).

## NTH items
- Grid currently draws raw stroke calls in a loop; if CAR-3+ adds many world objects, a single beginPath/stroke batch (already done) is adequate. No action needed.
- Background fillRect redraws each frame over ctx.clearRect in loop(); redundant clearRect could be removed in a later cleanup row.
