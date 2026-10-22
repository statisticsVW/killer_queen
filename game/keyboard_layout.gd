class_name KeyboardLayout
extends RefCounted
## One player's keys, read as a Seat's joystick and button. There is no Up key:
## the cabinet's sticks don't give Workers one.

var left: Key
var right: Key
var down: Key
var button: Key


static func wasd() -> KeyboardLayout:
	return _of(KEY_A, KEY_D, KEY_S, KEY_SPACE)


static func arrows() -> KeyboardLayout:
	return _of(KEY_LEFT, KEY_RIGHT, KEY_DOWN, KEY_ENTER)


static func _of(p_left: Key, p_right: Key, p_down: Key, p_button: Key) -> KeyboardLayout:
	var layout := KeyboardLayout.new()
	layout.left = p_left
	layout.right = p_right
	layout.down = p_down
	layout.button = p_button
	return layout


func read() -> SeatInput:
	var horizontal := SeatInput.NEUTRAL
	if Input.is_physical_key_pressed(left) and not Input.is_physical_key_pressed(right):
		horizontal = SeatInput.LEFT
	elif Input.is_physical_key_pressed(right) and not Input.is_physical_key_pressed(left):
		horizontal = SeatInput.RIGHT
	return SeatInput.of(horizontal, Input.is_physical_key_pressed(down), Input.is_physical_key_pressed(button))
