extends GdUnitTestSuite
## Famine: taking the Map's last Berry starts a countdown, at the end of which
## every Berry pile refills. Driven only through Sim.create_match and Sim.step.
##
## Every Map here is a floor (top at y 960 px) with one Berry pile at 300 px,
## all of Blue's Hive holes at the pile (so a Worker standing there picks up
## and deposits on alternate ticks) and a Warrior Gate at 600 px. The Hive has
## 18 holes, so filling it takes three piles' worth.
## Blue Seats come first, then Gold.

const PX := 1000
const BLUE := CharacterState.BLUE
const GOLD := CharacterState.GOLD
const PILE_X := 300 * PX
const GATE_X := 600 * PX


func test_taking_the_last_berry_on_the_map_starts_famine() -> void:
	var state := _match([Vector2i(300, 960)], [])
	assert_int(state.tuning.famine_countdown_ticks).is_equal(4500)

	for i in 5:
		state = _until_event(state, {}, MatchEvent.Type.BERRY_DEPOSIT)
		assert_int(state.famine_ticks).is_equal(0)
	state = _until_event(state, {}, MatchEvent.Type.BERRY_DEPOSIT)

	assert_int(_count(state, BerryState.Where.HIVE)).is_equal(6)
	assert_int(_count_events(state, MatchEvent.Type.FAMINE_START)).is_equal(1)
	assert_int(state.famine_ticks).is_equal(state.tuning.famine_countdown_ticks)


func test_when_the_countdown_ends_every_pile_is_back_to_its_starting_count_and_famine_ends() -> void:
	var start := _match([Vector2i(300, 960)], [])
	var state := _until_event(start, {}, MatchEvent.Type.FAMINE_START)
	var t := state.tuning

	for i in t.famine_countdown_ticks - 1:
		state = _step(state, {})
		assert_int(_count_events(state, MatchEvent.Type.FAMINE_START)).is_equal(0)
		assert_int(_count_events(state, MatchEvent.Type.FAMINE_END)).is_equal(0)
		assert_int(_count(state, BerryState.Where.PILE)).is_equal(0)
	assert_int(state.famine_ticks).is_equal(1)
	state = _step(state, {})

	assert_int(_count_events(state, MatchEvent.Type.FAMINE_END)).is_equal(1)
	assert_int(state.famine_ticks).is_equal(0)
	assert_int(_count(state, BerryState.Where.HIVE)).is_equal(6)
	assert_array(_pile_positions(state)).contains_exactly_in_any_order(_pile_positions(start))
	# A copy taken as Famine ends is the same state.
	assert_str(state.copy().fingerprint()).is_equal(state.fingerprint())

	# The refilled pile can be taken again, and starts the next Famine.
	state = _until_event(state, {}, MatchEvent.Type.FAMINE_START)
	assert_int(_count(state, BerryState.Where.HIVE)).is_equal(12)


func test_carried_and_loose_berries_are_not_taken() -> void:
	# Blue's Worker in Seat 1 takes a Berry from the pile and walks it into
	# Gold's Warrior, dying and dropping it loose, while Seat 0 deposits the
	# other five.
	var state := _match([Vector2i(300, 960), Vector2i(300, 960)], [Vector2i(900, 960)], [2])
	var away := {1: SeatInput.of(SeatInput.RIGHT)}
	state = _step(state, away)
	assert_int(state.characters[1].berry).is_not_equal(-1)
	for i in 20:
		state = _step(state, away)
	assert_int(_count(state, BerryState.Where.HIVE)).is_equal(5)
	assert_int(_count(state, BerryState.Where.CARRIED)).is_equal(1)
	assert_int(state.famine_ticks).is_equal(0)

	state = _until_event(state, {1: SeatInput.of(SeatInput.RIGHT)}, MatchEvent.Type.DEATH)
	assert_int(_count(state, BerryState.Where.LOOSE)).is_equal(1)
	# Gold's Warrior walks off to the right; Seat 0 fetches the loose Berry.
	var warrior_away := {2: SeatInput.of(SeatInput.RIGHT)}
	for i in 100:
		state = _step(state, warrior_away)
		assert_int(state.famine_ticks).is_equal(0)
	var loose := state.berries.filter(func(b: BerryState) -> bool: return b.where == BerryState.Where.LOOSE)
	state = _go_to(state, 0, loose[0].x, warrior_away)
	state = _step(state, warrior_away)
	assert_int(state.characters[0].berry).is_not_equal(-1)
	assert_int(state.famine_ticks).is_equal(0)

	state = _go_to(state, 0, PILE_X, warrior_away)
	state = _step(state, warrior_away)

	assert_int(_count(state, BerryState.Where.HIVE)).is_equal(6)
	assert_int(state.famine_ticks).is_greater(0)


func test_spending_the_last_berry_at_a_gate_starts_famine() -> void:
	# Seat 1 takes a Berry to the Warrior Gate while Seat 0 deposits the rest.
	var state := _match([Vector2i(300, 960), Vector2i(300, 960)], [])
	state = _go_to(state, 1, GATE_X)
	assert_int(_count(state, BerryState.Where.HIVE)).is_equal(5)
	state = _until_event(state, {}, MatchEvent.Type.TRANSFORM_START)
	var t := state.tuning

	for i in t.gate_hold_ticks - 1:
		state = _step(state, {})
		assert_int(state.famine_ticks).is_equal(0)
	state = _step(state, {})

	assert_int(_count(state, BerryState.Where.SPENT)).is_equal(1)
	assert_int(_count_events(state, MatchEvent.Type.FAMINE_START)).is_equal(1)

	# The spent Berry comes back in the refilled pile, beside five new ones.
	state = _until_event(state, {}, MatchEvent.Type.FAMINE_END)
	assert_int(_count(state, BerryState.Where.SPENT)).is_equal(0)
	assert_int(_count(state, BerryState.Where.PILE)).is_equal(6)
	assert_int(state.berries.size()).is_equal(11)


func test_a_map_without_berries_has_no_famine() -> void:
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(300, 960)])
	var config := MatchConfig.new()
	config.map = MapData.from_config(cfg)
	config.seat_teams = [BLUE]
	config.tuning = Tuning.load_default()
	var state := Sim.create_match(config)

	for i in 20:
		state = _step(state, {})
		assert_int(state.famine_ticks).is_equal(0)
		assert_array(state.events).is_empty()


## A Match on the Famine test Map, not yet stepped. `warriors` Seats start as
## Warriors.
func _match(blue_px: Array[Vector2i], gold_px: Array[Vector2i], warriors: Array[int] = []) -> MatchState:
	var cfg := TestMaps.config(TestMaps.floor_tiles(), blue_px, gold_px)
	cfg.set_value("berries", "piles", [Vector2i(300, 960)])
	var holes: Array[Vector2i] = []
	for i in 18:
		holes.append(Vector2i(300, 940))
	cfg.set_value("hive", "blue_holes", holes)
	cfg.set_value("gates", "warrior", [Vector2i(600, 960)])
	var config := MatchConfig.new()
	config.map = MapData.from_config(cfg)
	var teams: Array[int] = []
	for i in blue_px.size():
		teams.append(BLUE)
	for i in gold_px.size():
		teams.append(GOLD)
	config.seat_teams = teams
	config.warrior_seats = warriors
	config.tuning = Tuning.load_default().with_values(
		{"worker_run_accel": 1000 * PX, "worker_run_decel": 1000 * PX})
	return Sim.create_match(config)


## Walks `seat` toward x `to` (others given `inputs`) until one more tick
## would take it past, for at most 600 ticks. It stops on the next neutral
## tick.
func _go_to(state: MatchState, seat: int, to: int, inputs := {}) -> MatchState:
	for i in 600:
		var c := state.characters[seat]
		var dx := to - c.x
		if dx == 0 or absi(dx) < absi(c.vx):
			return state
		var held := inputs.duplicate()
		held[seat] = SeatInput.of(signi(dx))
		state = _step(state, held)
	fail("Seat %d never reached x %d" % [seat, to])
	return state


func _step(state: MatchState, inputs: Dictionary) -> MatchState:
	var seats: Array[SeatInput] = []
	for c in state.characters:
		seats.append(inputs.get(c.seat, SeatInput.of(SeatInput.NEUTRAL)))
	return Sim.step(state, TickInput.of(state.tick, seats))


## Steps with `inputs` until the tick an event of `type` happens, for at most
## 6000 ticks.
func _until_event(state: MatchState, inputs: Dictionary, type: MatchEvent.Type) -> MatchState:
	for i in 6000:
		state = _step(state, inputs)
		if _count_events(state, type) > 0:
			return state
	fail("No %s event" % MatchEvent.Type.keys()[type])
	return state


func _count_events(state: MatchState, type: MatchEvent.Type) -> int:
	return state.events.filter(func(e: MatchEvent) -> bool: return e.type == type).size()


func _count(state: MatchState, where: BerryState.Where) -> int:
	return state.berries.filter(func(b: BerryState) -> bool: return b.where == where).size()


## The positions of the Berries sitting in piles, as Vector2i.
func _pile_positions(state: MatchState) -> Array:
	var result := []
	for b in state.berries:
		if b.where == BerryState.Where.PILE:
			result.append(Vector2i(b.x, b.y))
	return result
