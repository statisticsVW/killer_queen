class_name Rng
extends RefCounted
## The Match's seeded random generator (ADR-0002): a 32-bit xorshift whose
## whole state is MatchState.rng, so it is copied, replayed and fingerprinted
## with the rest of the Match. Every random choice the sim makes (Bots, from
## ticket 17) must come from here.

const _MASK := 0xFFFFFFFF


## The generator state a Match with `seed` starts from. Never 0, which
## xorshift can't leave.
static func start(seed: int) -> int:
	var x := (seed * 2654435761 + 0x9E3779B9) & _MASK
	return x if x != 0 else 1


## Advances `state`'s generator and returns a number in [0, n).
static func below(state: MatchState, n: int) -> int:
	assert(n > 0, "Rng.below needs a positive bound")
	var x := state.rng
	x ^= (x << 13) & _MASK
	x ^= x >> 17
	x ^= (x << 5) & _MASK
	state.rng = x
	return x % n
