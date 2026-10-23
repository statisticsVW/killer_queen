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
const GATE := Color("8a8f98")
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

## Every device that can drive a Seat, in a fixed order: the two keyboard
## layouts, then pads by Godot device id. Each has read() -> SeatInput.
var _devices: Array = [KeyboardLayout.wasd(), KeyboardLayout.arrows()]
var _previous: MatchState
var _current: MatchState
## Seats the Warrior dev command has been given for the next tick.
var _dev_warrior_seats: Array[int] = []
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


func _start_live_match() -> void:
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
	_current = Sim.create_match(config)
	_previous = _current
	_pops = []


func _physics_process(_delta: float) -> void:
	var input: TickInput
	if _playback != null:
		if _current.tick >= _playback.length():
			_previous = _current
			return
		input = _playback.input(_current.tick)
	else:
		input = _read_devices()
		_recording.add(input)
		_saved = false
	_previous = _current
	_current = Sim.step(_current, input)
	_update_pops()
	if _playback == null and _current.win != MatchState.Win.NONE:
		_save_replay()


func _read_devices() -> TickInput:
	var seats: Array[SeatInput] = []
	for seat in SEAT_TEAMS.size():
		seats.append(SeatInput.of(SeatInput.NEUTRAL))
	for i in _devices.size():
		seats[DEVICE_SEATS[i]] = _devices[i].read()
	var input := TickInput.of(_current.tick, seats)
	input.dev_warrior_seats = _dev_warrior_seats
	_dev_warrior_seats = []
	return input


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


## Ages the kill pops and starts one where each character died this tick.
func _update_pops() -> void:
	for pop in _pops:
		pop.age += 1
	_pops = _pops.filter(func(pop: Dictionary) -> bool: return pop.age < POP_TICKS)
	var t := _current.tuning
	for e in _current.events:
		if e.type != MatchEvent.Type.DEATH:
			continue
		var c := _current.characters[e.seat]
		var height := t.winged_height if c.is_winged() else t.worker_height
		_pops.append({"at": _to_pixels(Vector2i(c.x, c.y - height / 2)), "team": c.team, "age": 0})


## Dev builds only. Until Gates exist, a digit key makes that Seat's Worker a
## Warrior. F9 plays back the last Match's Replay; F8 starts a new live Match.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not OS.is_debug_build() or not key.pressed or key.echo:
		return
	if key.physical_keycode >= KEY_0 and key.physical_keycode <= KEY_9:
		_dev_warrior_seats.append(key.physical_keycode - KEY_0)
	elif key.physical_keycode == KEY_F9:
		_play_last_replay()
	elif key.physical_keycode == KEY_F8:
		_save_replay()
		_start_live_match()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var map := _current.map
	draw_rect(Rect2(Vector2.ZERO, _to_pixels(Vector2i(MapData.WIDTH, MapData.HEIGHT))), BACKGROUND)
	_draw_hives(map)
	_draw_tiles(map)
	_draw_objects(map)
	_draw_characters()
	_draw_pops()
	_draw_win()
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


## Placeholder Gates, Berry piles, Snail and Snail Goals at their Map positions.
func _draw_objects(map: MapData) -> void:
	for gate in map.warrior_gates:
		var base := _to_pixels(gate)
		draw_rect(Rect2(base - Vector2(14, 26), Vector2(28, 26)), GATE)
		draw_rect(Rect2(base - Vector2(24, 34), Vector2(48, 6)), WINGS)
	for gate in map.speed_gates:
		var base := _to_pixels(gate)
		draw_rect(Rect2(base - Vector2(14, 26), Vector2(28, 26)), GATE)
		draw_rect(Rect2(base - Vector2(3, 24), Vector2(6, 20)), BOLT)
	for pile in map.berry_piles:
		# A triangle of six: rows of three, two and one from the bottom up.
		var base := _to_pixels(pile)
		for row in 3:
			for i in 3 - row:
				var centre := base + Vector2((i - (2 - row) / 2.0) * 7, -4 - row * 7)
				draw_circle(centre, 3.5, BERRY)
	var snail := _to_pixels(map.snail_start)
	draw_rect(Rect2(snail - Vector2(24, 26), Vector2(48, 26)), SNAIL)
	for team in map.snail_goals.size():
		var goal := _to_pixels(map.snail_goals[team])
		draw_rect(Rect2(goal - Vector2(26, 30), Vector2(52, 30)), TEAM_COLOURS[team], false, 2)


func _draw_characters() -> void:
	var t := _current.tuning
	var alpha := Engine.get_physics_interpolation_fraction()
	var worker_size := _to_pixels(Vector2i(t.worker_width, t.worker_height))
	var winged_size := _to_pixels(Vector2i(t.winged_width, t.winged_height))
	for i in _current.characters.size():
		var now := _current.characters[i]
		if not now.alive or (now.invulnerable_ticks / BLINK_TICKS) % 2 == 1:
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


## Placeholder: a Team-coloured collider box with an eye on its facing side.
## Winged characters get a wing stripe, and Queens a crown.
func _draw_character(feet: Vector2, size: Vector2, c: CharacterState) -> void:
	var body := Rect2(feet - Vector2(size.x / 2, size.y), size).abs()
	var top_left := body.position.round()
	draw_rect(Rect2(top_left, body.size), TEAM_COLOURS[c.team])
	var eye_x := body.get_center().x + c.facing * size.x / 4 - 1
	draw_rect(Rect2(Vector2(eye_x, body.position.y + 4).round(), Vector2(2, 2)), Color.WHITE)
	if c.is_winged():
		draw_rect(Rect2(top_left + Vector2(-3, 10), Vector2(size.x + 6, 3)), WINGS)
	if c.role == CharacterState.Role.QUEEN:
		draw_rect(Rect2(top_left + Vector2(4, -4), Vector2(size.x - 8, 4)), CROWN)


## Placeholder kill pop: a burst in the dead character's Team colour inside a
## growing white ring.
func _draw_pops() -> void:
	for pop in _pops:
		var grown := float(pop.age + 1) / POP_TICKS
		draw_circle(pop.at, 14.0 * (1.0 - grown) + 2.0, TEAM_COLOURS[pop.team])
		draw_arc(pop.at, 6.0 + 22.0 * grown, 0.0, TAU, 24, POP, 2.0)


## Placeholder until ticket 16's victory screen: the winning Team and win type
## across the middle of the screen.
func _draw_win() -> void:
	if _current.win == MatchState.Win.NONE:
		return
	var text := "%s %s WIN" % [TEAM_NAMES[_current.winner], MatchState.Win.keys()[_current.win]]
	var font := ThemeDB.fallback_font
	var size := 32
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := Vector2((SCREEN_WIDTH - width) / 2.0, 270)
	draw_rect(Rect2(0, at.y - size, SCREEN_WIDTH, size * 1.5), Color(0, 0, 0, 0.6))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, TEAM_COLOURS[_current.winner])


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
