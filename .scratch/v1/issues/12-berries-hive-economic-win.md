# 12: Berries and the Hive; Economic Win

**What to build:** Day's Berry piles (66 Berries) appear at Match start. A Worker picks up a Berry by touching it and carries one at a time; depositing it in an empty hole of their Team's Hive fills that hole. A carried Berry drops as a loose Berry where the Worker dies. Loose Berries have collision and are kicked when a Berry-carrying Worker runs into them. Filling all 12 holes is an Economic Win.

**Blocked by:** 10

**Status:** ready-for-agent

- [ ] Test: touching a Berry picks it up; a Worker already carrying one doesn't pick up another
- [ ] Test: depositing fills a hole in the Worker's own Hive only
- [ ] Test: a Worker killed while carrying drops a loose Berry at their position
- [ ] Test: running into a loose Berry while carrying one kicks it; loose Berries collide with characters and terrain
- [ ] Test: the 12th deposit emits an Economic Win and ends the Match
- [ ] Winged characters can't pick up Berries
- [ ] Hive holes are drawn and visibly fill
