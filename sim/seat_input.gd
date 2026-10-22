class_name SeatInput
extends RefCounted
## One Seat's joystick and button for one tick: the whole input a player has.
## Up is never represented; `down` is only ever read for a Queen.

const LEFT := -1
const NEUTRAL := 0
const RIGHT := 1

var horizontal: int = NEUTRAL
var down: bool = false
## Held state, not a press; the sim derives presses and releases.
var button: bool = false


static func of(p_horizontal: int, p_down := false, p_button := false) -> SeatInput:
	var input := SeatInput.new()
	input.horizontal = p_horizontal
	input.down = p_down
	input.button = p_button
	return input
