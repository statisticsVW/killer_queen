# 07: Ten Seats on Day, multiple devices, Bump and springboard

**What to build:** A Match has all ten Seats: five Blue and five Gold Workers spawn at their Team's spawn points on Day. Connected pads and the two keyboard layouts (WASD + Space, arrows + Enter) take Seats in a fixed order; unassigned Seats stand idle for now. Characters Bump each other (a non-lethal shove) and can springboard off another character's head.

**Blocked by:** 03

**Status:** ready-for-agent

- [x] Ten characters exist in Match state, each with a Team and Seat
- [ ] Xbox and Switch Pro controllers drive Seats without configuration; Up on a stick never reaches Seat input
- [x] Test: two Workers running into each other Bump apart and neither dies
- [x] Test: jumping shortly after landing on another character's head goes higher than a ground jump
- [x] On screen, several devices control several Workers at once

## Comments

Done, except one check only the user can do: plugging in real Xbox and Switch Pro controllers.

- Seats and devices: the game runs all ten Seats on Day (0-4 Blue, 5-9 Gold). Devices take Seats in a fixed order: WASD → Seat 0, arrows → 5, then pads by Godot device id → 1, 6, 2, 7, 3, 8, 4, 9. Teams alternate, so the first two players are opponents. Seats with no device stand idle. `KeyboardLayout.merge` is gone, since each layout now drives its own Seat.
- Pads (`game/Pad`): stick or d-pad steers, with a 0.5 deadzone. Any face button is the button. Down is read; Up never is. This relies on Godot's SDL mappings. It was checked with injected joypad events for devices 0 and 1, not with physical pads, which is why that box is still open.
- Bump: only enemies collide; teammates pass through each other (the reference says Workers bump *opponents*). Touching enemies swap horizontal velocities ("repelled according to their prior velocities"). If the swap wouldn't part them, both are pushed apart at `bump_speed`. Neither can steer or turn for `bump_ticks`. Running into a standing enemy shoves it.
- Heads and springboard: an enemy that comes down onto another's head stands on it. Jumping within `worker_springboard_ticks` of landing uses `worker_springboard_jump_speed`. All four new constants are placeholders until ticket 09.
- Tests: `test/sim/character_contact_test.gd` (8 tests). The springboard test fails if the springboard speed equals the jump speed.
- In the running game: keyboards Bump, pads move Seats 1 and 6 and jump, and a springboard off a head on Day rises 217.5 px against 150 px.

Open questions for ticket 09:
- Do teammates collide or springboard off each other in the arcade?
- How strong is the real Bump repel?
