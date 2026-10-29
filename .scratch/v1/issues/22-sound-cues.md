# 22: Sound cues

**What to build:** Placeholder sound effects triggered by sim events at the right moments: kill pop, Queen death, Egg hatch, Berry pickup and deposit, Gate claim, transform start and emerge, Snail mount and eat, Famine start and end, countdown, and a distinct cue for each win type. Sounds are driven only by the tick's events, never by the presentation layer re-deriving rules.

**Blocked by:** 13, 14, 15, 16

**Status:** ready-for-agent

- [x] Every event listed above has a cue
- [x] Cues play on the rendered frame closest to their tick, including under slow motion and Replay playback
- [x] Ten simultaneous kills don't clip into noise (voice limiting per cue)
- [x] Placeholder sounds are original (generated or made for this project)

## Comments

Done. Audio isn't automated (spec), so the event-to-cue mapping is a tested model and the sounds themselves were checked in the running game by logging every cue played.

- `game/cues.gd` (`Cues.of(state, ticks_per_second)`): the cues a state plays, from the events of the tick that produced it, plus the countdown. Each cue plays once a tick however often its moment happened, in Cue order.
  - Every DEATH plays the kill pop (as the visual pop shows on every death, a Snail eat's included). A Queen's death also plays QUEEN_DEATH. KILL events play nothing more.
  - HATCH, BERRY_PICKUP, BERRY_DEPOSIT, GATE_CLAIM, TRANSFORM_START, TRANSFORM_COMPLETE, SNAIL_MOUNT, EAT_START, EAT_COMPLETE, FAMINE_START and FAMINE_END each have their own cue.
  - WIN plays MILITARY_WIN, ECONOMIC_WIN or SNAIL_WIN by `MatchState.win`.
  - The countdown is state, not an event: COUNTDOWN beeps as each whole second is first shown (from the Match's first state, so 3, 2, 1) and GO plays on the state it ends, as `main.gd` draws them.
  - Events that play nothing: RESPAWN, BERRY_DROP, BERRY_KICK, SNAIL_DISMOUNT, EAT_INTERRUPT, TRANSFORM_INTERRUPT.
- `game/sounds.gd` (`Sounds`, a Node `main.gd` owns): plays cues.
  - Every sound is original, synthesised once at start-up into a 16-bit 22 kHz `AudioStreamWAV` from a few notes each (sine, square, triangle or noise, sliding pitch, fading). No assets.
  - Voice limiting: three `AudioStreamPlayer` voices per cue; a cue played while all three are busy restarts the one that has played longest. With the once-a-tick rule, ten kills at once are one pop, and a run of kills is at most three.
  - A hard limiter (`AudioEffectHardLimiter`, ceiling -0.3 dB) on the master bus keeps different cues sounding together from clipping.
- `main.gd` plays the cues of each state as the sim steps to it, right where it starts the kill pops, and of a Match's first state when it starts (stopping any still sounding). F9 Replay playback goes through the same `_step`, so it plays them too.
- Timing: a cue starts on the physics tick the sim steps to its state, the same moment its pop first shows, so it lands on the first rendered frame drawn toward that tick. Cues follow sim steps, never wall time, so a slow-motion dev tool (ticket 04, not built) that steps the sim more slowly would keep them on their ticks without changes.
- Nothing in `sim/` changed; no new events. `MatchConfig`, the tuning table and the Replay are unchanged (Replay version still 7).
- Tests: `test/game/cues_test.gd` (7). 187 in all.
  - Each listed event plays its own cue; the unlisted ones play nothing.
  - Every death pops; a Queen's (either Team's) also plays QUEEN_DEATH.
  - Each win type plays its own cue.
  - Ten deaths, two Queen deaths and three pickups in one tick play one KILL, one QUEEN_DEATH and one BERRY_PICKUP, in Cue order.
  - Over the countdown and three seconds after: COUNTDOWN at ticks 0, 50 and 100, GO at 150, nothing else; at 30 ticks a second, beeps at 0, 30, 60, 90 and 120.
- Mutation checks: each of these made a test fail: beeping at 0 left; beeping off the second; a fixed 50 ticks a second; GO on every tick after the countdown, or on every later one; no Queen-death check; one win cue for all; no sorting; dropping event cues entirely, or the HATCH, EAT_START or DEATH entries; inverting the lookup.
- In the running game (scratch script, all-Bot Match by F8, then F9):
  - Live: COUNTDOWN at ticks 0, 50 and 100, GO at 150, each on the physics frame the sim stepped to that tick. Blue won by Military at tick 2613. 113 cues: 31 kill pops, 4 Queen deaths, 34 pickups, 7 deposits, 11 Gate claims, 7 transform starts, 6 emerges, 5 Snail mounts, 3 hatches, the win.
  - F9 playback played the same 113 cues on the same ticks.
  - Ten kill cues on ten frames in a row: voices playing rose 1, 2, 3 and stayed at 3. Then every cue at once. The master peak never passed the limiter's -0.3 dB, through the Match, the Replay or the burst.
  - Eat, Famine, Economic and Snail win cues didn't come up in that Match; they played in the every-cue burst, and their mapping is tested.
- Not checked by ear: whether the placeholders sound right. That's a listening pass for the user.
