extends GdUnitTestSuite
## The dev build's tools: the overlay, frame-step and slow motion, driven by
## their keys, and how they pace the sim's ticks against the game's 50 Hz
## physics ticks. Driven only through DevTools' keys, tick() and fraction().

## Physics ticks run in each test that counts steps; bounds every loop.
const RUN := 40


func test_a_normal_build_ignores_every_dev_key_and_steps_the_sim_every_physics_tick() -> void:
	var dev := DevTools.of(false)
	for key in [DevTools.OVERLAY_KEY, DevTools.FREEZE_KEY, DevTools.STEP_KEY, DevTools.SLOW_KEY]:
		assert_bool(dev.key(key)).is_false()

	assert_bool(dev.overlay).is_false()
	assert_bool(dev.frozen).is_false()
	assert_int(dev.divisor).is_equal(1)
	assert_array(_steps(dev, RUN)).is_equal(range(RUN))


func test_a_dev_build_steps_the_sim_every_physics_tick_until_a_tool_changes_that() -> void:
	var dev := DevTools.of(true)

	assert_array(_steps(dev, RUN)).is_equal(range(RUN))
	# Between steps the screen goes from the last state to the current one
	# as Godot's own physics interpolation does.
	assert_float(dev.fraction(0.0)).is_equal(0.0)
	assert_float(dev.fraction(0.25)).is_equal(0.25)


func test_the_overlay_key_toggles_the_overlay() -> void:
	var dev := DevTools.of(true)

	assert_bool(dev.key(DevTools.OVERLAY_KEY)).is_true()
	assert_bool(dev.overlay).is_true()
	dev.key(DevTools.OVERLAY_KEY)
	assert_bool(dev.overlay).is_false()


func test_other_keys_are_left_to_the_game() -> void:
	var dev := DevTools.of(true)

	for key in [KEY_ESCAPE, KEY_F8, KEY_F9, KEY_SPACE, KEY_ENTER]:
		assert_bool(dev.key(key)).is_false()
	assert_bool(dev.overlay).is_false()
	assert_bool(dev.frozen).is_false()


func test_freezing_stops_the_sim_and_shows_the_current_state_until_unfrozen() -> void:
	var dev := DevTools.of(true)

	assert_bool(dev.key(DevTools.FREEZE_KEY)).is_true()
	assert_bool(dev.frozen).is_true()
	assert_array(_steps(dev, RUN)).is_empty()
	assert_float(dev.fraction(0.0)).is_equal(1.0)
	assert_float(dev.fraction(0.5)).is_equal(1.0)

	dev.key(DevTools.FREEZE_KEY)
	assert_bool(dev.frozen).is_false()
	assert_array(_steps(dev, RUN)).is_equal(range(RUN))


func test_each_frame_step_press_advances_the_sim_exactly_one_tick() -> void:
	var dev := DevTools.of(true)
	dev.key(DevTools.FREEZE_KEY)

	for press in 5:
		assert_bool(dev.key(DevTools.STEP_KEY)).is_true()
		assert_array(_steps(dev, RUN)).is_equal([0])
	# Frame-stepped states show as they are, not part-way from the last one.
	assert_float(dev.fraction(0.5)).is_equal(1.0)


func test_presses_faster_than_the_physics_tick_each_still_step_once() -> void:
	var dev := DevTools.of(true)
	dev.key(DevTools.FREEZE_KEY)

	dev.key(DevTools.STEP_KEY)
	dev.key(DevTools.STEP_KEY)
	dev.key(DevTools.STEP_KEY)
	# One step a physics tick, so each gets its own state, sound cues and all.
	assert_array(_steps(dev, RUN)).is_equal([0, 1, 2])


func test_frame_step_while_running_freezes_the_sim_after_one_tick() -> void:
	var dev := DevTools.of(true)

	dev.key(DevTools.STEP_KEY)
	assert_bool(dev.frozen).is_true()
	assert_array(_steps(dev, RUN)).is_equal([0])


func test_unfreezing_drops_steps_not_yet_taken() -> void:
	var dev := DevTools.of(true)
	dev.key(DevTools.FREEZE_KEY)
	dev.key(DevTools.STEP_KEY)
	dev.key(DevTools.STEP_KEY)
	dev.key(DevTools.FREEZE_KEY)
	dev.key(DevTools.FREEZE_KEY)

	assert_array(_steps(dev, RUN)).is_empty()


func test_slow_motion_cycles_through_its_speeds_and_back_to_full_speed() -> void:
	var dev := DevTools.of(true)
	var seen: Array[int] = []
	for press in DevTools.SLOW_DIVISORS.size():
		assert_bool(dev.key(DevTools.SLOW_KEY)).is_true()
		seen.append(dev.divisor)

	assert_array(seen).is_equal([2, 4, 10, 1])
	assert_array(DevTools.SLOW_DIVISORS).is_equal([1, 2, 4, 10])


func test_slow_motion_steps_the_sim_once_every_divisor_physics_ticks() -> void:
	for divisor in [2, 4, 10]:
		var dev := _slowed(divisor)
		var expected := []
		for step in range(divisor - 1, RUN, divisor):
			expected.append(step)

		assert_array(_steps(dev, RUN)).is_equal(expected)


func test_slow_motion_moves_the_screen_evenly_from_one_state_to_the_next() -> void:
	var dev := _slowed(4)
	# Run up to a step, so the screen is just leaving the last state.
	_run_to_step(dev)
	var shown: Array[float] = []
	for physics_tick in 4:
		for part in [0.0, 0.5]:
			shown.append(dev.fraction(part))
		if dev.tick():
			break

	assert_array(shown).is_equal([0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875])
	# It reaches the current state as the next one is stepped to, so the next
	# step starts where this one ended: no jump, no hold.
	assert_float(dev.fraction(0.0)).is_equal(0.0)


func test_changing_speed_keeps_the_screen_where_it_was() -> void:
	var dev := _slowed(2)
	_run_to_step(dev)
	dev.tick()
	assert_float(dev.fraction(0.0)).is_equal(0.5)

	dev.key(DevTools.SLOW_KEY)
	assert_int(dev.divisor).is_equal(4)
	assert_float(dev.fraction(0.0)).is_equal(0.5)
	# And steps when that speed's step is due: two physics ticks on.
	assert_array(_steps(dev, RUN).slice(0, 2)).is_equal([1, 5])


func test_frame_step_works_in_slow_motion_and_unfreezing_keeps_the_slow_speed() -> void:
	var dev := _slowed(4)
	dev.key(DevTools.FREEZE_KEY)

	dev.key(DevTools.STEP_KEY)
	assert_array(_steps(dev, RUN)).is_equal([0])
	dev.key(DevTools.FREEZE_KEY)
	assert_int(dev.divisor).is_equal(4)
	assert_array(_steps(dev, 12)).is_equal([3, 7, 11])


## Runs physics ticks up to and including one the sim steps on.
func _run_to_step(dev: DevTools) -> void:
	for i in RUN:
		if dev.tick():
			return
	fail("the sim never stepped")


## A dev build in slow motion at 1/`divisor` speed.
func _slowed(divisor: int) -> DevTools:
	var dev := DevTools.of(true)
	for press in DevTools.SLOW_DIVISORS.size():
		if dev.divisor == divisor:
			break
		dev.key(DevTools.SLOW_KEY)
	assert_int(dev.divisor).is_equal(divisor)
	return dev


## Runs `physics_ticks` physics ticks; the ones (from 0) on which the sim
## stepped.
func _steps(dev: DevTools, physics_ticks: int) -> Array:
	var stepped := []
	for i in physics_ticks:
		if dev.tick():
			stepped.append(i)
	return stepped
