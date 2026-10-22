class_name MatchState
extends RefCounted
## Everything about a Match at one tick. Sim.step() never modifies a state it is
## given; it returns a new one. The Map and Tuning are immutable and shared
## between copies.

## How the Match was won, if it has been.
enum Win { NONE, MILITARY, ECONOMIC, SNAIL }

var tick: int
var characters: Array[CharacterState]
var map: MapData
var tuning: Tuning
## What happened during the tick that produced this state, in order.
var events: Array[MatchEvent]
## Eggs still waiting at each Team's Hive, indexed by Team. They sit at the
## first that many of the Map's Egg positions.
var eggs: Array[int]
var win: Win = Win.NONE
## The Team that won, or -1.
var winner: int = -1


func copy() -> MatchState:
	var s := MatchState.new()
	s.tick = tick
	for c in characters:
		s.characters.append(c.copy())
	s.events = events.duplicate()
	s.eggs = eggs.duplicate()
	s.win = win
	s.winner = winner
	s.map = map
	s.tuning = tuning
	return s
