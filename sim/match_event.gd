class_name MatchEvent
extends RefCounted
## Something that happened during one tick, listed in that tick's
## MatchState.events. Presentation reacts to these (pops, sounds) instead of
## keeping its own copy of the rules. Treat as immutable.

enum Type {
	## `seat` killed `other`.
	KILL,
	## `seat` died, at its position in the state; `other` is the killer, or -1.
	DEATH,
	## `seat` came back to life at its spawn point.
	RESPAWN,
	## `seat`, a Queen, hatched from an Egg.
	HATCH,
	## `team` won the Match; MatchState.win says how.
	WIN,
	## `seat` picked up Berry `other` (an index in MatchState.berries).
	BERRY_PICKUP,
	## `seat` put Berry `other` in a hole of its Team's Hive.
	BERRY_DEPOSIT,
	## `seat` dropped Berry `other`, which is now loose.
	BERRY_DROP,
	## `seat` kicked the loose Berry `other`.
	BERRY_KICK,
	## `seat` mounted the Snail.
	SNAIL_MOUNT,
	## `seat` got off the Snail.
	SNAIL_DISMOUNT,
	## The Snail ridden by `seat` started eating `other`.
	EAT_START,
	## The Snail ridden by `seat` finished eating `other`, who died.
	EAT_COMPLETE,
	## The eat of `other` by the Snail `seat` was riding ended early, `other`
	## alive or killed by something else.
	EAT_INTERRUPT,
	## `seat`, a Queen, claimed Gate `other` (an index in MatchState.gates)
	## for her Team.
	GATE_CLAIM,
	## `seat` started transforming in Gate `other`.
	TRANSFORM_START,
	## `seat`'s transform in Gate `other` ended early: it was killed or
	## Bumped out.
	TRANSFORM_INTERRUPT,
	## `seat` emerged from Gate `other`, upgraded.
	TRANSFORM_COMPLETE,
}

var type: Type
var seat: int = -1
var other: int = -1
var team: int = -1


static func of(p_type: Type, p_seat: int, p_other := -1) -> MatchEvent:
	var e := MatchEvent.new()
	e.type = p_type
	e.seat = p_seat
	e.other = p_other
	return e


static func win(p_team: int) -> MatchEvent:
	var e := MatchEvent.new()
	e.type = Type.WIN
	e.team = p_team
	return e
