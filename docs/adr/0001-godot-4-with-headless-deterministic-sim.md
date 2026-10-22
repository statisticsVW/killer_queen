# Godot 4 (GDScript) with the simulation kept out of the engine

We need a Windows desktop game with up to ten gamepads, pixel-perfect 2D, and a simulation (movement, combat, snail, berries, bots) that we can tune and test precisely. Browser/Electron stacks were rejected because Chromium's Gamepad API caps at four controllers; Unity was rejected as heavier than needed, with scene files that are poor for agent-driven editing and licensing noise for a hobby project. We chose Godot 4 with GDScript, and we keep the simulation as plain GDScript classes on a fixed timestep using no Godot physics, so it is deterministic and runs headless in unit tests. Godot nodes only render the sim's state and feed it input.

## Consequences

- Movement and collision are hand-written against the sim's own tile/hitbox model, not `CharacterBody2D`/`Area2D`. This is deliberate; do not "simplify" by moving gameplay onto Godot physics.
- Determinism keeps a later online mode and input-only replays possible without a rewrite.
- Bots are sim-side and emit the same joystick+button input a pad does.
