extends GdUnitTestSuite
## Changing the tuning mid-Match, as dev builds' live editor does: a tick's
## input can carry a new tuning table, which applies from that tick on. Driven
## only through Sim.create_match and Sim.step.

const PX := 1000


func test_a_tuning_change_in_a_ticks_input_applies_from_that_tick() -> void:
	var state := _running_worker()
	var full := state.tuning.worker_max_speed
	assert_int(state.characters[0].vx).is_equal(full)
	var slower := state.tuning.with_values({"worker_max_speed": full / 2})

	var next := Sim.step(state, _tick(state, SeatInput.RIGHT, slower))

	assert_int(next.characters[0].vx).is_equal(full / 2)
	assert_int(next.tuning.worker_max_speed).is_equal(full / 2)


func test_a_tuning_change_stays_for_later_ticks_and_earlier_states_keep_theirs() -> void:
	var state := _running_worker()
	var full := state.tuning.worker_max_speed
	var changed := Sim.step(state, _tick(state, SeatInput.RIGHT, state.tuning.with_values(
		{"worker_max_speed": full / 2})))

	var later := changed
	for tick in 20:
		later = Sim.step(later, _tick(later, SeatInput.RIGHT, null))

	assert_int(later.characters[0].vx).is_equal(full / 2)
	assert_int(later.tuning.worker_max_speed).is_equal(full / 2)
	assert_int(state.tuning.worker_max_speed).is_equal(full)
	# The state before the change steps on under its own tuning.
	assert_int(Sim.step(state, _tick(state, SeatInput.RIGHT, null)).characters[0].vx).is_equal(full)


func test_bots_plan_again_under_a_changed_tuning() -> void:
	var config := MatchConfig.new()
	config.map = MapData.load_file("res://data/maps/day.cfg")
	config.seat_teams = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1]
	config.queen_seats = [0, 5]
	config.bot_seats = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	config.tuning = Tuning.load_default()
	config.seed = 11
	var state := Sim.create_match(config)
	for tick in config.tuning.match_countdown_ticks + 50:
		state = Sim.step(state, _neutral(state, null))
	var before := state.navs.duplicate()
	assert_dict(before).is_not_empty()

	# Workers' navigation depends on their speed, flyers' on their collider.
	var changed := state.tuning.with_values({"worker_max_speed": state.tuning.worker_max_speed * 2,
		"winged_width": state.tuning.winged_width + 2 * PX})
	var next := Sim.step(state, _neutral(state, changed))

	# Their navigation, built from the old tuning, is built again from the new;
	# the state before the change keeps its own.
	assert_dict(next.navs).is_not_empty()
	for key in next.navs:
		assert_object(next.navs[key]).is_not_same(before.get(key))
	for key in before:
		assert_object(state.navs[key]).is_same(before[key])


## A Worker on a flat floor who has been running right long enough to be at
## full speed (its acceleration is instant).
func _running_worker() -> MatchState:
	var config := MatchConfig.new()
	config.map = TestMaps.flat_floor(1)
	config.seat_teams = [CharacterState.BLUE]
	config.tuning = Tuning.load_default().with_values(
		{"worker_run_accel": 1000 * PX, "worker_run_decel": 1000 * PX})
	var state := Sim.create_match(config)
	for tick in 5:
		state = Sim.step(state, _tick(state, SeatInput.RIGHT, null))
	return state


func _tick(state: MatchState, horizontal: int, tuning: Tuning) -> TickInput:
	var input := TickInput.of(state.tick, [SeatInput.of(horizontal)])
	input.tuning = tuning
	return input


func _neutral(state: MatchState, tuning: Tuning) -> TickInput:
	var seats: Array[SeatInput] = []
	for c in state.characters:
		seats.append(SeatInput.of(SeatInput.NEUTRAL))
	var input := TickInput.of(state.tick, seats)
	input.tuning = tuning
	return input
