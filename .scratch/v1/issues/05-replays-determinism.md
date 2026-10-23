# 05: Replays and determinism tests

**What to build:** In dev builds, every Match's Replay (Map, Seats, Bot Difficulties, seed, tuning table, and tick-tagged human input) is saved automatically when the Match ends and can be played back to reproduce the Match exactly. Determinism tests guard ADR-0002 from here on.

**Blocked by:** 01

**Status:** ready-for-agent

- [x] Test: run a Match from scripted input, record its Replay, play it back; the final state hashes match
- [x] Test: copy the state mid-Match, step both copies with identical input for N ticks; the states match
- [x] The sim reads no wall-clock time, and all randomness comes from the seeded generator in Match state
- [x] A dev build saves the last Match's Replay and can play it back on screen
- [x] Replays stay out of git

## Comments

Done.

- Replay (`sim/Replay`): holds the Map file's text (`MapData.source`, kept by `from_config`), Seat teams, Queen Seats, seed, the whole tuning table (`Tuning.values()` / `Tuning.from_values()`) and every tick's input. Each Seat's input is one byte (horizontal, Down, button), plus a tick → Seats map for the dev Warrior command. `Replay.record(config)`, then `add(input)` each tick; `config()` and `input(tick)` play it back; `to_text()` / `from_text()` save it, using `var_to_str`, which keeps ints exact. A Replay carries its own Map and tuning, so it replays the same Match even after `day.cfg` or `tuning.cfg` change. To re-run its inputs under new constants, swap `config().tuning`.
- Not yet in the Replay: Bot Difficulties and the human-only input rule. Neither exists yet; ticket 17 or 21 adds them to `MatchConfig` and the Replay (bump `_VERSION`).
- Seeded randomness: `MatchConfig.seed` starts `MatchState.rng`, a 32-bit xorshift (`sim/Rng`: `Rng.below(state, n)`). Nothing draws from it yet; Bots (ticket 17) will. The game seeds each live Match with `randi()`, and the Replay records it.
- `MatchState.fingerprint()`: a SHA-256 of every script variable in the state, characters and events included, but not the shared Map and Tuning. It walks the property list, so new fields are covered without edits.
- Tests (`test/sim/determinism_test.gd`, 6): the scripted input is a fixed hash of tick and Seat, on Day with all ten Seats for 1500 ticks; it produces kills, Warriors and Dives.
  - A recorded Replay, saved to text, loaded and played back, gives the same final fingerprint.
  - A Replay keeps its own tuning, seed and Seats.
  - Two copies made mid-Match step identically (and match the original).
  - Every 5th tick, a state's `copy()` has the same fingerprint as the original. This is the guard for a field missed in `copy()`; it caught dropped `invulnerable_ticks` and `air_brake_ticks`.
  - The seed is in the state and survives stepping.
  - No file in `sim/` calls `Time`, `OS`, `RandomNumberGenerator` or the global random functions (comments excluded).
- Mutation checks: dropping each of `rng`, `eggs`, `invulnerable_ticks` and `air_brake_ticks` from `copy()`; swapping Down and button in the byte decoding; dropping the dev Warrior command or the seed from the Replay; ignoring the seed; and seeding from `Time`. Each failed a test. Dropping `springboard_ticks` from `copy()` is caught by the springboard test, not the copy check, because it only lives for 5 ticks.
- Dev build (`game/main.gd`): the live Match is recorded tick by tick. Its Replay is saved to `replays/last.replay` (under `res://` when running from the project, else `user://`) when the Match is won, when the window closes, and on F8 and F9. F9 plays the last Replay back from tick 0 with a "REPLAY tick / length" label, then holds on its last tick. F8 starts a new live Match. Ticket 04 can fold these keys into its dev tools.
- Replays stay out of git: `/replays/` was already in `.gitignore`.
- In the running game: 200 ticks of injected keyboard play (Flaps, Dive, a dev Warrior), then F9. The playback's fingerprint matched the live one on all 199 ticks compared, and `replays/last.replay` (23 KB) was written and ignored by git.
