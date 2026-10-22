# 08: Winged flight: Queen and Warrior

**What to build:** The Queen Seat plays a Queen. Queens and Warriors fly by Flapping (each press is one upward impulse, faster tapping climbs faster, no hold-to-fly), walk on the ground at 0.84× airborne speed, and can air brake with three rapid Flaps at terminal fall speed. The Queen Dives by holding Down in the air and arrests the Dive by releasing and Flapping. This ticket covers Dive as movement only; Dive kills arrive in ticket 10. A dev command spawns a Warrior until Gates exist.

**Blocked by:** 03

**Status:** ready-for-agent

- [x] Test: one Flap gives one impulse; holding the button gives no more lift than a single press
- [x] Test: Flapping above the hover rate climbs; below it the character descends
- [x] Test: grounded winged walking speed is 0.8412× max horizontal speed
- [x] Test: three Flaps within the window at terminal fall speed stop the fall
- [x] Test: a Queen holding Down falls faster; Down is ignored for Workers and Warriors
- [x] Queen and Warrior colliders match each other and differ from the Worker's
- [x] Test: a winged character is blocked at a Workers-only wrap edge (until now these wrap for everyone; see ticket 02 and `MapData.is_solid`)
- [x] Flight constants are tuning-table values

## Comments

Done.

- Roles: `CharacterState.role` is `Role.WORKER`, `QUEEN` or `WARRIOR`; Queens and Warriors are "winged". `MatchConfig.queen_seats` names the Queen Seats. A Team's Queen takes its first spawn point and its other Seats the following points in Seat order. The game makes each Team's first Seat (0 and 5, the two keyboards) its Queen. The Lobby (ticket 18) will choose this instead.
- Dev command: `TickInput.dev_warrior_seats` turns those Seats' Workers into Warriors at the start of the tick. Because it is part of the tick input, replays (ticket 05) record it. In a debug build, the digit keys 0-9 send it for that Seat. It does nothing to a Queen or a Warrior. Remove it when Gates exist (ticket 13). Ticket 04 can fold the key into its dev tools.
- Flap: each press adds `winged_flap_impulse` of upward speed, capped at `winged_max_rise_speed`. Holding adds nothing. Hovering takes one Flap every `flap_impulse / gravity` ticks (7 with the placeholders, about 7 a second). Faster tapping keeps climbing harder until the rise cap. Winged characters fall under their own `winged_gravity` and `winged_max_fall_speed`, so ticket 09 can tune flight apart from Worker jumps. Gravity comes before the Flap in a winged character's tick; Workers still jump before gravity, as before.
- Walking: grounded winged characters move at `worker_max_speed * winged_walk_speed_ratio / 10000` (8412, from the reference). In the air they move at the full max speed.
- Air brake: a Flap made at terminal fall speed starts an attempt. If the `winged_air_brake_flaps`th Flap (3) comes fewer than `winged_air_brake_ticks` ticks after the first, vertical speed becomes 0. This is an explicit rule, not something that falls out of the impulse maths. It needs checking against footage in ticket 09.
- Dive: a Queen holding Down while airborne falls under `queen_dive_gravity` up to `queen_dive_max_fall_speed`, and her Flaps do nothing. Once she releases Down, any speed above winged terminal speed is kept, not cut, until she Flaps it away. This is how "release and Flap arrests the Dive" works here. Starting from that speed counts as terminal speed, so three quick Flaps air-brake out of a Dive. `CharacterState.diving` is there for ticket 10's Dive kill. Diving while rising strips upward speed, which gives the dive cancel for free.
- Colliders: winged characters share a 40x48 px placeholder collider (Workers are 32x40). All map and character collision uses the character's own collider. `MapData.is_solid` takes a `winged` flag, and Workers-only wrap edges are solid for winged characters.
- Unchanged for now: winged characters still Bump enemies and stand on heads exactly as Workers do. Jousts arrive in ticket 11. They also stick to and ricochet off ceilings like Workers. With the placeholder max rise speed (8 px/tick) above the ricochet threshold (6), fast flapping into a ceiling ricochets. This is the arcade's "Warriors use it to drop fast".
- Tests: `test/sim/winged_flight_test.gd` (14 tests). Mutation checks were run on the air brake Flap count, the Workers-only edge, Dive for non-Queens, walking speed and Flaps while Diving; each made its matching test fail.
- In the running game: the Blue Queen climbs from the Hive tapping Space, the `1` key makes Seat 1 a Warrior, and holding S Dives (14.5 px/tick within 6 ticks).

Open questions for ticket 09:
- Flap impulse, hover rate, rise cap, winged gravity and terminal speed, and the Dive values are all placeholders.
- Is the air brake a rule of its own in the arcade, or just the impulse maths? Does it stop the character dead?
- Does releasing Down keep the Dive speed (as here) or drop back to normal terminal speed at once?
