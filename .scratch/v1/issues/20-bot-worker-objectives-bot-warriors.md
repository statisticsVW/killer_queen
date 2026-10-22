# 20: Bot Workers pick objectives; Bot Warriors

**What to build:** Bot Workers choose between running Berries, transforming at a usable Gate and riding the Snail, based on a read of the Match (Hive progress, Snail position, how many Warriors each Team has, which Gates their Team owns). Bot Warriors hunt enemy Workers (prioritising Snail riders and Berry carriers) and the enemy Queen, use height in Jousts, and protect their own Snail rider.

**Blocked by:** 13, 15, 17

**Status:** ready-for-agent

- [ ] Test: with the Snail close to their Goal and unridden, a Bot Worker goes to ride it
- [ ] Test: with their Team owning a Warrior Gate and no Warriors, a Bot Worker carrying a Berry goes to transform
- [ ] Test: a Bot Warrior with an enemy Snail rider in reach goes for the rider
- [ ] Test: an all-Bot Match on a fixed seed ends in a win within a time limit, and repeated runs end identically
- [ ] Across a batch of seeded all-Bot Matches, all three win types occur
