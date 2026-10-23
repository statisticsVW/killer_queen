# 14: Famine

**What to build:** When the Map's last Berry is taken (deposited or spent at a Gate), Famine starts: a 90-second (4500-tick) countdown is shown on screen, and when it runs out all Berry piles refresh to their starting state.

**Blocked by:** 13

**Status:** ready-for-agent

- [x] Test: taking the last Berry on the Map starts Famine; the countdown is 4500 ticks
- [x] Test: when the countdown ends, every Berry pile is back to its starting count and Famine ends
- [x] Test: Berries still being carried or lying loose don't count as "taken"; Famine starts only when none remain on the Map
- [x] Famine started/ended events are emitted; the countdown is visible on screen

## Comments

Done.

- Famine: `MatchState.famine_ticks`, the ticks left, counting this one, or 0 when there is none. `Sim._update_famine` runs last in the tick, after Berries.
  - While Famine lasts it counts down. On the tick it reaches 0, every pile refills and FAMINE_END is emitted, so the refill comes exactly `famine_countdown_ticks` (`[famine] countdown_ticks=4500`, 90 s, from the reference) after the start.
  - Otherwise, on a Map that has Berries, Famine starts (FAMINE_START) on the tick every Berry is in a Hive or spent at a Gate. Carried and loose Berries don't count as taken.
  - A Map with no Berry piles never has Famine. Without that rule, every test Map without piles would start one on its first tick.
  - Nothing happens once the Match is won, as for Berries.
- Refill: `Sim._pile_slots` gives every pile's six slots; `create_match` builds the piles from it too. Each slot gets a Berry back. Spent Berries are reused first, in index order, then new Berries are appended to `MatchState.berries` for the slots left, because the Berries in Hives stay there. So the Berry list only grows (Day: 66 + however many were deposited), and existing indices never change.
- Events: FAMINE_START and FAMINE_END (no seat).
- Replay version 5 (new tuning constant). Ticket 17's bump will be 6.
- Presentation: "FAMINE m:ss" under the Hives while it lasts. Berry drawing copes with Berries the previous state didn't have.
- Not modelled: the v20.12 "true famine" timer (out of scope in the spec).
- Tests: `test/sim/famine_test.gd` (5).
  - The sixth deposit of the last pile starts Famine at 4500.
  - The refill comes exactly 4500 ticks later, back to the starting pile positions, with the Hive kept, and the next Famine follows.
  - A carried and then loose Berry holds Famine off until it's deposited.
  - Spending the last Berry at a Gate starts Famine as the doors close, and that Berry comes back in the refill.
  - A Map without Berries has no Famine and no events.
- Mutation checks: each of these made a matching test fail.
  - Only piles, piles and loose only, or spent Berries not counting.
  - Starting on a Map without Berries.
  - The refill a tick early.
  - No refill.
  - Not reusing spent Berries.
  - A refill slot moved.
  - The countdown a tick short.
  - Dropping `famine_ticks` from `copy()`.
- Resetting a reused Berry's velocity was redundant, since picking a Berry up already zeroes it, so it was removed.
- In the running game on Day: six Berries were put in Blue's Hive and the rest marked spent. Famine started on the next tick and "FAMINE 1:30" showed under the Hives. With the countdown cut short, all 11 piles refilled (72 Berries in the list) and Blue's six stayed in the Hive.
