# 06: Ceiling stick and ricochet

**What to build:** Hitting a ceiling slowly sticks a character to it for a fixed time (button presses do nothing while stuck); hitting it fast ricochets them downward. The Speed upgrade raises the threshold between the two: the multiplier hook exists now and is wired up when Speed arrives in ticket 13.

**Blocked by:** 03

**Status:** ready-for-agent

- [x] Test: upward speed below the threshold sticks for the stick duration, then the character drops off ("time-out")
- [x] Test: upward speed above the threshold ricochets downward
- [x] Test: button presses while stuck have no effect
- [x] The threshold, stick duration and ricochet speed are tuning-table values

## Comments

Done. When a character's head stops against a solid tile, the sim compares its upward speed at impact with `ceiling_ricochet_threshold`. At or below the threshold it sticks for `ceiling_stick_ticks`: it doesn't fall and the button does nothing. When that time runs out it drops off. Above the threshold it ricochets down at `ceiling_ricochet_speed`. All three values are in a new `[ceiling]` section of `data/tuning.cfg`, as placeholders (25 ticks, 6 px/tick, 8 px/tick) until ticket 09. The Speed hook is `Sim._ricochet_threshold(c, t)`, which returns the base value until ticket 13 applies the 1.35x multiplier there.

Decision not in the ticket: while stuck, the stick still moves the character sideways along the ceiling, and running out from under the ceiling ends the stick early. Ticket 09 should check this against footage (the alternative is being frozen in place).

Tests: `test/sim/ceiling_test.gd` covers stick then time-out, ricochet, presses while stuck, and dropping off past the end of a ceiling. For a Worker today, the presses-while-stuck rule would hold even without the stuck check, because its coyote window has run out by then. The check starts to matter for Flaps (ticket 08). Checked in the running game under Day's tunnel roof: a full jump hits at about 10 px/tick and ricochets; a shortened jump hits at 4 px/tick and sticks for 25 ticks; mashing the button while stuck changes nothing.
