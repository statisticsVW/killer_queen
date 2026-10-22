# 22: Sound cues

**What to build:** Placeholder sound effects triggered by sim events at the right moments: kill pop, Queen death, Egg hatch, Berry pickup and deposit, Gate claim, transform start and emerge, Snail mount and eat, Famine start and end, countdown, and a distinct cue for each win type. Sounds are driven only by the tick's events, never by the presentation layer re-deriving rules.

**Blocked by:** 13, 14, 15, 16

**Status:** ready-for-agent

- [ ] Every event listed above has a cue
- [ ] Cues play on the rendered frame closest to their tick, including under slow motion and Replay playback
- [ ] Ten simultaneous kills don't clip into noise (voice limiting per cue)
- [ ] Placeholder sounds are original (generated or made for this project)
