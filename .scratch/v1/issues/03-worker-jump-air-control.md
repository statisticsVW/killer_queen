# 03: Worker jump and air control

**What to build:** The Worker jumps with the button: a tap gives a short hop, holding gives a full jump. One tick of coyote time, no jump buffer, and full horizontal speed in the air with mid-air direction changes.

**Blocked by:** 02

**Status:** ready-for-agent

- [x] Test: a tap (button held for 1 tick) reaches a lower apex than a full hold
- [x] Test: jumping on the first tick after walking off a ledge works; on the second tick it doesn't
- [x] Test: pressing the button before landing does not jump on landing
- [x] Test: horizontal speed in the air equals ground speed and can reverse mid-air
- [x] Jump constants are tuning-table values
- [x] Playable on screen on the Day Map

## Comments

Done, on top of ticket 02 (both uncommitted). A button press (not a hold) jumps when the Worker is standing or within `worker_coyote_ticks` (1) of leaving the ground. There is no buffer: a press in the air is lost, and holding through a landing doesn't jump again. Releasing the button while rising cuts the upward speed to `worker_jump_release_speed`, so a one-tick tap rises 45 px and a full hold rises 150 px with the placeholder gravity. That's enough to climb one Day level (120 px apart). Air control uses the same run code, so speed in the air equals ground speed and can reverse. New character state: `button_held`, `airborne_ticks`, `jumping`.

Tests: `test/sim/worker_jump_test.gd` (6 tests). I also checked that the coyote tests fail with coyote 0 and 2. Checked in the running game on Day with injected keys: tap and hold apexes as above, and climbing from the y 336 ledge onto the hive level.

Still placeholders: `worker_jump_speed` (12.5 px/tick) and `worker_jump_release_speed` (6 px/tick), until ticket 09. Hitting a ceiling just stops the rise until ticket 06.
