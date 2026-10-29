extends Node2D
## Drives the sim at a fixed 50 ticks/second (the physics tick rate in project
## settings) and draws it at the display rate, interpolating between the last
## two states, playing each state's sound cues as it steps to it. Rendering and
## sound only: no game rules live here.

const MAP_PATH := "res://data/maps/day.cfg"
## Where dev builds keep the last Match's Replay, under res:// or user://.
const REPLAY_FILE := "replays/last.replay"

## Sim milli-pixels per logical (960x540) pixel.
const MPX_PER_PIXEL := 2000
const SCREEN_WIDTH := MapData.WIDTH / MPX_PER_PIXEL

const BACKGROUND := Color("8ec8e8")
## The Day sky darkens toward the top; clouds and far hills sit behind the Map.
const SKY_TOP := Color("5aa6dc")
const CLOUD := Color("eef7fc")
const HILLS := Color("9fcf9a")
const DIRT := Color("7a5230")
const DIRT_DARK := Color("5e3e22")
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
const CROWN := Color("ffd23f")
const POP := Color.WHITE

## How long a kill pop shows, in physics ticks.
const POP_TICKS := 15
## Invulnerable characters blink: this many ticks shown, then as many hidden.
const BLINK_TICKS := 3

## Pads are read for this many Godot joypad ids.
const PADS := 8

## How long the victory screen shows before its menu takes input, in physics
## ticks, so a button mashed as the Match ends doesn't choose for anyone.
const VICTORY_MENU_DELAY := 50
## How long "GO!" shows once the countdown ends, in physics ticks.
const GO_TICKS := 50
## The dev overlay's colour for colliders other than characters', and how many
## ticks of movement a velocity line spans.
const OVERLAY_OBJECT := Color(1, 1, 1, 0.8)
const VELOCITY_TICKS := 4
## Constants the live tuning editor's panel lists at once.
const EDITOR_ROWS := 24
const ROPE := Color("8d6710")
const ROPE_LIGHT := Color("c79f2d")

## Menu options.
const RESUME := "RESUME"
const REMATCH := "REMATCH"
const LOBBY := "LOBBY"
const FULLSCREEN := "FULLSCREEN"
const WINDOWED := "WINDOWED"

enum Screen { LOBBY, MATCH }

## Where each slot of the Lobby's row is drawn: its centre x, in logical
## pixels. Each Queen Seat stands apart from its Team's Worker Seats, and each
## Team's Bot Difficulty is at its end.
const SLOT_X: Array[int] = [48, 146, 236, 306, 376, 446, 514, 584, 654, 724, 814, 912]
const LOBBY_SEAT_BOTTOM := 300
const DIFFICULTY_NAMES := ["EASY", "NORMAL", "HARD"]

## Every device that can drive a Seat, in a fixed order: the two keyboard
## layouts, then pads by Godot device id. Each has read() -> SeatInput,
## connected() -> bool and a label. The Lobby knows devices by this order.
var _devices: Array = [KeyboardLayout.wasd(), KeyboardLayout.arrows()]
var _lobby := Lobby.new()
var _screen := Screen.LOBBY
## The Seat each device plays in the Match, by device (from the Lobby).
var _device_seats := {}
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
var _sounds := Sounds.new()
var _sprites := Sprites.new()
## The overlay, frame-step and slow motion, and the live tuning editor; inert
## outside dev builds.
var _dev := DevTools.of(OS.is_debug_build())
var _editor := TuningEditor.of(OS.is_debug_build())
## The tuning file's values, which the editor marks edited constants against.
var _file_tuning: Tuning
## The Snail's textures, by whether it is eating.
var _snail_textures := {}


func _ready() -> void:
	add_child(_sounds)
	for device in PADS:
		_devices.append(Pad.of(device))


## Starts a new live Match with the Lobby's Seats; Bots take the rest. A
## rematch keeps the same Seats.
func _start_live_match() -> void:
	_save_replay()
	var config := _lobby.match_config()
	_device_seats = _lobby.local_seats()
	config.map = MapData.load_file(MAP_PATH)
	config.tuning = Tuning.load_default()
	config.seed = randi()
	_recording = Replay.record(config)
	_saved = false
	_playback = null
	_start(config)


func _start(config: MatchConfig) -> void:
	_screen = Screen.MATCH
	# Edits not yet applied belong to the Match before.
	_editor.take()
	_file_tuning = Tuning.load_default()
	_current = Sim.create_match(config)
	_previous = _current
	_pops = []
	_paused = false
	_menu = null
	_over_ticks = 0
	_sounds.stop()
	_play_cues()


## Leaves the Match for the Lobby, where everyone is still at their Seat.
func _to_lobby() -> void:
	_save_replay()
	_recording = null
	_playback = null
	_screen = Screen.LOBBY
	_paused = false
	_menu = null
	_lobby.reopen()


## Each tick: read every device, then run the Lobby, or step the Match or,
## while a menu is up, let the devices choose from it. The Match stands still
## while paused and once it is won. In dev builds, frame-step and slow motion
## step it on only some ticks.
func _physics_process(_delta: float) -> void:
	var inputs := _read_devices()
	_age_pops()
	if _screen == Screen.LOBBY:
		var connected: Array[bool] = []
		for device in _devices:
			connected.append(device.connected())
		if _lobby.update(inputs, connected):
			_start_live_match()
	elif _screen == Screen.MATCH:
		if _current.win != MatchState.Win.NONE:
			_previous = _current
			_over_ticks += 1
			if _over_ticks == VICTORY_MENU_DELAY:
				_menu = Menu.of([REMATCH, LOBBY])
		elif not _paused and _dev.tick():
			_previous = _current
			_step(inputs)
		elif _paused or _dev.frozen:
			_previous = _current
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
	# The live editor's edits apply from this tick, over any the Replay made at
	# it, and are recorded with the rest of the input.
	var edited := _editor.take()
	if edited != null:
		input.tuning = edited
	if _playback == null:
		_recording.add(input)
		_saved = false
	_current = Sim.step(_current, input)
	_add_pops()
	_play_cues()
	if _playback == null and _current.win != MatchState.Win.NONE:
		_save_replay()


func _choose(option: String) -> void:
	match option:
		RESUME:
			_resume()
		REMATCH:
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


## The Match's input for this tick from the devices' inputs: each human
## Seat's device. Bot Seats' input is left neutral; the sim makes their own.
func _tick_input(inputs: Array[SeatInput]) -> TickInput:
	var seats: Array[SeatInput] = []
	for seat in _current.characters.size():
		seats.append(SeatInput.of(SeatInput.NEUTRAL))
	for device in _device_seats:
		seats[_device_seats[device]] = inputs[device]
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


## Dev builds, running from the project: writes the Match's tuning, edits
## included, into the tuning file, keeping its comments, so the next Match
## starts with it.
func _save_tuning() -> void:
	if not OS.has_feature("editor"):
		push_warning("The tuning file can only be saved when running from the project")
		return
	var text := FileAccess.get_file_as_string(Tuning.DEFAULT_PATH)
	var file := FileAccess.open(Tuning.DEFAULT_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save the tuning file %s" % Tuning.DEFAULT_PATH)
		return
	file.store_string(TuningEditor.rewrite(text, _editor.shown(_current.tuning)))
	file.close()
	_file_tuning = Tuning.load_default()


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


## Plays the current state's sound cues. Like the pops, they start as the sim
## steps to the state, so they keep to its tick at any step rate.
func _play_cues() -> void:
	_sounds.play(Cues.of(_current, Engine.physics_ticks_per_second))


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
## Match with the Lobby's Seats as they are; DevTools and, in a Match,
## TuningEditor have the rest. Held, the editor's plus and minus repeat.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not OS.is_debug_build() or not key.pressed:
		return
	var in_match := _screen == Screen.MATCH
	if in_match and _editor.open and key.physical_keycode == TuningEditor.SAVE_KEY and not key.echo:
		_save_tuning()
	elif in_match and _editor.key(key.physical_keycode, key.shift_pressed, _current.tuning):
		get_viewport().set_input_as_handled()
	elif key.echo:
		return
	elif _dev.key(key.physical_keycode):
		get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_F9:
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
	_draw_sky()
	_draw_snail_track(map)
	_draw_hives(map)
	_draw_tiles(map)
	_draw_barriers(map)
	_draw_objects(map)
	_draw_snail()
	_draw_characters()
	_draw_berries()
	_draw_pops()
	_draw_countdown()
	_draw_famine()
	_draw_victory()
	_draw_pause()
	_draw_playback()
	_draw_overlay()
	_draw_dev_status()
	_draw_tuning_editor()


## Placeholder Day sky: bands darkening toward the top, a few clouds and a
## line of far hills.
func _draw_sky() -> void:
	var height := MapData.HEIGHT / MPX_PER_PIXEL
	for band in 6:
		draw_rect(Rect2(0, band * 30, SCREEN_WIDTH, 30), SKY_TOP.lerp(BACKGROUND, band / 6.0))
	for cloud: Vector3 in [Vector3(120, 70, 1.0), Vector3(400, 46, 0.8), Vector3(690, 84, 1.2), Vector3(880, 40, 0.7)]:
		for puff: Vector3 in [Vector3(0, 0, 14), Vector3(16, -6, 12), Vector3(32, 0, 13), Vector3(14, 6, 12)]:
			draw_circle(Vector2(cloud.x + puff.x * cloud.z, cloud.y + puff.y * cloud.z), puff.z * cloud.z, CLOUD)
	var hills := PackedVector2Array([Vector2(0, height)])
	for x in range(0, SCREEN_WIDTH + 1, 24):
		hills.append(Vector2(x, height - 120 - 40 * sin(x / 90.0) - 20 * sin(x / 37.0)))
	hills.append(Vector2(SCREEN_WIDTH, height))
	draw_colored_polygon(hills, HILLS)


func _draw_tiles(map: MapData) -> void:
	var tile := float(map.tile_size) / MPX_PER_PIXEL
	for row in map.rows:
		for column in map.columns:
			if not map.is_solid(column, row):
				continue
			var top_left := Vector2(column, row) * tile
			draw_rect(Rect2(top_left, Vector2(tile, tile)), DIRT)
			# A speck of darker earth, placed by the tile so it doesn't flicker.
			draw_rect(Rect2(top_left + Vector2((column * 7 + row * 3) % 4, 2 + (column + row * 5) % 3), Vector2(1, 1)),
				DIRT_DARK)
			if not map.is_solid(column, row - 1):
				draw_rect(Rect2(top_left, Vector2(tile, 3)), GRASS)
				draw_rect(Rect2(top_left + Vector2((column * 5) % 5, 3), Vector2(1, 1)), GRASS)
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
		var panel := bounds.grow_individual(22, 32, 22, 0)
		draw_rect(panel, HIVE_COLOURS[team])
		_draw_honeycomb(panel, HIVE_COLOURS[team].darkened(0.2))
		draw_rect(panel, HIVE_COLOURS[team].darkened(0.45), false, 2)
		for hole in map.hive_holes[team]:
			_draw_hex(_to_pixels(hole), 6, HOLE)
		for i in _current.eggs[team]:
			_draw_egg(map.eggs[team][i])
	# A dead Queen who will hatch shows as the Egg she is hatching from.
	for c in _current.characters:
		if c.role == CharacterState.Role.QUEEN and not c.alive and c.respawn_ticks > 0:
			_draw_egg(c.spawn)


## A placeholder Egg, 20x29 pixels standing on `at`, with a shine.
func _draw_egg(at: Vector2i) -> void:
	var base := _to_pixels(at)
	var outline := PackedVector2Array()
	var inside := PackedVector2Array()
	for i in 24:
		var angle := TAU * i / 24
		# Narrower toward the top.
		var half := 10.0 * (1.0 - 0.18 * maxf(-sin(angle), 0.0))
		outline.append(base + Vector2(cos(angle) * half, -14.5 + sin(angle) * 14.5))
		inside.append(base + Vector2(cos(angle) * (half - 1.5), -14.5 + sin(angle) * 13.0))
	draw_colored_polygon(outline, EGG.darkened(0.45))
	draw_colored_polygon(inside, EGG)
	draw_rect(Rect2(base + Vector2(-5, -22), Vector2(2, 4)), Color.WHITE)


## A flat-topped hexagon of `radius` pixels centred on `at`.
func _draw_hex(at: Vector2, radius: float, colour: Color) -> void:
	var points := PackedVector2Array()
	for i in 6:
		points.append(at + Vector2.from_angle(TAU * i / 6) * radius)
	draw_colored_polygon(points, colour)


## Honeycomb lines across a Hive's panel.
func _draw_honeycomb(panel: Rect2, colour: Color) -> void:
	var step := Vector2(15, 17)
	var row := 0
	var y := panel.position.y + 8
	while y < panel.end.y - 4:
		var x := panel.position.x + 8 + (7.5 if row % 2 == 1 else 0.0)
		while x < panel.end.x - 4:
			var points := PackedVector2Array()
			for i in 7:
				points.append(Vector2(x, y) + Vector2.from_angle(TAU * i / 6) * 7)
			draw_polyline(points, colour, 1)
			x += step.x
		y += step.y / 2
		row += 1


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
		var outline := frame.darkened(0.5)
		# An arched doorway, 28x26: posts and a rounded top in the owner's
		# colour, its doorway dark or, while a Worker is locked in, shut.
		draw_rect(Rect2(base - Vector2(14, 20), Vector2(28, 20)), outline)
		draw_circle(base - Vector2(0, 20), 7, outline)
		draw_rect(Rect2(base - Vector2(14, 19), Vector2(28, 19)), frame)
		draw_circle(base - Vector2(0, 19), 6, frame)
		draw_rect(Rect2(base - Vector2(9, 17), Vector2(18, 17)), DOORS if occupied.has(i) else HOLE)
		if occupied.has(i):
			draw_rect(Rect2(base - Vector2(1, 17), Vector2(2, 17)), DOORS.darkened(0.4))
		if gate.type == GateState.Type.WARRIOR:
			_draw_wing_sign(base - Vector2(0, 30), outline)
		else:
			_draw_bolt_sign(base - Vector2(0, 30), outline)
	for team in map.snail_goals.size():
		_draw_goal(_to_pixels(map.snail_goals[team]), TEAM_COLOURS[team])


## A Warrior Gate's sign: a pair of wings over the doorway.
func _draw_wing_sign(at: Vector2, outline: Color) -> void:
	for side in [-1, 1]:
		var wing := PackedVector2Array([at + Vector2(side * 2, 2), at + Vector2(side * 22, -5),
			at + Vector2(side * 20, 0), at + Vector2(side * 12, 4)])
		draw_colored_polygon(wing, WINGS)
		draw_polyline(wing + PackedVector2Array([wing[0]]), outline, 1)


## A Speed Gate's sign: a lightning bolt over the doorway.
func _draw_bolt_sign(at: Vector2, outline: Color) -> void:
	var bolt := PackedVector2Array([at + Vector2(2, -9), at + Vector2(-5, 1), at + Vector2(0, 1),
		at + Vector2(-2, 8), at + Vector2(5, -2), at + Vector2(0, -2)])
	draw_colored_polygon(bolt, BOLT)
	draw_polyline(bolt + PackedVector2Array([bolt[0]]), outline, 1)


## A Team's Snail Goal: a flag on a pole by the track.
func _draw_goal(at: Vector2, colour: Color) -> void:
	draw_rect(Rect2(at + Vector2(-1, -40), Vector2(2, 40)), Color("3a2a1a"))
	draw_colored_polygon(PackedVector2Array([at + Vector2(1, -40), at + Vector2(18, -34), at + Vector2(1, -28)]),
		colour)


## The Snail's track along the floor between the Snail Goals, with a tick at
## every tenth of the way and at its start, so its position reads at a glance.
func _draw_snail_track(map: MapData) -> void:
	if not map.has_snail:
		return
	var from := _to_pixels(map.snail_goals[0])
	var to := _to_pixels(map.snail_goals[1])
	var y := from.y - 2
	draw_line(Vector2(from.x, y), Vector2(to.x, y), Color(1, 1, 1, 0.35), 2)
	for i in 11:
		var x := lerpf(from.x, to.x, i / 10.0)
		draw_rect(Rect2(x - 1, y - 4, 2, 4), Color(1, 1, 1, 0.5))
	var start := _to_pixels(map.snail_start)
	draw_rect(Rect2(start.x - 1, y - 8, 2, 8), Color(1, 1, 1, 0.7))


func _draw_characters() -> void:
	var t := _current.tuning
	var humans := _human_labels() if _current.countdown_ticks() > 0 else {}
	for i in _current.characters.size():
		var now := _current.characters[i]
		if not now.alive or now.is_locked_in(t) or (now.invulnerable_ticks / BLINK_TICKS) % 2 == 1:
			continue
		var feet := _feet(i)
		var sprite := _sprites.texture(Pose.of(_current, i), TEAM_COLOURS[now.team], _place(i))
		# Draw a copy one screen width each side so a character straddling a
		# wrap edge shows on both sides.
		for offset in [-SCREEN_WIDTH, 0, SCREEN_WIDTH]:
			_draw_sprite(sprite, feet + Vector2(offset, 0), now.facing)
		if humans.has(i):
			_draw_highlight(feet, sprite.get_size(), humans[i])


## Where Seat `i`'s character's feet are drawn, in logical pixels: part-way
## from its last state to its current one.
func _feet(i: int) -> Vector2:
	var now := _current.characters[i]
	var before := _previous.characters[i]
	# Don't slide across the screen from where a respawned character died.
	if not before.alive:
		before = now
	var now_feet := _to_pixels(Vector2i(now.x, now.y))
	var before_feet := _to_pixels(Vector2i(before.x, before.y))
	# Interpolate across a wrap the short way round, not across the screen.
	if absf(now_feet.x - before_feet.x) > SCREEN_WIDTH / 2.0:
		before_feet.x += SCREEN_WIDTH * signf(now_feet.x - before_feet.x)
	return before_feet.lerp(now_feet, _fraction()).round()


## How far from the last state to the current one to draw: Godot's physics
## interpolation fraction, unless frame-step or slow motion pace the sim.
func _fraction() -> float:
	return _dev.fraction(Engine.get_physics_interpolation_fraction())


## The label of each Seat a connected device drives, by Seat.
func _human_labels() -> Dictionary:
	var labels := {}
	for device in _device_seats:
		if _devices[device].connected():
			labels[_device_seats[device]] = _devices[device].label
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


## The Snail at its state position, its collider's size, facing the way its
## rider is heading (toward their Snail Goal) or, unridden, the middle of the
## Map, its mouth open while it eats.
func _draw_snail() -> void:
	var s := _current.snail
	if s == null:
		return
	var t := _current.tuning
	var x := _snail_x()
	var eating := s.victim != -1
	if not _snail_textures.has(eating):
		var size := Vector2i(t.snail_width, t.snail_height) / MPX_PER_PIXEL
		_snail_textures[eating] = ImageTexture.create_from_image(Sprites.snail_image(size, eating))
	var facing := _current.characters[s.rider].facing if s.rider != -1 \
		else (SeatInput.RIGHT if s.x < MapData.WIDTH / 2 else SeatInput.LEFT)
	_draw_sprite(_snail_textures[eating], Vector2(x / MPX_PER_PIXEL, float(s.y) / MPX_PER_PIXEL).round(), facing)


## Where the Snail is drawn across the Map, in milli-pixels: part-way from its
## last state to its current one.
func _snail_x() -> float:
	var s := _current.snail
	var before_x := _previous.snail.x if _previous.snail != null else s.x
	return lerpf(before_x, s.x, _fraction())


## Draws a sprite (drawn facing right) standing on `feet`, mirrored when
## `facing` is left.
func _draw_sprite(sprite: Texture2D, feet: Vector2, facing: int) -> void:
	var size := sprite.get_size()
	var mirrored := facing == SeatInput.LEFT
	draw_set_transform(feet, 0, Vector2(-1 if mirrored else 1, 1))
	draw_texture(sprite, Vector2(-size.x / 2, -size.y))
	draw_set_transform(Vector2.ZERO)


## Where Seat `seat` stands among its Team's Workers, from 1, for its
## marking; 0 for a Queen.
func _place(seat: int) -> int:
	var team := _current.characters[seat].team
	if seat in _queen_seats():
		return 0
	var place := 1
	for c in _current.characters:
		if c.seat < seat and c.team == team and not c.seat in _queen_seats():
			place += 1
	return place


## The Queens' Seats. A Queen is always a Queen, and a Warrior keeps its
## Worker Seat's marking.
func _queen_seats() -> Array[int]:
	var seats: Array[int] = []
	for c in _current.characters:
		if c.role == CharacterState.Role.QUEEN:
			seats.append(c.seat)
	return seats


## Placeholder Berries: purple orbs, in piles, loose, on carriers' heads and
## in Hive holes. Moving ones interpolate like characters.
func _draw_berries() -> void:
	var radius := float(_current.tuning.berry_size) / MPX_PER_PIXEL / 2
	for i in _current.berries.size():
		if _current.berries[i].where == BerryState.Where.SPENT:
			continue
		var centre := _berry_at(i) - Vector2(0, radius)
		draw_circle(centre, radius + 0.5, BERRY.darkened(0.5))
		draw_circle(centre, radius - 0.5, BERRY)
		draw_rect(Rect2((centre + Vector2(-radius / 2, -radius / 2)).round(), Vector2(1, 1)), Color.WHITE)


## Where Berry `i`'s bottom is drawn, in logical pixels: part-way from its last
## state to its current one while it moves.
func _berry_at(i: int) -> Vector2:
	var now := _current.berries[i]
	# Famine's end can add Berries the previous state didn't have.
	var before := _previous.berries[i] if i < _previous.berries.size() else now
	if before.where != now.where and now.where != BerryState.Where.CARRIED:
		before = now
	var now_at := _to_pixels(Vector2i(now.x, now.y))
	var before_at := _to_pixels(Vector2i(before.x, before.y))
	if absf(now_at.x - before_at.x) > SCREEN_WIDTH / 2.0:
		before_at = now_at
	return before_at.lerp(now_at, _fraction())


## Placeholder kill pop: a burst in the dead character's Team colour inside a
## growing white ring.
func _draw_pops() -> void:
	for pop in _pops:
		var grown := float(pop.age + 1) / POP_TICKS
		draw_circle(pop.at, 14.0 * (1.0 - grown) + 2.0, TEAM_COLOURS[pop.team])
		draw_arc(pop.at, 6.0 + 22.0 * grown, 0.0, TAU, 24, POP, 2.0)


## The countdown's last Cues.COUNTED_SECONDS seconds over the middle of the
## Map, then "GO!".
func _draw_countdown() -> void:
	var left := _current.countdown_ticks()
	var text := ""
	if left > 0 and left <= Cues.COUNTED_SECONDS * Engine.physics_ticks_per_second:
		text = str(ceili(float(left) / Engine.physics_ticks_per_second))
	elif _current.tick < _current.tuning.match_countdown_ticks + GO_TICKS:
		text = "GO!"
	if text != "":
		_draw_centred(text, 300, 64, Color.WHITE)


## During Famine, the time left until the Berry piles refill, as minutes and
## seconds, under the Hives.
func _draw_famine() -> void:
	if _current.famine_ticks == 0:
		return
	var seconds := ceili(float(_current.famine_ticks) / Engine.physics_ticks_per_second)
	_draw_centred("FAMINE %d:%02d" % [seconds / 60, seconds % 60], 150, 20, BERRY.lightened(0.5))


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


## The Lobby: each Team's Seats (its Queen's larger and apart) and Bot
## Difficulty in one row, as the Lobby lays them out. A Seat someone locked
## into is filled in its Team colour with their device's name; one nobody has
## is marked BOT. Players still choosing show under where they are.
func _draw_lobby() -> void:
	_draw_centred("LOBBY", 80, 48, Color.WHITE)
	_draw_centred("Press your button to join. Move with the stick, press to lock in a Seat.", 120, 16,
		Color.WHITE)
	var font := ThemeDB.fallback_font
	for slot in Lobby.SLOT_SEATS.size():
		var seat := Lobby.SLOT_SEATS[slot]
		var x := SLOT_X[slot]
		if seat == -1:
			var side := 0 if slot == 0 else 1
			var panel := Rect2(x - 44, LOBBY_SEAT_BOTTOM - 70, 88, 70)
			draw_rect(panel, TEAM_COLOURS[side], false, 2)
			_draw_in(font, panel, 24, "BOTS", 12, Color.WHITE)
			_draw_in(font, panel, 48, DIFFICULTY_NAMES[_lobby.difficulties[side]], 14, Color.WHITE)
			continue
		var team := Lobby.SEAT_TEAMS[seat]
		var queen := seat in Lobby.QUEEN_SEATS
		var size := Vector2(72, 104) if queen else Vector2(60, 80)
		var box := Rect2(Vector2(x - size.x / 2, LOBBY_SEAT_BOTTOM - size.y), size)
		var holder := _lobby.owner_of(seat)
		if holder != null:
			draw_rect(box, TEAM_COLOURS[team])
			_draw_in(font, box, size.y / 2 + 5, _devices[holder.device].label, 12, Color.WHITE)
		else:
			draw_rect(box, HIVE_COLOURS[team].darkened(0.4))
			draw_rect(box, TEAM_COLOURS[team], false, 2)
			_draw_in(font, box, size.y / 2 + 5, "BOT", 12, Color(1, 1, 1, 0.6))
		if queen:
			draw_rect(Rect2(box.position + Vector2(10, -8), Vector2(size.x - 20, 8)), CROWN)
		_draw_in(font, box, size.y - 6, "QUEEN" if queen else "WORKER", 10, Color(1, 1, 1, 0.7))
	# Players not yet locked in, under the slot each is at.
	var shown := {}
	for p in _lobby.players:
		if p.locked:
			continue
		var row: int = shown.get(p.slot, 0)
		shown[p.slot] = row + 1
		var at := Vector2(SLOT_X[p.slot], LOBBY_SEAT_BOTTOM + 14 + row * 22)
		draw_colored_polygon(PackedVector2Array([at, at + Vector2(-5, 7), at + Vector2(5, 7)]), Color.WHITE)
		draw_string(font, at + Vector2(-40, 20), _devices[p.device].label, HORIZONTAL_ALIGNMENT_CENTER, 80, 12,
			Color.WHITE)
	if _lobby.start_ticks > 0:
		_draw_centred("STARTING IN %d" % ceili(float(_lobby.start_ticks) / Engine.physics_ticks_per_second),
			460, 32, Color.WHITE)
	elif _lobby.players.is_empty():
		_draw_centred("PRESS YOUR BUTTON TO JOIN", 460, 24, Color.WHITE)
	else:
		_draw_centred("The Match starts once everyone is locked in. Empty Seats are Bots.", 460, 16,
			Color.WHITE)


## Draws text centred across a box, its baseline y below the box's top.
func _draw_in(font: Font, box: Rect2, y: float, text: String, size: int, colour: Color) -> void:
	draw_string(font, Vector2(box.position.x, box.position.y + y), text, HORIZONTAL_ALIGNMENT_CENTER,
		box.size.x, size, colour)


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


## Dev builds, with the overlay on: every collider as the sim sees it (the
## Gates', the Snail's, the Berries' and each living character's, where they
## are drawn), and each character's velocity as a line and in arcade pixels a
## tick.
func _draw_overlay() -> void:
	if not _dev.overlay:
		return
	var t := _current.tuning
	for g in _current.gates:
		_draw_box(_to_pixels(Vector2i(g.x, g.y)), Vector2i(t.gate_width, t.gate_height), OVERLAY_OBJECT)
	if _current.snail != null:
		var snail_feet := Vector2(_snail_x(), _current.snail.y) / MPX_PER_PIXEL
		_draw_box(snail_feet, Vector2i(t.snail_width, t.snail_height), OVERLAY_OBJECT)
	for i in _current.berries.size():
		if _current.berries[i].where != BerryState.Where.SPENT:
			_draw_box(_berry_at(i), Vector2i(t.berry_size, t.berry_size), OVERLAY_OBJECT)
	var font := ThemeDB.fallback_font
	for i in _current.characters.size():
		var c := _current.characters[i]
		if not c.alive:
			continue
		var feet := _feet(i)
		var size := Vector2i(t.winged_width, t.winged_height) if c.is_winged() \
			else Vector2i(t.worker_width, t.worker_height)
		var colour: Color = TEAM_COLOURS[c.team].lightened(0.6)
		_draw_box(feet, size, colour)
		var centre := feet - Vector2(0, float(size.y) / MPX_PER_PIXEL / 2)
		draw_line(centre, centre + Vector2(c.vx, c.vy) / MPX_PER_PIXEL * VELOCITY_TICKS, colour, 1)
		var text := "%.1f, %.1f" % [c.vx / 1000.0, c.vy / 1000.0]
		draw_string_outline(font, feet + Vector2(-30, 10), text, HORIZONTAL_ALIGNMENT_CENTER, 60, 8, 2, Color.BLACK)
		draw_string(font, feet + Vector2(-30, 10), text, HORIZONTAL_ALIGNMENT_CENTER, 60, 8, colour)
	var keys := "F1 overlay  F2 freeze/run  F3 step  F4 slow motion  F5 tuning  F8 live  F9 Replay"
	draw_string_outline(font, Vector2(8, 532), keys, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 2, Color.BLACK)
	draw_string(font, Vector2(8, 532), keys, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)


## Outlines a collider `size` milli-pixels across, standing on `feet`.
func _draw_box(feet: Vector2, size: Vector2i, colour: Color) -> void:
	var pixels := Vector2(size) / MPX_PER_PIXEL
	draw_rect(Rect2(feet - Vector2(pixels.x / 2, pixels.y), pixels), colour, false, 1)


## Dev builds, at the top right: the tick while the overlay is on, and how the
## sim is paced while it is frozen or slowed.
func _draw_dev_status() -> void:
	var parts: Array[String] = []
	if _dev.overlay:
		parts.append("TICK %d" % _current.tick)
	if _dev.frozen:
		parts.append("FROZEN")
	elif _dev.divisor > 1:
		parts.append("1/%d SPEED" % _dev.divisor)
	if parts.is_empty():
		return
	var font := ThemeDB.fallback_font
	var text := "  ".join(parts)
	draw_string_outline(font, Vector2(0, 22), text, HORIZONTAL_ALIGNMENT_RIGHT, SCREEN_WIDTH - 8, 16, 3, Color.BLACK)
	draw_string(font, Vector2(0, 22), text, HORIZONTAL_ALIGNMENT_RIGHT, SCREEN_WIDTH - 8, 16, Color.WHITE)


## Dev builds, while the live tuning editor is open: a panel at the right of
## the constants around the picked one, with their values as the next tick
## will have them. A * marks a value that differs from the tuning file's.
func _draw_tuning_editor() -> void:
	if not _editor.open:
		return
	var tuning := _editor.shown(_current.tuning)
	var names := tuning.names()
	var font := ThemeDB.fallback_font
	var panel := Rect2(SCREEN_WIDTH - 300, 32, 292, 40 + EDITOR_ROWS * 14)
	draw_rect(panel, Color(0, 0, 0, 0.75))
	draw_string(font, panel.position + Vector2(8, 16), "TUNING  PgUp/PgDn pick  -/+ change (Shift x10)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	draw_string(font, panel.position + Vector2(8, 30), "F6 save to tuning.cfg  F5 close",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	var first := clampi(_editor.selected - EDITOR_ROWS / 2, 0, names.size() - EDITOR_ROWS)
	for row in EDITOR_ROWS:
		var i := first + row
		var y := panel.position.y + 48 + row * 14
		var picked := i == _editor.selected
		if picked:
			draw_rect(Rect2(panel.position.x + 4, y - 11, panel.size.x - 8, 14), Color(1, 1, 1, 0.25))
		var value: int = tuning.get(names[i])
		var edited: bool = value != _file_tuning.get(names[i])
		var colour := CROWN if edited else Color.WHITE
		draw_string(font, Vector2(panel.position.x + 8, y), ("* " if edited else "  ") + names[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, colour)
		draw_string(font, Vector2(panel.position.x + 8, y), str(value), HORIZONTAL_ALIGNMENT_RIGHT,
			panel.size.x - 16, 11, colour)


func _to_pixels(mpx: Vector2i) -> Vector2:
	return Vector2(mpx) / MPX_PER_PIXEL
