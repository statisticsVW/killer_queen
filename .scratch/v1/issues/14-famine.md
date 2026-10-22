# 14: Famine

**What to build:** When the Map's last Berry is taken (deposited or spent at a Gate), Famine starts: a 90-second (4500-tick) countdown is shown on screen, and when it runs out all Berry piles refresh to their starting state.

**Blocked by:** 13

**Status:** ready-for-agent

- [ ] Test: taking the last Berry on the Map starts Famine; the countdown is 4500 ticks
- [ ] Test: when the countdown ends, every Berry pile is back to its starting count and Famine ends
- [ ] Test: Berries still being carried or lying loose don't count as "taken"; Famine starts only when none remain on the Map
- [ ] Famine started/ended events are emitted; the countdown is visible on screen
