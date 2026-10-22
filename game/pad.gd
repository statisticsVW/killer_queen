class_name Pad
extends RefCounted
## One game controller, read as a Seat's joystick and button. Godot's SDL
## mappings give Xbox and Switch Pro pads the same layout, so neither needs
## configuring. Any face button is the button. Up is never read: the cabinet's
## sticks don't give it to anyone.

const DEADZONE := 0.5
const FACE_BUTTONS: Array[JoyButton] = [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y]

## Godot's joypad device id. Ids are handed out in connection order.
var device: int


static func of(p_device: int) -> Pad:
	var pad := Pad.new()
	pad.device = p_device
	return pad


func read() -> SeatInput:
	var x := Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
	var left := x < -DEADZONE or Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT)
	var right := x > DEADZONE or Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)
	var horizontal := SeatInput.NEUTRAL
	if left and not right:
		horizontal = SeatInput.LEFT
	elif right and not left:
		horizontal = SeatInput.RIGHT
	var down := Input.get_joy_axis(device, JOY_AXIS_LEFT_Y) > DEADZONE \
		or Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN)
	var button := false
	for b in FACE_BUTTONS:
		button = button or Input.is_joy_button_pressed(device, b)
	return SeatInput.of(horizontal, down, button)
