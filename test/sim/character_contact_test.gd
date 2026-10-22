extends GdUnitTestSuite
## Ten Seats, Bumps between enemies and springboarding off heads, driven only
## through Sim.create_match and Sim.step.

const PX := 1000
const FLOOR_Y := 960 * PX
const BLUE := CharacterState.BLUE
const GOLD := CharacterState.GOLD


func test_a_match_on_day_has_ten_characters_each_with_its_seat_and_team() -> void:
	var teams: Array[int] = [BLUE, GOLD, BLUE, GOLD, BLUE, GOLD, BLUE, GOLD, BLUE, GOLD]
	var config := MatchConfig.new()
	config.map = MapData.load_file("res://data/maps/day.cfg")
	config.seat_teams = teams
	config.tuning = _tuning()

	var state := Sim.create_match(config)

	assert_int(state.characters.size()).is_equal(10)
	for seat in 10:
		assert_int(state.characters[seat].seat).is_equal(seat)
		assert_int(state.characters[seat].team).is_equal(teams[seat])


func test_two_workers_running_into_each_other_bump_apart_and_neither_dies() -> void:
	var state := _match([Vector2i(800, 960)], [Vector2i(1120, 960)])

	state = _until_bumped(state, SeatInput.RIGHT, SeatInput.LEFT)
	var gap := _gap(state)
	var blue := state.characters[0]
	var gold := state.characters[1]
	assert_int(blue.vx).is_less(0)
	assert_int(gold.vx).is_greater(0)
	assert_int(blue.x).is_less(gold.x)

	state = _hold(state, SeatInput.RIGHT, SeatInput.LEFT, state.tuning.bump_ticks - 1)

	assert_int(_gap(state)).is_greater(gap)
	for c in state.characters:
		assert_int(c.y).is_equal(FLOOR_Y)


func test_a_bumped_worker_cannot_turn_during_the_bump() -> void:
	var state := _match([Vector2i(800, 960)], [Vector2i(1120, 960)])
	state = _until_bumped(state, SeatInput.RIGHT, SeatInput.LEFT)

	state = _hold(state, SeatInput.LEFT, SeatInput.RIGHT, state.tuning.bump_ticks - 1)
	assert_int(state.characters[0].facing).is_equal(SeatInput.RIGHT)
	assert_int(state.characters[1].facing).is_equal(SeatInput.LEFT)

	state = _hold(state, SeatInput.LEFT, SeatInput.RIGHT, 2)
	assert_int(state.characters[0].facing).is_equal(SeatInput.LEFT)
	assert_int(state.characters[1].facing).is_equal(SeatInput.RIGHT)


func test_running_into_a_standing_worker_shoves_it() -> void:
	var state := _match([Vector2i(800, 960)], [Vector2i(1000, 960)])
	var gold_x := state.characters[1].x

	state = _until_bumped(state, SeatInput.RIGHT, SeatInput.NEUTRAL)
	state = _hold(state, SeatInput.RIGHT, SeatInput.NEUTRAL, 5)

	assert_int(state.characters[1].x).is_greater(gold_x)


func test_teammates_pass_through_each_other() -> void:
	var state := _match([Vector2i(800, 960), Vector2i(1120, 960)], [])

	state = _hold(state, SeatInput.RIGHT, SeatInput.LEFT, 60)

	assert_int(state.characters[0].x).is_greater(state.characters[1].x)


func test_a_worker_falling_onto_an_enemy_stands_on_its_head() -> void:
	var state := _stand_on_head()

	state = _hold(state, SeatInput.NEUTRAL, SeatInput.NEUTRAL, 20)

	var top := state.characters[0]
	var under := state.characters[1]
	assert_int(top.y).is_equal(under.y - state.tuning.worker_height)
	assert_int(under.x).is_equal(960 * PX)
	assert_int(under.y).is_equal(FLOOR_Y)


func test_jumping_shortly_after_landing_on_a_head_goes_higher_than_a_ground_jump() -> void:
	var ground := _match([Vector2i(400, 960)], [])
	var head := _stand_on_head()

	assert_int(_jump_rise(head)).is_greater(_jump_rise(ground))


func test_jumping_off_a_head_after_the_springboard_window_is_a_normal_jump() -> void:
	var ground := _match([Vector2i(400, 960)], [])
	var head := _stand_on_head()
	head = _hold(head, SeatInput.NEUTRAL, SeatInput.NEUTRAL, head.tuning.worker_springboard_ticks)

	assert_int(_jump_rise(head)).is_equal(_jump_rise(ground))


## A Blue Worker dropped onto a Gold Worker's head, from the tick it lands.
func _stand_on_head() -> MatchState:
	var state := _match([Vector2i(960, 600)], [Vector2i(960, 960)])
	var height := state.tuning.worker_height
	for i in 100:
		state = _hold(state, SeatInput.NEUTRAL, SeatInput.NEUTRAL, 1)
		if state.characters[0].y == FLOOR_Y - height:
			return state
	fail("The Worker never landed on the head")
	return state


## How far the Blue Worker (Seat 0) rises in a jump pressed on the next tick
## and held.
func _jump_rise(state: MatchState) -> int:
	var start := state.characters[0].y
	var apex := start
	for i in 60:
		var seats: Array[SeatInput] = []
		for c in state.characters:
			seats.append(SeatInput.of(SeatInput.NEUTRAL, false, c.seat == 0))
		state = Sim.step(state, TickInput.of(state.tick, seats))
		apex = mini(apex, state.characters[0].y)
	return start - apex


## Steps Blue (Seat 0) and Gold (Seat 1) with the given sticks until the tick
## their horizontal speeds are first changed by contact.
func _until_bumped(state: MatchState, blue: int, gold: int) -> MatchState:
	for i in 200:
		var next := _hold(state, blue, gold, 1)
		var b := next.characters[0]
		var g := next.characters[1]
		if b.vx != blue * next.tuning.worker_max_speed or g.vx != gold * next.tuning.worker_max_speed:
			return next
		state = next
	fail("The Workers never bumped")
	return state


func _gap(state: MatchState) -> int:
	return state.characters[1].x - state.characters[0].x


func _tuning() -> Tuning:
	return Tuning.load_default().with_values(
		{"worker_run_accel": 1000 * PX, "worker_run_decel": 1000 * PX})


## Seats in order: Blue spawns first, then Gold.
func _match(blue_px: Array[Vector2i], gold_px: Array[Vector2i]) -> MatchState:
	var config := MatchConfig.new()
	config.map = TestMaps.build(TestMaps.floor_tiles(), blue_px, gold_px)
	var teams: Array[int] = []
	for i in blue_px.size():
		teams.append(BLUE)
	for i in gold_px.size():
		teams.append(GOLD)
	config.seat_teams = teams
	config.tuning = _tuning()
	return Sim.create_match(config)


## Holds Seat 0's stick at `first` and Seat 1's (if any) at `second`.
func _hold(state: MatchState, first: int, second: int, ticks: int) -> MatchState:
	for i in ticks:
		var seats: Array[SeatInput] = [SeatInput.of(first)]
		if state.characters.size() > 1:
			seats.append(SeatInput.of(second))
		state = Sim.step(state, TickInput.of(state.tick, seats))
	return state
