# 06: Ceiling stick and ricochet

**What to build:** Hitting a ceiling slowly sticks a character to it for a fixed time (button presses do nothing while stuck); hitting it fast ricochets them downward. The Speed upgrade raises the threshold between the two: the multiplier hook exists now and is wired up when Speed arrives in ticket 13.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] Test: upward speed below the threshold sticks for the stick duration, then the character drops off ("time-out")
- [ ] Test: upward speed above the threshold ricochets downward
- [ ] Test: button presses while stuck have no effect
- [ ] The threshold, stick duration and ricochet speed are tuning-table values
