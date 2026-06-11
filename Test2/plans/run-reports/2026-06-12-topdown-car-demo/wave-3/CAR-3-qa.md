# CAR-3 QA Report
Date: 2026-06-12
Task: Car arcade physics — momentum, friction, lateral grip/drift, speed-scaled steering

## Re-Audit Notice

This is a scoped re-audit after a fix-findings round targeting F1 and F2 from Round 0.
Full AC verification (AC1–AC7, physics correctness, cleanliness) was completed in Round 0 and is not re-run here.

---

## F1 Re-Verification: Dead variable `lateralVel`

```
$ grep -n 'lateralVel' index.html
(no output)
```

0 hits. Variable removed. `forwardVel` (line 98) still present and read at line 106 for brake direction. `lv2` (line 123) continues to serve all grip/slip logic. No dangling references.

F1: RESOLVED

---

## F2 Re-Verification: Magic number `1.5` brake multiplier

```
$ grep -n '1\.5' index.html
45:    const BRAKE_MULTIPLIER  = 1.5;   // brake force relative to ACCEL (braking is stronger than accelerating)
```

1 hit — appears only as the RHS of the constant definition. No inline magic number in physics code.

```
$ grep -n 'BRAKE_MULTIPLIER' index.html
45:    const BRAKE_MULTIPLIER  = 1.5;   // brake force relative to ACCEL (braking is stronger than accelerating)
108:          car.vx -= cosH * ACCEL * dt * BRAKE_MULTIPLIER;
109:          car.vy -= sinH * ACCEL * dt * BRAKE_MULTIPLIER;
```

3 hits: 1 definition, 2 usages (both brake force lines). Constant sits at line 45 — inside the TUNABLES block (lines 29–45), alongside all other named constants. Placement correct.

F2: RESOLVED

---

## Spot-Check: Fix-Adjacent Lines

- Removed `lateralVel` line (was line 98, now gone): `forwardVel` at new line 98 unaffected; brake branch at line 106 reads `forwardVel` correctly. No stale references.
- `BRAKE_MULTIPLIER` constant: placed at end of tunables block with matching comment style. No orphaned `1.5` literals anywhere in physics code.

No new issues introduced by either fix.

---

## Findings

None open. Both prior findings resolved.

---

## Task Status

Round 0 AC results carry forward (all PASS).

F1 (dead variable `lateralVel`): RESOLVED
F2 (magic number `1.5`): RESOLVED

Overall: PASS — 0 open findings
