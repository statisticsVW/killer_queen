extends GdUnitTestSuite
## Swords killing Workers, the Queen's Dive, death, respawn and spawn
## invulnerability, driven only through Sim.create_match and Sim.step.
##
## Blue Seats come first, then Gold. Tests that need a Warrior start the Match
## with one.

const PX := 1000
const FLOOR_Y := 960 * PX
const QUEEN := CharacterState.Role.QUEEN
const WARRIOR := CharacterState.Role.WARRIOR


func test_enemy_sword_contact_kills_a_worker_from_either_side_above_and_below() -> void:
	# Worker spawn, enemy spawn, the enemy's stick.
	var approaches := [
		[Vector2i(960, 960), Vector2i(700, 960), SeatInput.RIGHT],
		[Vector2i(960, 960), Vector2i(1220, 960), SeatInput.LEFT],
		[Vector2i(960, 960), Vector2i(960, 600), SeatInput.NEUTRAL],
		[Vector2i(960, 600), Vector2i(960, 960), SeatInput.NEUTRAL],
	]
	for role in [QUEEN, WARRIOR]:
		for approach in approaches:
			var state := _worker_and(approach[0], approach[1], role)
			var enemy := {1: SeatInput.of(approach[2])}

			state = _until_dead(state, enemy, 0)

			assert_bool(state.characters[0].alive).is_false()
			assert_bool(state.characters[1].alive).is_true()


func test_a_teammates_sword_passes_through_a_worker() -> void:
	for role in [QUEEN, WARRIOR]:
		var state := _worker_and(Vector2i(960, 960), Vector2i(700, 960), role, false)

		state = _hold(state, {1: SeatInput.of(SeatInput.RIGHT)}, 120)

		assert_bool(state.characters[0].alive).is_true()
		assert_bool(state.characters[1].alive).is_true()
		assert_int(state.characters[1].x).is_greater(state.characters[0].x)


func test_a_kill_and_a_death_appear_in_the_events_of_the_tick_they_happen() -> void:
	var state := _worker_and(Vector2i(960, 960), Vector2i(700, 960), WARRIOR)
	var enemy := {1: SeatInput.of(SeatInput.RIGHT)}

	state = _until_dead(state, enemy, 0)

	assert_bool(_has_event(state, MatchEvent.Type.KILL, 1, 0)).is_true()
	assert_bool(_has_event(state, MatchEvent.Type.DEATH, 0, 1)).is_true()
	state = _hold(state, enemy, 1)
	assert_array(state.events).is_empty()


func test_a_dead_worker_stays_where_it_was_killed_and_ignores_its_stick() -> void:
	var state := _worker_and(Vector2i(960, 960), Vector2i(700, 960), WARRIOR)
	state = _until_dead(state, {1: SeatInput.of(SeatInput.RIGHT)}, 0)
	var x := state.characters[0].x

	state = _hold(state, {0: SeatInput.of(SeatInput.RIGHT, false, true)}, state.tuning.respawn_ticks - 1)

	assert_bool(state.characters[0].alive).is_false()
	assert_int(state.characters[0].x).is_equal(x)
	assert_int(state.characters[0].y).is_equal(FLOOR_Y)


func test_a_diving_queen_kills_a_worker_beneath_her() -> void:
	var state := _worker_and(Vector2i(960, 960), Vector2i(960, 400), QUEEN)
	var diving := {1: SeatInput.of(SeatInput.NEUTRAL, true)}

	state = _until_dead(state, diving, 0)

	assert_bool(state.characters[1].diving).is_true()
	assert_bool(state.characters[0].alive).is_false()
	assert_bool(_has_event(state, MatchEvent.Type.KILL, 1, 0)).is_true()


func test_a_diving_queen_kills_a_warrior_beneath_her() -> void:
	var state := _match([Vector2i(960, 960)], [Vector2i(960, 400)], [1], [0])

	state = _until_dead(state, {1: SeatInput.of(SeatInput.NEUTRAL, true)}, 0)

	assert_bool(state.characters[0].alive).is_false()
	assert_bool(state.characters[1].alive).is_true()


func test_a_dive_kills_however_little_higher_the_queen_is_than_a_joust_needs() -> void:
	# A Joust margin taller than a collider: no Joust can be won by height.
	var tuning := {"joust_height_margin": 100 * PX}
	var falling := _match([Vector2i(960, 960)], [Vector2i(960, 400)], [1], [0], tuning)
	var diving := _match([Vector2i(960, 960)], [Vector2i(960, 400)], [1], [0], tuning)

	falling = _hold(falling, {}, 80)
	diving = _until_dead(diving, {1: SeatInput.of(SeatInput.NEUTRAL, true)}, 0)

	assert_bool(falling.characters[0].alive).is_true()
	assert_int(falling.characters[1].y).is_equal(FLOOR_Y - falling.tuning.winged_height)
	assert_bool(diving.characters[0].alive).is_false()


func test_a_dead_worker_respawns_at_its_spawn_point_after_the_respawn_delay() -> void:
	var state := _worker_and(Vector2i(960, 960), Vector2i(700, 960), WARRIOR)
	var enemy := {1: SeatInput.of(SeatInput.LEFT)}
	state = _until_dead(state, {0: SeatInput.of(SeatInput.LEFT), 1: SeatInput.of(SeatInput.RIGHT)}, 0)
	assert_int(state.characters[0].x).is_less(960 * PX)

	state = _hold(state, enemy, state.tuning.respawn_ticks - 1)
	assert_bool(state.characters[0].alive).is_false()
	state = _hold(state, enemy, 1)

	var worker := state.characters[0]
	assert_bool(worker.alive).is_true()
	assert_int(worker.x).is_equal(960 * PX)
	assert_int(worker.y).is_equal(FLOOR_Y)
	assert_int(worker.role).is_equal(CharacterState.Role.WORKER)
	assert_bool(_has_event(state, MatchEvent.Type.RESPAWN, 0, -1)).is_true()


func test_a_respawned_worker_is_invulnerable_to_swords_for_the_invulnerability_window() -> void:
	# The Warrior is made on the Worker's spawn point, so kills it at once and
	# is still standing there when it respawns.
	var state := _match([Vector2i(960, 960)], [Vector2i(960, 960)], [], [1])
	var t := state.tuning
	assert_bool(state.characters[0].alive).is_false()
	state = _hold(state, {}, t.respawn_ticks)
	assert_bool(state.characters[0].alive).is_true()

	state = _hold(state, {}, t.respawn_invulnerable_ticks - 1)
	assert_bool(state.characters[0].alive).is_true()
	assert_int(state.characters[0].x).is_equal(960 * PX)
	state = _hold(state, {}, 1)

	assert_bool(state.characters[0].alive).is_false()
	assert_bool(_has_event(state, MatchEvent.Type.KILL, 1, 0)).is_true()


## A Blue Worker (Seat 0) and a Queen or Warrior (Seat 1), Gold unless
## `enemy` is false.
func _worker_and(worker_px: Vector2i, other_px: Vector2i, role: CharacterState.Role,
		enemy := true) -> MatchState:
	var blue: Array[Vector2i] = [worker_px]
	var gold: Array[Vector2i] = []
	if enemy:
		gold.append(other_px)
	else:
		blue.append(other_px)
	var queens: Array[int] = []
	var warriors: Array[int] = []
	(queens if role == QUEEN else warriors).append(1)
	return _match(blue, gold, queens, warriors)


## A Match on a floor (top at y 960 px), after one tick of neutral input, with
## `warriors` starting as Warriors. `tuning` overrides
## constants.
func _match(blue_px: Array[Vector2i], gold_px: Array[Vector2i], queens: Array[int],
		warriors: Array[int], tuning := {}) -> MatchState:
	var config := MatchConfig.new()
	config.map = TestMaps.build(TestMaps.floor_tiles(), blue_px, gold_px)
	var teams: Array[int] = []
	for i in blue_px.size():
		teams.append(CharacterState.BLUE)
	for i in gold_px.size():
		teams.append(CharacterState.GOLD)
	config.seat_teams = teams
	config.queen_seats = queens
	var overrides := {"worker_run_accel": 1000 * PX, "worker_run_decel": 1000 * PX}
	overrides.merge(tuning, true)
	config.tuning = Tuning.load_default().with_values(overrides)
	config.warrior_seats = warriors
	return _step(Sim.create_match(config), {})


## One tick with `inputs` (Seat -> SeatInput); Seats not in it are neutral.
func _step(state: MatchState, inputs: Dictionary) -> MatchState:
	var seats: Array[SeatInput] = []
	for c in state.characters:
		seats.append(inputs.get(c.seat, SeatInput.of(SeatInput.NEUTRAL)))
	return Sim.step(state, TickInput.of(state.tick, seats))


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
