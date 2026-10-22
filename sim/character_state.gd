class_name CharacterState
extends RefCounted
## One Seat's character within a MatchState.
## Position is the bottom-centre of the collider, in milli-pixels.

const BLUE := 0
const GOLD := 1

var seat: int
var team: int
var x: int
var y: int
var vx: int
var vy: int
## SeatInput.LEFT or SeatInput.RIGHT.
var facing: int = SeatInput.RIGHT


func copy() -> CharacterState:
	var c := CharacterState.new()
	c.seat = seat
	c.team = team
	c.x = x
	c.y = y
	c.vx = vx
	c.vy = vy
	c.facing = facing
	return c
