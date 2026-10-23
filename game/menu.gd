class_name Menu
extends RefCounted
## A row of options that any device can choose from with the cabinet's
## controls: the stick moves along the row and the button chooses. The choice
## is made when the button is let go, and only by a press that began while the
## menu was open, so a button held from play does nothing, and the release
## doesn't reach a Match the choice resumes.

const FONT_SIZE := 16
const SELECTED := Color.WHITE
const UNSELECTED := Color(1, 1, 1, 0.45)

var options: Array[String]
var selected := 0
## Each device's input from the last update, or empty before the first.
var _last: Array[SeatInput] = []
## Per device: whether its button went down while the menu was open.
var _pressing: Array[bool] = []


static func of(p_options: Array[String]) -> Menu:
	var menu := Menu.new()
	menu.options = p_options
	return menu


## Reads one tick of every device's input, in device order. Returns the index
## of the option chosen this tick, or -1.
func update(inputs: Array[SeatInput]) -> int:
	if _last.is_empty():
		_last = inputs
		_pressing.resize(inputs.size())
		return -1
	var chosen := -1
	for i in inputs.size():
		var now := inputs[i]
		var before := _last[i]
		if now.horizontal != SeatInput.NEUTRAL and now.horizontal != before.horizontal:
			selected = posmod(selected + now.horizontal, options.size())
		if now.button and not before.button:
			_pressing[i] = true
		elif not now.button and _pressing[i]:
			_pressing[i] = false
			chosen = selected
	_last = inputs
	return chosen


## Draws the options spread evenly across `width`, centred on `y`, the selected
## one bright and bracketed.
func draw(canvas: CanvasItem, y: float, width: float) -> void:
	var font := ThemeDB.fallback_font
	var slot := width / options.size()
	for i in options.size():
		var text := options[i]
		if i == selected:
			text = "> %s <" % text
		var at := Vector2(slot * i, y + FONT_SIZE / 2.0)
		canvas.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, slot, FONT_SIZE,
			SELECTED if i == selected else UNSELECTED)
