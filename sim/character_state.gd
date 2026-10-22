class_name CharacterState
extends RefCounted
## One Seat's character within a MatchState.
## Position is the bottom-centre of the collider, in milli-pixels.

const BLUE := 0
const GOLD := 1

## Queens and Warriors are winged: they Flap instead of jumping.
enum Role { WORKER, QUEEN, WARRIOR }

var seat: int
var team: int
var role: Role = Role.WORKER
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
## Ticks left stuck to a ceiling; 0 when not stuck.
var stuck_ticks: int
## Ticks left of a Bump, during which the stick neither steers nor turns.
var bump_ticks: int
## Standing on an enemy's head at the end of this tick.
var on_head: bool
## Ticks left in which a jump springboards higher, after landing on a head.
var springboard_ticks: int
## A Queen holding Down in the air this tick.
var diving: bool
## Flaps so far in the current air brake attempt, and ticks left in which it
## can still complete; 0 when there is none.
var air_brake_flaps: int
var air_brake_ticks: int


func is_winged() -> bool:
	return role != Role.WORKER


func copy() -> CharacterState:
	var c := CharacterState.new()
	c.seat = seat
	c.team = team
	c.role = role
	c.x = x
	c.y = y
	c.vx = vx
	c.vy = vy
	c.facing = facing
	c.button_held = button_held
	c.airborne_ticks = airborne_ticks
	c.jumping = jumping
	c.stuck_ticks = stuck_ticks
	c.bump_ticks = bump_ticks
	c.on_head = on_head
	c.springboard_ticks = springboard_ticks
	c.diving = diving
	c.air_brake_flaps = air_brake_flaps
	c.air_brake_ticks = air_brake_ticks
	return c
