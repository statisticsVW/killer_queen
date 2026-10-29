class_name DevTools
extends RefCounted
## The dev build's tools and their keys: the overlay (hitboxes, velocities and
## the tick), frame-step and slow motion. Frame-step and slow motion pace the
## sim's ticks against the game's 50 Hz physics ticks: the sim steps on some
## physics ticks and not others, and the screen moves evenly between states
## across the ticks it doesn't, so nothing stutters. Sound cues come with the
## states, so they keep to their ticks at any pace. A normal build has none of
## it: every key is ignored and the sim steps every physics tick.

const OVERLAY_KEY := KEY_F1
## Freezes the sim, or lets it run again.
const FREEZE_KEY := KEY_F2
## Freezes the sim if it is running, and advances it one tick.
const STEP_KEY := KEY_F3
## Moves on to the next slow motion speed.
const SLOW_KEY := KEY_F4
## Slow motion's speeds, as divisors of 50 Hz, full speed first: the sim steps
## once every this many physics ticks.
const SLOW_DIVISORS: Array[int] = [1, 2, 4, 10]

var enabled: bool
var overlay := false
var frozen := false
var divisor := 1
## Physics ticks since the sim last stepped, while running.
var _phase := 0
## Frame-steps pressed but not yet taken, while frozen.
var _queued := 0


static func of(p_enabled: bool) -> DevTools:
	var dev := DevTools.new()
	dev.enabled = p_enabled
	return dev


## Acts on a key press. Whether a dev tool took it; the game ignores those.
func key(keycode: Key) -> bool:
	if not enabled:
		return false
	match keycode:
		OVERLAY_KEY:
			overlay = not overlay
		FREEZE_KEY:
			frozen = not frozen
			_queued = 0
		STEP_KEY:
			frozen = true
			_queued += 1
		SLOW_KEY:
			var next: int = SLOW_DIVISORS[(SLOW_DIVISORS.find(divisor) + 1) % SLOW_DIVISORS.size()]
			# Keep the screen as far between states as it was.
			_phase = _phase * next / divisor
			divisor = next
		_:
			return false
	return true


## Called every physics tick the Match runs: whether the sim steps on it. A
## frozen sim takes one queued frame-step a tick.
func tick() -> bool:
	if frozen:
		if _queued == 0:
			return false
		_queued -= 1
		return true
	_phase += 1
	if _phase < divisor:
		return false
	_phase = 0
	return true


## How far from the last state to the current one to draw, given how far the
## game is from its last physics tick to its next (Godot's physics
## interpolation fraction). A frozen sim shows its current state.
func fraction(physics_fraction: float) -> float:
	if frozen:
		return 1.0
	return (_phase + physics_fraction) / divisor
