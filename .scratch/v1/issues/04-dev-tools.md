# 04: Dev tools

**What to build:** A dev build with an overlay (hitboxes, velocities, tick counter), frame-step (pause and advance one tick), slow motion, and a live editor for the tuning table whose changes apply from the next tick without restarting. The normal build contains none of it.

**Blocked by:** 01

**Status:** ready-for-agent

- [x] The overlay toggles on and off and shows hitboxes, each character's velocity and the current tick
- [x] Frame-step pauses the sim and advances exactly one tick per press
- [x] Slow motion runs the sim at a selectable fraction of 50 Hz
- [x] Editing a tuning constant in the live editor changes behaviour from the next tick
- [x] None of these tools can be reached in a normal (non-dev) export (gated and tested; no release export was built, see Comments)

## Comments

Done.

- Keys (dev builds only, as F8/F9 already were): F1 overlay, F2 freeze or run, F3 frame-step, F4 slow motion (full, 1/2, 1/4, 1/10, round again), F5 tuning editor, F6 save the tuning (editor open), F8 live Match, F9 Replay. The overlay's bottom line lists them.
- `game/dev_tools.gd` (`DevTools`): the overlay toggle, frame-step and slow motion, and how they pace the sim against the 50 Hz physics tick.
  - Slow motion keeps the physics tick at 50 Hz and steps the sim once every N physics ticks. The draw fraction is `(physics ticks since the step + Godot's fraction) / N`, so the screen moves evenly from one state to the next and reaches it just as the next step comes: no stutter. The Lobby, menus, input and kill pops keep running at full rate, and `Engine.physics_ticks_per_second` stays 50, so the countdown's beeps and display are unaffected.
  - Rejected: `Engine.time_scale` (slows menus and the Lobby too) and changing `physics_ticks_per_second` (moves the countdown beeps, which `Cues.of` times by it).
  - Sound cues still come from `_step`, so each plays as the sim steps to its tick, at any pace.
  - Frame-step: F3 freezes the sim if it is running and queues one step; a frozen sim takes one queued step per physics tick, so presses inside one physics tick still each get their own state and cues. F2 unfreezes and drops queued steps. Frozen, the screen shows the current state (fraction 1). The Esc pause menu is separate and still works.
  - A tap shorter than a slowed step's interval can fall between steps and be missed; slow motion reads the devices only on stepping ticks.
- Overlay (`main.gd`): every collider as the sim sees it, at its drawn (interpolated) position: Gates, the Snail, Berries, and each living character in its Team colour with a velocity line (4 ticks long) and `vx, vy` in arcade px/tick. The tick and the pace (FROZEN, 1/N SPEED) show at the top right; the pace shows even with the overlay off.
- Live tuning editor. You chose to record edits in the Replay, with an in-game panel.
  - Sim: `TickInput.tuning` is an optional new tuning table. `Sim.step` makes it the Match's from that tick and drops the Bots' cached navigation, which was built from the old tuning; earlier states keep theirs. BotNav and BotFlight already cache builds by what they depend on, so only navigation that the change affects is rebuilt.
  - Replay (`_VERSION` 8): keeps the whole tuning table of each tick whose input changed it, and `input(tick)` gives it back. F9 reproduces an edited Match exactly. Edits during F9 playback apply on top of the recorded input (spec story 86).
  - `game/tuning_editor.gd` (`TuningEditor`): F5 opens a panel of every constant in the file's order. PgUp/PgDn picks one, wrapping round; -/+ (or the keypad's) changes it by a step, the power of ten between a hundredth and a tenth of its value, with Shift for ten steps; values never go below 0; held keys repeat. Edits build on the Match's current tuning and add up until `take()` hands them to the next tick's input, so a frozen sim takes them with its next frame-step. The panel marks values that differ from the file with *.
  - F6 writes the shown tuning into `data/tuning.cfg`, changing only the values and keeping every comment (`TuningEditor.rewrite`). That only works when running from the project. Every Match starts from the file, so unsaved edits last only for the Match they were made in.
- Normal builds: `DevTools` and `TuningEditor` are built with `OS.is_debug_build()` and ignore every key when it is false, and `_unhandled_key_input` returns first in a non-debug build. A release export wasn't built: no export templates are installed.
- Tests: `test/game/dev_tools_test.gd` (14), `test/game/tuning_editor_test.gd` (8), `test/sim/tuning_change_test.gd` (3), and one more in `determinism_test.gd`. 224 in all.
  - Through `Sim.step`: a tuning change applies from its tick and stays; earlier states keep their tuning and navigation; Bots' navigation is rebuilt. A Replay with two mid-Match changes and human plus Bot Seats plays back to the same fingerprint and tuning, and plays out differently with the changes dropped.
- Mutation checks: each of these made a test fail.
  - DevTools: toggles stuck on; freeze or unfreeze not dropping queued steps; one queued step at most; F3 not freezing; changing speed resetting the phase; the enabled gate removed; off-by-one cadence; frozen or slowed fraction wrong; unknown keys taken; the queue not consumed; the speeds skipping.
  - TuningEditor: gate, open toggle and open check removed; PgUp as PgDn; wrap by `%` (caught by the picked row's index); Shift ignored; the 0 floor removed; `take()` not clearing; pending edits not shown or not added up; the step boundary; comment lines rewritten; unknown keys taken; minus as plus.
  - Sim and Replay: the tuning not swapped; navigation not dropped, or cleared in place (which would empty earlier states' too); changes not recorded, not played back or not loaded.
  - One survivor, removed rather than tested: resetting the slow-motion phase on a frame-step. While frozen the screen holds the current state, so it changed nothing anyone could see.
- In the running game (scratch scripts), all-Bot Matches:
  - Overlay: toggled on, off, on, with frames saved. At 4x zoom the hitboxes sit exactly on the sprites (as ticket 23 sized them), and the velocity text and the TICK/FROZEN label read clearly. Text from overlapping Bots overprints.
  - Frame-step: frozen at tick 210 and still 210 twenty frames later. Each of five F3 presses advanced exactly one tick (210 to 215), and two presses inside one physics tick advanced two (215 to 217).
  - Slow motion: 1/4 took 52 steps, every 4th physics frame without exception, at 12.49 ticks a wall second; 1/10 took 21 steps every 10th frame, at 5.01 a second. Measured over each rendered frame, the drawn sim time moved by exactly what render time called for (min = max = 1.00), and never backwards.
  - Cues landed on their steps: at 1/4, ticks 262, 263 and 264 played 4 physics frames apart. F9 at full speed played the same 12 (tick, cue) pairs as the live slowed and frame-stepped run.
  - Editor: F5 does nothing in the Lobby. In a Match, frozen at tick 180, three Shift+minus took worker_max_speed from 5000 to 2000. The panel showed 2000 marked *, and the Match kept 5000 until the frame-step. Tick 180's fastest plain Worker ran at 5000; from tick 181 it ran at 2000.
  - F9 played back all 321 ticks with identical fingerprints, the change landing on tick 181.
  - F6 rewrote only `max_speed=2000` in `tuning.cfg` and cleared the * mark. The file was then restored.
