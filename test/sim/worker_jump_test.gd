extends GdUnitTestSuite
## A Worker jumping: tap vs hold, coyote time, no jump buffer and air control,
## driven only through Sim.create_match and Sim.step.

const PX := 1000
const FLOOR_Y := 960 * PX


func test_a_tapped_jump_peaks_lower_than_a_held_jump() -> void:
	var tap_apex := _apex(1)
	var hold_apex := _apex(60)

	assert_int(tap_apex).is_less(FLOOR_Y)
	assert_int(hold_apex).is_less(tap_apex)


func test_jumping_on_the_first_tick_after_walking_off_a_ledge_works() -> void:
	var state := _walk_off_ledge()

	state = _step(state, SeatInput.RIGHT, true)

	assert_int(state.characters[0].vy).is_less(0)


func test_jumping_on_the_second_tick_after_walking_off_a_ledge_does_nothing() -> void:
	var state := _walk_off_ledge()
	state = _step(state, SeatInput.RIGHT, false)

	state = _step(state, SeatInput.RIGHT, true)

	assert_int(state.characters[0].vy).is_greater(0)


func test_pressing_the_button_before_landing_does_not_jump_on_landing() -> void:
	var state := _step(_match(TestMaps.flat_floor(1)), SeatInput.NEUTRAL, true)
	state = _step(state, SeatInput.NEUTRAL, false)
	# Wait until falling, then press and keep holding through the landing.
	while state.characters[0].vy <= 0:
		state = _step(state, SeatInput.NEUTRAL, false)
	assert_int(state.characters[0].y).is_less(FLOOR_Y)

	state = _hold(state, SeatInput.NEUTRAL, true, 100)

	assert_int(state.characters[0].y).is_equal(FLOOR_Y)
	assert_int(state.characters[0].vy).is_equal(0)


func test_holding_the_button_jumps_once() -> void:
	var state := _hold(_match(TestMaps.flat_floor(1)), SeatInput.NEUTRAL, true, 200)

	assert_int(state.characters[0].y).is_equal(FLOOR_Y)


func test_horizontal_speed_in_the_air_equals_ground_speed_and_can_reverse() -> void:
	var state := _match(TestMaps.flat_floor(1))
	var speed := state.tuning.worker_max_speed
	state = _hold(state, SeatInput.RIGHT, false, 5)
	var x := state.characters[0].x

	state = _hold(state, SeatInput.RIGHT, true, 10)

	assert_int(state.characters[0].y).is_less(FLOOR_Y)
	assert_int(state.characters[0].x - x).is_equal(10 * speed)
	x = state.characters[0].x

	state = _hold(state, SeatInput.LEFT, true, 5)

	assert_int(state.characters[0].y).is_less(FLOOR_Y)
	assert_int(state.characters[0].vx).is_equal(-speed)
	assert_int(state.characters[0].x - x).is_equal(-5 * speed)


## Highest point (smallest y) of a jump from the floor with the button held for
## `held_ticks`.
func _apex(held_ticks: int) -> int:
	var state := _match(TestMaps.flat_floor(1))
	var apex := state.characters[0].y
	for i in 100:
		state = _step(state, SeatInput.NEUTRAL, i < held_ticks)
		apex = mini(apex, state.characters[0].y)
	return apex


## Runs right off the end of a ledge at y 600 px and returns the state from the
## first tick the Worker is no longer standing on it.
func _walk_off_ledge() -> MatchState:
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
	var state := _match(map)
	while state.characters[0].y == 600 * PX:
		state = _step(state, SeatInput.RIGHT, false)
	return state


func _match(map: MapData) -> MatchState:
	var config := MatchConfig.new()
	config.map = map
	config.seat_teams = [CharacterState.BLUE]
	config.tuning = Tuning.load_default().with_values(
		{"worker_run_accel": 1000 * PX, "worker_run_decel": 1000 * PX})
	return Sim.create_match(config)


func _step(state: MatchState, horizontal: int, button: bool) -> MatchState:
	return Sim.step(state, TickInput.of(state.tick, [SeatInput.of(horizontal, false, button)]))


func _hold(state: MatchState, horizontal: int, button: bool, ticks: int) -> MatchState:
	for i in ticks:
		state = _step(state, horizontal, button)
	return state
