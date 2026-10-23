extends GdUnitTestSuite
## Gates: Queens claiming them, Workers spending a Berry to transform, and the
## upgrades that come out, driven only through Sim.create_match and Sim.step.
##
## Every Map here is a floor (top at y 960 px) with a Warrior Gate (Gate 0) at
## 600 px, a Speed Gate (Gate 1) at 1000 px and Berry piles at 300 and 1100
## px. Blue Seats come first, then Gold.

const PX := 1000
const BLUE := CharacterState.BLUE
const GOLD := CharacterState.GOLD
const WARRIOR_GATE := 0
const SPEED_GATE := 1
const WARRIOR_GATE_X := 600 * PX
const SPEED_GATE_X := 1000 * PX
const WORKER := CharacterState.Role.WORKER
const WARRIOR := CharacterState.Role.WARRIOR


func test_a_queen_touching_a_neutral_or_enemy_gate_claims_it() -> void:
	var state := _match([Vector2i(600, 960)], [Vector2i(800, 960)], [0, 1])
	assert_int(state.gates[WARRIOR_GATE].team).is_equal(-1)

	state = _step(state, {})
	assert_int(state.gates[WARRIOR_GATE].team).is_equal(BLUE)
	assert_bool(_has_event(state, MatchEvent.Type.GATE_CLAIM, 0, WARRIOR_GATE)).is_true()

	# Still touching her own Gate claims nothing more.
	for i in 40:
		state = _step(state, {0: SeatInput.of(SeatInput.LEFT)})
		assert_int(_count_events(state, MatchEvent.Type.GATE_CLAIM)).is_equal(0)

	state = _until_event(state, {1: SeatInput.of(SeatInput.LEFT)}, MatchEvent.Type.GATE_CLAIM)
	assert_int(state.gates[WARRIOR_GATE].team).is_equal(GOLD)
	assert_bool(_has_event(state, MatchEvent.Type.GATE_CLAIM, 1, WARRIOR_GATE)).is_true()
	assert_int(state.gates[SPEED_GATE].team).is_equal(-1)


func test_only_a_queen_claims_a_gate() -> void:
	var state := _match([Vector2i(600, 960), Vector2i(1000, 960)], [], [], [0])

	state = _hold(state, {}, 20)

	assert_int(state.gates[WARRIOR_GATE].team).is_equal(-1)
	assert_int(state.gates[SPEED_GATE].team).is_equal(-1)
	assert_int(_count_events(state, MatchEvent.Type.GATE_CLAIM)).is_equal(0)


func test_workers_cannot_use_an_enemy_owned_gate() -> void:
	# Gold's Queen claims the Warrior Gate and walks off; Blue's Worker brings
	# a Berry to it.
	var state := _match([Vector2i(300, 960)], [Vector2i(600, 960)], [1])
	state = _step(state, {})
	assert_int(state.gates[WARRIOR_GATE].team).is_equal(GOLD)
	state = _go_to(state, 0, WARRIOR_GATE_X, {1: SeatInput.of(SeatInput.RIGHT)})

	for i in 200:
		state = _step(state, {})
		assert_int(_count_events(state, MatchEvent.Type.TRANSFORM_START)).is_equal(0)

	assert_int(state.characters[0].role).is_equal(WORKER)
	assert_int(state.characters[0].berry).is_not_equal(-1)


func test_a_worker_with_a_berry_becomes_a_warrior_after_100_ticks_at_an_owned_warrior_gate() -> void:
	# Blue's Queen (Seat 1, so on Blue's first spawn point) stands on the
	# Warrior Gate, claiming it.
	var state := _match([Vector2i(600, 960), Vector2i(300, 960)], [], [1])
	var t := state.tuning
	assert_int(t.gate_hold_ticks + t.gate_locked_ticks).is_equal(100)
	state = _step(state, {})
	assert_int(state.gates[WARRIOR_GATE].team).is_equal(BLUE)
	var berry := state.characters[0].berry
	assert_int(berry).is_not_equal(-1)

	state = _go_to(state, 0, WARRIOR_GATE_X)
	state = _until_event(state, {}, MatchEvent.Type.TRANSFORM_START)
	assert_bool(_has_event(state, MatchEvent.Type.TRANSFORM_START, 0, WARRIOR_GATE)).is_true()
	assert_int(state.characters[0].x).is_equal(WARRIOR_GATE_X)

	# The Berry is held overhead for the first gate_hold_ticks, then spent as
	# the doors close. Holding the stick doesn't walk the Worker out.
	var left := {0: SeatInput.of(SeatInput.LEFT)}
	for i in t.gate_hold_ticks - 1:
		state = _step(state, left)
	assert_int(state.berries[berry].where).is_equal(BerryState.Where.CARRIED)
	state = _step(state, left)
	assert_int(state.berries[berry].where).is_equal(BerryState.Where.SPENT)
	assert_int(state.characters[0].berry).is_equal(-1)
	# A copy taken mid-transform is the same state.
	assert_str(state.copy().fingerprint()).is_equal(state.fingerprint())

	for i in t.gate_locked_ticks - 1:
		state = _step(state, left)
		assert_int(state.characters[0].role).is_equal(WORKER)
	state = _step(state, left)

	var c := state.characters[0]
	assert_int(c.role).is_equal(WARRIOR)
	assert_bool(c.speed).is_false()
	assert_bool(_has_event(state, MatchEvent.Type.TRANSFORM_COMPLETE, 0, WARRIOR_GATE)).is_true()
	assert_int(c.invulnerable_ticks).is_equal(t.gate_invulnerable_ticks)
	assert_int(c.x).is_equal(WARRIOR_GATE_X)


func test_a_gate_takes_one_worker_at_a_time() -> void:
	# Two Blue Workers take a Berry each from the pile at 300 px and arrive at
	# the Warrior Gate together.
	var state := _match([Vector2i(300, 960), Vector2i(300, 960)], [])
	state = _go_to(state, 0, WARRIOR_GATE_X, {1: SeatInput.of(SeatInput.RIGHT)})
	assert_int(state.characters[1].x).is_equal(state.characters[0].x)

	state = _until_event(state, {}, MatchEvent.Type.TRANSFORM_START)
	assert_int(_count_events(state, MatchEvent.Type.TRANSFORM_START)).is_equal(1)
	assert_bool(_has_event(state, MatchEvent.Type.TRANSFORM_START, 0, WARRIOR_GATE)).is_true()
	state = _until_event(state, {}, MatchEvent.Type.TRANSFORM_COMPLETE)

	# The second goes in as the first comes out.
	assert_bool(_has_event(state, MatchEvent.Type.TRANSFORM_START, 1, WARRIOR_GATE)).is_true()
	assert_int(state.characters[1].role).is_equal(WORKER)
	state = _until_event(state, {}, MatchEvent.Type.TRANSFORM_COMPLETE)
	assert_int(state.characters[1].role).is_equal(WARRIOR)


func test_a_worker_in_a_gate_picks_nothing_up() -> void:
	# A second pile sits on the Warrior Gate.
	var state := _match([Vector2i(300, 960)], [], [], [], [], [Vector2i(300, 960), Vector2i(600, 960)])
	var t := state.tuning
	state = _go_to(state, 0, WARRIOR_GATE_X)
	state = _until_event(state, {}, MatchEvent.Type.TRANSFORM_START)

	for i in t.gate_hold_ticks + t.gate_locked_ticks:
		state = _step(state, {})
		assert_int(_count_events(state, MatchEvent.Type.BERRY_PICKUP)).is_equal(0)

	assert_int(state.characters[0].role).is_equal(WARRIOR)
	assert_int(state.characters[0].berry).is_equal(-1)
	assert_int(_count_berries(state, BerryState.Where.PILE)).is_equal(11)


func test_a_worker_of_either_team_can_use_a_neutral_gate() -> void:
	for team in [BLUE, GOLD]:
		var spawn: Array[Vector2i] = [Vector2i(300, 960)]
		var none: Array[Vector2i] = []
		var state := _match(spawn if team == BLUE else none, none if team == BLUE else spawn)
		state = _go_to(state, 0, WARRIOR_GATE_X)

		state = _until_event(state, {}, MatchEvent.Type.TRANSFORM_COMPLETE)

		assert_int(state.characters[0].role).is_equal(WARRIOR)
		assert_int(state.gates[WARRIOR_GATE].team).is_equal(-1)


func test_a_kill_in_the_first_50_ticks_interrupts_the_transform_and_drops_the_berry() -> void:
	var state := _gold_warrior_walks_in_at(0)

	var c := state.characters[0]
	assert_bool(c.alive).is_false()
	assert_bool(_has_event(state, MatchEvent.Type.DEATH, 0, 1)).is_true()
	assert_bool(_has_event(state, MatchEvent.Type.TRANSFORM_INTERRUPT, 0, WARRIOR_GATE)).is_true()
	assert_int(c.berry).is_equal(-1)
	assert_int(_count_berries(state, BerryState.Where.LOOSE)).is_equal(1)
	assert_int(_count_berries(state, BerryState.Where.SPENT)).is_equal(0)

	state = _hold(state, {}, 100)
	assert_int(state.characters[0].role).is_equal(WORKER)


func test_the_worker_cannot_be_harmed_while_locked_in() -> void:
	var state := _gold_warrior_walks_in_at(1)
	var t := state.tuning
	assert_bool(state.characters[0].alive).is_true()

	# The Warrior walks on through the Gate while the Worker is locked in.
	for i in t.gate_locked_ticks - 2:
		state = _step(state, {1: SeatInput.of(SeatInput.LEFT)})
		assert_bool(state.characters[0].alive).is_true()
		assert_int(_count_events(state, MatchEvent.Type.TRANSFORM_INTERRUPT)).is_equal(0)
		assert_int(state.characters[0].x).is_equal(WARRIOR_GATE_X)
	assert_int(state.characters[1].x).is_less(WARRIOR_GATE_X - 40 * PX)
	state = _step(state, {})

	assert_int(state.characters[0].role).is_equal(WARRIOR)
	assert_bool(_has_event(state, MatchEvent.Type.TRANSFORM_COMPLETE, 0, WARRIOR_GATE)).is_true()


func test_a_bump_in_the_first_50_ticks_interrupts_the_transform_and_keeps_the_berry() -> void:
	# A Gold Worker walks into Blue's Worker while it holds its Berry up.
	var state := _match([Vector2i(300, 960)], [Vector2i(700, 960)])
	var t := state.tuning
	state = _go_to(state, 0, WARRIOR_GATE_X)
	state = _until_event(state, {}, MatchEvent.Type.TRANSFORM_START)
	var started := state.tick

	state = _until_event(state, {1: SeatInput.of(SeatInput.LEFT)}, MatchEvent.Type.TRANSFORM_INTERRUPT)
	assert_int(state.tick - started).is_less_equal(t.gate_hold_ticks)
	assert_bool(_has_event(state, MatchEvent.Type.TRANSFORM_INTERRUPT, 0, WARRIOR_GATE)).is_true()
	assert_bool(state.characters[0].alive).is_true()
	assert_int(state.characters[0].vx).is_less(0)
	state = _hold(state, {}, started + t.gate_hold_ticks + t.gate_locked_ticks - state.tick)

	assert_int(state.characters[0].role).is_equal(WORKER)
	assert_int(state.characters[0].berry).is_not_equal(-1)
	assert_int(_count_berries(state, BerryState.Where.SPENT)).is_equal(0)


func test_a_worker_without_a_berry_standing_at_a_gate_stays_a_worker() -> void:
	var state := _match([Vector2i(600, 960), Vector2i(1000, 960)], [])

	for i in 200:
		state = _step(state, {})
		assert_int(_count_events(state, MatchEvent.Type.TRANSFORM_START)).is_equal(0)

	for seat in [0, 1]:
		assert_int(state.characters[seat].role).is_equal(WORKER)
		assert_bool(state.characters[seat].speed).is_false()


func test_a_worker_at_a_speed_gate_becomes_a_speed_worker() -> void:
	var state := _match([Vector2i(300, 960)], [])
	var berry := _step(state, {}).characters[0].berry
	state = _go_to(state, 0, SPEED_GATE_X)

	state = _until_event(state, {}, MatchEvent.Type.TRANSFORM_COMPLETE)

	var c := state.characters[0]
	assert_bool(_has_event(state, MatchEvent.Type.TRANSFORM_COMPLETE, 0, SPEED_GATE)).is_true()
	assert_int(c.role).is_equal(WORKER)
	assert_bool(c.speed).is_true()
	assert_int(c.berry).is_equal(-1)
	assert_int(state.berries[berry].where).is_equal(BerryState.Where.SPENT)


func test_a_speed_worker_reentering_a_speed_gate_stays_as_they_are_and_keeps_the_berry() -> void:
	var state := _match([Vector2i(300, 960)], [], [], [], [0])
	state = _go_to(state, 0, SPEED_GATE_X)

	for i in 200:
		state = _step(state, {})
		assert_int(_count_events(state, MatchEvent.Type.TRANSFORM_START)).is_equal(0)

	var c := state.characters[0]
	assert_int(c.role).is_equal(WORKER)
	assert_bool(c.speed).is_true()
	assert_int(c.berry).is_not_equal(-1)


func test_a_speed_worker_at_a_warrior_gate_becomes_a_speed_warrior() -> void:
	var state := _match([Vector2i(300, 960)], [], [], [], [0])
	state = _go_to(state, 0, WARRIOR_GATE_X)
	# Running at Speed, the Worker stops short of the Gate's centre and is
	# snapped to it as it goes in.
	assert_int(state.characters[0].x).is_not_equal(WARRIOR_GATE_X)
	state = _until_event(state, {}, MatchEvent.Type.TRANSFORM_START)
	assert_int(state.characters[0].x).is_equal(WARRIOR_GATE_X)

	state = _until_event(state, {}, MatchEvent.Type.TRANSFORM_COMPLETE)

	assert_int(state.characters[0].role).is_equal(WARRIOR)
	assert_bool(state.characters[0].speed).is_true()


func test_dying_loses_all_upgrades() -> void:
	# Blue's Speed Warrior faces right; Gold's Warrior runs into its back.
	var state := _match([Vector2i(600, 960)], [Vector2i(500, 960)], [], [0, 1], [0])
	assert_int(state.characters[0].role).is_equal(WARRIOR)
	assert_bool(state.characters[0].speed).is_true()

	state = _until_event(state, {1: SeatInput.of(SeatInput.RIGHT)}, MatchEvent.Type.DEATH)
	assert_bool(_has_event(state, MatchEvent.Type.DEATH, 0, 1)).is_true()
	state = _until_event(state, {}, MatchEvent.Type.RESPAWN)

	assert_int(state.characters[0].role).is_equal(WORKER)
	assert_bool(state.characters[0].speed).is_false()


func test_emerge_invulnerability_ends_when_the_character_picks_up_a_berry() -> void:
	var state := _match([Vector2i(300, 960)], [])
	state = _go_to(state, 0, SPEED_GATE_X)
	state = _until_event(state, {}, MatchEvent.Type.TRANSFORM_COMPLETE)
	assert_int(state.characters[0].invulnerable_ticks).is_equal(state.tuning.gate_invulnerable_ticks)

	# Walk to the pile at 1100 px.
	var before := state
	for i in 50:
		before = state
		state = _step(state, {0: SeatInput.of(SeatInput.RIGHT)})
		if _count_events(state, MatchEvent.Type.BERRY_PICKUP) > 0:
			break

	assert_bool(_has_event(state, MatchEvent.Type.BERRY_PICKUP, 0, state.characters[0].berry)).is_true()
	assert_int(before.characters[0].invulnerable_ticks).is_greater(1)
	assert_int(state.characters[0].invulnerable_ticks).is_equal(0)


## Blue's Worker brings a Berry from 300 px to the neutral Warrior Gate, with
## Gold's Warrior standing 45 px to the Gate's right. Once the transform
## starts, the Warrior waits, then walks left so that it first touches the
## Worker `late` ticks after the last of the gate_hold_ticks. Returns the
## state after that tick.
func _gold_warrior_walks_in_at(late: int) -> MatchState:
	var state := _match([Vector2i(300, 960)], [Vector2i(645, 960)], [], [1])
	var t := state.tuning
	state = _go_to(state, 0, WARRIOR_GATE_X)
	state = _until_event(state, {}, MatchEvent.Type.TRANSFORM_START)
	assert_int(state.characters[0].x).is_equal(WARRIOR_GATE_X)
	# Ticks of walking until the Warrior's collider overlaps the Worker's.
	var gap := 45 * PX - (t.worker_width + t.winged_width) / 2
	var walk := t.worker_max_speed * t.winged_walk_speed_ratio / 10000
	var steps := gap / walk + 1

	for i in t.gate_hold_ticks + late:
		var walking := i >= t.gate_hold_ticks + late - steps
		state = _step(state, {1: SeatInput.of(SeatInput.LEFT if walking else SeatInput.NEUTRAL)})
		if i < t.gate_hold_ticks + late - 1:
			assert_bool(state.characters[0].alive).is_true()
	return state


## A Match on the Gate test Map, not yet stepped. `warriors` and `speed` Seats
## start as Warriors and with the Speed upgrade. `piles_px` replaces the Map's
## Berry piles.
func _match(blue_px: Array[Vector2i], gold_px: Array[Vector2i], queens: Array[int] = [],
		warriors: Array[int] = [], speed: Array[int] = [],
		piles_px: Array[Vector2i] = [Vector2i(300, 960), Vector2i(1100, 960)]) -> MatchState:
	var cfg := TestMaps.config(TestMaps.floor_tiles(), blue_px, gold_px)
	cfg.set_value("gates", "warrior", [Vector2i(600, 960)])
	cfg.set_value("gates", "speed", [Vector2i(1000, 960)])
	cfg.set_value("berries", "piles", piles_px)
	var config := MatchConfig.new()
	config.map = MapData.from_config(cfg)
	var teams: Array[int] = []
	for i in blue_px.size():
		teams.append(BLUE)
	for i in gold_px.size():
		teams.append(GOLD)
	config.seat_teams = teams
	config.queen_seats = queens
	config.warrior_seats = warriors
	config.speed_seats = speed
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


func _hold(state: MatchState, inputs: Dictionary, ticks: int) -> MatchState:
	for i in ticks:
		state = _step(state, inputs)
	return state


## Steps with `inputs` until the tick an event of `type` happens, for at most
## 3000 ticks.
func _until_event(state: MatchState, inputs: Dictionary, type: MatchEvent.Type) -> MatchState:
	for i in 3000:
		state = _step(state, inputs)
		if _count_events(state, type) > 0:
			return state
	fail("No %s event" % MatchEvent.Type.keys()[type])
	return state


func _has_event(state: MatchState, type: MatchEvent.Type, seat: int, other: int) -> bool:
	for e in state.events:
		if e.type == type and e.seat == seat and e.other == other:
			return true
	return false


func _count_events(state: MatchState, type: MatchEvent.Type) -> int:
	return state.events.filter(func(e: MatchEvent) -> bool: return e.type == type).size()


func _count_berries(state: MatchState, where: BerryState.Where) -> int:
	return state.berries.filter(func(b: BerryState) -> bool: return b.where == where).size()
