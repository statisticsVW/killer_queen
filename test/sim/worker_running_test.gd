extends GdUnitTestSuite
## A Worker running on a flat floor, driven only through Sim.create_match and
## Sim.step.

const PX := 1000


func test_default_tuning_uses_the_arcade_run_speed_of_5_px_per_tick() -> void:
	assert_int(Tuning.load_default().worker_max_speed).is_equal(5 * PX)


func test_holding_right_for_50_ticks_moves_exactly_250_px() -> void:
	var state := _match(_instant_accel())
	var start_x := state.characters[0].x

	state = _hold(state, SeatInput.RIGHT, 50)

	assert_int(state.characters[0].x - start_x).is_equal(250 * PX)


func test_holding_left_moves_left_and_faces_left() -> void:
	var state := _match(_instant_accel())
	var start_x := state.characters[0].x

	state = _hold(state, SeatInput.LEFT, 10)

	assert_int(state.characters[0].x - start_x).is_equal(-10 * state.tuning.worker_max_speed)
	assert_int(state.characters[0].facing).is_equal(SeatInput.LEFT)


func test_speed_builds_up_by_run_accel_until_max_speed() -> void:
	var tuning := Tuning.load_default().with_values({"worker_max_speed": 5000, "worker_run_accel": 2000})
	var state := _match(tuning)

	var speeds: Array[int] = []
	for i in 4:
		state = _hold(state, SeatInput.RIGHT, 1)
		speeds.append(state.characters[0].vx)

	assert_array(speeds).is_equal([2000, 4000, 5000, 5000])


func test_releasing_the_stick_slows_by_run_decel_to_a_stop() -> void:
	var tuning := Tuning.load_default().with_values(
		{"worker_max_speed": 5000, "worker_run_accel": 5000, "worker_run_decel": 2000})
	var state := _hold(_match(tuning), SeatInput.RIGHT, 5)

	var speeds: Array[int] = []
	for i in 4:
		state = _hold(state, SeatInput.NEUTRAL, 1)
		speeds.append(state.characters[0].vx)

	assert_array(speeds).is_equal([3000, 1000, 0, 0])


func test_releasing_the_stick_keeps_facing() -> void:
	var state := _hold(_match(_instant_accel()), SeatInput.LEFT, 3)

	state = _hold(state, SeatInput.NEUTRAL, 3)

	assert_int(state.characters[0].facing).is_equal(SeatInput.LEFT)


func test_a_worker_stops_at_the_edge_of_the_map() -> void:
	var state := _match(_instant_accel())

	state = _hold(state, SeatInput.RIGHT, 500)

	var c := state.characters[0]
	assert_int(c.x).is_equal(MapData.WIDTH - state.tuning.worker_width / 2)
	assert_int(c.vx).is_equal(0)


func test_step_leaves_the_given_state_unchanged() -> void:
	var before := _match(_instant_accel())

	var after := Sim.step(before, _tick_input(before.tick, SeatInput.RIGHT))

	assert_int(before.tick).is_equal(0)
	assert_int(before.characters[0].x).is_equal(before.map.spawns[0].x)
	assert_int(after.tick).is_equal(1)
	assert_int(after.characters[0].x).is_not_equal(before.characters[0].x)


func test_a_copied_state_steps_independently_of_the_original() -> void:
	var original := _match(_instant_accel())
	var copy := original.copy()

	copy = _hold(copy, SeatInput.RIGHT, 5)
	original = _hold(original, SeatInput.LEFT, 5)

	assert_int(copy.characters[0].x).is_greater(original.characters[0].x)


func _instant_accel() -> Tuning:
	return Tuning.load_default().with_values(
		{"worker_run_accel": 1000 * PX, "worker_run_decel": 1000 * PX})


func _match(tuning: Tuning) -> MatchState:
	var config := MatchConfig.new()
	config.map = MapData.test_floor(1)
	config.seat_teams = [CharacterState.BLUE]
	config.tuning = tuning
	return Sim.create_match(config)


func _tick_input(tick: int, horizontal: int) -> TickInput:
	return TickInput.of(tick, [SeatInput.of(horizontal)])


func _hold(state: MatchState, horizontal: int, ticks: int) -> MatchState:
	for i in ticks:
		state = Sim.step(state, _tick_input(state.tick, horizontal))
	return state
