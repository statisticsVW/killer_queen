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
}

var type: Type
var seat: int
var other: int = -1


static func of(p_type: Type, p_seat: int, p_other := -1) -> MatchEvent:
	var e := MatchEvent.new()
	e.type = p_type
	e.seat = p_seat
	e.other = p_other
	return e
