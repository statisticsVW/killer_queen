# 09: Measure and tune movement

**What to build:** Replace the placeholder movement constants with values measured from Killer Queen Arcade footage, then tune by feel with the user. Measure frame by frame in logical pixels against known tile sizes: gravity, terminal velocity, Worker tap and hold jump apex and duration, Flap impulse and hover rate, ceiling stick/ricochet threshold and stick duration, Bump repel strength and no-turn window, Dive speed, respawn delays, invulnerability durations, and countdown length. Record each value, and how it was measured, in the research doc.

**Blocked by:** 03, 04, 06, 08

**Status:** ready-for-human

- [ ] The user approves which footage to download before anything is downloaded
- [ ] Each measured constant is in the tuning table with a note of its source clip and method
- [ ] Values that couldn't be measured are listed along with the estimate chosen
- [ ] The research doc's open-questions section is updated with what was resolved
- [ ] The user plays the movement sandbox and signs off that it feels like the arcade (the arcade reference wins over Killer Queen Black memory)
