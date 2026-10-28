# 19: Bot Queen

**What to build:** A convincing Bot Queen, given the most Bot effort because she plays nearly every Match. She claims Gates early (neutral first, then steals), defends her Hive and Gates from enemy Warriors, hunts enemy Workers riding the Snail and carrying Berries, Dives on targets below her, uses height in Jousts, and flees when she's at risk (low on Eggs, outnumbered by Warriors).

**Blocked by:** 11, 13, 15, 17

**Status:** ready-for-agent

- [x] Test: from Match start, a Bot Queen claims at least one Gate within a time limit
- [x] Test: with an enemy Worker riding the Snail toward her Goal and no other threats, she moves to intercept it
- [x] Test: facing a higher enemy Warrior, she gains height or retreats instead of flying into it
- [x] Test: her input never contains anything a human Queen couldn't do
- [ ] Playtest: a human Team without a Queen loses Military pressure fights to a Bot Queen at Normal unless they coordinate

## Comments

Done, except the playtest box, which needs humans: does a Queenless human Team lose Military pressure fights to a Normal Bot Queen unless it coordinates?

- Code: `Bot.input` now dispatches by role: `BotQueen` (new), `BotWorker` (ticket 17's Worker, moved out of `Bot` unchanged), Warriors idle until ticket 20. `Bot.press` is the shared "let go, then press" helper.
- Flying (`sim/bot_flight.gd`, `BotFlight`):
  - The Map is cut into 24 px cells. A cell is open if a Queen/Warrior collider centred in it touches no solid tile (starting barriers ignored). Cells wrap sideways only on rows where winged characters wrap.
  - For a target cell, a breadth-first search gives every cell's distance to it in steps through open cells. Fields are remembered (512 per Map), and the BotFlight itself is memoised by Map and winged size and kept in `MatchState.navs["flight"]`, like BotNav.
  - `BotFlight.toward(state, c, x, y, dive)` aims at the cell two steps nearer along the field (or the target itself once that close, or if it can't be reached). It steers toward it with the stick and Flaps whenever she is sinking faster than a quarter of the height still to make up, capped at her max rise speed. A Flap is always a fresh press. With `dive`, it holds Down instead of Flapping.
  - Warriors (ticket 20) can fly with the same call.
- The Queen (`sim/bot_queen.gd`) does the first that applies, each tick:
  1. A dangerous enemy within 120 px: she backs off 200 px horizontally at her own height. Dangerous means a Queen or Warrior whose feet aren't more than the Joust margin below hers, or one that is invulnerable. The range is 220 px when she's at risk: no Eggs waiting, or more living enemy Warriors than hers.
  2. An enemy Worker riding the Snail.
  3. An enemy Queen or Warrior within 260 px whose sword is below hers and that isn't invulnerable.
  4. The nearest neutral Gate.
  5. The nearest enemy Worker carrying a Berry.
  6. The nearest enemy Gate, to steal.
  7. The nearest enemy Worker.
  8. Otherwise, wait at her spawn point by the Hive.
  - Targets 2 and 4–7 are skipped while guarded, meaning a dangerous enemy is within 120 px of them. Without that, the two Queens met over the middle Warrior Gate and backed off from each other forever. Stealing comes after hunting carriers for the same reason: before, each Queen spent the Match trying to reach the other's Gates past the other Queen.
  - Prey is attacked from just above: she lines her feet up 8 px over its head, and Dives once it is within 24 px horizontally and below her.
  - Climbing above a threat was tried first. In a mirror Match both Queens climbed to get above each other and pinned themselves to the top of the Map, so a threat now only makes her back off. She still uses height: a Queen or Warrior below her is prey, and one above her is avoided.
  - She uses no randomness yet. All-Bot Matches still differ by seed through the Workers' choices.
- Tests: `test/sim/bot_queen_test.gd` (9). 151 in all; the suite now takes about 1 min 55 s, from the all-Bot determinism tests.
  - On Day, both Bot Queens claim a Gate within 500 ticks.
  - On Day, with a Gold Worker riding the Snail, the Blue Bot Queen comes down from the Hives' level, Dives onto it and kills it, claiming no Gate first, long before a Snail Win.
  - On a floor, she claims a Gate 1200 px away. With a Gold Warrior hovering 30 px up in the way, she isn't killed in 600 ticks.
  - She claims a far neutral Gate before stealing a nearer Gold one.
  - A Warrior 170 px up halfway along: she passes under it to the Gate with Eggs left and even Warriors, but not with no Eggs or with a second Gold Warrior.
  - She leaves a nearer Gate a higher Warrior hovers over for a free one.
  - She kills a Berry carrier before a nearer empty-handed Worker.
  - She flies the short way round where the Map wraps.
  - Input shape: ticket 17's test runs an all-Bot Match with Bot Queens and checks every input is a stick, Down and button, with Down only for Queens.
- Mutation checks: each of these made a matching test fail.
  - No threat response.
  - Only invulnerable enemies dangerous.
  - Eggs or Warrior numbers not counting toward risk.
  - Stealing before neutral Gates.
  - No Dive.
  - The Snail rider not first.
  - No guarding.
  - Attacking winged enemies whatever their height.
  - Carriers not first.
  - Every cell open.
  - No wrapping.
  - Flapping only when falling.
  - No path following.
  - The Queen not dispatched.
- In the running game: both keyboards locked Worker Seats, so both Queens were Bots. Each claimed its Speed Gate on tick 89 and its side Warrior Gate on tick 264. Then Gold's Queen killed Blue Workers on ticks 533, 535 and 737, and chased Blue's Queen, which kept away. No Queen died.

Open questions:
- Mirror all-Bot Matches can end in a stand-off between the Queens: one chases the other around the wrap at equal speed. Ticket 21 (reaction delay and mistakes, drawn from the RNG) should break these up.
- Cost: all-Bot Matches step in about 3–4 ms per tick (2.3 with Worker Bots only), mostly breadth-first searches toward moving prey. Fine at 50 ticks/s, but it is why the suite is slower.
- Does the arcade Bot Queen take Gates during the countdown? Here she can, as a human can (ticket 13's open question).
