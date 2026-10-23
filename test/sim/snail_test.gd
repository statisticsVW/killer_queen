extends GdUnitTestSuite
## The Snail: mounting, riding toward a Snail Goal, dismounting, eating enemy
## Workers and the Snail Win, driven only through Sim.create_match and
## Sim.step.
##
## Every Map here is a floor (top at y 960 px) with the Snail starting at 960
## px, Blue's Snail Goal at 400 px and Gold's at 1520 px. Blue Seats come
## first, then Gold. Warriors and Speed Workers are made with dev commands on
## the Match's first tick.

const PX := 1000
const FLOOR_Y := 960 * PX
const BLUE := CharacterState.BLUE
const GOLD := CharacterState.GOLD
const SNAIL_X := 960 * PX
const BLUE_GOAL_X := 400 * PX
const GOLD_GOAL_X := 1520 * PX


func test_walking_into_an_unridden_snail_mounts_it() -> void:
	var state := _match([Vector2i(1200, 960)], [])

	state = _until_event(state, {0: SeatInput.of(SeatInput.LEFT)}, MatchEvent.Type.SNAIL_MOUNT)

	assert_int(state.snail.rider).is_equal(0)
	assert_bool(_has_event(state, MatchEvent.Type.SNAIL_MOUNT, 0, -1)).is_true()


func test_queens_and_warriors_cannot_mount_the_snail() -> void:
	var state := _match([Vector2i(1200, 960), Vector2i(1200, 960)], [], [0], [1])

	state = _hold(state, {0: SeatInput.of(SeatInput.LEFT), 1: SeatInput.of(SeatInput.LEFT)}, 100)

	assert_int(state.characters[0].x).is_less(SNAIL_X - 100 * PX)
	assert_int(state.snail.rider).is_equal(-1)
	assert_int(state.snail.x).is_equal(SNAIL_X)


func test_an_unridden_snail_stays_still() -> void:
	var state := _match([Vector2i(200, 960)], [])

	state = _hold(state, {}, 100)

	assert_int(state.snail.x).is_equal(SNAIL_X)


func test_a_ridden_snail_moves_toward_its_riders_snail_goal_at_the_snail_speed() -> void:
	for team in [BLUE, GOLD]:
		var spawn: Array[Vector2i] = [Vector2i(1200, 960)]
		var none: Array[Vector2i] = []
		var state := _match(spawn if team == BLUE else none, none if team == BLUE else spawn)
		state = _until_event(state, {0: SeatInput.of(SeatInput.LEFT)}, MatchEvent.Type.SNAIL_MOUNT)
		var x := state.snail.x

		state = _hold(state, {}, 10)

		var toward_goal := -1 if team == BLUE else 1
		assert_int(state.snail.x - x).is_equal(toward_goal * 10 * state.tuning.snail_speed)
		assert_int(state.characters[0].x).is_equal(state.snail.x)


func test_a_speed_worker_rides_the_snail_faster() -> void:
	var state := _match([Vector2i(1200, 960)], [], [], [], [0])
	state = _until_event(state, {0: SeatInput.of(SeatInput.LEFT)}, MatchEvent.Type.SNAIL_MOUNT)
	var x := state.snail.x

	state = _hold(state, {}, 10)

	var t := state.tuning
	assert_int(x - state.snail.x).is_equal(10 * (t.snail_speed * t.snail_speed_rider_ratio / 10000))
	assert_int(x - state.snail.x).is_greater(10 * t.snail_speed)


func test_pressing_the_button_dismounts_and_the_rider_does_not_remount_at_once() -> void:
	var state := _match([Vector2i(1200, 960)], [])
	state = _until_event(state, {0: SeatInput.of(SeatInput.LEFT)}, MatchEvent.Type.SNAIL_MOUNT)
	state = _hold(state, {}, 5)
	var x := state.snail.x

	state = _step(state, {0: SeatInput.of(SeatInput.NEUTRAL, false, true)})
	assert_bool(_has_event(state, MatchEvent.Type.SNAIL_DISMOUNT, 0, -1)).is_true()
	state = _hold(state, {}, 60)

	assert_int(state.snail.rider).is_equal(-1)
	assert_int(state.snail.x).is_equal(x)
	assert_int(state.characters[0].y).is_equal(FLOOR_Y)


func test_an_enemy_worker_walking_into_the_front_is_eaten_over_the_eat_duration() -> void:
	# Blue rides left; a Gold Worker holding a Berry stands in the way.
	for speed_rider in [false, true]:
		var state := _eat_setup(speed_rider)
		var t := state.tuning
		var duration := t.snail_speed_rider_eat_ticks if speed_rider else t.snail_eat_ticks
		var x := state.snail.x
		assert_int(state.snail.victim).is_equal(1)

		# The rider can't move the Snail or dismount while it eats.
		state = _hold(state, {0: SeatInput.of(SeatInput.NEUTRAL, false, true)}, 1)
		state = _hold(state, {}, duration - 2)
		assert_bool(state.characters[1].alive).is_true()
		assert_int(state.snail.rider).is_equal(0)
		assert_int(state.snail.x).is_equal(x)
		state = _hold(state, {}, 1)

		assert_bool(state.characters[1].alive).is_false()
		assert_bool(_has_event(state, MatchEvent.Type.EAT_COMPLETE, 0, 1)).is_true()
		assert_bool(_has_event(state, MatchEvent.Type.DEATH, 1, -1)).is_true()
		assert_int(state.snail.victim).is_equal(-1)
		assert_int(_loose_berries(state)).is_equal(1)


func test_a_teammate_walking_into_the_front_is_not_eaten() -> void:
	# The teammate stands just in front of where the Snail starts.
	var state := _match([Vector2i(1200, 960), Vector2i(880, 960)], [])
	state = _until_event(state, {0: SeatInput.of(SeatInput.LEFT)}, MatchEvent.Type.SNAIL_MOUNT)

	state = _hold(state, {}, 300)

	assert_int(state.snail.victim).is_equal(-1)
	assert_bool(state.characters[1].alive).is_true()
	assert_int(state.snail.x).is_less(850 * PX)


func test_an_enemy_worker_touching_the_back_is_not_eaten() -> void:
	# Blue rides left; a Gold Worker catches up from behind and stops touching
	# the Snail's back.
	var state := _match([Vector2i(1200, 960)], [Vector2i(1400, 960)])
	state = _until_event(state, {0: SeatInput.of(SeatInput.LEFT)}, MatchEvent.Type.SNAIL_MOUNT)
	var t := state.tuning
	var reach := (t.snail_width + t.worker_width) / 2
	for i in 200:
		state = _step(state, {1: SeatInput.of(SeatInput.LEFT)})
		if state.characters[1].x - state.snail.x < reach - 4 * PX:
			break
	assert_int(state.characters[1].x).is_greater(state.snail.x)

	state = _hold(state, {}, 20)

	assert_int(state.snail.victim).is_equal(-1)
	assert_bool(state.characters[1].alive).is_true()


func test_killing_the_rider_mid_eat_frees_the_victim_alive() -> void:
	# A Gold Warrior stands where the eat happens and Flaps up into the rider.
	var state := _eat_setup(false, true)
	state = _hold(state, {}, 20)
	assert_int(state.snail.victim).is_equal(1)

	for i in 40:
		state = _step(state, {2: SeatInput.of(SeatInput.NEUTRAL, false, i % 2 == 0)})
		if not state.characters[0].alive:
			break

	assert_bool(state.characters[0].alive).is_false()
	assert_bool(_has_event(state, MatchEvent.Type.EAT_INTERRUPT, 0, 1)).is_true()
	assert_int(state.snail.rider).is_equal(-1)
	assert_int(state.snail.victim).is_equal(-1)
	var victim_x := state.characters[1].x
	state = _hold(state, {1: SeatInput.of(SeatInput.LEFT)}, state.tuning.snail_eat_ticks)
	assert_bool(state.characters[1].alive).is_true()
	assert_int(state.characters[1].x).is_less(victim_x)


func test_the_snail_reaching_a_snail_goal_is_a_snail_win_that_ends_the_match() -> void:
	for team in [BLUE, GOLD]:
		var spawn: Array[Vector2i] = [Vector2i(1200, 960)]
		var none: Array[Vector2i] = []
		var state := _match(spawn if team == BLUE else none, none if team == BLUE else spawn,
			[], [], [], {"snail_speed": 5 * PX})
		state = _until_event(state, {0: SeatInput.of(SeatInput.LEFT)}, MatchEvent.Type.SNAIL_MOUNT)

		state = _until_event(state, {}, MatchEvent.Type.WIN)

		assert_int(state.win).is_equal(MatchState.Win.SNAIL)
		assert_int(state.winner).is_equal(team)
		assert_int(state.snail.x).is_equal(BLUE_GOAL_X if team == BLUE else GOLD_GOAL_X)
		var tick := state.tick
		state = _hold(state, {}, 5)
		assert_int(state.tick).is_equal(tick + 5)
		assert_int(state.snail.x).is_equal(BLUE_GOAL_X if team == BLUE else GOLD_GOAL_X)


## Blue Seat 0 mounts the Snail from the right and rides it left into Gold
## Seat 1, a Worker standing at 700 px on a Berry pile (so holding a Berry),
## until the eat starts. With `warrior`, Gold Seat 2 is a Warrior standing
## where the Snail stops. Returns the state on the tick the eat starts.
func _eat_setup(speed_rider: bool, warrior := false) -> MatchState:
	var gold: Array[Vector2i] = [Vector2i(700, 960)]
	var warriors: Array[int] = []
	if warrior:
		gold.append(Vector2i(763, 960))
		warriors.append(2)
	var speed: Array[int] = []
	if speed_rider:
		speed.append(0)
	var cfg := _config([Vector2i(1200, 960)], gold)
	cfg.set_value("berries", "piles", [Vector2i(700, 960)])
	var state := _start(MapData.from_config(cfg), [], warriors, speed, {})
	state = _until_event(state, {0: SeatInput.of(SeatInput.LEFT)}, MatchEvent.Type.SNAIL_MOUNT)
	assert_int(state.characters[1].berry).is_not_equal(-1)
	state = _until_event(state, {}, MatchEvent.Type.EAT_START)
	assert_bool(_has_event(state, MatchEvent.Type.EAT_START, 0, 1)).is_true()
	return state


func _config(blue_px: Array[Vector2i], gold_px: Array[Vector2i]) -> ConfigFile:
	var cfg := TestMaps.config(TestMaps.floor_tiles(), blue_px, gold_px)
	cfg.set_value("snail", "start", Vector2i(960, 960))
	cfg.set_value("snail", "blue_goal", Vector2i(400, 960))
	cfg.set_value("snail", "gold_goal", Vector2i(1520, 960))
	return cfg


func _match(blue_px: Array[Vector2i], gold_px: Array[Vector2i], queens: Array[int] = [],
		warriors: Array[int] = [], speed: Array[int] = [], tuning := {}) -> MatchState:
	return _start(MapData.from_config(_config(blue_px, gold_px)), queens, warriors, speed, tuning)


## A Match after one tick of neutral input in which dev commands made
## `warriors` Warriors and `speed` Speed Workers. `tuning` overrides
## constants.
func _start(map: MapData, queens: Array[int], warriors: Array[int], speed: Array[int],
		tuning: Dictionary) -> MatchState:
	var config := MatchConfig.new()
	config.map = map
	var teams: Array[int] = []
	for i in map.spawns[BLUE].size():
		teams.append(BLUE)
	for i in map.spawns[GOLD].size():
		teams.append(GOLD)
	config.seat_teams = teams
	config.queen_seats = queens
	var overrides := {"worker_run_accel": 1000 * PX, "worker_run_decel": 1000 * PX}
	overrides.merge(tuning, true)
	config.tuning = Tuning.load_default().with_values(overrides)
	var state := Sim.create_match(config)
	var input := _tick_input(state, {})
	input.dev_warrior_seats = warriors
	input.dev_speed_seats = speed
	return Sim.step(state, input)


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


## Steps with `inputs` until the tick an event of `type` happens, for at most
## 3000 ticks.
func _until_event(state: MatchState, inputs: Dictionary, type: MatchEvent.Type) -> MatchState:
	for i in 3000:
		state = _step(state, inputs)
		for e in state.events:
			if e.type == type:
				return state
	fail("No %s event" % MatchEvent.Type.keys()[type])
	return state


func _has_event(state: MatchState, type: MatchEvent.Type, seat: int, other: int) -> bool:
	for e in state.events:
		if e.type == type and e.seat == seat and e.other == other:
			return true
	return false


func _loose_berries(state: MatchState) -> int:
	return state.berries.filter(func(b: BerryState) -> bool: return b.where == BerryState.Where.LOOSE).size()
