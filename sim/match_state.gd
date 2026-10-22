class_name MatchState
extends RefCounted
## Everything about a Match at one tick. Sim.step() never modifies a state it is
## given; it returns a new one. The Map and Tuning are immutable and shared
## between copies.

var tick: int
var characters: Array[CharacterState]
var map: MapData
var tuning: Tuning


func copy() -> MatchState:
	var s := MatchState.new()
	s.tick = tick
	for c in characters:
		s.characters.append(c.copy())
	s.map = map
	s.tuning = tuning
	return s
