class_name Pose
extends RefCounted
## How a character is drawn this tick: its look, what it is doing and which
## frame of that animation, read from the Match state alone. Frame counts and
## timings are placeholders; the arcade's aren't documented.

enum Look { WORKER, SPEED_WORKER, WARRIOR, SPEED_WARRIOR, QUEEN }
enum Action {
	STAND,
	## On the ground and moving (a winged character walks).
	RUN,
	## A Worker in the air, rising.
	JUMP,
	## A Worker in the air, not rising.
	FALL,
	## A Worker at a Gate holding its Berry up, before the doors close.
	HOLD_UP,
	## Riding the Snail.
	RIDE,
	## Riding the Snail while it eats.
	EAT,
	## Being eaten by the Snail.
	EATEN,
	## Winged, in the air, rising: wings beating.
	FLAP,
	## Winged, in the air, not rising: wings spread.
	GLIDE,
	## A Queen diving.
	DIVE,
}

const RUN_FRAMES := 4
## Milli-pixels run per running frame, so the legs keep pace with the ground.
const RUN_STRIDE := 8000
## Ticks each wing beat and each chomp of an eat shows; both have two frames.
const FLAP_FRAME_TICKS := 3
const EAT_FRAME_TICKS := 8

var look: Look
var action: Action
## Carrying a Berry.
var carrying: bool
## The frame of the action's animation, from 0.
var frame: int


static func of(state: MatchState, seat: int) -> Pose:
	var c := state.characters[seat]
	var pose := Pose.new()
	pose.carrying = c.berry != -1
	match c.role:
		CharacterState.Role.QUEEN:
			pose.look = Look.QUEEN
		CharacterState.Role.WARRIOR:
			pose.look = Look.SPEED_WARRIOR if c.speed else Look.WARRIOR
		_:
			pose.look = Look.SPEED_WORKER if c.speed else Look.WORKER
	var s := state.snail
	if c.gate != -1:
		pose.action = Action.HOLD_UP
	elif s != null and s.rider == seat:
		pose.action = Action.EAT if s.victim != -1 else Action.RIDE
	elif s != null and s.victim == seat:
		pose.action = Action.EATEN
	elif c.airborne_ticks == 0:
		pose.action = Action.RUN if c.vx != 0 else Action.STAND
	elif c.is_winged():
		if c.diving:
			pose.action = Action.DIVE
		else:
			pose.action = Action.FLAP if c.vy < 0 else Action.GLIDE
	else:
		pose.action = Action.JUMP if c.vy < 0 else Action.FALL
	match pose.action:
		Action.RUN:
			pose.frame = posmod(c.x * c.facing, RUN_STRIDE * RUN_FRAMES) / RUN_STRIDE
		Action.FLAP:
			pose.frame = state.tick / FLAP_FRAME_TICKS % 2
		Action.EAT:
			pose.frame = state.tick / EAT_FRAME_TICKS % 2
	return pose
