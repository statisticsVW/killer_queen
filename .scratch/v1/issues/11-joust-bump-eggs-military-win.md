# 11: Joust, Bump, Queen Eggs and Military Win

**What to build:** Contact between winged characters (Warrior or Queen) is a Joust: the higher sword wins and kills, and contact from behind kills. A Joust nobody wins is a Bump: both are repelled by their prior velocity and briefly can't turn. A Warrior who dies respawns as a Worker. Each Team's Queen has three Eggs at the Hive; a Queen death hatches the next Egg; killing a Queen with no Eggs left is a Military Win.

**Blocked by:** 10

**Status:** ready-for-agent

- [x] Test: the higher of two Jousting Warriors kills the lower
- [x] Test: contact from behind kills; a level, face-to-face Joust Bumps and blocks turning for the no-turn window
- [x] Test: a dead Warrior respawns as a Worker
- [x] Test: Queen deaths use up Eggs and the Queen hatches from the next one; the death after the last Egg emits a Military Win and ends the Match
- [x] Eggs are drawn at each Hive and disappear as they are used

## Comments

Done.

- Joust: when two enemy Queens or Warriors touch, the one whose feet are more than `joust_height_margin` (8 px placeholder) above the other's kills it. Within the margin, one that faces the other and runs into its back (the victim faces the same way) kills it. Face to face or back to back is a Bump, with the no-turn window being the existing `bump_ticks`. A Diving Queen needs no margin, so her Dive still kills anything beneath her. `Sim._winner` decides every kill, Workers included.
- Height comes first. A lower attacker who is behind its target doesn't kill it; the higher one wins.
- Winged landing on winged: the one above now kills by height instead of standing on the head. The ticket 10 test of a Queen standing on a Warrior became a test that the Dive ignores the margin; it sets the margin taller than a collider.
- Invulnerable, changed from ticket 10: an enemy sword now passes through any invulnerable player, winged or not, with no Bump. An invulnerable Queen or Warrior can still kill. Two Workers still Bump.
- Warrior death: a dead Warrior respawns as a Worker.
- Eggs: `MatchState.eggs[team]` counts the waiting Eggs. A Map's Egg positions give each Team's starting count (Day: 2 waiting, plus the one the Queen hatched from at the start, so 3 lives). A Queen's death uses the next Egg (the last of the first `eggs` positions) and makes it her spawn point. She hatches there after `respawn_queen_ticks` (150 placeholder) with the usual invulnerability, and a `HATCH` event replaces `RESPAWN`. A Queen who dies with no Eggs waiting stays dead.
- Military Win: that last death sets `MatchState.win = Win.MILITARY` and `winner` to the killer's Team, and emits `MatchEvent.win(team)` (`WIN`, with `team`). Once a Match is won, `_collide_characters` stops (nothing else dies that tick) and `Sim.step` only advances the tick. Ticket 16 decides what happens next. `Win.ECONOMIC` and `Win.SNAIL` exist for tickets 12 and 15.
- `TestMaps.build` takes optional Egg positions (the same for both Teams). Test Maps have none by default, so a Queen's first death there wins.
- Presentation: each Hive draws only its waiting Eggs. A dead Queen who will hatch is drawn as the Egg she is hatching from. A placeholder banner ("BLUE MILITARY WIN") stands in for ticket 16's victory screen.
- Tests: `test/sim/joust_test.gd` (8 tests). Mutation checks: the height comparison, the Dive's zero margin, the victim and attacker facing tests in "behind" (the attacker one needed the back-to-back test), Warrior→Worker, the Egg count, the hatch position, the Queen hatch delay, the winner's Team, the freeze after a win, stopping collisions after a win, invulnerable losers and the pass-through rule. Each made a matching test fail.
- In the running game (hatch and invulnerability shortened): a Blue Warrior killed the Gold Queen from behind three times. She hatched at 1031 then 1102 px, Gold's Eggs went 2 → 1 → 0, and the third kill drew "BLUE MILITARY WIN" and froze the Match.

Open questions for ticket 09:
- The real Joust geometry: the height margin, and whether the attacker must face the victim for a height kill.
- The Queen's hatch delay.
