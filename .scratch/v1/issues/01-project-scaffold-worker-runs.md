# 01: Project scaffold: one Worker runs on a test floor

**What to build:** A Godot 4 project where one Worker runs left and right on a flat test floor using the keyboard, drawn at 960×540 logical resolution with integer scaling, driven by the headless sim at 50 ticks/second and rendered at 60 Hz with interpolation. This sets the shape every later ticket builds on: the sim's two-call interface (create a Match, advance one tick), the tuning table, the per-Seat input shape, and the headless test run. See the spec's Implementation Decisions and ADR-0001/0002.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [x] Latest stable Godot 4.x is installed on the dev machine and the project opens in it
- [x] gdUnit4 tests run headless from a single command, and that command is documented in CLAUDE.md
- [x] The sim has no dependency on Godot nodes, scenes or physics; creating a Match and advancing it one tick are its only public operations, and Match state is a single copyable value
- [x] Positions are integer fixed-point in 1920×1080 monitor-pixel space at 1/1000-pixel resolution
- [x] Seat input is `{horizontal: left|right|neutral, down: bool, button: bool}`, tagged with its tick
- [x] Every movement constant used so far lives in the tuning table; the Worker's max horizontal speed is 5 px/tick
- [x] Test: a Worker holding right for 50 ticks moves exactly 250 px; with neutral input it stops as the tuning table says
- [x] Keyboard (WASD/arrows) moves the Worker on screen; the window scales by whole numbers with crisp pixels
- [x] A `.gitattributes` enforces LF line endings

## Comments

Done. Godot 4.7.2 via winget, gdUnit4 6.2.2 vendored; `bash scripts/test.sh` runs 9 sim tests headless (all pass). Verified in the running game with injected key presses: 5 px/tick, facing flips, instant stop with placeholder accel/decel, 1920x1080 window over a 960x540 viewport. Worker collider and run accel/decel are placeholders until ticket 09.
