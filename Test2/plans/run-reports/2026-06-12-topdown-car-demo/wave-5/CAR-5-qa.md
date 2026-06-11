# CAR-5 QA Report (Re-Audit after fix-findings round)
Date: 2026-06-12
Mode: task — scoped re-audit (3 prior low findings)
File audited: /Users/Baba/hadi-phased-workflow/Test2/index.html

---

## Restated Intent

Ship bounded arena walls (position clamp + velocity reflect via RESTITUTION) and ~10 static circle obstacles (random spawn outside center zone, push-out + impulse reflect on collision) drawn in world space, all wired into existing update()/draw() loop. The three prior low findings were about constants placement violations (TUNABLES invariant); this re-audit verifies only those three fixes and that the critical AC still passes.

---

## Scoped Re-Audit: Finding Resolution

### F1 — CAR_R local inside update() — RESOLVED

Verification:
```
$ grep -n 'const CAR_R\b' index.html
(no output)
```
Zero hits. Local-per-frame declaration gone.

```
$ grep -n 'CAR_RADIUS' index.html
46:    const CAR_RADIUS        = 18;    // approximate car collision radius (px)
175:      if (car.x - CAR_RADIUS < 0) { car.x = CAR_RADIUS; car.vx *= -RESTITUTION; }
176:      if (car.x + CAR_RADIUS > ARENA_SIZE) { car.x = ARENA_SIZE - CAR_RADIUS; car.vx *= -RESTITUTION; }
177:      if (car.y - CAR_RADIUS < 0) { car.y = CAR_RADIUS; car.vy *= -RESTITUTION; }
178:      if (car.y + CAR_RADIUS > ARENA_SIZE) { car.y = ARENA_SIZE - CAR_RADIUS; car.vy *= -RESTITUTION; }
185:        const minDist = CAR_RADIUS + obs.r;
```
Line 46 is in the TUNABLES block. Used in wall-bounce (lines 175-178) and obstacle collision (line 185). PASS.

### F2 — CAR_HALF_W / CAR_HALF_H dead constants — RESOLVED

Verification:
```
$ grep -n 'CAR_HALF' index.html
(no output)
```
Zero hits. Dead constants removed entirely. PASS.

### F3 — OBS_RADIUS inside IIFE — RESOLVED

Verification:
```
$ grep -n 'const OBS_RADIUS\b' index.html
(no output)
```
Zero hits. Local IIFE declaration gone.

```
$ grep -n 'OBS_RADIUS_T' index.html
47:    const OBS_RADIUS_T      = 30;    // obstacle circle radius (px)
90:        const x = OBS_RADIUS_T + Math.random() * (ARENA_SIZE - OBS_RADIUS_T * 2);
91:        const y = OBS_RADIUS_T + Math.random() * (ARENA_SIZE - OBS_RADIUS_T * 2);
94:          obstacles.push({ x, y, r: OBS_RADIUS_T });
```
Line 47 is in the TUNABLES block. Used in spawn bounds (lines 90-91) and stored on obstacle object at line 94. PASS.

---

## Critical AC — RESTITUTION velocity reflect still passes

```
$ grep -E 'car\.vx\s*\*=\s*-RESTITUTION|car\.vy\s*\*=\s*-RESTITUTION' index.html
      if (car.x - CAR_RADIUS < 0) { car.x = CAR_RADIUS; car.vx *= -RESTITUTION; }
      if (car.x + CAR_RADIUS > ARENA_SIZE) { car.x = ARENA_SIZE - CAR_RADIUS; car.vx *= -RESTITUTION; }
      if (car.y - CAR_RADIUS < 0) { car.y = CAR_RADIUS; car.vy *= -RESTITUTION; }
      if (car.y + CAR_RADIUS > ARENA_SIZE) { car.y = ARENA_SIZE - CAR_RADIUS; car.vy *= -RESTITUTION; }
```
4 wall-bounce lines present. The rename from CAR_R to CAR_RADIUS did not break the RESTITUTION reflection expressions. PASS.

---

## Spot-check: No new issues introduced by renames

- `CAR_RADIUS = 18` matches the prior `CAR_R = 18` value. No drift.
- `OBS_RADIUS_T = 30` matches the prior `OBS_RADIUS = 30` value. No drift.
- `CAR_HALF_W`/`CAR_HALF_H` removed cleanly; no remaining references anywhere.
- No typos or broken references observed in changed lines.

---

## Findings

None. All 3 prior findings resolved. No new issues introduced.

---

## Summary

| Severity | Count |
|----------|-------|
| critical | 0 |
| high     | 0 |
| medium   | 0 |
| low      | 0 |

All 3 prior low findings: RESOLVED.
Critical RESTITUTION AC: PASS.
No new issues from the renames.

## Task status: PASS
