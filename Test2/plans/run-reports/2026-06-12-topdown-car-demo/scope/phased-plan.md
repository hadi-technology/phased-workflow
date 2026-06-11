# Scaffold meta — top-down car demo

Greenfield single-file build. No phased-plan subagent dispatched: there is no codebase to
scaffold against, so Zayneb authored the 7 rows inline from the locked Step-1 scope.

Decomposition (strict serial chain, all rows edit index.html):
CAR-1 scaffold+loop+tunables -> CAR-2 camera+grid -> CAR-3 physics(crit) ->
CAR-4 input -> CAR-5 walls+obstacles+collision(crit) -> CAR-6 skid marks -> CAR-7 HUD.

qa_tier: CAR-3 (physics) and CAR-5 (collision) overridden standard->critical as the two
highest-bug-risk surfaces. Rest standard. No P0 outside those two.
