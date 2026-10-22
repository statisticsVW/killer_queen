# 04: Dev tools

**What to build:** A dev build with an overlay (hitboxes, velocities, tick counter), frame-step (pause and advance one tick), slow motion, and a live editor for the tuning table whose changes apply from the next tick without restarting. The normal build contains none of it.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] The overlay toggles on and off and shows hitboxes, each character's velocity and the current tick
- [ ] Frame-step pauses the sim and advances exactly one tick per press
- [ ] Slow motion runs the sim at a selectable fraction of 50 Hz
- [ ] Editing a tuning constant in the live editor changes behaviour from the next tick
- [ ] None of these tools can be reached in a normal (non-dev) export
