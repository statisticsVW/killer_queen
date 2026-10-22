# 05: Replays and determinism tests

**What to build:** In dev builds, every Match's Replay (Map, Seats, Bot Difficulties, seed, tuning table, and tick-tagged human input) is saved automatically when the Match ends and can be played back to reproduce the Match exactly. Determinism tests guard ADR-0002 from here on.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Test: run a Match from scripted input, record its Replay, play it back; the final state hashes match
- [ ] Test: copy the state mid-Match, step both copies with identical input for N ticks; the states match
- [ ] The sim reads no wall-clock time, and all randomness comes from the seeded generator in Match state
- [ ] A dev build saves the last Match's Replay and can play it back on screen
- [ ] Replays stay out of git
