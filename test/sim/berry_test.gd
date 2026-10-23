extends GdUnitTestSuite
## Berries: picking up, carrying, depositing in the Hive, dropping on death,
## kicking loose Berries and the Economic Win, driven only through
## Sim.create_match and Sim.step.
##
## Blue Seats come first, then Gold. Warriors are made with the dev command on
## the Match's first tick. Berry piles hold six Berries.

const PX := 1000
const FLOOR_Y := 960 * PX
const BLUE := CharacterState.BLUE
const GOLD := CharacterState.GOLD
## The left face of the wall in _carrier_killed's Map.
const WALL_X := 1680 * PX


func test_touching_a_berry_picks_it_up_and_a_carrying_worker_picks_up_no_more() -> void:
	var state := _match(_map([Vector2i(700, 960)], [Vector2i(960, 960)]), [], [])

	state = _hold(state, {0: SeatInput.of(SeatInput.RIGHT)}, 100)

	assert_int(state.characters[0].x).is_greater(1100 * PX)
	assert_int(_count(state, BerryState.Where.CARRIED)).is_equal(1)
	assert_int(_count(state, BerryState.Where.PILE)).is_equal(5)
	var berry := state.characters[0].berry
	assert_int(berry).is_not_equal(-1)
	assert_int(state.berries[berry].where).is_equal(BerryState.Where.CARRIED)


func test_queens_and_warriors_cannot_pick_up_berries() -> void:
	var map := _map([Vector2i(700, 960), Vector2i(700, 960)], [Vector2i(960, 960)])
	var state := _match(map, [0], [1])

	state = _hold(state, {0: SeatInput.of(SeatInput.RIGHT), 1: SeatInput.of(SeatInput.RIGHT)}, 120)

	assert_int(state.characters[0].berry).is_equal(-1)
	assert_int(state.characters[1].berry).is_equal(-1)
	assert_int(_count(state, BerryState.Where.PILE)).is_equal(6)


func test_a_worker_made_a_warrior_drops_its_berry() -> void:
	var state := _match(_map([Vector2i(900, 960)], [Vector2i(960, 960)]), [], [])
	state = _hold(state, {0: SeatInput.of(SeatInput.RIGHT)}, 10)
	assert_int(state.characters[0].berry).is_not_equal(-1)

	state = _step(state, {}, [0])

	assert_int(state.characters[0].berry).is_equal(-1)
	assert_int(_count(state, BerryState.Where.LOOSE)).is_equal(1)


func test_depositing_fills_an_empty_hole_in_the_workers_own_hive_only() -> void:
	# Running right, a lone Worker picks up a Berry, passes a hole of the other
	# Team's Hive and reaches one of its own.
	for team in [BLUE, GOLD]:
		var spawn: Array[Vector2i] = [Vector2i(600, 960)]
		var none: Array[Vector2i] = []
		var cfg := _map_config(spawn if team == BLUE else none, [Vector2i(700, 960)],
			none if team == BLUE else spawn)
		var own_key := "blue_holes" if team == BLUE else "gold_holes"
		var other_key := "gold_holes" if team == BLUE else "blue_holes"
		cfg.set_value("hive", other_key, [Vector2i(900, 940)])
		cfg.set_value("hive", own_key, [Vector2i(1300, 940)])
		var state := _match(MapData.from_config(cfg), [], [])
		assert_int(state.characters[0].team).is_equal(team)

		state = _hold(state, {0: SeatInput.of(SeatInput.RIGHT)}, 75)
		assert_int(state.characters[0].x).is_greater(950 * PX)
		assert_int(state.characters[0].berry).is_not_equal(-1)
		assert_int(_filled(state, 1 - team)).is_equal(0)
		state = _hold(state, {0: SeatInput.of(SeatInput.RIGHT)}, 70)

		assert_int(state.characters[0].berry).is_equal(-1)
		assert_int(_filled(state, team)).is_equal(1)
		assert_int(_filled(state, 1 - team)).is_equal(0)
		var berry := _first(state, BerryState.Where.HIVE)
		assert_int(berry.team).is_equal(team)
		assert_int(berry.hole).is_equal(0)


func test_a_worker_killed_while_carrying_drops_a_loose_berry_where_it_died() -> void:
	var state := _carrier_killed([])

	var worker := state.characters[0]
	var berry := _first(state, BerryState.Where.LOOSE)
	assert_object(berry).is_not_null()
	assert_int(worker.berry).is_equal(-1)
	assert_int(berry.x).is_equal(worker.x)
	assert_int(berry.y).is_equal(FLOOR_Y)
	assert_bool(_has_event(state, MatchEvent.Type.BERRY_DROP, 0)).is_true()


func test_a_free_worker_picks_up_a_loose_berry() -> void:
	var state := _carrier_killed([Vector2i(1500, 960)])
	var loose := state.berries.find(_first(state, BerryState.Where.LOOSE))

	state = _after_kill(state, {1: SeatInput.of(SeatInput.LEFT)}, 150)

	assert_int(state.characters[1].berry).is_equal(loose)


func test_running_into_a_loose_berry_while_carrying_kicks_it_until_terrain_stops_it() -> void:
	# The second Blue Worker takes a Berry from the pile on its way, so it
	# reaches the loose one carrying, and kicks it right into the wall.
	var state := _carrier_killed([Vector2i(200, 960)])
	var loose := state.berries.find(_first(state, BerryState.Where.LOOSE))
	var kicked := false
	for i in 300:
		state = _after_kill(state, {1: SeatInput.of(SeatInput.RIGHT)}, 1)
		if _has_event(state, MatchEvent.Type.BERRY_KICK, 1):
			kicked = true
			break
	assert_bool(kicked).is_true()
	assert_int(state.berries[loose].vx).is_greater(0)

	state = _after_kill(state, {}, 150)

	var berry := state.berries[loose]
	assert_int(state.characters[1].berry).is_not_equal(loose)
	assert_int(berry.where).is_equal(BerryState.Where.LOOSE)
	assert_int(berry.x).is_equal(WALL_X - state.tuning.berry_size / 2)
	assert_int(berry.y).is_equal(FLOOR_Y)
	assert_int(berry.vx).is_equal(0)


func test_picking_up_a_berry_ends_respawn_invulnerability() -> void:
	# The Warrior is made on the Worker's spawn point and kills it at once.
	var cfg := _map_config([Vector2i(300, 960)], [Vector2i(400, 960)], [Vector2i(300, 960)])
	var state := _match(MapData.from_config(cfg), [], [1])
	state = _hold(state, {}, state.tuning.respawn_ticks)
	assert_int(state.characters[0].invulnerable_ticks).is_greater(0)

	state = _hold(state, {0: SeatInput.of(SeatInput.RIGHT)}, 20)

	assert_int(state.characters[0].berry).is_not_equal(-1)
	assert_int(state.characters[0].invulnerable_ticks).is_equal(0)


func test_the_last_hole_filled_is_an_economic_win_that_ends_the_match() -> void:
	# A Worker standing on two piles (12 Berries) in front of 12 Blue holes,
	# with Gold's 12 holes in the same place, fills Blue's without moving.
	var cfg := _map_config([Vector2i(960, 960)], [Vector2i(960, 960), Vector2i(960, 960)])
	var holes: Array[Vector2i] = []
	for i in 12:
		holes.append(Vector2i(950 + i * 2, 930))
	cfg.set_value("hive", "blue_holes", holes)
	cfg.set_value("hive", "gold_holes", holes)
	var state := _match(MapData.from_config(cfg), [], [])

	state = _until_filled(state, 11)
	assert_int(_filled(state, BLUE)).is_equal(11)
	assert_int(state.win).is_equal(MatchState.Win.NONE)
	state = _until_filled(state, 12)

	assert_int(_filled(state, BLUE)).is_equal(12)
	assert_int(state.win).is_equal(MatchState.Win.ECONOMIC)
	assert_int(state.winner).is_equal(BLUE)
	assert_bool(_has_win_event(state, BLUE)).is_true()
	assert_bool(_has_event(state, MatchEvent.Type.BERRY_DEPOSIT, 0)).is_true()
	assert_int(_filled(state, GOLD)).is_equal(0)
	# One Berry per hole: a full hole takes no more.
	var holes_used := {}
	for b in state.berries:
		if b.where == BerryState.Where.HIVE:
			holes_used[b.hole] = true
	assert_int(holes_used.size()).is_equal(12)
	var tick := state.tick
	state = _hold(state, {0: SeatInput.of(SeatInput.RIGHT)}, 5)
	assert_int(state.tick).is_equal(tick + 5)
	assert_int(state.characters[0].x).is_equal(960 * PX)



## Seat 0, a Blue Worker, runs right from 400 px, takes a Berry from the pile
## at 600 px and dies on a Gold Warrior standing at 1000 px, dropping the Berry
## on the floor. `others_px` are more Blue Workers (Seats 1 on); the Warrior
## is the last Seat. A wall's left face is at WALL_X. Returns the state on the
## tick Seat 0 dies.
func _carrier_killed(others_px: Array[Vector2i]) -> MatchState:
	var blue: Array[Vector2i] = [Vector2i(400, 960)]
	blue.append_array(others_px)
	var cfg := _map_config(blue, [Vector2i(600, 960)], [Vector2i(1000, 960)])
	var tiles := TestMaps.floor_tiles()
	tiles[7] = "|..............#."
	cfg.set_value("map", "tiles", tiles)
	var state := _match(MapData.from_config(cfg), [], [blue.size()])
	for i in 200:
		state = _step(state, {0: SeatInput.of(SeatInput.RIGHT)})
		if not state.characters[0].alive:
			return state
	fail("The carrier never died")
	return state


## Steps a Match from _carrier_killed with `inputs` while the Warrior Flaps
## up out of the way.
func _after_kill(state: MatchState, inputs: Dictionary, ticks: int) -> MatchState:
	var warrior := state.characters.size() - 1
	for i in ticks:
		var with_warrior := inputs.duplicate()
		with_warrior[warrior] = SeatInput.of(SeatInput.NEUTRAL, false, state.tick % 3 == 0)
		state = _step(state, with_warrior)
	return state


## Floor rows with Blue and Gold spawn points and Berry piles, in whole pixels.
func _map_config(blue_px: Array[Vector2i], piles_px: Array[Vector2i],
		gold_px: Array[Vector2i] = []) -> ConfigFile:
	var cfg := TestMaps.config(TestMaps.floor_tiles(), blue_px, gold_px)
	cfg.set_value("berries", "piles", piles_px)
	return cfg


func _map(blue_px: Array[Vector2i], piles_px: Array[Vector2i]) -> MapData:
	return MapData.from_config(_map_config(blue_px, piles_px))


## A Match after one tick of neutral input in which the dev command made
## `warriors` Warriors. Blue's Seats come first, then Gold's.
func _match(map: MapData, queens: Array[int], warriors: Array[int]) -> MatchState:
	var config := MatchConfig.new()
	config.map = map
	var teams: Array[int] = []
	for i in map.spawns[BLUE].size():
		teams.append(BLUE)
	for i in map.spawns[GOLD].size():
		teams.append(GOLD)
	config.seat_teams = teams
	config.queen_seats = queens
	config.tuning = Tuning.load_default().with_values(
		{"worker_run_accel": 1000 * PX, "worker_run_decel": 1000 * PX, "berry_kick_speed": 20 * PX})
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


## Steps with neutral input until Blue's Hive has `holes` filled, for at most
## 100 ticks.
func _until_filled(state: MatchState, holes: int) -> MatchState:
	for i in 100:
		if _filled(state, BLUE) >= holes:
			break
		state = _step(state, {})
	return state


func _count(state: MatchState, where: BerryState.Where) -> int:
	return state.berries.filter(func(b: BerryState) -> bool: return b.where == where).size()


func _first(state: MatchState, where: BerryState.Where) -> BerryState:
	for b in state.berries:
		if b.where == where:
			return b
	return null


func _filled(state: MatchState, team: int) -> int:
	return state.berries.filter(
		func(b: BerryState) -> bool: return b.where == BerryState.Where.HIVE and b.team == team).size()


func _has_event(state: MatchState, type: MatchEvent.Type, seat: int) -> bool:
	for e in state.events:
		if e.type == type and e.seat == seat:
			return true
	return false


func _has_win_event(state: MatchState, team: int) -> bool:
	for e in state.events:
		if e.type == MatchEvent.Type.WIN and e.team == team:
			return true
	return false
