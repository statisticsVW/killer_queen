extends Node2D
## Drives the sim at a fixed 50 ticks/second (the physics tick rate in project
## settings) and draws it at the display rate, interpolating between the last
## two states. Rendering only: no game rules live here.

## Sim milli-pixels per logical (960x540) pixel.
const MPX_PER_PIXEL := 2000

const BACKGROUND := Color("8ec8e8")
const FLOOR := Color("5a3d2b")
const TEAM_COLOURS := [Color("2f6fdf"), Color("e8b020")]

var _layouts: Array[KeyboardLayout] = [KeyboardLayout.wasd(), KeyboardLayout.arrows()]
var _previous: MatchState
var _current: MatchState


func _ready() -> void:
	var config := MatchConfig.new()
	config.map = MapData.test_floor(1)
	config.seat_teams = [CharacterState.BLUE]
	config.tuning = Tuning.load_default()
	_current = Sim.create_match(config)
	_previous = _current


func _physics_process(_delta: float) -> void:
	var inputs: Array[SeatInput] = []
	for layout in _layouts:
		inputs.append(layout.read())
	var seats: Array[SeatInput] = [KeyboardLayout.merge(inputs)]
	_previous = _current
	_current = Sim.step(_current, TickInput.of(_current.tick, seats))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := _current.tuning
	draw_rect(Rect2(Vector2.ZERO, _to_pixels(Vector2i(MapData.WIDTH, MapData.HEIGHT))), BACKGROUND)
	var floor_top := _to_pixels(Vector2i(0, _current.map.floor_y))
	draw_rect(Rect2(floor_top, Vector2(MapData.WIDTH / MPX_PER_PIXEL, 540 - floor_top.y)), FLOOR)

	var alpha := Engine.get_physics_interpolation_fraction()
	var size := _to_pixels(Vector2i(t.worker_width, t.worker_height))
	for i in _current.characters.size():
		var now := _current.characters[i]
		var before := _previous.characters[i]
		var feet := _to_pixels(Vector2i(before.x, before.y)).lerp(_to_pixels(Vector2i(now.x, now.y)), alpha)
		var body := Rect2(feet - Vector2(size.x / 2, size.y), size).abs()
		draw_rect(Rect2(body.position.round(), body.size), TEAM_COLOURS[now.team])
		# Placeholder eye so facing is visible.
		var eye_x := body.get_center().x + now.facing * size.x / 4 - 1
		draw_rect(Rect2(Vector2(eye_x, body.position.y + 4).round(), Vector2(2, 2)), Color.WHITE)


func _to_pixels(mpx: Vector2i) -> Vector2:
	return Vector2(mpx) / MPX_PER_PIXEL
