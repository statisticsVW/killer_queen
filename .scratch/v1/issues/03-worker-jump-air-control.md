# 03: Worker jump and air control

**What to build:** The Worker jumps with the button: a tap gives a short hop, holding gives a full jump. One tick of coyote time, no jump buffer, and full horizontal speed in the air with mid-air direction changes.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Test: a tap (button held for 1 tick) reaches a lower apex than a full hold
- [ ] Test: jumping on the first tick after walking off a ledge works; on the second tick it doesn't
- [ ] Test: pressing the button before landing does not jump on landing
- [ ] Test: horizontal speed in the air equals ground speed and can reverse mid-air
- [ ] Jump constants are tuning-table values
- [ ] Playable on screen on the Day Map
