class_name BerryState
extends RefCounted
## One Berry within a MatchState. Position is the bottom-centre of its
## berry_size square collider, in milli-pixels.

## In a pile it sits still until a Worker takes it; loose it falls, slides and
## can be kicked; carried it rides on the head of the Worker whose
## CharacterState.berry it is; in a Hive hole it stays for good; spent at a
## Gate it is gone.
enum Where { PILE, LOOSE, CARRIED, HIVE, SPENT }

var where: Where = Where.PILE
var x: int
var y: int
var vx: int
var vy: int
## The Hive (Team) and hole index it fills, while in a HIVE; otherwise -1.
var team: int = -1
var hole: int = -1


func copy() -> BerryState:
	var b := BerryState.new()
	b.where = where
	b.x = x
	b.y = y
	b.vx = vx
	b.vy = vy
	b.team = team
	b.hole = hole
	return b
