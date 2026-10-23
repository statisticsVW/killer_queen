extends Node2D
## Drives the sim at a fixed 50 ticks/second (the physics tick rate in project
## settings) and draws it at the display rate, interpolating between the last
## two states. Rendering only: no game rules live here.

const MAP_PATH := "res://data/maps/day.cfg"
## Where dev builds keep the last Match's Replay, under res:// or user://.
const REPLAY_FILE := "replays/last.replay"

## Sim milli-pixels per logical (960x540) pixel.
const MPX_PER_PIXEL := 2000
const SCREEN_WIDTH := MapData.WIDTH / MPX_PER_PIXEL

const BACKGROUND := Color("8ec8e8")
const DIRT := Color("7a5230")
const GRASS := Color("3f9a2c")
const WRAP_MARK := Color(1, 1, 1, 0.5)
const WORKER_WRAP_MARK := Color(1, 0.6, 0.9, 0.7)
const TEAM_COLOURS := [Color("2f6fdf"), Color("e8b020")]
const TEAM_NAMES := ["BLUE", "GOLD"]
const HIVE_COLOURS := [Color("1d4fa8"), Color("b8601c")]
const HOLE := Color("102030")
const EGG := Color("f4e04a")
const GATE := Color("c8ccd2")
const DOORS := Color("6b4a2a")
const WINGS := Color("f2f2f2")
const BOLT := Color("ffe14d")
const BERRY := Color("a63fc4")
const SNAIL := Color("e86aa8")
const CROWN := Color("ffd23f")
const POP := Color.WHITE

## How long a kill pop shows, in physics ticks.
const POP_TICKS := 15
## Invulnerable characters blink: this many ticks shown, then as many hidden.
const BLINK_TICKS := 3

## Seats 0-4 are Blue, 5-9 Gold.
const SEAT_TEAMS: Array[int] = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1]
## Each Team's first Seat is its Queen, so the two keyboards play the Queens.
const QUEEN_SEATS: Array[int] = [0, 5]
## The Seat each device drives, in device order (see _devices). Teams
## alternate, so the first two players are opponents. Seats no device drives
## stand idle.
const DEVICE_SEATS: Array[int] = [0, 5, 1, 6, 2, 7, 3, 8, 4, 9]

## How long the victory screen shows before its menu takes input, in physics
## ticks, so a button mashed as the Match ends doesn't choose for anyone.
const VICTORY_MENU_DELAY := 50
## How long "GO!" shows once the countdown ends, in physics ticks.
const GO_TICKS := 50
const ROPE := Color("8d6710")
const ROPE_LIGHT := Color("c79f2d")

## Menu options.
const RESUME := "RESUME"
const REMATCH := "REMATCH"
const LOBBY := "LOBBY"
const FULLSCREEN := "FULLSCREEN"
const WINDOWED := "WINDOWED"
const START := "START MATCH"

## The Lobby is a placeholder until ticket 18.
enum Screen { LOBBY, MATCH }

## Every device that can drive a Seat, in a fixed order: the two keyboard
## layouts, then pads by Godot device id. Each has read() -> SeatInput,
## connected() -> bool and a label.
var _devices: Array = [KeyboardLayout.wasd(), KeyboardLayout.arrows()]
var _screen := Screen.MATCH
var _previous: MatchState
var _current: MatchState
## Whether the Match is paused: the sim doesn't step.
var _paused := false
## The Lobby's, pause or victory menu, or null.
var _menu: Menu
## Physics ticks since the Match was won.
var _over_ticks := 0
## Kill pops still showing: each {at: Vector2 (logical pixels), team: int,
## age: int (ticks)}.
var _pops: Array[Dictionary] = []
## The live Match's Replay so far, or null while a Replay plays back.
var _recording: Replay
## Whether the live Match's Replay has been saved since its last tick.
var _saved := false
## The Replay playing back, or null during a live Match.
var _playback: Replay


func _ready() -> void:
	for device in DEVICE_SEATS.size() - _devices.size():
		_devices.append(Pad.of(device))
	_start_live_match()


## Starts a new live Match with the same Seats (a rematch).
func _start_live_match() -> void:
	_save_replay()
	var config := MatchConfig.new()
	config.map = MapData.load_file(MAP_PATH)
	config.seat_teams = SEAT_TEAMS
	config.queen_seats = QUEEN_SEATS
	config.tuning = Tuning.load_default()
	config.seed = randi()
	_recording = Replay.record(config)
	_saved = false
	_playback = null
	_start(config)


func _start(config: MatchConfig) -> void:
	_screen = Screen.MATCH
	_current = Sim.create_match(config)
	_previous = _current
	_pops = []
	_paused = false
	_menu = null
	_over_ticks = 0


## Leaves the Match for the Lobby (a placeholder until ticket 18).
func _to_lobby() -> void:
	_save_replay()
	_recording = null
	_playback = null
	_screen = Screen.LOBBY
	_paused = false
	_menu = Menu.of([START])


## Each tick: read every device, then either step the Match or, while a menu
## is up, let the devices choose from it. The Match stands still while paused
## and once it is won.
func _physics_process(_delta: float) -> void:
	var inputs := _read_devices()
	_age_pops()
	if _screen == Screen.MATCH:
		_previous = _current
		if _current.win != MatchState.Win.NONE:
			_over_ticks += 1
			if _over_ticks == VICTORY_MENU_DELAY:
				_menu = Menu.of([REMATCH, LOBBY])
		elif not _paused:
			_step(inputs)
	if _menu != null:
		var chosen := _menu.update(inputs)
		if chosen != -1:
			_choose(_menu.options[chosen])


func _step(inputs: Array[SeatInput]) -> void:
	var input: TickInput
	if _playback != null:
		if _current.tick >= _playback.length():
			return
		input = _playback.input(_current.tick)
	else:
		input = _tick_input(inputs)
		_recording.add(input)
		_saved = false
	_current = Sim.step(_current, input)
	_add_pops()
	if _playback == null and _current.win != MatchState.Win.NONE:
		_save_replay()


func _choose(option: String) -> void:
	match option:
		RESUME:
			_resume()
		REMATCH, START:
			_start_live_match()
		LOBBY:
			_to_lobby()
		FULLSCREEN, WINDOWED:
			_toggle_fullscreen()
			_menu.options = _pause_options()


func _pause() -> void:
	_paused = true
	_menu = Menu.of(_pause_options())


func _resume() -> void:
	_paused = false
	_menu = null


func _pause_options() -> Array[String]:
	return [RESUME, REMATCH, LOBBY, WINDOWED if _fullscreen() else FULLSCREEN]


func _fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


## Switches between borderless fullscreen (the default, in project settings)
## and a window. The window is the largest whole multiple of 960x540 that fits
## on its screen, so integer scaling still fills it.
func _toggle_fullscreen() -> void:
	if not _fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var logical := Vector2i(SCREEN_WIDTH, MapData.HEIGHT / MPX_PER_PIXEL)
	# Leave room for the title bar.
	var scale := maxi(mini(usable.size.x / logical.x, (usable.size.y - 40) / logical.y), 1)
	DisplayServer.window_set_size(logical * scale)
	DisplayServer.window_set_position(usable.position + (usable.size - logical * scale) / 2)


## Every device's input this tick, in device order.
func _read_devices() -> Array[SeatInput]:
	var inputs: Array[SeatInput] = []
	for device in _devices:
		inputs.append(device.read())
	return inputs


## The Match's input for this tick from the devices' inputs.
func _tick_input(inputs: Array[SeatInput]) -> TickInput:
	var seats: Array[SeatInput] = []
	for seat in SEAT_TEAMS.size():
		seats.append(SeatInput.of(SeatInput.NEUTRAL))
	for i in _devices.size():
		seats[DEVICE_SEATS[i]] = inputs[i]
	return TickInput.of(_current.tick, seats)


## Dev builds save the live Match's Replay when it is won, when the game is
## closed and before playing a Replay back. It goes in the project's replays/
## folder (kept out of git) when running from the project, else user://.
func _save_replay() -> void:
	if not OS.is_debug_build() or _recording == null or _saved:
		return
	var path := _replay_path()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save the Replay to %s" % path)
		return
	file.store_string(_recording.to_text())
	_saved = true


## Dev builds: plays the last saved Replay back from its first tick.
func _play_last_replay() -> void:
	_save_replay()
	var path := _replay_path()
	if not FileAccess.file_exists(path):
		return
	_playback = Replay.from_text(FileAccess.get_file_as_string(path))
	_recording = null
	_start(_playback.config())


func _replay_path() -> String:
	return ("res://" if OS.has_feature("editor") else "user://") + REPLAY_FILE


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_replay()


## Ages the kill pops. They keep playing out while the Match stands still.
func _age_pops() -> void:
	for pop in _pops:
		pop.age += 1
	_pops = _pops.filter(func(pop: Dictionary) -> bool: return pop.age < POP_TICKS)


## Starts a kill pop where each character died this tick.
func _add_pops() -> void:
	var t := _current.tuning
	for e in _current.events:
		if e.type != MatchEvent.Type.DEATH:
			continue
		var c := _current.characters[e.seat]
		var height := t.winged_height if c.is_winged() else t.worker_height
		_pops.append({"at": _to_pixels(Vector2i(c.x, c.y - height / 2)), "team": c.team, "age": 0})


## Esc on a keyboard or Start/Menu on a pad pauses a Match in play, or
## resumes it.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	var pad := event as InputEventJoypadButton
	var pause := (key != null and key.pressed and not key.echo and key.physical_keycode == KEY_ESCAPE) \
		or (pad != null and pad.pressed and pad.button_index == JOY_BUTTON_START)
	if not pause or _screen != Screen.MATCH or _current.win != MatchState.Win.NONE:
		return
	if _paused:
		_resume()
	else:
		_pause()


## Dev builds only. F9 plays back the last Match's Replay; F8 starts a new live
## Match.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not OS.is_debug_build() or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_F9:
		_play_last_replay()
	elif key.physical_keycode == KEY_F8:
		_start_live_match()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, _to_pixels(Vector2i(MapData.WIDTH, MapData.HEIGHT))), BACKGROUND)
	if _screen == Screen.LOBBY:
		_draw_lobby()
		return
	var map := _current.map
	_draw_hives(map)
	_draw_tiles(map)
	_draw_barriers(map)
	_draw_objects(map)
	_draw_snail()
	_draw_characters()
	_draw_berries()
	_draw_pops()
	_draw_countdown()
	_draw_victory()
	_draw_pause()
	_draw_playback()


func _draw_tiles(map: MapData) -> void:
	var tile := float(map.tile_size) / MPX_PER_PIXEL
	for row in map.rows:
		for column in map.columns:
			if not map.is_solid(column, row):
				continue
			var top_left := Vector2(column, row) * tile
			draw_rect(Rect2(top_left, Vector2(tile, tile)), DIRT)
			if not map.is_solid(column, row - 1):
				draw_rect(Rect2(top_left, Vector2(tile, 3)), GRASS)
		# Mark the side edges of rows that wrap.
		if map.edges[row] != MapData.Edge.BLOCKED:
			var mark := WRAP_MARK if map.edges[row] == MapData.Edge.WRAP else WORKER_WRAP_MARK
			draw_rect(Rect2(Vector2(0, row * tile + 2), Vector2(1, tile - 4)), mark)
			draw_rect(Rect2(Vector2(SCREEN_WIDTH - 1, row * tile + 2), Vector2(1, tile - 4)), mark)


## Placeholder starting barriers, while they stand: two ropes along the top of
## each.
func _draw_barriers(map: MapData) -> void:
	if _current.countdown_ticks() == 0:
		return
	for barrier in map.barriers:
		var top_left := _to_pixels(barrier.position)
		var width := _to_pixels(barrier.size).x
		for y in [2, 7]:
			draw_rect(Rect2(top_left + Vector2(0, y), Vector2(width, 3)), ROPE)
			draw_rect(Rect2(top_left + Vector2(0, y + 1), Vector2(width, 1)), ROPE_LIGHT)


## Placeholder Hives: a team-coloured panel behind each Team's holes and Eggs.
func _draw_hives(map: MapData) -> void:
	for team in map.hive_holes.size():
		var points: Array[Vector2i] = []
		points.append_array(map.hive_holes[team])
		points.append_array(map.eggs[team])
		if points.is_empty():
			continue
		var bounds := Rect2(_to_pixels(points[0]), Vector2.ZERO)
		for p in points:
			bounds = bounds.expand(_to_pixels(p))
		draw_rect(bounds.grow_individual(22, 32, 22, 0), HIVE_COLOURS[team])
		for hole in map.hive_holes[team]:
			draw_rect(Rect2(_to_pixels(hole) - Vector2(5, 4), Vector2(10, 8)), HOLE)
		for i in _current.eggs[team]:
			_draw_egg(map.eggs[team][i])
	# A dead Queen who will hatch shows as the Egg she is hatching from.
	for c in _current.characters:
		if c.role == CharacterState.Role.QUEEN and not c.alive and c.respawn_ticks > 0:
			_draw_egg(c.spawn)


func _draw_egg(at: Vector2i) -> void:
	draw_rect(Rect2(_to_pixels(at) - Vector2(10, 29), Vector2(20, 29)), EGG)


## Placeholder Gates: a doorway framed in its owner's Team colour (grey while
## neutral), its doors shut while a Worker is locked in, under wings (Warrior
## Gate) or with a bolt (Speed Gate). Placeholder Snail Goals at their Map
## positions.
func _draw_objects(map: MapData) -> void:
	var occupied := {}
	for c in _current.characters:
		if c.is_locked_in(_current.tuning):
			occupied[c.gate] = true
	for i in _current.gates.size():
		var gate := _current.gates[i]
		var base := _to_pixels(Vector2i(gate.x, gate.y))
		var frame: Color = GATE if gate.team == -1 else TEAM_COLOURS[gate.team]
		draw_rect(Rect2(base - Vector2(14, 26), Vector2(28, 26)), frame)
		draw_rect(Rect2(base - Vector2(10, 22), Vector2(20, 22)), DOORS if occupied.has(i) else HOLE)
		if gate.type == GateState.Type.WARRIOR:
			draw_rect(Rect2(base - Vector2(24, 34), Vector2(48, 6)), WINGS)
		else:
			draw_rect(Rect2(base - Vector2(3, 20), Vector2(6, 16)), BOLT)
	for team in map.snail_goals.size():
		var goal := _to_pixels(map.snail_goals[team])
		draw_rect(Rect2(goal - Vector2(26, 30), Vector2(52, 30)), TEAM_COLOURS[team], false, 2)


func _draw_characters() -> void:
	var t := _current.tuning
	var alpha := Engine.get_physics_interpolation_fraction()
	var worker_size := _to_pixels(Vector2i(t.worker_width, t.worker_height))
	var winged_size := _to_pixels(Vector2i(t.winged_width, t.winged_height))
	var humans := _human_labels() if _current.countdown_ticks() > 0 else {}
	for i in _current.characters.size():
		var now := _current.characters[i]
		if not now.alive or now.is_locked_in(t) or (now.invulnerable_ticks / BLINK_TICKS) % 2 == 1:
			continue
		var before := _previous.characters[i]
		# Don't slide across the screen from where a respawned character died.
		if not before.alive:
			before = now
		var now_feet := _to_pixels(Vector2i(now.x, now.y))
		var before_feet := _to_pixels(Vector2i(before.x, before.y))
		# Interpolate across a wrap the short way round, not across the screen.
		if absf(now_feet.x - before_feet.x) > SCREEN_WIDTH / 2.0:
			before_feet.x += SCREEN_WIDTH * signf(now_feet.x - before_feet.x)
		var feet := before_feet.lerp(now_feet, alpha)
		# Draw a copy one screen width each side so a character straddling a
		# wrap edge shows on both sides.
		var size := winged_size if now.is_winged() else worker_size
		for offset in [-SCREEN_WIDTH, 0, SCREEN_WIDTH]:
			_draw_character(feet + Vector2(offset, 0), size, now)
		if humans.has(i):
			_draw_highlight(feet, size, humans[i])


## The label of each Seat a connected device drives, by Seat.
func _human_labels() -> Dictionary:
	var labels := {}
	for i in _devices.size():
		if _devices[i].connected():
			labels[DEVICE_SEATS[i]] = _devices[i].label
	return labels


## Marks a human's character during the countdown, so each player can find
## themselves: a white outline, and an arrow under their device's name.
func _draw_highlight(feet: Vector2, size: Vector2, label: String) -> void:
	var body := Rect2(feet - Vector2(size.x / 2, size.y), size).grow(2)
	draw_rect(Rect2(body.position.round(), body.size), Color.WHITE, false, 1)
	var tip := Vector2(feet.x, body.position.y - 6).round()
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-5, -6), tip + Vector2(5, -6)]), Color.WHITE)
	var font := ThemeDB.fallback_font
	draw_string_outline(font, tip + Vector2(-40, -10), label, HORIZONTAL_ALIGNMENT_CENTER, 80, 10, 3, Color.BLACK)
	draw_string(font, tip + Vector2(-40, -10), label, HORIZONTAL_ALIGNMENT_CENTER, 80, 10, Color.WHITE)


## Placeholder Snail: a pink box at its state position, with an eye on the
## side it's heading (toward its rider's Snail Goal) and its mouth open,
## darker, while it eats.
func _draw_snail() -> void:
	var s := _current.snail
	if s == null:
		return
	var t := _current.tuning
	var before_x := _previous.snail.x if _previous.snail != null else s.x
	var x := lerpf(before_x, s.x, Engine.get_physics_interpolation_fraction())
	var size := _to_pixels(Vector2i(t.snail_width, t.snail_height))
	var feet := Vector2(x / MPX_PER_PIXEL, float(s.y) / MPX_PER_PIXEL)
	var body := Rect2(feet - Vector2(size.x / 2, size.y), size)
	draw_rect(body, SNAIL.darkened(0.3) if s.victim != -1 else SNAIL)
	if s.rider != -1:
		var heading := _current.characters[s.rider].facing
		var eye := Vector2(body.get_center().x + heading * size.x / 3, body.position.y + 6)
		draw_rect(Rect2(eye.round(), Vector2(3, 3)), Color.WHITE)


## Placeholder: a Team-coloured collider box with an eye on its facing side.
## Winged characters get a wing stripe, Queens a crown, and Speed characters a
## yellow belt.
func _draw_character(feet: Vector2, size: Vector2, c: CharacterState) -> void:
	var body := Rect2(feet - Vector2(size.x / 2, size.y), size).abs()
	var top_left := body.position.round()
	draw_rect(Rect2(top_left, body.size), TEAM_COLOURS[c.team])
	var eye_x := body.get_center().x + c.facing * size.x / 4 - 1
	draw_rect(Rect2(Vector2(eye_x, body.position.y + 4).round(), Vector2(2, 2)), Color.WHITE)
	if c.speed:
		draw_rect(Rect2(top_left + Vector2(0, body.size.y - 6), Vector2(body.size.x, 2)), BOLT)
	if c.is_winged():
		draw_rect(Rect2(top_left + Vector2(-3, 10), Vector2(size.x + 6, 3)), WINGS)
	if c.role == CharacterState.Role.QUEEN:
		draw_rect(Rect2(top_left + Vector2(4, -4), Vector2(size.x - 8, 4)), CROWN)


## Placeholder Berries: purple orbs, in piles, loose, on carriers' heads and
## in Hive holes. Moving ones interpolate like characters.
func _draw_berries() -> void:
	var alpha := Engine.get_physics_interpolation_fraction()
	var radius := float(_current.tuning.berry_size) / MPX_PER_PIXEL / 2
	for i in _current.berries.size():
		var now := _current.berries[i]
		if now.where == BerryState.Where.SPENT:
			continue
		var before := _previous.berries[i]
		if before.where != now.where and now.where != BerryState.Where.CARRIED:
			before = now
		var now_at := _to_pixels(Vector2i(now.x, now.y))
		var before_at := _to_pixels(Vector2i(before.x, before.y))
		if absf(now_at.x - before_at.x) > SCREEN_WIDTH / 2.0:
			before_at = now_at
		draw_circle(before_at.lerp(now_at, alpha) - Vector2(0, radius), radius, BERRY)


## Placeholder kill pop: a burst in the dead character's Team colour inside a
## growing white ring.
func _draw_pops() -> void:
	for pop in _pops:
		var grown := float(pop.age + 1) / POP_TICKS
		draw_circle(pop.at, 14.0 * (1.0 - grown) + 2.0, TEAM_COLOURS[pop.team])
		draw_arc(pop.at, 6.0 + 22.0 * grown, 0.0, TAU, 24, POP, 2.0)


## The countdown's seconds left over the middle of the Map, then "GO!".
func _draw_countdown() -> void:
	var left := _current.countdown_ticks()
	var text := ""
	if left > 0:
		text = str(ceili(float(left) / Engine.physics_ticks_per_second))
	elif _current.tick < _current.tuning.match_countdown_ticks + GO_TICKS:
		text = "GO!"
	if text != "":
		_draw_centred(text, 300, 64, Color.WHITE)


## Placeholder victory screen: the winning Team and how it won, then, after a
## moment, a menu to rematch or return to the Lobby.
func _draw_victory() -> void:
	if _current.win == MatchState.Win.NONE:
		return
	draw_rect(Rect2(0, 0, SCREEN_WIDTH, 540), Color(0, 0, 0, 0.6))
	_draw_centred(TEAM_NAMES[_current.winner], 210, 64, TEAM_COLOURS[_current.winner])
	_draw_centred("%s VICTORY" % MatchState.Win.keys()[_current.win], 260, 32, Color.WHITE)
	if _menu != null:
		_menu.draw(self, 360, SCREEN_WIDTH)


func _draw_pause() -> void:
	if not _paused:
		return
	draw_rect(Rect2(0, 0, SCREEN_WIDTH, 540), Color(0, 0, 0, 0.6))
	_draw_centred("PAUSED", 230, 48, Color.WHITE)
	_menu.draw(self, 320, SCREEN_WIDTH)


## Placeholder until ticket 18's Lobby.
func _draw_lobby() -> void:
	_draw_centred("LOBBY", 200, 64, Color.WHITE)
	_draw_centred("Placeholder until ticket 18: the Seats are fixed and the keyboards play the Queens.",
		250, 16, Color.WHITE)
	_menu.draw(self, 340, SCREEN_WIDTH)


## Draws `text` centred across the screen with its baseline at `y`, outlined so
## it reads over the Map.
func _draw_centred(text: String, y: float, size: int, colour: Color) -> void:
	var font := ThemeDB.fallback_font
	var at := Vector2(0, y)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, SCREEN_WIDTH, size, maxi(size / 8, 2),
		Color.BLACK)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, SCREEN_WIDTH, size, colour)


## While a Replay plays back: which tick of how many, at the top left.
func _draw_playback() -> void:
	if _playback == null:
		return
	var text := "REPLAY %d / %d" % [_current.tick, _playback.length()]
	if _current.tick >= _playback.length():
		text += "  (over: F9 again, F8 live)"
	draw_string(ThemeDB.fallback_font, Vector2(8, 22), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)


func _to_pixels(mpx: Vector2i) -> Vector2:
	return Vector2(mpx) / MPX_PER_PIXEL
