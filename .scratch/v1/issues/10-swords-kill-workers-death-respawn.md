# 10: Swords kill Workers; death, respawn and invulnerability

**What to build:** Any enemy sword contact (Queen or Warrior) kills a Worker regardless of angle, and the Queen's Dive kills anything beneath her. A dead character pops, then respawns at their Team's Hive after the respawn delay with blinking invulnerability. Kill and death events are emitted.

**Blocked by:** 07, 08

**Status:** ready-for-agent

- [x] Test: enemy sword contact from any side kills a Worker; same-Team contact doesn't
- [x] Test: a Diving Queen kills a Worker beneath her
- [x] Test: the dead Worker respawns at their Hive after the respawn delay and is invulnerable for the invulnerability window
- [x] Kill and death events appear in the tick's event list
- [x] On screen: kill pop, respawn, blinking

## Comments

Done.

- Swords: Queens and Warriors always have their swords out, and the sword is the whole winged collider for now (reference open question 16). Any overlap between an enemy Queen or Warrior and a Worker kills the Worker, from any side, including a Worker landing on their head. Worker-on-Worker contact is unchanged (Bump or stand on head). Teammates still pass through each other.
- Dive: a Diving Queen (`CharacterState.diving`) kills any enemy she overlaps whose feet are below hers, winged or not. Without Diving, a Queen landing on a Warrior stands on its head. All other winged-vs-winged contact is still a Bump until ticket 11's Joust.
- Death: `CharacterState.alive` goes false. The dead character keeps its position (where presentation draws the pop), ignores input and touches nothing. Its motion state is cleared.
- Respawn: after `respawn_ticks` steps it reappears at `CharacterState.spawn` (its spawn point in front of the Hive, set by `create_match`), standing, and doesn't move on that tick. It keeps its role for now: ticket 11 makes a dead Warrior respawn as a Worker and replaces a Queen's respawn with Egg hatching. The dev Warrior command skips dead Seats.
- Invulnerable: `invulnerable_ticks` is set to `respawn_invulnerable_ticks` on respawn, counting that tick, and counts down. Nothing kills an invulnerable character. An enemy sword touching an invulnerable Worker passes through it without a Bump (otherwise a Worker respawning into a Warrior would just be shoved off). Invulnerable winged characters still Bump. Ticket 13 reuses this for Gate emergence; ticket 12 ends it early on Berry pickup.
- Events: `MatchState.events` lists what happened during the tick that produced the state (`MatchEvent`: `KILL` seat killed other, `DEATH` seat died and other killed it or -1, `RESPAWN`). `Sim.step` starts each state's list empty; `copy()` copies it.
- Tick order: dead characters count down and maybe respawn, living ones count down invulnerability and move, then `_collide_characters` resolves kills, pass-through, heads and Bumps in Seat order between living enemies.
- Tuning: `[respawn] ticks=100` (2 s) and `invulnerable_ticks=75` (1.5 s), both placeholders until ticket 09.
- Presentation: a DEATH event starts a 15-tick pop at the victim (Team-coloured burst in a growing white ring). Dead characters aren't drawn, invulnerable ones blink 3 ticks on, 3 off, and a respawned character doesn't interpolate from where it died.
- Tests: `test/sim/combat_test.gd` (9 tests). Mutation checks: Worker kills from any side, the Dive height test, Dive needing `diving`, the invulnerability boundary, its countdown, the respawn delay, the respawn position, the sword pass-through, dead characters colliding, the per-tick event reset, and Workers having no sword. Each made a matching test fail.
- In the running game: the Gold Queen ran into a Blue Worker on the Hive ledge. The Worker popped (KILL 5→4, DEATH 4), respawned at its spawn point exactly 100 ticks later and blinked.

Open questions for ticket 09:
- Respawn delay and invulnerability window are placeholders.
- Is the sword the whole body, or only a forward/down hitbox (does a Worker landing on a Warrior's head die)?
- How far below the Queen must something be for her Dive to kill it?
- Do enemy swords pass through an invulnerable Worker, or Bump it?
