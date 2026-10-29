extends GdUnitTestSuite
## Bot Warriors hunt enemy Workers, Snail riders and Berry carriers first, and
## the enemy Queen; they kill what is below them, keep away from enemy swords
## higher than theirs, and guard their own Team's Snail rider. Driven only
## through Sim.create_match and Sim.step.

const PX := 1000
const BLUE := CharacterState.BLUE
const GOLD := CharacterState.GOLD


func test_a_bot_warrior_with_an_enemy_snail_rider_in_reach_goes_for_the_rider() -> void:
	# On a floor, Gold's human Worker rides the Snail from x 960 toward Gold's
	# goal on the right. Blue's Bot Warrior starts at x 1300; a Gold Worker
	# carrying a Berry stands nearer it, at x 1500.
	var cfg := _snail_floor()
	cfg.set_value("spawns", "blue", [Vector2i(1300, 960)])
	cfg.set_value("spawns", "gold", [Vector2i(960, 960), Vector2i(1500, 960)])
	cfg.set_value("berries", "piles", [Vector2i(1500, 960)])
	var config := _config(MapData.from_config(cfg), [BLUE, GOLD, GOLD], [], [0])
	config.warrior_seats = [0]
	var state := Sim.create_match(config)
	state = _step(state)
	assert_int(state.snail.rider).is_equal(1)
	assert_int(state.characters[2].berry).is_not_equal(-1)

	assert_int(_first_kill(state, 0, 400)).is_equal(1)


func test_a_bot_warrior_leaves_alone_an_enemy_snail_rider_a_higher_enemy_warrior_guards() -> void:
	# Gold's human Worker rides the Snail from x 960; Gold's human Warrior
	# hovers 100 px over it. Blue's Bot Warrior, at x 300, stays away.
	var cfg := _snail_floor()
	cfg.set_value("spawns", "blue", [Vector2i(300, 960)])
	cfg.set_value("spawns", "gold", [Vector2i(960, 960), Vector2i(960, 960)])
	var config := _config(MapData.from_config(cfg), [BLUE, GOLD, GOLD], [], [0])
	config.warrior_seats = [0, 2]
	var state := Sim.create_match(config)
	for i in 300:
		var inputs := _hover(state, 2, 860 * PX)
		# The guard keeps over the rider as the Snail carries it right.
		var dx := state.characters[1].x - state.characters[2].x
		inputs.seats[2] = SeatInput.of(signi(dx) if absi(dx) > 4 * PX else SeatInput.NEUTRAL, false, inputs.seats[2].button)
		state = Sim.step(state, inputs)

	assert_int(state.snail.rider).is_equal(1)
	assert_bool(state.characters[0].alive).is_true()


func test_a_bot_warrior_hunts_an_enemy_berry_carrier_before_a_nearer_empty_handed_worker() -> void:
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(900, 960)], [Vector2i(700, 960), Vector2i(1400, 960)])
	cfg.set_value("berries", "piles", [Vector2i(1400, 960)])
	var config := _config(MapData.from_config(cfg), [BLUE, GOLD, GOLD], [], [0])
	config.warrior_seats = [0]

	assert_int(_first_kill(Sim.create_match(config), 0, 400)).is_equal(2)


func test_a_bot_warrior_kills_the_enemy_queen_from_above() -> void:
	# Gold's human Queen hovers 100 px up, 400 px from Blue's Bot Warrior. With
	# no Eggs on a test Map, killing her wins.
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(500, 960)], [Vector2i(900, 960)])
	var config := _config(MapData.from_config(cfg), [BLUE, GOLD], [1], [0])
	config.warrior_seats = [0]
	var state := Sim.create_match(config)
	for i in 600:
		state = Sim.step(state, _hover(state, 1, 860 * PX))
		if state.win != MatchState.Win.NONE:
			break

	assert_int(state.win).is_equal(MatchState.Win.MILITARY)
	assert_int(state.winner).is_equal(BLUE)


func test_a_bot_warrior_gets_above_a_higher_enemy_warrior_in_its_way_and_kills_it() -> void:
	# Gold's human Warrior hovers 30 px up at x 900, between Blue's Bot Warrior
	# at x 500 and a Gold Worker at x 1300: higher than the Bot as it comes
	# along the floor, so flying into it would lose the Joust. The Bot backs
	# off and climbs, then comes down on it from above.
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(500, 960)], [Vector2i(900, 960), Vector2i(1300, 960)])
	var config := _config(MapData.from_config(cfg), [BLUE, GOLD, GOLD], [], [0])
	config.warrior_seats = [0, 1]
	var state := Sim.create_match(config)
	for i in 600:
		state = Sim.step(state, _hover(state, 1, 930 * PX))
		if not state.characters[0].alive:
			fail("The Bot Warrior flew into the higher Warrior at tick %d" % state.tick)
			return
		if not state.characters[1].alive:
			break

	assert_bool(state.characters[1].alive).is_false()


func test_a_bot_warrior_guards_its_own_snail_rider_from_the_enemy_queen() -> void:
	# On a floor, Blue's human Worker rides the Snail toward Blue's goal on the
	# left, and Gold's Bot Queen comes for it from the right. Without a Blue
	# Warrior she kills the rider; with Blue's Bot Warrior starting by the
	# Snail, the rider gets home.
	assert_bool(_rider_gets_home(false)).is_false()
	assert_bool(_rider_gets_home(true)).is_true()


func test_a_bot_warrior_guarding_its_snail_rider_kills_an_enemy_warrior_flying_at_it() -> void:
	# Blue's human Worker rides the Snail from x 700 toward Blue's goal on the
	# left, with Blue's Bot Warrior by it. Gold's human Warrior flies at the
	# rider low over the floor from x 1100.
	var cfg := _snail_floor()
	cfg.set_value("snail", "start", Vector2i(700, 960))
	cfg.set_value("spawns", "blue", [Vector2i(700, 960), Vector2i(760, 960)])
	cfg.set_value("spawns", "gold", [Vector2i(1100, 960)])
	var config := _config(MapData.from_config(cfg), [BLUE, BLUE, GOLD], [], [1])
	config.warrior_seats = [1, 2]
	var state := Sim.create_match(config)
	for i in 300:
		var inputs := _hover(state, 2, 930 * PX)
		inputs.seats[2] = SeatInput.of(SeatInput.LEFT, false, inputs.seats[2].button)
		state = Sim.step(state, inputs)
		if not state.characters[0].alive or not state.characters[2].alive:
			break

	assert_bool(state.characters[0].alive).is_true()
	assert_bool(state.characters[2].alive).is_false()


func test_only_the_bot_warrior_nearest_its_snail_rider_guards_it_and_the_other_hunts() -> void:
	# Blue's human Worker rides the Snail from x 700. Blue's Bot Warriors start
	# at x 760, by it, and x 1500, near a Gold Worker carrying a Berry at 1700.
	var cfg := _snail_floor()
	cfg.set_value("snail", "start", Vector2i(700, 960))
	cfg.set_value("spawns", "blue", [Vector2i(700, 960), Vector2i(760, 960), Vector2i(1500, 960)])
	cfg.set_value("spawns", "gold", [Vector2i(1700, 960)])
	cfg.set_value("berries", "piles", [Vector2i(1700, 960)])
	var config := _config(MapData.from_config(cfg), [BLUE, BLUE, BLUE, GOLD], [], [1, 2])
	config.warrior_seats = [1, 2]
	var state := Sim.create_match(config)
	var killer := -1
	for i in 300:
		state = _step(state)
		for e in state.events:
			if e.type == MatchEvent.Type.KILL:
				killer = e.seat
		if killer != -1:
			break

	assert_int(killer).is_equal(2)
	assert_int(absi(state.characters[1].x - state.characters[0].x)).is_less(100 * PX)


## Whether Blue's rider, Seat 0, brings the Snail home to a Snail Win, with or
## without a Blue Bot Warrior guarding it.
func _rider_gets_home(guarded: bool) -> bool:
	var cfg := _snail_floor()
	cfg.set_value("snail", "start", Vector2i(700, 960))
	var blue: Array[Vector2i] = [Vector2i(700, 960)]
	if guarded:
		blue.append(Vector2i(760, 960))
	cfg.set_value("spawns", "blue", blue)
	cfg.set_value("spawns", "gold", [Vector2i(1700, 960)])
	var teams: Array[int] = []
	for i in blue.size():
		teams.append(BLUE)
	teams.append(GOLD)
	var gold_queen := blue.size()
	var config := _config(MapData.from_config(cfg), teams, [gold_queen], [gold_queen])
	if guarded:
		config.bot_seats = [1, gold_queen]
		config.warrior_seats = [1]
	var state := Sim.create_match(config)
	for i in 1800:
		state = _step(state)
		if not state.characters[0].alive or state.win != MatchState.Win.NONE:
			break
	return state.win == MatchState.Win.SNAIL and state.winner == BLUE


## A floor with the Snail at x 960, Blue's Snail Goal at the left edge and
## Gold's at the right.
func _snail_floor() -> ConfigFile:
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [])
	cfg.set_value("snail", "start", Vector2i(960, 960))
	cfg.set_value("snail", "blue_goal", Vector2i(60, 960))
	cfg.set_value("snail", "gold_goal", Vector2i(1860, 960))
	return cfg


## The Seat that `killer` kills first within `ticks`, or -1.
func _first_kill(state: MatchState, killer: int, ticks: int) -> int:
	for i in ticks:
		state = _step(state)
		for e in state.events:
			if e.type == MatchEvent.Type.KILL and e.seat == killer:
				return e.other
	return -1


func _config(map: MapData, teams: Array[int], queens: Array[int], bots: Array[int]) -> MatchConfig:
	var config := MatchConfig.new()
	config.map = map
	config.seat_teams = teams
	config.queen_seats = queens
	config.bot_seats = bots
	config.tuning = Tuning.load_default()
	config.seed = 1
	# Hard Bots react quickest and notice every threat; Difficulty has its own
	# tests.
	config.bot_difficulties = [Bot.Difficulty.HARD, Bot.Difficulty.HARD]
	return config


func _step(state: MatchState) -> MatchState:
	return Sim.step(state, _neutral(state))


## Neutral input, but Seat `seat` Flaps to hold its feet at about `height`.
func _hover(state: MatchState, seat: int, height: int) -> TickInput:
	var c := state.characters[seat]
	var inputs := _neutral(state)
	inputs.seats[seat] = SeatInput.of(SeatInput.NEUTRAL, false,
		c.y > height and c.vy >= 0 and not c.button_held)
	return inputs


func _neutral(state: MatchState) -> TickInput:
	var inputs: Array[SeatInput] = []
	for c in state.characters:
		inputs.append(SeatInput.of(SeatInput.NEUTRAL))
	return TickInput.of(state.tick, inputs)
