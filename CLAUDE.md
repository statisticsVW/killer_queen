# Killer Queen

A game that works, looks and feels like the Killer Queen arcade game.

## Development

Godot 4.7.2 (installed via winget; no `godot` alias, so scripts default to the winget install path and honour a `GODOT` env var).

- Run the tests (headless gdUnit4): `bash scripts/test.sh`
- Run the game: open the project in Godot and press F5, or run the Godot binary with `--path .`

Layout:

- `sim/`: the Match simulation. Plain GDScript, integer maths, no Godot nodes, physics, floats or clock (ADR-0001, ADR-0002). Its public interface is `Sim.create_match` and `Sim.step`.
- `game/`: presentation. Drives the sim at 50 ticks/s, reads devices into `SeatInput`, draws state. No game rules.
- `data/tuning.cfg`: every movement and timing constant; the sim has no built-in defaults.
- `data/maps/`: Map layouts as data (tile rows, wrap edges, object positions); `day.cfg` documents the format.
- `test/sim/`: gdUnit4 suites that test only through `Sim.create_match` and `Sim.step`.
- `test/game/`: gdUnit4 suites for presentation logic that has rules of its own (the Lobby, sound cues, poses and sprites), through its public interface.
- `addons/gdUnit4/`: vendored gdUnit4 6.2.2.

## Agent skills

### Issue tracker

Issues and specs live as local markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Uses the five default triage labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`), recorded as a `Status:` line in each issue file. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
