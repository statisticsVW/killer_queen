# 20: Bot Workers pick objectives; Bot Warriors

**What to build:** Bot Workers choose between running Berries, transforming at a usable Gate and riding the Snail, based on a read of the Match (Hive progress, Snail position, how many Warriors each Team has, which Gates their Team owns). Bot Warriors hunt enemy Workers (prioritising Snail riders and Berry carriers) and the enemy Queen, use height in Jousts, and protect their own Snail rider.

**Blocked by:** 13, 15, 17

**Status:** ready-for-agent

- [x] Test: with the Snail close to their Goal and unridden, a Bot Worker goes to ride it
- [x] Test: with their Team owning a Warrior Gate and no Warriors, a Bot Worker carrying a Berry goes to transform
- [x] Test: a Bot Warrior with an enemy Snail rider in reach goes for the rider
- [x] Test: an all-Bot Match on a fixed seed ends in a win within a time limit, and repeated runs end identically
- [x] Across a batch of seeded all-Bot Matches, all three win types occur

## Comments

Done.

- Code: `BotSword` (new, `sim/bot_sword.gd`) holds what a winged Bot reads before using its sword, moved unchanged out of `BotQueen`: `dangerous`, `guarded`, `threat`, `back_off`, `snail_rider`, `winged_below`, `worker`, `enemies` and the distances. `BotQueen` keeps only what is hers (`_at_risk`, `_gate_to_claim`, the Dive attack). `BotWarrior` (new) uses the same calls. `Bot.input` now dispatches Warriors to `BotWarrior`.
- Bot Worker objectives (`BotWorker.Objective`: BERRY, HOLE, GATE, SNAIL). `BotState.carrying` became `BotState.objective`, with `target` its index (a Berry, hole or Gate; 0 for the Snail). Each tick on a Ledge the Bot works out the objective it should pick. If that differs from the one it holds, it chooses a new target, as it already did when the target went away. In order:
  1. SNAIL: the Snail stands unridden on its Team's half of the track (no further from its Snail Goal than from the other Team's; exactly halfway counts, which is where every Match starts), and of the Team's living Bot Workers this one is nearest it. Nearness is horizontal plus vertical distance, ties going to the lower Seat. The usual Chebyshev distance tied every Worker on the Hives' level at the start (the vertical gap dominates), so all of them went. Carriers ride too. A rider stays on while the Snail is on its Team's half and presses to get off on the other half. Ticket 17's "gets off the Snail" habit now applies only there.
  2. HOLE or GATE when carrying: GATE while a Warrior Gate its Team owns is free (nobody in it), the Team has no more Warriors than the enemy, and more than 3 holes of its Hive are empty (`_HIVE_NEARLY_FULL`). The Team's count includes its other Bots whose objective is GATE (on the way or inside), so two carriers don't both go for the one Warrior wanted. Bots use only Gates their Team owns: neutral ones need a Queen's claim first, and Speed Gates are never used on purpose.
  3. BERRY otherwise.
- Transforming on purpose: at its Gate the Bot stands still (neutral stick) and `Sim`'s Gate rule starts the transform. `_past_gates` skips the Gate the Bot is going to transform in, and still keeps it walking past every other one.
- Bot Warriors (`sim/bot_warrior.gd`) do the first that applies, each tick:
  1. A dangerous enemy within 120 px: back off 200 px and climb to its height. From there a Flap or two puts the Bot above, and the enemy becomes prey. Climbing a further 48 px made no difference in tests, so it was dropped. Backing off at its own height, as the Queen does, never gets above.
  2. If it is its Team's living Warrior nearest its own Team's Snail rider, guard it: go for the enemy nearest the rider within 300 px, or else hover 120 px over the rider. A hovering guard is dangerous to an enemy Queen coming in lower than it, so she sees the rider as guarded and leaves it.
  3. An enemy Snail rider (unless guarded).
  4. An enemy Queen or Warrior below it within 260 px.
  5. The nearest unguarded enemy Berry carrier.
  6. The enemy Queen: fly to 80 px above her; once above, step 4 takes over.
  7. The nearest unguarded enemy Worker.
  8. Otherwise, wait at its spawn point.
  - It strikes by flying its body at a Worker's body, or at a Queen's or Warrior's head, so its feet stay above the other's. Warriors can't Dive (Down is the Queen's), and the Bot input test still checks they never hold it.
- Tests: `test/sim/bot_worker_objectives_test.gd` (11), `test/sim/bot_warrior_test.gd` (8), and 2 new in `bot_test.gd`. 171 in all; the suite takes about 2 min 20 s.
  - Snail: on Day with the Snail near Blue's goal, a lone Blue Bot Worker passes every pile, rides it home and wins, never getting off. From exactly halfway it goes too. Only the nearest Bot Worker goes; of two at the same point, the lower Seat goes; a Bot Warrior by the Snail and a dead teammate there don't count. A Bot Worker on the Snail on Gold's half gets off and runs Berries (ticket 17's test, with the goals swapped).
  - Gates: a carrier transforms at its Team's Warrior Gate with no Warriors on either side, stopping with a neutral stick. It also goes when each Team has one Warrior. It doesn't when the Gate is Gold's, when Blue has a Warrior and Gold none, when Blue's Hive has only 3 holes, when the Gate is a Speed Gate, or when a human teammate is already in the only Gate. Of two carriers, only one goes.
  - Warriors:
    - It kills an enemy Snail rider before a nearer carrier, and a carrier before a nearer empty-handed Worker.
    - It leaves alone an enemy rider a higher enemy Warrior hovers over.
    - It kills the enemy Queen from above.
    - It gets above a Warrior hovering 30 px up in its path and kills it, without dying.
    - Guarding: a lone Bot Warrior keeps a Bot Queen off its rider all the way to a Snail Win (without it she kills the rider). It also kills a human Warrior flying straight at the rider. Of two Warriors, the nearer guards and the farther kills a carrier.
  - All-Bot: seed 2 on Day ends in a win within 6000 ticks (a Military Win at tick 2062), and a second run ends on the same tick with the same fingerprint.
  - Ticket 17's untested check is now tested: a human Worker dies on Gold's Queen at the end of a platform, dropping its Berry loose there. Gold's Bot Worker on the floor goes for it. A second Worker kicks it off the platform onto the floor, and the Bot picks it up there. Without the Ledge check in `_still_there`, it stands on the platform where the Berry was.
  - Changed: ticket 17's "every Bot moved" check now looks at every tick. A killed Bot Worker happened to be passing its spawn x on the last one.
- All three win types: 12 seeded all-Bot Matches on Day (Normal against Normal) gave Military 5, Snail 5 and Economic 2, all over by tick 4,221 (85 s). Before this ticket every one was an Economic Win in about 1,100–2,000 ticks. A Match now takes about 2,000–4,200 ticks at 3.5–4.5 ms per tick.
- Mutation checks: each of these made a matching test fail.
  - Bot Workers:
    - The rider getting off on its own half.
    - Its own half strictly nearer (the halfway start).
    - Every half its own.
    - No nearest rule, no tie-break, dead or winged teammates counting.
    - Carriers not riding.
    - No Snail target or the wrong Snail x.
    - The Hive threshold off by one.
    - Strictly fewer Warriors than the enemy.
    - Teammates on the way not counting.
    - Speed Gates or enemy Gates usable.
    - Occupied Gates usable.
    - The wrong Gate x.
    - Not standing still at the Gate.
    - Walking on past its own target Gate.
    - Never re-choosing when the objective changes.
  - Bot Warriors:
    - No threat response, and backing off at its own height.
    - No guarding, no intruder strike, guard reach 0.
    - The farther Warrior guarding.
    - Non-Warriors counting as guards.
    - No rider, winged-below or carrier priority.
    - No Queen approach, or every enemy taken for the Queen.
    - Striking a winged enemy's body instead of its head.
  - BotSword: the guard range, the back-off direction and the carriers-only filter.
  - Survivors, run against the full suite:
    - `_short_of_warriors` not counting the Bot itself, and `_still_there` keeping a SNAIL target, only save routing. Without them a Bot going to a Gate or the Snail chooses again every tick and gets the same answer, since `_choose` clears the target first.
    - `_own_rider` skipping dead Warriors. It matters (a dead Warrior keeps its role until it respawns, so for 100 ticks it would keep the nearest living one from guarding), but a test needs a Warrior killed beside the rider, which a floor Map can't easily stage.
    - `_own_rider`'s own-Team check is an equivalent mutant: "guarding" an enemy rider means striking it, since it is the enemy nearest itself.
    - In `BotSword` (ticket 19's code, moved unchanged): an invulnerable enemy below counting as dangerous, and the guard check on enemy Snail riders. The threat check (step 1 for both Queen and Warrior) keeps a Bot off a guarded rider anyway.
  - Removed as untested and not needed: a Worker in a Gate or one that just got off the Snail being skipped as rider-to-be (Bots only get off on the enemy half, where nobody rides), human teammates in a Gate counting toward Warriors, and locked-in or higher enemies being skipped as intruders (the threat check comes first).
- In the running game: F8 in the Lobby started an all-Bot Match. Bot Workers transformed at the side Warrior Gates their Queens had claimed (seats 8 and 1 at ticks 404–405), and Blue's seat 2 mounted the Snail at the start position on tick 506. Gold's Warrior 7 killed that rider on tick 768. Blue's Warrior 1 killed Gold's Queen on tick 1021, and Warriors jousted (Warrior 4 killed Warrior 7 on tick 1212). Riders kept remounting, and Blue brought the Snail home for a Snail Victory on tick 4789, with 18 Warrior kills in all. The frames show the rider on the Snail with Warriors overhead and Workers holding Berries up in their Gates, then BLUE SNAIL VICTORY with the Snail in Blue's goal.

Open questions:
- Bots never use Speed Gates on purpose. A Speed rider (1.35x Snail, half-time eats) or a Speed Warrior would be worth it; ticket 21 or later.
- Bot Workers don't avoid an enemy-ridden Snail's front, or enemy swords; they walk into both. Ticket 21's "a Worker fleeing a Warrior" is that.
- Bots only spend Berries at Gates their Queen has claimed, never neutral ones. In the arcade, Workers can use neutral Gates.
- The thresholds (Hive nearly full at 3 holes left, one Warrior more than the enemy, guard height and reach) are first guesses; ticket 21 can tune them per Difficulty.
- Snail Wins now come from whichever Team mounts first and guards its rider. Is that too strong against Bots? A playtest question.
