# 07: Ten Seats on Day, multiple devices, Bump and springboard

**What to build:** A Match has all ten Seats: five Blue and five Gold Workers spawn at their Team's spawn points on Day. Connected pads and the two keyboard layouts (WASD + Space, arrows + Enter) take Seats in a fixed order; unassigned Seats stand idle for now. Characters Bump each other (a non-lethal shove) and can springboard off another character's head.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] Ten characters exist in Match state, each with a Team and Seat
- [ ] Xbox and Switch Pro controllers drive Seats without configuration; Up on a stick never reaches Seat input
- [ ] Test: two Workers running into each other Bump apart and neither dies
- [ ] Test: jumping shortly after landing on another character's head goes higher than a ground jump
- [ ] On screen, several devices control several Workers at once
