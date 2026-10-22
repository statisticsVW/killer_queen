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
## The button's held state last tick, so a press can be told from a hold.
var button_held: bool
## Ticks since the character last ended a tick standing on something; 0 while
## standing.
var airborne_ticks: int
## Rising from a jump whose button is still held; releasing it cuts the rise.
var jumping: bool


func copy() -> CharacterState:
	var c := CharacterState.new()
	c.seat = seat
	c.team = team
	c.x = x
	c.y = y
	c.vx = vx
	c.vy = vy
	c.facing = facing
	c.button_held = button_held
	c.airborne_ticks = airborne_ticks
	c.jumping = jumping
	return c
