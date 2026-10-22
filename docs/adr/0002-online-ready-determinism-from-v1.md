# Online-ready determinism is a v1 rule, not a v2 feature

Online play with two to four friends (host-based, no servers or matchmaking) is a v2 goal, but a sim that is not deterministic cannot be made so later without a rewrite. So v1 commits to the constraints online needs while shipping local-only: the sim runs at a fixed 50 ticks/second with rendering decoupled at 60 Hz (the arcade's own split, so community frame data applies unchanged; see `docs/research/killer-queen-arcade-reference.md`); sim state is a single copyable value advanced by `step(state, inputs) -> state`, so it can be snapshotted and restored (enabling rollback netcode and Replay seek); all randomness, including Bot decisions, comes from a seed inside the state; the sim never reads wall-clock time, Godot nodes, or float values whose results could differ between machines; every input is tagged with the tick it applies to; and the Lobby does not assume all ten Seats live on one machine. The choice between lockstep and rollback is deferred to v2.

## Consequences

- Movement constants are integers or fixed-point, not floats, even where floats would be more convenient.
- A Bot that consults anything outside the sim state is a bug, even if it plays well.
- Replays are a by-product: a seed plus the tick-tagged input stream reproduces a Match exactly, which is also our desync test.
