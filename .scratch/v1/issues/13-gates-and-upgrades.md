# 13: Gates and upgrades

**What to build:** Day's five Gates (three Warrior Gates, two Speed Gates) start neutral and usable by both Teams. A Queen claims a Gate by touching it, turning it her Team's colour so only her Workers can use it, until the other Queen touches it. A Worker carrying a Berry who stands still at a usable Gate transforms: 50 ticks holding the Berry overhead (can be killed or Bumped out), then 50 ticks locked in (invisible, invulnerable), then emerges upgraded with blinking invulnerability that ends early if they pick up a Berry. A Speed Gate makes a Speed Worker (1.35× horizontal speed and rise rate); a Warrior Gate makes a Warrior, or a Speed Warrior from a Speed Worker. Upgrades are lost on death.

**Blocked by:** 08, 12

**Status:** ready-for-agent

- [x] Test: a Queen touching a neutral or enemy Gate claims it; Workers can't use an enemy-owned Gate
- [x] Test: a Worker with a Berry becomes a Warrior after 100 ticks at an owned Warrior Gate, and the Berry is consumed
- [x] Test: a kill or Bump during the first 50 ticks interrupts the transform; the Worker can't be harmed during the last 50
- [x] Test: a Worker without a Berry standing at a Gate stays a Worker
- [x] Test: a Speed Worker re-entering a Speed Gate stays as they are and keeps the Berry
- [x] Test: a Speed Worker at a Warrior Gate becomes a Speed Warrior; dying loses all upgrades
- [x] Test: emerge invulnerability ends when the character picks up a Berry
- [x] Speed raises the ceiling stick/ricochet threshold (ticket 06's hook)
- [x] Gate colour shows ownership on screen; Gate claim and transform events are emitted

## Comments

Done.

- Gates: `MatchState.gates` (`GateState`: `type` WARRIOR or SPEED, position, `team`, -1 while neutral), the Map's Warrior Gates then its Speed Gates, in Map order. That order is the Gate index used by events and `CharacterState.gate`. Collider `gate_width` x `gate_height` (56x52 px placeholder, the drawn Gate).
- Tick order: after characters collide and before Berries, `Sim._update_gates` runs.
  - In Seat order, every living Queen claims each Gate she touches that isn't already her Team's (GATE_CLAIM, seat = Queen, other = Gate). Only Queens claim.
  - Each transform goes on. `CharacterState.gate` is the Gate and `gate_ticks` the ticks spent in it. At `gate_hold_ticks` (50) the doors close and the Berry becomes `BerryState.Where.SPENT`. At `gate_hold_ticks + gate_locked_ticks` (100) the Worker emerges (TRANSFORM_COMPLETE) upgraded and invulnerable for `gate_invulnerable_ticks` (75 placeholder; the existing `invulnerable_ticks`, so the existing Berry-pickup rule ends it).
  - In Seat order, a living Worker carrying a Berry who stands still (`vx` 0, on the ground, not on the Snail) touching a Gate starts transforming (TRANSFORM_START), snapped to the Gate's x. The Gate must be neutral or its Team's, empty, and able to change it: a Speed Gate does nothing for a Speed Worker, who keeps the Berry.
- During a transform the Worker ignores its stick, doesn't move, picks nothing up and is out of the Snail's reach.
  - Holding phase (the first 50 ticks): it collides as normal. A sword kills it, dropping the Berry loose. A Bump knocks it out of the Gate, keeping the Berry. Both emit TRANSFORM_INTERRUPT. Standing still again at the Gate starts over.
  - Locked phase: everyone passes through it, and it isn't drawn. `CharacterState.is_locked_in(tuning)` is the shared test, so presentation doesn't keep its own copy.
- Upgrades: a Warrior Gate makes a Warrior (a Speed Warrior from a Speed Worker), a Speed Gate a Speed Worker. Respawning now clears `speed` as well as Warrior, so dying loses every upgrade.
- Speed (`[speed] ratio`, 1.35x): a Speed Worker's or Speed Warrior's max horizontal speed (running, flying, and walking before the 0.84x) and a Speed Warrior's `winged_max_rise_speed`. The ceiling ricochet threshold becomes `ceiling_speed_ricochet_threshold` (8.1 px/tick placeholder, 1.35x; the reference says Speed raises it but not by how much). Speed doesn't change a Worker's jump.
- Dev commands removed: `TickInput.dev_warrior_seats` and `dev_speed_seats` are gone, and so are the digit and Shift+digit dev keys. Tests and dev setups start Seats upgraded with `MatchConfig.warrior_seats` and `speed_seats` instead (Queen Seats ignore both). The Replay records those, at version 4 (ticket 17 will need 5). Ticket 04 can add mid-Match dev commands back if they're missed.
- For ticket 14: a Berry spent at a Gate is `Where.SPENT`, so Famine can count it as taken. A Famine refresh must bring `SPENT` Berries back too.
- Presentation: each Gate's frame is its owner's Team colour, light grey while neutral. Its doorway is dark, and shut (brown) while a Worker is locked in. Wings sit above a Warrior Gate and a bolt in a Speed Gate's doorway. Locked-in Workers and spent Berries aren't drawn. The emerging character blinks like a respawn.
- Tests: `test/sim/gate_test.gd` (16), plus Speed tests in `worker_running_test`, `winged_flight_test` and `ceiling_test`. 119 in all.
- Mutation checks: each of these made a matching test fail.
  - Warriors claiming.
  - Claiming an owned Gate again.
  - Enemy Gates usable.
  - Speed Gates usable by Speed Workers.
  - The Berry spent a tick late.
  - The locked phase starting a tick late.
  - Bumps and kills not ending a transform.
  - Respawn keeping Speed.
  - No emerge invulnerability.
  - No snap to the Gate.
  - Two Workers in one Gate.
  - Gate users moving.
  - Entering while moving.
  - Each Speed effect (run, rise, ricochet threshold).
  - Starting Warrior and Speed Seats ignored.
  - Locked-in Workers colliding.
  - Gate users picking up Berries.
  - Dropping `gate`, `gate_ticks` or Gate `team` from `copy()`. The determinism copy check catches Gate `team`, since Queens claim Gates in its scripted Match.
  - Dropping the starting Seats from the Replay.
  - Swapping the Gate order.
- One guard survives mutation: the Snail ignoring Workers in a Gate. It only matters if a Gate stands on the Snail track, which no Map has.
- In the running game on Day: the Gold Queen, put on the right Warrior Gate, claimed it on tick 10. The Blue Queen walked left along the Hives' level during the countdown and claimed Blue's Speed Gate on tick 114. A Blue Worker given a Berry on the middle Warrior Gate started at tick 210. It showed with the Berry overhead, then the doors shut with nothing drawn, and the spent Berry was gone. At tick 310 it emerged as a blinking Warrior. The first run drew the spent Berry over the shut Gate; that is fixed.

Open questions:
- Can a Queen claim Gates during the countdown? Here she can: Day's Speed Gates are inside the starting barriers, so each Queen can claim her side's before play begins.
- Does a Queen claiming a Gate stop an enemy Worker already transforming in it? Here it doesn't.
- How much does Speed raise the ricochet threshold? Does Speed raise a Worker's jump? Ticket 09.
- Can a Worker walk out of a Gate during the holding second? Here it can't; only a Bump or a kill gets it out.
- The Gate collider size and the emerge invulnerability length are placeholders. Ticket 09.
