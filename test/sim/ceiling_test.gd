extends GdUnitTestSuite
## Hitting a ceiling: slow hits stick, fast hits ricochet. Driven only through
## Sim.create_match and Sim.step.

const PX := 1000
const FLOOR_Y := 960 * PX
## Bottom of the ceiling in the test Maps below.
const CEILING_Y := 840 * PX

## A ceiling across the middle of the screen, 80 px above a standing Worker's
## head.
const LOW_CEILING: Array[String] = [
	"|................",
	"|................",
	"|................",
	"|................",
	"|................",
	"|................",
	"|....######......",
	"|................",
	"|################",
]


func test_a_slow_hit_sticks_for_the_stick_duration_then_drops_off() -> void:
	# Any rise up to the jump speed is below this threshold.
	var state := _match(_tuning().with_values({"ceiling_ricochet_threshold": 1000 * PX}))
	var t := state.tuning

	state = _jump_to_ceiling(state)
	var stuck_y := state.characters[0].y
	assert_int(stuck_y).is_equal(CEILING_Y + t.worker_height)

	for i in t.ceiling_stick_ticks:
		state = _step(state, SeatInput.NEUTRAL, false)
		assert_int(state.characters[0].y).is_equal(stuck_y)

	state = _step(state, SeatInput.NEUTRAL, false)
	assert_int(state.characters[0].y).is_greater(stuck_y)
	state = _hold(state, SeatInput.NEUTRAL, false, 100)
	assert_int(state.characters[0].y).is_equal(FLOOR_Y)


func test_a_fast_hit_ricochets_downward() -> void:
	# The jump is still rising faster than 1 px/tick when it reaches the ceiling.
	var state := _match(_tuning().with_values({"ceiling_ricochet_threshold": 1 * PX}))

	state = _jump_to_ceiling(state)

	assert_int(state.characters[0].vy).is_equal(state.tuning.ceiling_ricochet_speed)
	var y := state.characters[0].y
	state = _step(state, SeatInput.NEUTRAL, false)
	assert_int(state.characters[0].y).is_greater(y)


func test_button_presses_while_stuck_have_no_effect() -> void:
	var tuning := _tuning().with_values({"ceiling_ricochet_threshold": 1000 * PX})
	var pressed := _jump_to_ceiling(_match(tuning))
	var untouched := pressed.copy()
	var t := tuning

	for i in t.ceiling_stick_ticks + 10:
		pressed = _step(pressed, SeatInput.NEUTRAL, i % 2 == 1)
		untouched = _step(untouched, SeatInput.NEUTRAL, false)
		assert_int(pressed.characters[0].y).is_equal(untouched.characters[0].y)
		assert_int(pressed.characters[0].vy).is_equal(untouched.characters[0].vy)


func test_the_speed_upgrade_raises_the_ricochet_threshold() -> void:
	assert_int(Tuning.load_default().ceiling_speed_ricochet_threshold).is_greater(
		Tuning.load_default().ceiling_ricochet_threshold)
	# The jump reaches the ceiling rising faster than 1 px/tick but slower than
	# 1000.
	var tuning := _tuning().with_values(
		{"ceiling_ricochet_threshold": 1 * PX, "ceiling_speed_ricochet_threshold": 1000 * PX})

	var worker := _jump_to_ceiling(_match(tuning))
	var speed_worker := _jump_to_ceiling(_match(tuning, true))

	assert_int(worker.characters[0].vy).is_equal(tuning.ceiling_ricochet_speed)
	assert_int(speed_worker.characters[0].stuck_ticks).is_equal(tuning.ceiling_stick_ticks)
	assert_int(speed_worker.characters[0].vy).is_equal(0)


func test_running_out_from_under_the_ceiling_drops_off_early() -> void:
	var state := _match(_tuning().with_values(
		{"ceiling_ricochet_threshold": 1000 * PX, "ceiling_stick_ticks": 100}))
	state = _jump_to_ceiling(state)
	var stuck_y := state.characters[0].y

	# The ceiling ends at x 1200 px. Running right clears it after 52 ticks,
	# long before the 100-tick stick would time out.
	state = _hold(state, SeatInput.RIGHT, false, 60)

	assert_int(state.characters[0].x - state.tuning.worker_width / 2).is_greater(1200 * PX)
	assert_int(state.characters[0].y).is_greater(stuck_y)


## Holds a jump from the floor until the Worker's head reaches the ceiling and
## returns the state from that tick.
func _jump_to_ceiling(state: MatchState) -> MatchState:
	var head_room := state.characters[0].y - state.tuning.worker_height - CEILING_Y
	assert_int(head_room).is_greater(0)
	for i in 50:
		state = _step(state, SeatInput.NEUTRAL, true)
		if state.characters[0].y - state.tuning.worker_height == CEILING_Y:
			return state
	fail("The jump never reached the ceiling")
	return state


func _tuning() -> Tuning:
	return Tuning.load_default().with_values(
		{"worker_run_accel": 1000 * PX, "worker_run_decel": 1000 * PX})


## A Match with one Blue Worker under the ceiling; a Speed Worker with `speed`.
func _match(tuning: Tuning, speed := false) -> MatchState:
	var config := MatchConfig.new()
	config.map = TestMaps.build(LOW_CEILING, [Vector2i(960, 960)])
	config.seat_teams = [CharacterState.BLUE]
	if speed:
		config.speed_seats = [0]
	config.tuning = tuning
	return Sim.create_match(config)


func _step(state: MatchState, horizontal: int, button: bool) -> MatchState:
	return Sim.step(state, TickInput.of(state.tick, [SeatInput.of(horizontal, false, button)]))


func _hold(state: MatchState, horizontal: int, button: bool, ticks: int) -> MatchState:
	for i in ticks:
		state = _step(state, horizontal, button)
	return state
