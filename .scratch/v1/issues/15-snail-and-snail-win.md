# 15: Snail and Snail Win

**What to build:** The Snail sits on Day's bottom track. A Worker mounts it by walking into it when nobody is riding, and the Snail then moves toward that Worker's Snail Goal at ~0.446 px/tick (1.35× if the rider is a Speed Worker). An unridden Snail stays still. The rider dismounts with the button. An enemy Worker walking into the Snail's front gets eaten: the Snail stops for 184 ticks (92 with a Speed Worker rider), during which the rider can't move or dismount. Killing the rider during the eat frees the victim alive; a completed eat kills the victim and spits out their Berry as a loose Berry. Reaching the Snail Goal is a Snail Win.

**Blocked by:** 12

**Status:** ready-for-agent

- [ ] Test: walking into an unridden Snail mounts it; winged characters can't mount
- [ ] Test: a ridden Snail moves toward the rider's Snail Goal at the tuned speed; a Speed Worker rider moves it 1.35× faster; unridden, it doesn't move
- [ ] Test: pressing the button dismounts (but not during an eat)
- [ ] Test: an enemy Worker entering the front starts an eat lasting 184 ticks (92 with a Speed Worker rider)
- [ ] Test: killing the rider mid-eat frees the victim alive; a completed eat kills the victim and drops their Berry
- [ ] Test: the Snail reaching a Snail Goal emits a Snail Win for that Team and ends the Match
- [ ] Snail mount/dismount and eat started/completed/interrupted events are emitted
