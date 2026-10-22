extends Node2D
## Drives the sim at a fixed 50 ticks/second (the physics tick rate in project
## settings) and draws it at the display rate, interpolating between the last
## two states. Rendering only: no game rules live here.

const MAP_PATH := "res://data/maps/day.cfg"

## Sim milli-pixels per logical (960x540) pixel.
const MPX_PER_PIXEL := 2000
const SCREEN_WIDTH := MapData.WIDTH / MPX_PER_PIXEL

const BACKGROUND := Color("8ec8e8")
const DIRT := Color("7a5230")
const GRASS := Color("3f9a2c")
const WRAP_MARK := Color(1, 1, 1, 0.5)
const WORKER_WRAP_MARK := Color(1, 0.6, 0.9, 0.7)
const TEAM_COLOURS := [Color("2f6fdf"), Color("e8b020")]
const HIVE_COLOURS := [Color("1d4fa8"), Color("b8601c")]
const HOLE := Color("102030")
const EGG := Color("f4e04a")
const GATE := Color("8a8f98")
const WINGS := Color("f2f2f2")
const BOLT := Color("ffe14d")
const BERRY := Color("a63fc4")
const SNAIL := Color("e86aa8")

## Seats 0-4 are Blue, 5-9 Gold.
const SEAT_TEAMS: Array[int] = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1]
## The Seat each device drives, in device order (see _devices). Teams
## alternate, so the first two players are opponents. Seats no device drives
## stand idle.
const DEVICE_SEATS: Array[int] = [0, 5, 1, 6, 2, 7, 3, 8, 4, 9]

## Every device that can drive a Seat, in a fixed order: the two keyboard
## layouts, then pads by Godot device id. Each has read() -> SeatInput.
var _devices: Array = [KeyboardLayout.wasd(), KeyboardLayout.arrows()]
var _previous: MatchState
var _current: MatchState


func _ready() -> void:
	for device in DEVICE_SEATS.size() - _devices.size():
		_devices.append(Pad.of(device))
	var config := MatchConfig.new()
	config.map = MapData.load_file(MAP_PATH)
	config.seat_teams = SEAT_TEAMS
	config.tuning = Tuning.load_default()
	_current = Sim.create_match(config)
	_previous = _current


func _physics_process(_delta: float) -> void:
	var seats: Array[SeatInput] = []
	for seat in SEAT_TEAMS.size():
		seats.append(SeatInput.of(SeatInput.NEUTRAL))
	for i in _devices.size():
		seats[DEVICE_SEATS[i]] = _devices[i].read()
	_previous = _current
	_current = Sim.step(_current, TickInput.of(_current.tick, seats))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var map := _current.map
	draw_rect(Rect2(Vector2.ZERO, _to_pixels(Vector2i(MapData.WIDTH, MapData.HEIGHT))), BACKGROUND)
	_draw_hives(map)
	_draw_tiles(map)
	_draw_objects(map)
	_draw_characters()


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
		for egg in map.eggs[team]:
			draw_rect(Rect2(_to_pixels(egg) - Vector2(10, 29), Vector2(20, 29)), EGG)


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
	var size := _to_pixels(Vector2i(t.worker_width, t.worker_height))
	for i in _current.characters.size():
		var now := _current.characters[i]
		var before := _previous.characters[i]
		var now_feet := _to_pixels(Vector2i(now.x, now.y))
		var before_feet := _to_pixels(Vector2i(before.x, before.y))
		# Interpolate across a wrap the short way round, not across the screen.
		if absf(now_feet.x - before_feet.x) > SCREEN_WIDTH / 2.0:
			before_feet.x += SCREEN_WIDTH * signf(now_feet.x - before_feet.x)
		var feet := before_feet.lerp(now_feet, alpha)
		# Draw a copy one screen width each side so a character straddling a
		# wrap edge shows on both sides.
		for offset in [-SCREEN_WIDTH, 0, SCREEN_WIDTH]:
			_draw_worker(feet + Vector2(offset, 0), size, now)


func _draw_worker(feet: Vector2, size: Vector2, c: CharacterState) -> void:
	var body := Rect2(feet - Vector2(size.x / 2, size.y), size).abs()
	draw_rect(Rect2(body.position.round(), body.size), TEAM_COLOURS[c.team])
	# Placeholder eye so facing is visible.
	var eye_x := body.get_center().x + c.facing * size.x / 4 - 1
	draw_rect(Rect2(Vector2(eye_x, body.position.y + 4).round(), Vector2(2, 2)), Color.WHITE)


func _to_pixels(mpx: Vector2i) -> Vector2:
	return Vector2(mpx) / MPX_PER_PIXEL
