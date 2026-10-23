# 15: Snail and Snail Win

**What to build:** The Snail sits on Day's bottom track. A Worker mounts it by walking into it when nobody is riding, and the Snail then moves toward that Worker's Snail Goal at ~0.446 px/tick (1.35× if the rider is a Speed Worker). An unridden Snail stays still. The rider dismounts with the button. An enemy Worker walking into the Snail's front gets eaten: the Snail stops for 184 ticks (92 with a Speed Worker rider), during which the rider can't move or dismount. Killing the rider during the eat frees the victim alive; a completed eat kills the victim and spits out their Berry as a loose Berry. Reaching the Snail Goal is a Snail Win.

**Blocked by:** 12

**Status:** ready-for-agent

- [x] Test: walking into an unridden Snail mounts it; winged characters can't mount
- [x] Test: a ridden Snail moves toward the rider's Snail Goal at the tuned speed; a Speed Worker rider moves it 1.35× faster; unridden, it doesn't move
- [x] Test: pressing the button dismounts (but not during an eat)
- [x] Test: an enemy Worker entering the front starts an eat lasting 184 ticks (92 with a Speed Worker rider)
- [x] Test: killing the rider mid-eat frees the victim alive; a completed eat kills the victim and drops their Berry
- [x] Test: the Snail reaching a Snail Goal emits a Snail Win for that Team and ends the Match
- [x] Snail mount/dismount and eat started/completed/interrupted events are emitted

## Comments

Done.

- Snail: `MatchState.snail` (`SnailState`, or null on a Map without `[snail] start`; `MapData.has_snail`) runs along a horizontal track at the start height. It holds `x`, the `rider`, the eat's `victim` and `eat_ticks`, and the Seat that last `dismounted`.
- Tick order: after characters move and before they collide, `Sim._update_snail` runs.
  - An eat counts down and completes.
  - Otherwise a ridden Snail moves toward its rider's Snail Goal by `snail_speed` (446, i.e. 0.446 px/tick, from the reference), times `snail_speed_rider_ratio` (1.35) for a Speed rider. It stops exactly at the goal, which is a Snail Win.
  - Then, in Seat order, the first living Worker touching an unridden Snail mounts it (ending invulnerability). A ridden Snail that isn't eating starts eating the first enemy Worker touching its front half, the side it is heading toward. Teammates and Queens and Warriors pass through.
  - The rider sits on top, facing the goal, and skips normal movement. The victim is held where it was caught.
- Riding is automatic: the Snail moves whenever it is ridden, whatever the rider's stick does. That is how the ticket reads. Check in ticket 09 whether the arcade rider has to hold toward the goal.
- Dismount: a press gets the rider off unless the Snail is eating. The rider jumps off as from the ground, and the Snail isn't solid, so it falls back through to the floor. It can't remount until it has stood on the ground clear of the Snail; without that rule it hopped clear and landed back on at once.
- Eat: 184 ticks (`snail_eat_ticks`, the reference's frame data), or 92 with a Speed rider (`snail_speed_rider_eat_ticks`). On completion the victim dies (DEATH with no killer, after EAT_COMPLETE), and `_kill` spits out its Berry loose. A dead rider leaves the Snail, which interrupts the eat (EAT_INTERRUPT) and frees the victim alive. Anything else that removes the rider or the victim from the Snail does the same: a sword killing the victim, or the dev Warrior command.
- `_kill` now takes a null killer (the Snail). The Military Win's winner is the dead Queen's opponent, no longer the killer's Team.
- Speed Workers: `CharacterState.speed`. Gates don't exist yet, so `TickInput.dev_speed_seats` gives Seats the upgrade, like the dev Warrior command. Replays record it (Replay version 2), and Shift and a digit sends it in a debug build. For now Speed only affects the Snail; ticket 13 adds faster movement and the higher ricochet threshold, and replaces both dev commands.
- Events: SNAIL_MOUNT and SNAIL_DISMOUNT (seat), and EAT_START, EAT_COMPLETE and EAT_INTERRUPT (seat = rider, other = victim).
- Tuning `[snail]`: speed, the Speed rider ratio and both eat times come from the reference. The 96x52 px collider is a placeholder.
- Presentation: the Snail is drawn at its state position, interpolated, with an eye on the side it's heading and darker while it eats. Speed characters get a yellow belt.
- Tests: `test/sim/snail_test.gd` (12 tests). Mutation checks: winged characters mounting, the Speed rider ratio, the direction of travel, dismounting during an eat, the remount rule (also with the "stood on the ground" part dropped), eating teammates, eating from the back (needed the back-contact test), the Speed rider eat time, the eat killing its victim, rider death freeing the victim, the Snail Win and its winner, and the Speed dev command. Recording the Speed command in Replays needed the determinism test's script to issue it. Each made a matching test fail.
- In the running game on Day: a Blue Worker mounted the Snail, which carried it toward Blue's goal, stopped and ate a Gold Worker in its way for exactly 184 ticks, then (sped up for the check) reached Blue's Snail Goal and drew "BLUE SNAIL WIN".

Open questions for ticket 09:
- Does the rider have to hold toward the goal for the Snail to move?
- Is the Snail solid to stand on, and how does a dismount look in the arcade?
- The collider size, and how far into the front an enemy must be to be eaten.
