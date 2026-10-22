# 11: Joust, Bump, Queen Eggs and Military Win

**What to build:** Contact between winged characters (Warrior or Queen) is a Joust: the higher sword wins and kills, and contact from behind kills. A Joust nobody wins is a Bump: both are repelled by their prior velocity and briefly can't turn. A Warrior who dies respawns as a Worker. Each Team's Queen has three Eggs at the Hive; a Queen death hatches the next Egg; killing a Queen with no Eggs left is a Military Win.

**Blocked by:** 10

**Status:** ready-for-agent

- [ ] Test: the higher of two Jousting Warriors kills the lower
- [ ] Test: contact from behind kills; a level, face-to-face Joust Bumps and blocks turning for the no-turn window
- [ ] Test: a dead Warrior respawns as a Worker
- [ ] Test: Queen deaths use up Eggs and the Queen hatches from the next one; the death after the last Egg emits a Military Win and ends the Match
- [ ] Eggs are drawn at each Hive and disappear as they are used
