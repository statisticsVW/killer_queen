extends GdUnitTestSuite
## The start of a Match: during the countdown the Map's starting barriers are
## solid, and once it ends they are gone. Driven only through Sim.create_match
## and Sim.step.
##
## Test Maps are a floor (top at y 960 px) with the barriers each test adds.
## Blue Seats come first, then Gold.

const PX := 1000
const BLUE := CharacterState.BLUE
const GOLD := CharacterState.GOLD
const COUNTDOWN := 100


func test_during_the_countdown_a_starting_barrier_stops_characters_and_then_it_is_gone() -> void:
	# A barrier wall from x 1080 to 1200 px, all the way up.
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(700, 960), Vector2i(700, 960)])
	cfg.set_value("barriers", "rects", [Rect2i(1080, 0, 120, 960)])
	var state := _match(cfg, [1])
	var right := {0: SeatInput.of(SeatInput.RIGHT), 1: SeatInput.of(SeatInput.RIGHT)}
	var t := state.tuning

	state = _hold(state, right, COUNTDOWN)

	assert_int(state.countdown_ticks()).is_equal(0)
	assert_int(state.characters[0].x).is_equal(1080 * PX - t.worker_width / 2)
	assert_int(state.characters[1].x).is_equal(1080 * PX - t.winged_width / 2)

	state = _step(state, right)

	assert_int(state.characters[0].x).is_greater(1080 * PX - t.worker_width / 2)
	assert_int(state.characters[1].x).is_greater(1080 * PX - t.winged_width / 2)

	state = _hold(state, right, 40)

	assert_int(state.characters[0].x).is_greater(1200 * PX)
	assert_int(state.characters[1].x).is_greater(1200 * PX)


func test_a_worker_stands_on_a_barrier_over_a_gap_until_the_countdown_ends() -> void:
	# A ledge at y 480 px with a gap from x 720 to 1200 px that a barrier fills.
	var tiles := TestMaps.floor_tiles()
	tiles[4] = "|######....######"
	var cfg := TestMaps.config(tiles, [Vector2i(600, 480)])
	cfg.set_value("barriers", "rects", [Rect2i(720, 480, 480, 120)])
	var state := _match(cfg, [])

	state = _hold(state, {0: SeatInput.of(SeatInput.RIGHT)}, 40)
	state = _hold(state, {}, COUNTDOWN - 40)

	assert_int(state.characters[0].x).is_between(800 * PX, 1100 * PX)
	assert_int(state.characters[0].y).is_equal(480 * PX)

	state = _hold(state, {}, 30)

	assert_int(state.characters[0].y).is_greater(600 * PX)


func test_a_queen_cannot_fly_up_through_a_barrier_until_the_countdown_ends() -> void:
	# A barrier across the whole Map from y 480 to 600 px.
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(960, 960)])
	cfg.set_value("barriers", "rects", [Rect2i(0, 480, 1920, 120)])
	var state := _match(cfg, [0])
	var t := state.tuning
	var highest := 960 * PX

	for i in COUNTDOWN:
		state = _step(state, {0: SeatInput.of(SeatInput.NEUTRAL, false, i % 4 < 2)})
		highest = mini(highest, state.characters[0].y)

	assert_int(highest).is_equal(600 * PX + t.winged_height)

	for i in 200:
		state = _step(state, {0: SeatInput.of(SeatInput.NEUTRAL, false, i % 4 < 2)})
		highest = mini(highest, state.characters[0].y)

	assert_int(highest).is_less(480 * PX)


func test_a_queen_sticks_under_a_barrier_as_under_a_ceiling() -> void:
	# A barrier across the whole Map from y 480 to 600 px.
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(960, 960)])
	cfg.set_value("barriers", "rects", [Rect2i(0, 480, 1920, 120)])
	var state := _match(cfg, [0], {"ceiling_ricochet_threshold": 100 * PX})
	var t := state.tuning
	var flush := 600 * PX + t.winged_height
	for i in COUNTDOWN / 2:
		if state.characters[0].y == flush:
			break
		state = _step(state, {0: SeatInput.of(SeatInput.NEUTRAL, false, i % 4 < 2)})
	assert_int(state.characters[0].y).is_equal(flush)

	state = _hold(state, {}, t.ceiling_stick_ticks - 1)

	assert_int(state.countdown_ticks()).is_greater(0)
	assert_int(state.characters[0].y).is_equal(flush)


func test_a_loose_berry_rests_on_a_barrier_until_the_countdown_ends() -> void:
	# A ledge at y 480 px with a gap from x 720 to 1200 px that a barrier fills.
	# A Blue Worker stands on the barrier, on a Berry pile; the Gold Queen
	# walks into it and kills it, and its Berry drops onto the barrier.
	var tiles := TestMaps.floor_tiles()
	tiles[4] = "|######....######"
	var cfg := TestMaps.config(tiles, [Vector2i(960, 480)], [Vector2i(1100, 480)])
	cfg.set_value("barriers", "rects", [Rect2i(720, 480, 480, 120)])
	cfg.set_value("berries", "piles", [Vector2i(960, 480)])
	var state := _match(cfg, [1])
	state = _step(state, {})
	var berry := state.characters[0].berry
	assert_int(berry).is_not_equal(-1)
	for i in COUNTDOWN / 2:
		if not state.characters[0].alive:
			break
		state = _step(state, {1: SeatInput.of(SeatInput.LEFT)})
	assert_int(state.berries[berry].where).is_equal(BerryState.Where.LOOSE)

	state = _hold(state, {}, state.countdown_ticks())

	assert_int(state.berries[berry].y).is_equal(480 * PX)

	state = _hold(state, {}, 30)

	assert_int(state.berries[berry].y).is_greater(600 * PX)


func test_on_day_the_starting_barriers_hold_everyone_on_the_hive_level_until_the_countdown_ends() -> void:
	var config := MatchConfig.new()
	config.map = MapData.load_file("res://data/maps/day.cfg")
	config.seat_teams = [BLUE, BLUE, BLUE, BLUE, BLUE, GOLD, GOLD, GOLD, GOLD, GOLD]
	config.queen_seats = [0, 5]
	config.tuning = Tuning.load_default()
	var state := Sim.create_match(config)
	var countdown := state.countdown_ticks()
	assert_int(countdown).is_greater(0)

	# Even Seats run left and odd Seats right, pressing the button every few
	# ticks, so between them they cross every gap in the Hives' level.
	var lowest := 0
	for i in countdown:
		state = _step(state, _spread(state, i % 6 < 3))
		lowest = maxi(lowest, _lowest_feet(state))

	assert_int(state.countdown_ticks()).is_equal(0)
	assert_int(lowest).is_less_equal(216 * PX)

	state = _hold(state, _spread(state, false), 150)

	assert_int(_lowest_feet(state)).is_greater(240 * PX)


## A Match on the Map `cfg` describes, with a COUNTDOWN-tick countdown and
## instant running. `tuning` overrides more constants.
func _match(cfg: ConfigFile, queens: Array[int], tuning := {}) -> MatchState:
	var config := MatchConfig.new()
	config.map = MapData.from_config(cfg)
	var teams: Array[int] = []
	for i in config.map.spawns[BLUE].size():
		teams.append(BLUE)
	for i in config.map.spawns[GOLD].size():
		teams.append(GOLD)
	config.seat_teams = teams
	config.queen_seats = queens
	var overrides := {
		"match_countdown_ticks": COUNTDOWN,
		"worker_run_accel": 1000 * PX,
		"worker_run_decel": 1000 * PX,
	}
	overrides.merge(tuning, true)
	config.tuning = Tuning.load_default().with_values(overrides)
	var state := Sim.create_match(config)
	assert_int(state.countdown_ticks()).is_equal(COUNTDOWN)
	return state


## Even Seats hold left, odd Seats right.
func _spread(state: MatchState, button: bool) -> Dictionary:
	var inputs := {}
	for c in state.characters:
		inputs[c.seat] = SeatInput.of(SeatInput.LEFT if c.seat % 2 == 0 else SeatInput.RIGHT, false, button)
	return inputs


## The y of the lowest living character's feet.
func _lowest_feet(state: MatchState) -> int:
	var lowest := 0
	for c in state.characters:
		if c.alive:
			lowest = maxi(lowest, c.y)
	return lowest


func _tick_input(state: MatchState, inputs: Dictionary) -> TickInput:
	var seats: Array[SeatInput] = []
	for c in state.characters:
		seats.append(inputs.get(c.seat, SeatInput.of(SeatInput.NEUTRAL)))
	return TickInput.of(state.tick, seats)


func _step(state: MatchState, inputs: Dictionary) -> MatchState:
	return Sim.step(state, _tick_input(state, inputs))


func _hold(state: MatchState, inputs: Dictionary, ticks: int) -> MatchState:
	for i in ticks:
		state = _step(state, inputs)
	return state
