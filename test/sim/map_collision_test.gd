extends GdUnitTestSuite
## Gravity, platforms, walls and wrap edges, on small test Maps (120 px tiles)
## and on Day, driven only through Sim.create_match and Sim.step.

const PX := 1000
const DAY_PATH := "res://data/maps/day.cfg"


func test_a_falling_worker_lands_on_a_platform_and_stays_there() -> void:
	var map := TestMaps.build([
		"|................",
		"|................",
		"|................",
		"|................",
		"|................",
		"|......####......",
		"|................",
		"|................",
		"|################",
	], [Vector2i(960, 240)])
	var state := _match(map, _instant_accel())

	state = _hold(state, SeatInput.NEUTRAL, 100)

	var c := state.characters[0]
	assert_int(c.y).is_equal(600 * PX)
	assert_int(c.vy).is_equal(0)


func test_gravity_builds_fall_speed_up_to_max_fall_speed() -> void:
	var tuning := _instant_accel().with_values({"worker_gravity": 1000, "worker_max_fall_speed": 3000})
	var state := _match(TestMaps.build(_open_rows("|"), [Vector2i(960, 120)]), tuning)

	var speeds: Array[int] = []
	var drops: Array[int] = []
	for i in 4:
		var y := state.characters[0].y
		state = _hold(state, SeatInput.NEUTRAL, 1)
		speeds.append(state.characters[0].vy)
		drops.append(state.characters[0].y - y)

	assert_array(speeds).is_equal([1000, 2000, 3000, 3000])
	assert_array(drops).is_equal([1000, 2000, 3000, 3000])


func test_a_worker_walking_off_a_ledge_falls_to_the_floor_below() -> void:
	var map := TestMaps.build([
		"|................",
		"|................",
		"|................",
		"|................",
		"|................",
		"|######..........",
		"|................",
		"|................",
		"|################",
	], [Vector2i(600, 600)])
	var state := _match(map, _instant_accel())

	state = _hold(state, SeatInput.RIGHT, 20)
	assert_int(state.characters[0].y).is_equal(600 * PX)
	state = _hold(state, SeatInput.RIGHT, 100)

	assert_int(state.characters[0].y).is_equal(960 * PX)


func test_walking_into_a_wall_stops_the_worker_against_it() -> void:
	var map := TestMaps.build([
		"|................",
		"|................",
		"|................",
		"|................",
		"|................",
		"|................",
		"|..........#.....",
		"|..........#.....",
		"|################",
	], [Vector2i(960, 960)])
	var state := _match(map, _instant_accel())

	state = _hold(state, SeatInput.RIGHT, 100)

	var c := state.characters[0]
	assert_int(c.x).is_equal(1200 * PX - state.tuning.worker_width / 2)
	assert_int(c.vx).is_equal(0)
	assert_int(c.y).is_equal(960 * PX)


func test_walking_left_into_a_wall_stops_the_worker_against_it() -> void:
	var map := TestMaps.build([
		"|................",
		"|................",
		"|................",
		"|................",
		"|................",
		"|................",
		"|.....#..........",
		"|.....#..........",
		"|################",
	], [Vector2i(960, 960)])
	var state := _match(map, _instant_accel())

	state = _hold(state, SeatInput.LEFT, 100)

	assert_int(state.characters[0].x).is_equal(720 * PX + state.tuning.worker_width / 2)


func test_walking_off_a_wrap_edge_reappears_on_the_opposite_edge() -> void:
	var state := _match(TestMaps.build(_floor_rows("~"), [Vector2i(1800, 960)]), _instant_accel())

	state = _hold(state, SeatInput.RIGHT, 40)

	var c := state.characters[0]
	assert_int(c.x).is_equal(1800 * PX + 40 * state.tuning.worker_max_speed - MapData.WIDTH)
	assert_int(c.y).is_equal(960 * PX)

	state = _hold(state, SeatInput.LEFT, 40)

	assert_int(state.characters[0].x).is_equal(1800 * PX)


func test_a_worker_wraps_through_a_workers_only_wrap_edge() -> void:
	var state := _match(TestMaps.build(_floor_rows("w"), [Vector2i(120, 960)]), _instant_accel())

	state = _hold(state, SeatInput.LEFT, 40)

	assert_int(state.characters[0].x).is_equal(120 * PX - 40 * state.tuning.worker_max_speed + MapData.WIDTH)


func test_walking_into_a_non_wrap_edge_is_blocked() -> void:
	var state := _match(TestMaps.build(_floor_rows("|"), [Vector2i(120, 960)]), _instant_accel())

	state = _hold(state, SeatInput.LEFT, 40)

	var c := state.characters[0]
	assert_int(c.x).is_equal(state.tuning.worker_width / 2)
	assert_int(c.vx).is_equal(0)


func test_a_worker_straddling_a_wrap_edge_stands_on_floor_across_it() -> void:
	# Only the leftmost tile is floor; a Worker centred 5 px left of the right
	# edge overlaps it through the wrap.
	var map := TestMaps.build([
		"~................",
		"~................",
		"~................",
		"~................",
		"~................",
		"~#...............",
		"~................",
		"~................",
		"~################",
	], [Vector2i(1915, 240)])
	var state := _match(map, _instant_accel())

	state = _hold(state, SeatInput.NEUTRAL, 100)

	assert_int(state.characters[0].y).is_equal(600 * PX)


func test_every_seat_on_day_spawns_standing_on_a_platform() -> void:
	var config := MatchConfig.new()
	config.map = MapData.load_file(DAY_PATH)
	config.seat_teams = [
		CharacterState.BLUE, CharacterState.BLUE, CharacterState.BLUE, CharacterState.BLUE, CharacterState.BLUE,
		CharacterState.GOLD, CharacterState.GOLD, CharacterState.GOLD, CharacterState.GOLD, CharacterState.GOLD,
	]
	config.tuning = _instant_accel()
	var state := Sim.create_match(config)
	var seats: Array[SeatInput] = []
	for i in 10:
		seats.append(SeatInput.of(SeatInput.NEUTRAL))

	var after := Sim.step(state, TickInput.of(0, seats))

	for i in 10:
		assert_int(after.characters[i].y).is_equal(state.characters[i].y)
		assert_int(after.characters[i].vy).is_equal(0)


func _open_rows(edge: String) -> Array[String]:
	var rows: Array[String] = []
	for i in 9:
		rows.append(edge + "................")
	return rows


func _floor_rows(edge: String) -> Array[String]:
	var rows := _open_rows(edge)
	rows[8] = edge + "################"
	return rows


func _instant_accel() -> Tuning:
	return Tuning.load_default().with_values(
		{"worker_run_accel": 1000 * PX, "worker_run_decel": 1000 * PX})


func _match(map: MapData, tuning: Tuning) -> MatchState:
	var config := MatchConfig.new()
	config.map = map
	config.seat_teams = [CharacterState.BLUE]
	config.tuning = tuning
	return Sim.create_match(config)


func _hold(state: MatchState, horizontal: int, ticks: int) -> MatchState:
	for i in ticks:
		state = Sim.step(state, TickInput.of(state.tick, [SeatInput.of(horizontal)]))
	return state
