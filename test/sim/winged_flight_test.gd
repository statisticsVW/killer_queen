extends GdUnitTestSuite
## Queens and Warriors: Flapping, walking, the air brake, the Queen's Dive and
## the winged collider, driven only through Sim.create_match and Sim.step.
##
## Most tests run three Blue Seats side by side, teammates passing through each
## other, and give all three the same input: Seat 0 is the Queen, Seat 1 a
## Worker made a Warrior by the dev command, Seat 2 a Worker.

const PX := 1000
const FLOOR_Y := 960 * PX
const QUEEN := 0
const WARRIOR := 1
const WORKER := 2


func test_the_queen_seat_plays_a_queen_from_her_teams_first_spawn_point() -> void:
	var config := MatchConfig.new()
	config.map = TestMaps.build(TestMaps.floor_tiles(),
		[Vector2i(300, 960), Vector2i(600, 960), Vector2i(900, 960)])
	config.seat_teams = [CharacterState.BLUE, CharacterState.BLUE, CharacterState.BLUE]
	config.queen_seats = [2]
	config.tuning = Tuning.load_default()

	var state := Sim.create_match(config)

	var c := state.characters
	assert_int(c[2].role).is_equal(CharacterState.Role.QUEEN)
	assert_int(c[2].x).is_equal(300 * PX)
	assert_int(c[0].role).is_equal(CharacterState.Role.WORKER)
	assert_int(c[0].x).is_equal(600 * PX)
	assert_int(c[1].x).is_equal(900 * PX)


func test_the_dev_command_makes_a_worker_a_warrior_and_leaves_a_queen_alone() -> void:
	var state := _match(Vector2i(960, 960))

	state = _step(state, SeatInput.NEUTRAL, false, false, [QUEEN, WORKER])

	assert_int(state.characters[QUEEN].role).is_equal(CharacterState.Role.QUEEN)
	assert_int(state.characters[WARRIOR].role).is_equal(CharacterState.Role.WARRIOR)
	assert_int(state.characters[WORKER].role).is_equal(CharacterState.Role.WARRIOR)


func test_one_flap_gives_one_upward_impulse() -> void:
	var state := _match(Vector2i(960, 960))
	var t := state.tuning

	state = _step(state, SeatInput.NEUTRAL, false, true)

	for seat in [QUEEN, WARRIOR]:
		assert_int(state.characters[seat].vy).is_equal(t.winged_gravity - t.winged_flap_impulse)


func test_holding_the_button_gives_no_more_lift_than_a_single_press() -> void:
	var tapped := _apexes(_match(Vector2i(960, 960)), 1)
	var held := _apexes(_match(Vector2i(960, 960)), 60)

	for seat in [QUEEN, WARRIOR]:
		assert_int(tapped[seat]).is_less(FLOOR_Y)
		assert_int(held[seat]).is_equal(tapped[seat])


func test_flapping_above_the_hover_rate_climbs_and_below_it_descends() -> void:
	var start := _match(Vector2i(960, 540))
	var t := start.tuning
	# Ticks between Flaps at which Flaps exactly cancel gravity.
	var hover_period := t.winged_flap_impulse / t.winged_gravity
	assert_int(hover_period).is_greater_equal(5)

	var fast := _tap_every(start, hover_period - 2, 40)
	var faster := _tap_every(start, hover_period - 3, 40)
	var slow := _tap_every(start, hover_period + 2, 40)

	for seat in [QUEEN, WARRIOR]:
		var y := start.characters[seat].y
		assert_int(fast.characters[seat].y).is_less(y)
		assert_int(faster.characters[seat].y).is_less(fast.characters[seat].y)
		assert_int(slow.characters[seat].y).is_greater(y)


func test_grounded_winged_walking_speed_is_a_fraction_of_max_horizontal_speed() -> void:
	var state := _match(Vector2i(960, 960))
	var t := state.tuning
	var walk_speed := t.worker_max_speed * t.winged_walk_speed_ratio / 10000

	state = _hold(state, SeatInput.RIGHT, false, false, 10)

	assert_int(walk_speed).is_less(t.worker_max_speed)
	for seat in [QUEEN, WARRIOR]:
		assert_int(state.characters[seat].y).is_equal(FLOOR_Y)
		assert_int(state.characters[seat].vx).is_equal(walk_speed)
	assert_int(state.characters[WORKER].vx).is_equal(t.worker_max_speed)


func test_airborne_winged_characters_move_at_max_horizontal_speed() -> void:
	var state := _match(Vector2i(960, 960))

	state = _step(state, SeatInput.RIGHT, false, true)
	state = _hold(state, SeatInput.RIGHT, false, false, 3)

	for seat in [QUEEN, WARRIOR]:
		assert_int(state.characters[seat].y).is_less(FLOOR_Y)
		assert_int(state.characters[seat].vx).is_equal(state.tuning.worker_max_speed)


func test_three_flaps_within_the_window_at_terminal_fall_speed_stop_the_fall() -> void:
	var state := _at_terminal_fall_speed()

	state = _flap_series(state, 3, 2)

	for seat in [QUEEN, WARRIOR]:
		assert_int(state.characters[seat].vy).is_equal(0)


func test_two_flaps_at_terminal_fall_speed_do_not_stop_the_fall() -> void:
	var state := _at_terminal_fall_speed()

	state = _flap_series(state, 2, 2)

	for seat in [QUEEN, WARRIOR]:
		assert_int(state.characters[seat].vy).is_greater(0)


func test_three_flaps_spread_wider_than_the_window_do_not_stop_the_fall() -> void:
	var state := _at_terminal_fall_speed()
	var spacing := state.tuning.winged_air_brake_ticks / 2 + 1

	state = _flap_series(state, 3, spacing)

	for seat in [QUEEN, WARRIOR]:
		assert_int(state.characters[seat].vy).is_greater(0)


func test_a_queen_holding_down_falls_faster_and_down_is_ignored_for_others() -> void:
	var plain := _hold(_match(Vector2i(960, 300)), SeatInput.NEUTRAL, false, false, 20)
	var down := _hold(_match(Vector2i(960, 300)), SeatInput.NEUTRAL, true, false, 20)

	assert_int(down.characters[QUEEN].y).is_greater(plain.characters[QUEEN].y)
	assert_int(down.characters[QUEEN].vy).is_greater(plain.characters[QUEEN].vy)
	for seat in [WARRIOR, WORKER]:
		assert_int(down.characters[seat].y).is_equal(plain.characters[seat].y)
		assert_int(down.characters[seat].vy).is_equal(plain.characters[seat].vy)


func test_a_diving_queen_ignores_flaps_until_she_releases_down() -> void:
	var state := _hold(_match(Vector2i(960, 60)), SeatInput.NEUTRAL, true, false, 30)
	var t := state.tuning
	assert_int(state.characters[QUEEN].vy).is_equal(t.queen_dive_max_fall_speed)

	state = _step(state, SeatInput.NEUTRAL, true, true)

	assert_int(state.characters[QUEEN].vy).is_equal(t.queen_dive_max_fall_speed)

	state = _step(state, SeatInput.NEUTRAL, false, false)
	state = _step(state, SeatInput.NEUTRAL, false, true)

	assert_int(state.characters[QUEEN].vy).is_less(t.queen_dive_max_fall_speed)


func test_queen_and_warrior_colliders_match_and_differ_from_the_workers() -> void:
	var map := TestMaps.build([
		"|................",
		"|................",
		"|................",
		"|................",
		"|................",
		"|................",
		"|................",
		"|#...............",
		"|################",
	], [Vector2i(600, 960), Vector2i(600, 960), Vector2i(600, 960)])
	var state := _match_on(map)

	state = _hold(state, SeatInput.LEFT, false, false, 200)

	var c := state.characters
	assert_int(c[QUEEN].x).is_equal(120 * PX + state.tuning.winged_width / 2)
	assert_int(c[WARRIOR].x).is_equal(c[QUEEN].x)
	assert_int(c[WORKER].x).is_equal(120 * PX + state.tuning.worker_width / 2)
	assert_int(c[WORKER].x).is_not_equal(c[QUEEN].x)


func test_a_winged_character_is_blocked_at_a_workers_only_wrap_edge() -> void:
	var rows: Array[String] = []
	for i in 8:
		rows.append("w................")
	rows.append("w################")
	var spawn := Vector2i(120, 960)
	var state := _match_on(TestMaps.build(rows, [spawn, spawn, spawn]))

	state = _hold(state, SeatInput.LEFT, false, false, 40)

	var t := state.tuning
	for seat in [QUEEN, WARRIOR]:
		assert_int(state.characters[seat].x).is_equal(t.winged_width / 2)
	assert_int(state.characters[WORKER].x).is_greater(MapData.WIDTH / 2)


## A Match of three Blue Seats spawned at `at_px` on a floor (top at y 960 px),
## after one tick in which the dev command made Seat 1 a Warrior.
func _match(at_px: Vector2i) -> MatchState:
	return _match_on(TestMaps.build(TestMaps.floor_tiles(), [at_px, at_px, at_px]))


func _match_on(map: MapData) -> MatchState:
	var config := MatchConfig.new()
	config.map = map
	config.seat_teams = [CharacterState.BLUE, CharacterState.BLUE, CharacterState.BLUE]
	config.queen_seats = [QUEEN]
	config.tuning = Tuning.load_default().with_values(
		{"worker_run_accel": 1000 * PX, "worker_run_decel": 1000 * PX})
	return _step(Sim.create_match(config), SeatInput.NEUTRAL, false, false, [WARRIOR])


## Every Seat gets the same input.
func _step(state: MatchState, horizontal: int, down: bool, button: bool,
		dev_warrior_seats: Array[int] = []) -> MatchState:
	var seats: Array[SeatInput] = []
	for c in state.characters:
		seats.append(SeatInput.of(horizontal, down, button))
	var input := TickInput.of(state.tick, seats)
	input.dev_warrior_seats = dev_warrior_seats
	return Sim.step(state, input)


func _hold(state: MatchState, horizontal: int, down: bool, button: bool, ticks: int) -> MatchState:
	for i in ticks:
		state = _step(state, horizontal, down, button)
	return state


## Presses the button on the first tick of every `period` ticks, for `ticks`.
func _tap_every(state: MatchState, period: int, ticks: int) -> MatchState:
	for i in ticks:
		state = _step(state, SeatInput.NEUTRAL, false, i % period == 0)
	return state


## Each Seat's highest point (smallest y) over 100 ticks with the button held
## for `held_ticks`.
func _apexes(state: MatchState, held_ticks: int) -> Array[int]:
	var apexes: Array[int] = []
	for c in state.characters:
		apexes.append(c.y)
	for i in 100:
		state = _step(state, SeatInput.NEUTRAL, false, i < held_ticks)
		for seat in apexes.size():
			apexes[seat] = mini(apexes[seat], state.characters[seat].y)
	return apexes


## Falls from near the top of the Map until the winged characters are at
## terminal fall speed.
func _at_terminal_fall_speed() -> MatchState:
	var state := _match(Vector2i(960, 60))
	while state.characters[QUEEN].vy < state.tuning.winged_max_fall_speed:
		state = _step(state, SeatInput.NEUTRAL, false, false)
	return state


## `flaps` Flaps, `spacing` ticks apart, ending on the tick of the last Flap.
func _flap_series(state: MatchState, flaps: int, spacing: int) -> MatchState:
	for i in (flaps - 1) * spacing + 1:
		state = _step(state, SeatInput.NEUTRAL, false, i % spacing == 0)
	return state
