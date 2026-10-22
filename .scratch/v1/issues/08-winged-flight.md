# 08: Winged flight: Queen and Warrior

**What to build:** The Queen Seat plays a Queen. Queens and Warriors fly by Flapping (each press is one upward impulse, faster tapping climbs faster, no hold-to-fly), walk on the ground at 0.84× airborne speed, and can air brake with three rapid Flaps at terminal fall speed. The Queen Dives by holding Down in the air and arrests the Dive by releasing and Flapping. This ticket covers Dive as movement only; Dive kills arrive in ticket 10. A dev command spawns a Warrior until Gates exist.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] Test: one Flap gives one impulse; holding the button gives no more lift than a single press
- [ ] Test: Flapping above the hover rate climbs; below it the character descends
- [ ] Test: grounded winged walking speed is 0.8412× max horizontal speed
- [ ] Test: three Flaps within the window at terminal fall speed stop the fall
- [ ] Test: a Queen holding Down falls faster; Down is ignored for Workers and Warriors
- [ ] Queen and Warrior colliders match each other and differ from the Worker's
- [ ] Flight constants are tuning-table values
