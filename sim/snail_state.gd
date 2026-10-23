class_name SnailState
extends RefCounted
## The Map's Snail within a MatchState. It runs along a horizontal track at
## the Map's Snail start height; `x` is the bottom-centre of its collider, in
## milli-pixels.

var x: int
var y: int
## The Seat riding it, or -1.
var rider: int = -1
## The Seat being eaten, or -1; and ticks left until the eat completes.
var victim: int = -1
var eat_ticks: int
## The Seat that last dismounted, which can't mount again until it has stood
## on the ground clear of the Snail; or -1.
var dismounted: int = -1


func copy() -> SnailState:
	var s := SnailState.new()
	s.x = x
	s.y = y
	s.rider = rider
	s.victim = victim
	s.eat_ticks = eat_ticks
	s.dismounted = dismounted
	return s
