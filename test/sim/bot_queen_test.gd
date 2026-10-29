extends GdUnitTestSuite
## The Bot Queen: she claims Gates, hunts enemy Workers (Snail riders first),
## Dives on what's below her, and keeps away from enemy swords higher than
## hers. Driven only through Sim.create_match and Sim.step.

const PX := 1000
const BLUE := CharacterState.BLUE
const GOLD := CharacterState.GOLD
const DAY := "res://data/maps/day.cfg"


func test_from_match_start_each_bot_queen_claims_a_gate_within_10_seconds() -> void:
	var config := _config(MapData.load_file(DAY), [0, 0, 0, 0, 0, 1, 1, 1, 1, 1], [0, 5],
		[0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 2)
	var state := Sim.create_match(config)
	var claimed := {}
	for i in 500:
		state = _step(state)
		for e in state.events:
			if e.type == MatchEvent.Type.GATE_CLAIM:
				claimed[e.seat] = true

	assert_dict(claimed).contains_keys([0, 5])


func test_she_goes_straight_down_and_kills_an_enemy_worker_riding_the_snail_diving_onto_it() -> void:
	# On Day, Gold's only Seat is a human Worker who starts on the Snail and
	# rides it toward Gold's Snail Goal; Blue's only Seat is the Bot Queen, up
	# on the Hives' level.
	var cfg := ConfigFile.new()
	cfg.load(DAY)
	cfg.set_value("spawns", "gold", [cfg.get_value("snail", "start")])
	var state := Sim.create_match(_config(MapData.from_config(cfg), [BLUE, GOLD], [0], [0], 4))
	state = _step(state)
	assert_int(state.snail.rider).is_equal(1)
	var dived := false
	var killed := -1
	for i in 1500:
		state = _step(state)
		dived = dived or state.inputs[0].down
		for e in state.events:
			if e.type == MatchEvent.Type.KILL and e.seat == 0 and e.other == 1:
				killed = state.tick
			# The rider comes before the Gates.
			assert_int(e.type).is_not_equal(MatchEvent.Type.GATE_CLAIM)
		if killed != -1:
			break

	assert_int(killed).is_greater(0)
	assert_bool(dived).is_true()
	# She got there long before the Snail reached Gold's goal.
	assert_int(state.win).is_equal(MatchState.Win.NONE)


func test_she_climbs_over_or_backs_off_from_a_higher_enemy_warrior_in_her_way() -> void:
	# On a floor, the Bot Queen starts at the left; a neutral Warrior Gate is
	# on the right, the nearest thing for her to do.
	var alone := _gate_match([])
	var claimed := false
	for i in 400:
		alone = _step(alone)
		claimed = claimed or _has_event(alone, MatchEvent.Type.GATE_CLAIM)
	assert_bool(claimed).is_true()

	# A Gold Warrior hovers just above the floor halfway there: higher than
	# her as she comes along the floor, so flying into it would kill her.
	var state := _gate_match([Vector2i(900, 960)])
	for i in 600:
		state = Sim.step(state, _hover(state, 1, 930 * PX))
		if not state.characters[0].alive:
			fail("The Bot Queen flew into the higher Warrior at tick %d" % state.tick)
			return


func test_she_claims_a_neutral_gate_before_stealing_a_nearer_enemy_one() -> void:
	# Gold's human Queen starts on the Gate at x 1000, claiming it, then flies
	# up out of the way; the Gate at x 300 is neutral. Blue's Bot Queen starts
	# at 700, too far from Gold's to go for her.
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(700, 960)], [Vector2i(1000, 960)])
	cfg.set_value("gates", "warrior", [Vector2i(300, 960), Vector2i(1000, 960)])
	var state := Sim.create_match(_config(MapData.from_config(cfg), [BLUE, GOLD], [0, 1], [0], 1))
	var claims := []
	for i in 600:
		# She Flaps as fast as she can until 200 px from the top.
		var inputs := _neutral(state)
		var gold := state.characters[1]
		inputs.seats[1] = SeatInput.of(SeatInput.NEUTRAL, false, gold.y > 200 * PX and not gold.button_held)
		state = Sim.step(state, inputs)
		for e in state.events:
			if e.type == MatchEvent.Type.GATE_CLAIM:
				claims.append([e.seat, e.other])

	assert_array(claims).is_equal([[1, 1], [0, 0], [0, 1]])


func test_she_keeps_further_from_a_higher_warrior_with_no_eggs_left_or_fewer_warriors() -> void:
	# A Gold Warrior hovers 170 px up, halfway along the floor to the Gate. Blue
	# has a Warrior of its own, far off. With Eggs left and Warriors even, she
	# passes under it to the Gate; with no Eggs, or a second Gold Warrior, she
	# keeps away from it.
	var safe := _risk_match(1, false)
	var no_eggs := _risk_match(0, false)
	var outnumbered := _risk_match(1, true)
	var claimed := [false, false, false]
	for i in 400:
		safe = Sim.step(safe, _hover(safe, 2, 790 * PX))
		no_eggs = Sim.step(no_eggs, _hover(no_eggs, 2, 790 * PX))
		outnumbered = Sim.step(outnumbered, _hover(outnumbered, 2, 790 * PX))
		claimed[0] = claimed[0] or _has_event(safe, MatchEvent.Type.GATE_CLAIM)
		claimed[1] = claimed[1] or _has_event(no_eggs, MatchEvent.Type.GATE_CLAIM)
		claimed[2] = claimed[2] or _has_event(outnumbered, MatchEvent.Type.GATE_CLAIM)

	assert_array(claimed).is_equal([true, false, false])


func test_she_leaves_a_gate_a_higher_enemy_warrior_guards_for_one_nobody_guards() -> void:
	# The neutral Gate at x 1200 is nearer her, but a Gold Warrior hovers over
	# it; the one at x 300 is free.
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(900, 960)], [Vector2i(1200, 960)])
	cfg.set_value("gates", "warrior", [Vector2i(300, 960), Vector2i(1200, 960)])
	var config := _config(MapData.from_config(cfg), [BLUE, GOLD], [0], [0], 1)
	config.warrior_seats = [1]
	var state := Sim.create_match(config)
	var claimed := -1
	for i in 300:
		state = Sim.step(state, _hover(state, 1, 900 * PX))
		for e in state.events:
			if e.type == MatchEvent.Type.GATE_CLAIM:
				claimed = e.other
		if claimed != -1:
			break

	assert_int(claimed).is_equal(0)


func test_she_hunts_an_enemy_worker_carrying_a_berry_before_a_nearer_empty_handed_one() -> void:
	# Gold's Worker at x 1400 stands on a Berry pile, so carries a Berry; the
	# one at x 700 has none. Blue's Bot Queen starts at x 900.
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(900, 960)], [Vector2i(700, 960), Vector2i(1400, 960)])
	cfg.set_value("berries", "piles", [Vector2i(1400, 960)])
	var state := Sim.create_match(_config(MapData.from_config(cfg), [BLUE, GOLD, GOLD], [0], [0], 1))
	var first_killed := -1
	for i in 400:
		state = _step(state)
		for e in state.events:
			if e.type == MatchEvent.Type.KILL and first_killed == -1:
				first_killed = e.other
		if first_killed != -1:
			break

	assert_int(first_killed).is_equal(2)


func test_she_flies_the_short_way_round_where_the_map_wraps() -> void:
	# A floor whose rows wrap; the only Gate is 200 px from her across the
	# side edge, and 1720 px the other way.
	var tiles: Array[String] = []
	for row in TestMaps.floor_tiles():
		tiles.append("~" + row.substr(1))
	var cfg := TestMaps.config(tiles, [Vector2i(100, 960)])
	cfg.set_value("gates", "warrior", [Vector2i(1820, 960)])
	var state := Sim.create_match(_config(MapData.from_config(cfg), [BLUE], [0], [0], 1))
	var claimed := -1
	for i in 150:
		state = _step(state)
		if _has_event(state, MatchEvent.Type.GATE_CLAIM):
			claimed = state.tick
			break

	assert_int(claimed).is_between(1, 100)


## The floor Match of the higher-Warrior test with Blue's Bot Queen (Seat 0)
## given `eggs` Eggs, a Blue Warrior far off (Seat 1) and a Gold Warrior
## (Seat 2) at x 900, and a second idle Gold Warrior far off if `outnumbered`.
func _risk_match(eggs: int, outnumbered: bool) -> MatchState:
	var gold: Array[Vector2i] = [Vector2i(900, 960)]
	if outnumbered:
		gold.append(Vector2i(60, 960))
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(300, 960), Vector2i(1860, 960)], gold)
	cfg.set_value("gates", "warrior", [Vector2i(1500, 960)])
	var egg_points: Array[Vector2i] = []
	for i in eggs:
		egg_points.append(Vector2i(300, 960))
	cfg.set_value("hive", "blue_eggs", egg_points)
	var teams: Array[int] = [BLUE, BLUE]
	var warriors: Array[int] = [1]
	for i in gold.size():
		teams.append(GOLD)
		warriors.append(2 + i)
	var config := _config(MapData.from_config(cfg), teams, [0], [0], 1)
	config.warrior_seats = warriors
	return Sim.create_match(config)


## A Match on a floor (top at y 960 px) with a neutral Warrior Gate at x 1500
## px: Blue's Bot Queen at x 300, and a Gold Warrior at each of `gold_px`.
func _gate_match(gold_px: Array[Vector2i]) -> MatchState:
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(300, 960)], gold_px)
	cfg.set_value("gates", "warrior", [Vector2i(1500, 960)])
	var teams: Array[int] = [BLUE]
	var warriors: Array[int] = []
	for i in gold_px.size():
		teams.append(GOLD)
		warriors.append(1 + i)
	var config := _config(MapData.from_config(cfg), teams, [0], [0], 1)
	config.warrior_seats = warriors
	return Sim.create_match(config)


## Neutral input for every Seat but `seat`, a winged character that Flaps to
## hold its feet at `height` and doesn't steer.
func _hover(state: MatchState, seat: int, height: int) -> TickInput:
	var c := state.characters[seat]
	var inputs := _neutral(state)
	inputs.seats[seat] = SeatInput.of(SeatInput.NEUTRAL, false,
		c.y > height and c.vy >= 0 and not c.button_held)
	return inputs


func _config(map: MapData, teams: Array[int], queens: Array[int], bots: Array[int], seed: int) -> MatchConfig:
	var config := MatchConfig.new()
	config.map = map
	config.seat_teams = teams
	config.queen_seats = queens
	config.bot_seats = bots
	config.tuning = Tuning.load_default()
	config.seed = seed
	# Hard Bots react quickest and notice every threat; Difficulty has its own
	# tests.
	config.bot_difficulties = [Bot.Difficulty.HARD, Bot.Difficulty.HARD]
	return config


func _step(state: MatchState) -> MatchState:
	return Sim.step(state, _neutral(state))


func _neutral(state: MatchState) -> TickInput:
	var inputs: Array[SeatInput] = []
	for c in state.characters:
		inputs.append(SeatInput.of(SeatInput.NEUTRAL))
	return TickInput.of(state.tick, inputs)


func _has_event(state: MatchState, type: MatchEvent.Type) -> bool:
	return state.events.any(func(e: MatchEvent) -> bool: return e.type == type)
