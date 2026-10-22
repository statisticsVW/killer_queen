# 10: Swords kill Workers; death, respawn and invulnerability

**What to build:** Any enemy sword contact (Queen or Warrior) kills a Worker regardless of angle, and the Queen's Dive kills anything beneath her. A dead character pops, then respawns at their Team's Hive after the respawn delay with blinking invulnerability. Kill and death events are emitted.

**Blocked by:** 07, 08

**Status:** ready-for-agent

- [ ] Test: enemy sword contact from any side kills a Worker; same-Team contact doesn't
- [ ] Test: a Diving Queen kills a Worker beneath her
- [ ] Test: the dead Worker respawns at their Hive after the respawn delay and is invulnerable for the invulnerability window
- [ ] Kill and death events appear in the tick's event list
- [ ] On screen: kill pop, respawn, blinking
