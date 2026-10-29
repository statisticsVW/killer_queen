class_name TuningEditor
extends RefCounted
## Dev builds' live tuning editor: a panel listing every tuning constant, in
## the tuning file's order. Page keys pick a constant and plus and minus step
## its value, ten steps with Shift. Edits go to the Match in the next tick's
## input (take()), so a Replay records them and the change applies from that
## tick. A normal build has none of it: every key is ignored.

const OPEN_KEY := KEY_F5
## Writes the Match's tuning into the tuning file (main.gd does the writing).
const SAVE_KEY := KEY_F6
const PREVIOUS_KEY := KEY_PAGEUP
const NEXT_KEY := KEY_PAGEDOWN
const MORE_KEYS: Array[Key] = [KEY_EQUAL, KEY_KP_ADD]
const LESS_KEYS: Array[Key] = [KEY_MINUS, KEY_KP_SUBTRACT]

var enabled: bool
var open := false
## The picked constant, by its place in the tuning file.
var selected := 0
var _names: Array[String] = Tuning.new().names()
## The Match's tuning with the edits made since the last tick, or null.
var _pending: Tuning


static func of(p_enabled: bool) -> TuningEditor:
	var editor := TuningEditor.new()
	editor.enabled = p_enabled
	return editor


## Acts on a key press, Shift held or not, while the Match's tuning is
## `current`. Whether the editor took it; the game ignores those.
func key(keycode: Key, shift: bool, current: Tuning) -> bool:
	if not enabled:
		return false
	if keycode == OPEN_KEY:
		open = not open
		return true
	if not open:
		return false
	if keycode == NEXT_KEY or keycode == PREVIOUS_KEY:
		selected = posmod(selected + (1 if keycode == NEXT_KEY else -1), _names.size())
	elif keycode in MORE_KEYS or keycode in LESS_KEYS:
		var tuning := shown(current)
		var value: int = tuning.get(selected_name())
		var change := step_for(value) * (10 if shift else 1) * (1 if keycode in MORE_KEYS else -1)
		_pending = tuning.with_values({selected_name(): maxi(value + change, 0)})
	else:
		return false
	return true


func selected_name() -> String:
	return _names[selected]


## The tuning the panel shows: the Match's, `current`, with edits not yet
## applied.
func shown(current: Tuning) -> Tuning:
	return _pending if _pending != null else current


## The edited tuning for the next tick's input, once; null if nothing was
## edited since the last.
func take() -> Tuning:
	var change := _pending
	_pending = null
	return change


## How much one press changes a constant of `value`: the power of ten
## between a hundredth and a tenth of it, and at least 1.
static func step_for(value: int) -> int:
	var step := 1
	while step * 100 <= value:
		step *= 10
	return step


## The text of a tuning file with each constant's value set to `tuning`'s,
## its comments and layout kept.
static func rewrite(text: String, tuning: Tuning) -> String:
	var lines := text.split("\n")
	var section := ""
	for i in lines.size():
		var line := lines[i]
		if line.begins_with("["):
			section = line.trim_prefix("[").trim_suffix("]")
		elif not line.begins_with(";") and line.contains("="):
			var key := line.get_slice("=", 0)
			lines[i] = "%s=%d" % [key, tuning.get("%s_%s" % [section, key])]
	return "\n".join(lines)
