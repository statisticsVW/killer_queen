extends GdUnitTestSuite
## Bot Workers choose what to do from a read of the Match: run Berries, spend
## a Berry at their Team's Warrior Gate when their Team is short of Warriors,
## or ride the Snail when it stands on their half of its track. Driven only
## through Sim.create_match and Sim.step.

const BLUE := CharacterState.BLUE
const GOLD := CharacterState.GOLD
const DAY := "res://data/maps/day.cfg"


func test_with_the_snail_close_to_their_goal_and_unridden_a_bot_worker_rides_it_home() -> void:
	# On Day, the Snail stands near Blue's Snail Goal. Blue's only Seat is a
	# Bot Worker up on the Hives' level, with every Berry pile to go for.
	var cfg := ConfigFile.new()
	cfg.load(DAY)
	cfg.set_value("snail", "start", Vector2i(300, 1056))
	var state := Sim.create_match(_config(MapData.from_config(cfg), [BLUE], [], [0]))
	var mounted := -1
	for i in 2500:
		state = _step(state)
		for e in state.events:
			if e.type == MatchEvent.Type.SNAIL_MOUNT:
				mounted = state.tick
			assert_int(e.type).is_not_equal(MatchEvent.Type.SNAIL_DISMOUNT)
			assert_int(e.type).is_not_equal(MatchEvent.Type.BERRY_DEPOSIT)
		if state.win != MatchState.Win.NONE:
			break

	assert_int(mounted).is_greater(0)
	assert_int(state.win).is_equal(MatchState.Win.SNAIL)
	assert_int(state.winner).is_equal(BLUE)


func test_a_bot_worker_goes_to_ride_the_snail_from_halfway_along_its_track() -> void:
	# As at the start of a Match: the Snail at x 960 is as far from each Snail
	# Goal.
	var cfg := _snail_floor([Vector2i(1200, 960)], [])
	cfg.set_value("snail", "start", Vector2i(960, 960))
	var state := Sim.create_match(_config(MapData.from_config(cfg), [BLUE], [], [0]))
	for i in 60:
		state = _step(state)

	assert_int(state.snail.rider).is_equal(0)


func test_only_the_bot_worker_nearest_the_snail_goes_to_ride_it() -> void:
	# On a floor, the Snail stands at x 600, on Blue's half. Blue's Bot Worker
	# at x 800 is nearer it than the one at x 1000; a Berry pile is off to the
	# right. Blue's Bot Warrior, waiting by the Snail, can't ride it.
	var cfg := _snail_floor([Vector2i(800, 960), Vector2i(1000, 960), Vector2i(560, 960)], [])
	var config := _config(MapData.from_config(cfg), [BLUE, BLUE, BLUE], [], [0, 1, 2])
	config.warrior_seats = [2]
	var state := Sim.create_match(config)
	for i in 60:
		state = _step(state)

	assert_int(state.snail.rider).is_equal(0)
	assert_int(state.characters[1].x).is_greater(1000 * 1000)


func test_of_two_bot_workers_as_near_the_snail_only_the_lower_seat_goes_to_ride_it() -> void:
	var cfg := _snail_floor([Vector2i(1000, 960), Vector2i(1000, 960)], [])
	var state := Sim.create_match(_config(MapData.from_config(cfg), [BLUE, BLUE], [], [0, 1]))
	for i in 80:
		state = _step(state)

	assert_int(state.snail.rider).is_equal(0)
	assert_int(state.characters[1].x).is_greater(1000 * 1000)


func test_a_dead_teammate_by_the_snail_doesnt_keep_a_bot_worker_from_riding_it() -> void:
	# Blue's Bot Worker at x 500 is the nearer to the Snail at x 600, but
	# Gold's human Queen stands on it and kills it at once. The one at x 1000
	# goes instead, before the first respawns.
	var cfg := _snail_floor([Vector2i(500, 960), Vector2i(1000, 960)], [Vector2i(500, 960)])
	var state := Sim.create_match(_config(MapData.from_config(cfg), [BLUE, BLUE, GOLD], [2], [0, 1]))
	for i in 90:
		state = _step(state)

	assert_bool(state.characters[0].alive).is_false()
	assert_int(state.snail.rider).is_equal(1)


func test_a_bot_worker_leaves_the_snail_on_the_enemy_half_alone_and_runs_berries() -> void:
	# On a floor, a Blue Bot Worker spawns on the Snail, which stands on Gold's
	# half of the track; a Berry pile and Blue's Hive are off to the right. It
	# gets off, and fills its Hive rather than ride the Snail all the way.
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(300, 960)])
	cfg.set_value("snail", "start", Vector2i(300, 960))
	cfg.set_value("snail", "blue_goal", Vector2i(1860, 960))
	cfg.set_value("snail", "gold_goal", Vector2i(60, 960))
	cfg.set_value("berries", "piles", [Vector2i(900, 960)])
	cfg.set_value("hive", "blue_holes", [Vector2i(1500, 900), Vector2i(1560, 900)])
	var state := Sim.create_match(_config(MapData.from_config(cfg), [BLUE], [], [0]))
	var seen := {}
	for i in 600:
		state = _step(state)
		for e in state.events:
			if not seen.has(e.type):
				seen[e.type] = state.tick
		if state.win != MatchState.Win.NONE:
			break

	assert_int(seen.get(MatchEvent.Type.SNAIL_MOUNT, -1)).is_equal(1)
	assert_int(seen.get(MatchEvent.Type.SNAIL_DISMOUNT, 99)).is_less_equal(3)
	assert_int(state.win).is_equal(MatchState.Win.ECONOMIC)


func test_with_their_team_owning_a_warrior_gate_and_no_warriors_a_carrying_bot_worker_transforms() -> void:
	var state := _gate_match(BLUE, [], [], 4, 1)
	var started := -1
	for i in 400:
		state = _step(state)
		for e in state.events:
			if e.type == MatchEvent.Type.TRANSFORM_START and e.seat == 0:
				started = e.other
				# It stopped there on purpose, not by turning round.
				assert_int(state.inputs[0].horizontal).is_equal(SeatInput.NEUTRAL)
			assert_int(e.type).is_not_equal(MatchEvent.Type.BERRY_DEPOSIT)
		if state.characters[0].role == CharacterState.Role.WARRIOR:
			break

	assert_int(started).is_equal(0)
	assert_int(state.characters[0].role).is_equal(CharacterState.Role.WARRIOR)


func test_a_carrying_bot_worker_transforms_to_match_the_enemy_warriors_and_one_more() -> void:
	# Blue has a Warrior, but so has Gold: Blue wants one more.
	assert_bool(_transforms(_gate_match(BLUE, [Vector2i(1860, 960)], [Vector2i(60, 960)], 4, 1))).is_true()


func test_only_one_of_two_carrying_bot_workers_goes_to_make_the_one_warrior_wanted() -> void:
	# Both Blue Bot Workers spawn on the pile at x 900; the Gate is to the
	# left and the Hive to the right.
	var state := _gate_match(BLUE, [], [], 4, 2)
	var transforms := []
	var leftmost := state.characters[1].x
	for i in 400:
		state = _step(state)
		leftmost = mini(leftmost, state.characters[1].x)
		for e in state.events:
			if e.type == MatchEvent.Type.TRANSFORM_START:
				transforms.append(e.seat)

	assert_array(transforms).is_equal([0])
	assert_int(leftmost).is_greater(850 * 1000)


func test_a_carrying_bot_worker_runs_its_berry_home_instead_of_transforming() -> void:
	# A Gate Gold owns is no use to Blue.
	assert_bool(_transforms(_gate_match(GOLD, [], [], 4, 1))).is_false()
	# Blue already has a Warrior and Gold none.
	assert_bool(_transforms(_gate_match(BLUE, [Vector2i(1860, 960)], [], 4, 1))).is_false()
	# Blue's Hive has only three holes left to fill.
	assert_bool(_transforms(_gate_match(BLUE, [], [], 3, 1))).is_false()
	# Blue's Gate is a Speed Gate, which makes no Warrior.
	assert_bool(_transforms(_gate_match(BLUE, [], [], 4, 1, "speed"))).is_false()


func test_a_carrying_bot_worker_runs_its_berry_home_while_a_teammate_is_in_the_only_gate() -> void:
	# On a floor, Blue's human Worker spawns on a Berry pile on Blue's Warrior
	# Gate at x 300 and transforms there. Gold has a Warrior, so Blue is short
	# of one, but Blue's Bot Worker, carrying a Berry at x 900, heads for the
	# Hive on the right rather than wait for the Gate.
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(300, 960), Vector2i(900, 960), Vector2i(300, 960)],
		[Vector2i(1860, 960)])
	cfg.set_value("gates", "warrior", [Vector2i(300, 960)])
	cfg.set_value("berries", "piles", [Vector2i(900, 960), Vector2i(300, 960)])
	cfg.set_value("hive", "blue_holes", [Vector2i(1500, 900), Vector2i(1560, 900), Vector2i(1620, 900), Vector2i(1680, 900)])
	var config := _config(MapData.from_config(cfg), [BLUE, BLUE, BLUE, GOLD], [2], [0])
	config.warrior_seats = [3]
	var state := Sim.create_match(config)
	for i in 50:
		state = _step(state)

	assert_int(state.characters[1].gate).is_equal(0)
	assert_int(state.characters[0].x).is_greater(900 * 1000)


## On a floor, the first `workers` Seats are Blue Bot Workers spawned at x
## 902 on a Berry pile, so they carry a Berry from the first tick (and, at 5
## px a tick, can't reach the Gate's centre exactly). Blue's Hive has `holes`
## holes off to the right. Each Team has a Warrior at each of its given
## points, and `owner_team`'s human Queen stands on the Gate (a Warrior Gate
## unless `gate_type` says otherwise) at x 300, claiming it.
func _gate_match(owner_team: int, blue_warriors: Array[Vector2i], gold_warriors: Array[Vector2i],
		holes: int, workers: int, gate_type := "warrior") -> MatchState:
	var blue: Array[Vector2i] = []
	var gold: Array[Vector2i] = []
	if owner_team == BLUE:
		blue.append(Vector2i(300, 960))
	else:
		gold.append(Vector2i(300, 960))
	for i in workers:
		blue.append(Vector2i(902, 960))
	blue.append_array(blue_warriors)
	gold.append_array(gold_warriors)
	var cfg := TestMaps.config(TestMaps.floor_tiles(), blue, gold)
	cfg.set_value("gates", gate_type, [Vector2i(300, 960)])
	cfg.set_value("berries", "piles", [Vector2i(900, 960)])
	var hive: Array[Vector2i] = []
	for i in holes:
		hive.append(Vector2i(1500 + 60 * i, 900))
	cfg.set_value("hive", "blue_holes", hive)
	var teams: Array[int] = []
	for i in blue.size():
		teams.append(BLUE)
	for i in gold.size():
		teams.append(GOLD)
	# Seats: the Bot Workers, Blue's Warriors, then Blue's Queen or Gold's,
	# then Gold's Warriors.
	var bots: Array[int] = []
	for i in workers:
		bots.append(i)
	var warriors: Array[int] = []
	for i in blue_warriors.size():
		warriors.append(workers + i)
	var queen := workers + blue_warriors.size()
	for i in gold_warriors.size():
		warriors.append(queen + 1 + i)
	var config := _config(MapData.from_config(cfg), teams, [queen], bots)
	config.warrior_seats = warriors
	return Sim.create_match(config)


## Whether the Blue Bot Worker transforms within 400 ticks.
func _transforms(state: MatchState) -> bool:
	for i in 400:
		state = _step(state)
		if state.events.any(func(e: MatchEvent) -> bool: return e.type == MatchEvent.Type.TRANSFORM_START):
			return true
	return false


## A floor with the Snail at x 600, on Blue's half: Blue's Snail Goal is at
## the left edge and Gold's at the right. A Berry pile and Blue's Hive are off
## to the right.
func _snail_floor(blue: Array[Vector2i], gold: Array[Vector2i]) -> ConfigFile:
	var cfg := TestMaps.config(TestMaps.floor_tiles(), blue, gold)
	cfg.set_value("snail", "start", Vector2i(600, 960))
	cfg.set_value("snail", "blue_goal", Vector2i(60, 960))
	cfg.set_value("snail", "gold_goal", Vector2i(1860, 960))
	cfg.set_value("berries", "piles", [Vector2i(1400, 960)])
	cfg.set_value("hive", "blue_holes", [Vector2i(1500, 900), Vector2i(1560, 900)])
	return cfg


func _config(map: MapData, teams: Array[int], queens: Array[int], bots: Array[int]) -> MatchConfig:
	var config := MatchConfig.new()
	config.map = map
	config.seat_teams = teams
	config.queen_seats = queens
	config.bot_seats = bots
	config.tuning = Tuning.load_default()
	config.seed = 1
	return config


func _step(state: MatchState) -> MatchState:
	var inputs: Array[SeatInput] = []
	for c in state.characters:
		inputs.append(SeatInput.of(SeatInput.NEUTRAL))
	return Sim.step(state, TickInput.of(state.tick, inputs))
