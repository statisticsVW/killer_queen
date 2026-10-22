# 21: Bot Difficulty levels

**What to build:** Bot Difficulty spreads Bot play across Easy, Normal and Hard: reaction delay, the rate at which a Bot picks a worse objective, and whether Bots notice threats (a Worker fleeing a Warrior, a Queen avoiding a higher Warrior). Easy keeps the 0.8× speed. No level gives a Bot anything a human lacks.

**Blocked by:** 19, 20

**Status:** ready-for-agent

- [ ] Reaction delay, mistake rate and threat awareness are per-level tuning values
- [ ] Test: across a batch of seeded Matches, Hard Bots beat Normal Bots, and Normal beat Easy, more often than not
- [ ] Test: Easy Bots react more slowly than Hard Bots to the same scripted threat
- [ ] Playtest: 2 humans can beat Easy, find Normal a fair fight, and are pushed by Hard
