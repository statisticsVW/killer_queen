class_name GateState
extends RefCounted
## One of the Map's Gates within a MatchState. Position is the bottom-centre of
## its gate_width by gate_height collider, in milli-pixels.

## What a Worker who transforms here becomes: a Warrior Gate makes a Warrior
## (a Speed Warrior from a Speed Worker), a Speed Gate a Speed Worker.
enum Type { WARRIOR, SPEED }

var type: Type
var x: int
var y: int
## The Team whose Queen last touched it, the only Team whose Workers can use
## it; -1 while neutral, usable by both.
var team: int = -1


func copy() -> GateState:
	var g := GateState.new()
	g.type = type
	g.x = x
	g.y = y
	g.team = team
	return g
