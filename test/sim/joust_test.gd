extends GdUnitTestSuite
## Jousts between Queens and Warriors, Queen Eggs and the Military Win, driven
## only through Sim.create_match and Sim.step.
##
## Blue Seats come first, then Gold. Warriors are made with the dev command on
## the Match's first tick.

const PX := 1000
const FLOOR_Y := 960 * PX
const BLUE := CharacterState.BLUE
const GOLD := CharacterState.GOLD


func test_the_higher_of_two_jousting_warriors_kills_the_lower() -> void:
	# Blue above Gold, then Gold above Blue: Seat order doesn't decide it.
	for blue_on_top in [true, false]:
		var high := Vector2i(940, 700)
		var low := Vector2i(960, 960)
		var state := _match([high if blue_on_top else low], [low if blue_on_top else high], [], [0, 1])
		var lower := 1 if blue_on_top else 0

		state = _until_dead(state, {}, lower)

		assert_bool(state.characters[1 - lower].alive).is_true()
		assert_bool(_has_event(state, MatchEvent.Type.KILL, 1 - lower, lower)).is_true()


func test_level_contact_from_behind_kills() -> void:
	# Both stand facing right; the one on the left runs into the other's back.
	for blue_behind in [true, false]:
		var behind := Vector2i(700, 960)
		var ahead := Vector2i(960, 960)
		var state := _match([behind if blue_behind else ahead], [ahead if blue_behind else behind],
			[], [0, 1])
		var attacker := 0 if blue_behind else 1

		state = _until_dead(state, {attacker: SeatInput.of(SeatInput.RIGHT)}, 1 - attacker)

		assert_bool(state.characters[attacker].alive).is_true()
		assert_int(state.characters[attacker].y).is_equal(FLOOR_Y)


func test_a_level_face_to_face_joust_bumps_and_blocks_turning_for_the_no_turn_window() -> void:
	var state := _match([Vector2i(700, 960)], [Vector2i(1220, 960)], [], [0, 1])
	var charge := {0: SeatInput.of(SeatInput.RIGHT), 1: SeatInput.of(SeatInput.LEFT)}
	var retreat := {0: SeatInput.of(SeatInput.LEFT), 1: SeatInput.of(SeatInput.RIGHT)}
	for i in 200:
		state = _step(state, charge)
		if state.characters[0].bump_ticks > 0:
			break
	assert_int(state.characters[0].vx).is_less(0)
	assert_int(state.characters[1].vx).is_greater(0)

	state = _hold(state, retreat, state.tuning.bump_ticks - 1)
	assert_int(state.characters[0].facing).is_equal(SeatInput.RIGHT)
	assert_int(state.characters[1].facing).is_equal(SeatInput.LEFT)
	state = _hold(state, retreat, 2)

	assert_int(state.characters[0].facing).is_equal(SeatInput.LEFT)
	assert_int(state.characters[1].facing).is_equal(SeatInput.RIGHT)
	for c in state.characters:
		assert_bool(c.alive).is_true()


func test_back_to_back_contact_bumps() -> void:
	# The Blue Warrior faces right. Gold Warrior 1 charges it face to face and
	# Bumps it back, still facing right, into Gold Warrior 2, who faces left.
	var state := _match([Vector2i(700, 960)], [Vector2i(820, 960), Vector2i(640, 960)], [], [0, 1, 2])
	state = _step(state, {1: SeatInput.of(SeatInput.LEFT), 2: SeatInput.of(SeatInput.LEFT)})
	for i in 100:
		state = _step(state, {1: SeatInput.of(SeatInput.LEFT)})
		if state.characters[0].bump_ticks > 0:
			break
	var backs_bumped := false

	for i in 30:
		state = _step(state, {})
		backs_bumped = backs_bumped or state.characters[2].bump_ticks > 0

	assert_bool(backs_bumped).is_true()
	assert_int(state.characters[0].facing).is_equal(SeatInput.RIGHT)
	assert_int(state.characters[2].facing).is_equal(SeatInput.LEFT)
	for c in state.characters:
		assert_bool(c.alive).is_true()


func test_a_dead_warrior_respawns_as_a_worker() -> void:
	var state := _match([Vector2i(960, 960)], [Vector2i(940, 700)], [], [0, 1])
	state = _until_dead(state, {}, 0)

	state = _hold(state, {}, state.tuning.respawn_ticks)

	var worker := state.characters[0]
	assert_bool(worker.alive).is_true()
	assert_int(worker.role).is_equal(CharacterState.Role.WORKER)
	assert_int(worker.x).is_equal(960 * PX)


func test_queen_deaths_use_up_eggs_and_the_death_after_the_last_is_a_military_win() -> void:
	# The Gold Queen spawns and hatches just ahead of a Blue Warrior, both
	# facing right, so each time she can be killed she is killed from behind.
	var egg := Vector2i(960, 960)
	var state := _match([Vector2i(930, 960)], [egg], [1], [0], [egg, egg])
	var t := state.tuning
	var queen := state.characters[1]
	assert_bool(queen.alive).is_false()
	assert_int(state.eggs[GOLD]).is_equal(1)
	assert_int(state.eggs[BLUE]).is_equal(2)

	state = _hold(state, {}, t.respawn_queen_ticks - 1)
	assert_bool(state.characters[1].alive).is_false()
	state = _hold(state, {}, 1)
	assert_bool(state.characters[1].alive).is_true()
	assert_int(state.characters[1].x).is_equal(egg.x * PX)
	assert_bool(_has_event(state, MatchEvent.Type.HATCH, 1, -1)).is_true()

	state = _hold(state, {}, t.respawn_invulnerable_ticks)
	assert_bool(state.characters[1].alive).is_false()
	assert_int(state.eggs[GOLD]).is_equal(0)
	assert_int(state.win).is_equal(MatchState.Win.NONE)

	state = _hold(state, {}, t.respawn_queen_ticks + t.respawn_invulnerable_ticks)
	assert_bool(state.characters[1].alive).is_false()
	assert_int(state.win).is_equal(MatchState.Win.MILITARY)
	assert_int(state.winner).is_equal(BLUE)
	assert_bool(_has_win_event(state, BLUE)).is_true()


func test_a_dead_queen_hatches_from_her_teams_next_egg() -> void:
	var eggs: Array[Vector2i] = [Vector2i(300, 960), Vector2i(400, 960)]
	var state := _match([Vector2i(930, 960)], [Vector2i(960, 960)], [1], [0], eggs)
	assert_bool(state.characters[1].alive).is_false()

	state = _hold(state, {}, state.tuning.respawn_queen_ticks)

	var queen := state.characters[1]
	assert_bool(queen.alive).is_true()
	assert_int(queen.role).is_equal(CharacterState.Role.QUEEN)
	assert_int(queen.x).is_equal(400 * PX)
	assert_int(state.eggs[GOLD]).is_equal(1)


func test_a_won_match_is_over_and_nothing_more_happens() -> void:
	# A Gold Worker touches the Blue Warrior on the tick the Queen's last death
	# wins the Match; it is too late to kill it.
	var state := _match([Vector2i(930, 960)], [Vector2i(960, 960), Vector2i(900, 960)], [1], [0])
	assert_int(state.win).is_equal(MatchState.Win.MILITARY)
	var tick := state.tick
	var x := state.characters[0].x

	state = _hold(state, {0: SeatInput.of(SeatInput.RIGHT, false, true)}, 20)

	assert_int(state.tick).is_equal(tick + 20)
	assert_int(state.characters[0].x).is_equal(x)
	assert_int(state.characters[0].y).is_equal(FLOOR_Y)
	assert_bool(state.characters[1].alive).is_false()
	assert_bool(state.characters[2].alive).is_true()
	assert_array(state.events).is_empty()


## A Match on a floor (top at y 960 px), after one tick of neutral input in
## which the dev command made `warriors` Warriors. Both Teams get waiting Eggs
## at `eggs_px`.
func _match(blue_px: Array[Vector2i], gold_px: Array[Vector2i], queens: Array[int],
		warriors: Array[int], eggs_px: Array[Vector2i] = []) -> MatchState:
	var config := MatchConfig.new()
	config.map = TestMaps.build(TestMaps.floor_tiles(), blue_px, gold_px, eggs_px)
	var teams: Array[int] = []
	for i in blue_px.size():
		teams.append(BLUE)
	for i in gold_px.size():
		teams.append(GOLD)
	config.seat_teams = teams
	config.queen_seats = queens
	config.tuning = Tuning.load_default().with_values(
		{"worker_run_accel": 1000 * PX, "worker_run_decel": 1000 * PX})
	return _step(Sim.create_match(config), {}, warriors)


## One tick with `inputs` (Seat -> SeatInput); Seats not in it are neutral.
func _step(state: MatchState, inputs: Dictionary, dev_warrior_seats: Array[int] = []) -> MatchState:
	var seats: Array[SeatInput] = []
	for c in state.characters:
		seats.append(inputs.get(c.seat, SeatInput.of(SeatInput.NEUTRAL)))
	var input := TickInput.of(state.tick, seats)
	input.dev_warrior_seats = dev_warrior_seats
	return Sim.step(state, input)


func _hold(state: MatchState, inputs: Dictionary, ticks: int) -> MatchState:
	for i in ticks:
		state = _step(state, inputs)
	return state


## Steps with `inputs` until the tick `seat` dies.
func _until_dead(state: MatchState, inputs: Dictionary, seat: int) -> MatchState:
	for i in 200:
		state = _step(state, inputs)
		if not state.characters[seat].alive:
			return state
	fail("Seat %d never died" % seat)
	return state


func _has_event(state: MatchState, type: MatchEvent.Type, seat: int, other: int) -> bool:
	for e in state.events:
		if e.type == type and e.seat == seat and e.other == other:
			return true
	return false


func _has_win_event(state: MatchState, team: int) -> bool:
	for e in state.events:
		if e.type == MatchEvent.Type.WIN and e.team == team:
			return true
	return false
