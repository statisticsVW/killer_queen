# 21: Bot Difficulty levels

**What to build:** Bot Difficulty spreads Bot play across Easy, Normal and Hard: reaction delay, the rate at which a Bot picks a worse objective, and whether Bots notice threats (a Worker fleeing a Warrior, a Queen avoiding a higher Warrior). Easy keeps the 0.8× speed. No level gives a Bot anything a human lacks.

**Blocked by:** 19, 20

**Status:** ready-for-agent

- [x] Reaction delay, mistake rate and threat awareness are per-level tuning values
- [x] Test: across a batch of seeded Matches, Hard Bots beat Normal Bots, and Normal beat Easy, more often than not
- [x] Test: Easy Bots react more slowly than Hard Bots to the same scripted threat
- [ ] Playtest: 2 humans can beat Easy, find Normal a fair fight, and are pushed by Hard

## Comments

Done, except the playtest box, which needs humans: can 2 humans beat Easy, find Normal a fair fight, and get pushed by Hard?

- Tuning (`[bot]`, nine new constants, all placeholders): `reaction_ticks` Easy 18, Normal 10, Hard 4 (0.36, 0.2 and 0.08 s); `mistake_percent` 30, 10 and 0; `awareness_percent` 50, 85 and 100. `Bot.by_level(c, easy, normal, hard)` picks a Bot's value. Easy keeps its 0.8x speed. Replay version 7, since the tuning table changed shape.
- Reaction delay: Bots see their enemies late.
  - `MatchState.seen` holds the characters as they stood at the start of each of the last `Bot.memory_ticks` ticks (the slowest level's delay plus one), newest first.
  - Those arrays are earlier states' `characters`, never changed after their tick, so `Sim.step` builds a new list each tick and every copy shares it. Nothing is copied.
  - `Bot.view(state, c)` gives the one a Bot's delay looks back to, or the oldest kept.
  - `BotSword.enemies` and the enemy Snail rider come from that view, so the Queen's and Warriors' threats, prey and guards all see enemies late, and so does a Worker's flight. Teammates, the Bot itself, Berries, Gates and the Snail are seen as they are now.
  - The fingerprint skips `seen`: it holds earlier states' characters, which were in those states' fingerprints. A new determinism test checks instead that a mid-Match copy with Bots steps identically.
- Threat awareness: `BotSword.threat` (used by every role) rolls once, from the Match's random generator, when an enemy sword first becomes a threat (dangerous and within range).
  - On a hit the Bot notices it; on a miss it ignores that enemy until it is no longer a threat, then rolls again the next time.
  - The rolls are remembered in `BotState.noticed` and `missed`, bit masks by Seat.
- Bot Workers now run from enemy swords: a noticed threat within 140 px (dangerous: a Queen or Warrior not more than the Joust margin below its feet) sends it straight away along the ground, until the threat is gone. That is ticket 21's "a Worker fleeing a Warrior".
- Mistakes: when a Bot Worker chooses a target (`_choose`), it rolls its mistake rate. On a hit it takes a random reachable target for its objective instead of the soonest (a far Berry, a far hole). Winged Bots weigh their targets afresh every tick, so a mistake there would only jitter; their weakness is the reaction delay and awareness.
- Tests: `test/sim/bot_difficulty_test.gd` (8), plus a determinism test. 180 in all; the suite takes about 3 min 30 s, a minute of it the Difficulty batch.
  - The per-level values are as above.
  - On a floor, Blue's Bot Queen waits while Gold's human Warrior flies at her 100 px up. Easy steers away later than Hard, or not at all.
  - With every level fully aware, each level steers away exactly its reaction delay after Hard, less Hard's.
  - At awareness 0 she never steers away.
  - At 50%, over eight passes of the Warrior she misses at least one, and notices a later one.
  - A Hard Bot Worker runs back from a Warrior flying at it, but not at awareness 0.
  - At a 100% mistake rate, a Bot Worker sometimes goes for a far pile first (over 12 seeds); at 0% never.
  - All-Bot Matches on Day, seeds 1 and 2 with the better level on each side: Hard beat Normal and Normal beat Easy in more than 2 of 4 each.
- Ticket 19 and 20's role tests now run Hard Bots, which react quickest and notice every threat. Normal's delay and misses broke five of them; Difficulty has its own tests now.
  - The Queen's "neutral Gate before stealing" test changed its setup. Gold's Queen used to walk away, almost as fast as the Bot Queen flies, and the Bot Queen used to lose her. Seeing her 4 ticks late, she kept chasing.
  - Now Gold's Queen flies straight up out of the way, from 300 px away. Even then, at 200 px a 4-tick-old view of a climbing Queen showed her below, as prey, so the Bot Queen followed her up and killed her.
- Batches (scratch script, 12 Matches each, seeds 1–6 with each level on each side):
  - Hard beat Normal 10 of 12 (Economic 6, Military 5, Snail 1).
  - Normal beat Easy 12 of 12 (Military 10, Economic 2).
  - Normal against Normal split 6–6 (Military 8, Snail 4).
  - Normal Bots are slower to react than ticket 20's, and Workers now flee, so Normal-v-Normal Economic Wins are rarer than ticket 20's 12-seed batch (2 of 12 there). All three win types still occur across the batches.
- Mutation checks: each of these made a matching test fail.
  - Easy or Hard using Normal's values.
  - Keeping one tick too few of what Bots see.
  - No reaction delay.
  - Always noticing.
  - Acting on missed threats.
  - Never forgetting a miss (needed the "notices a later pass" check).
  - No Worker flight.
  - No mistakes.
  - `Sim.step` not keeping what Bots saw.
  - `copy()` dropping it.
  - Also re-checked: stealing before claiming neutral still fails the reworked Queen test.
- In the running game: in the Lobby, WASD set Blue's Bots to HARD and the arrows walked to Gold's panel and set EASY. F8 started an all-Bot Match with those levels.
  - Blue's Hard Queen killed Gold's Easy Queen three times (ticks 22, 312, 717), and Blue won by Military at tick 717, with 8 kills to Gold's 0.
  - In a run where Gold stayed Normal (a miscounted key press), Blue still won, by Economic at tick 2736, 10 kills to 7.

Open questions:
- The values are first guesses for the playtest to tune: delays, mistake rates, awareness and the 140 px flight range.
- The Queen's first kill came on tick 22, during the countdown. Ticket 16's open question (can players kill each other during the countdown?) matters more now Hard Bots exploit it.
- Should winged Bots make objective mistakes too (a Queen chasing the wrong Worker)? Here only Bot Workers do.
- A fleeing Worker only runs along the ground. It doesn't jump, route away, or hide in the Hive.

