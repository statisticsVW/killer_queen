# 09: Measure and tune movement

**What to build:** Replace the placeholder movement constants with values measured from Killer Queen Arcade footage, then tune by feel with the user. Measure frame by frame in logical pixels against known tile sizes: gravity, terminal velocity, Worker tap and hold jump apex and duration, Flap impulse and hover rate, ceiling stick/ricochet threshold and stick duration, Bump repel strength and no-turn window, Dive speed, respawn delays, invulnerability durations, and countdown length. Record each value, and how it was measured, in the research doc.

**Blocked by:** 03, 04, 06, 08

**Status:** ready-for-human

- [x] The user approves which footage to download before anything is downloaded
- [x] Each measured constant is in the tuning table with a note of its source clip and method
- [x] Values that couldn't be measured are listed along with the estimate chosen
- [x] The research doc's open-questions section is updated with what was resolved
- [x] The user plays the movement sandbox and signs off that it feels like the arcade (the arcade reference wins over Killer Queen Black memory)

## Comments

Done. The user played it and signed off on the feel (2026-10-29).

- Footage, approved clip by clip:
  - six arantius *Killer Queen Tech* videos;
  - 5:00-10:24 of the SF League Night 2026-08-24 stream, fetched as byte ranges so nothing else was downloaded.
  - Two Bump shorts were turned down.
  - All of it stays in the session scratchpad.
  - yt-dlp was installed with winget, with the user's OK.
- How it was measured: `docs/research/killer-queen-arcade-reference.md` section 3.1 (clips, method, results, estimates, and where the sim's rules differ). Every value in `data/tuning.cfg` says "measured" or "estimate", with its clip and method.
- The user's decisions:
  - **Flap impulse 4.3 px/tick**, not the 6 the tap data suggests: 6 makes two Flaps stop a terminal fall, against the triple-tap air brake.
  - **The countdown now beeps and shows only 3, 2, 1** (`Cues.COUNTED_SECONDS`), as the arcade does. The other 4 s of the 7 s start pass in silence.
  - **The Bot Warrior fix lands in this ticket.** With the new tuning, a Bot Warrior hung at exactly its 260 px attack range forever. Inside it, `_strike`'s path stepped straight down to a cell whose centre was 4.8 px behind it, so it steered away; outside it, it steered back. Now `BotFlight._aim` keeps the flyer's own x for a cell straight above or below it whose centre is on the far side from the target.
    - Rejected: breaking path ties toward the longer axis. It fixed the dither but changed other approaches (a Warrior flew level into a higher enemy instead of climbing).
- Tests changed:
  - The two countdown cue tests: the new 3-2-1 rule. The 30 Hz test hard-coded the old 150 ticks.
  - The Day barrier test: its runners turn back once the countdown ends. Seven seconds of running had pinned everyone against the top walls, past every gap.
  - The Bot Queen's outnumbered case: its second Gold Warrior now starts past the Gate. At x 60 it was an idle Warrior within her reach, and with the Bot fix she rightly killed it, so she was no longer outnumbered. The case only passed before because of the dither bug.
- Not measured, estimates kept: Bump speed and no-turn window, respawn invulnerability, stick/ricochet threshold and ricochet speed, air-brake window, run accel/decel (instant), springboard jump.
- Rules that tuning can't match (for the user to decide on later):
  - climbing at a constant rate whatever the tap rate;
  - stick time growing with impact speed;
  - a Worker jump's first few ticks speeding up.

