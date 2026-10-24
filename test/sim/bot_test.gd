extends GdUnitTestSuite
## Bots: Seats the sim drives itself, through the same Seat input a device
## gives. This ticket's Bot Workers run Berries. Driven only through
## Sim.create_match and Sim.step, on Day.
##
## Seats 0-4 are Blue and 5-9 Gold unless a test says otherwise.

const BLUE := CharacterState.BLUE
const GOLD := CharacterState.GOLD
const TEAMS: Array[int] = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1]
const QUEENS: Array[int] = [0, 5]
const WORKERS: Array[int] = [1, 2, 3, 4, 6, 7, 8, 9]
const EVERY_SEAT: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]


func test_a_bot_seat_plays_its_own_input_whatever_the_tick_input_holds_for_it() -> void:
	var config := _config(TEAMS, QUEENS, WORKERS, 3)
	var fed := Sim.create_match(config)
	var idle := Sim.create_match(config)
	var start := idle.copy()
	# Every Seat is fed "right, button held": the humans (the Queens) play it,
	# the Bots ignore it.
	var mashing: Array[SeatInput] = []
	for seat in TEAMS.size():
		mashing.append(SeatInput.of(SeatInput.RIGHT, false, true))

	for i in 300:
		fed = Sim.step(fed, TickInput.of(fed.tick, mashing))
		var neutral := _neutral(idle.tick, TEAMS.size())
		for queen in QUEENS:
			neutral.seats[queen] = mashing[queen]
		idle = Sim.step(idle, neutral)
		if fed.fingerprint() != idle.fingerprint():
			fail("Bot Seats played the tick input at tick %d" % fed.tick)
			return

	for queen in QUEENS:
		assert_object(fed.inputs[queen]).is_same(mashing[queen])
	# The Bots did move, on their own input.
	var moved := WORKERS.filter(func(s: int) -> bool: return fed.characters[s].x != start.characters[s].x)
	assert_int(moved.size()).is_equal(WORKERS.size())
	for seat in WORKERS:
		assert_object(fed.inputs[seat]).is_not_same(mashing[seat])


func test_bot_input_is_only_ever_a_stick_and_button_with_down_only_for_a_queen() -> void:
	var config := _config(TEAMS, QUEENS, EVERY_SEAT, 11)
	config.bot_difficulties = [Bot.Difficulty.EASY, Bot.Difficulty.HARD]
	var state := Sim.create_match(config)
	var directions := [SeatInput.LEFT, SeatInput.NEUTRAL, SeatInput.RIGHT]

	for i in 1000:
		state = Sim.step(state, _neutral(state.tick, TEAMS.size()))
		assert_int(state.inputs.size()).is_equal(TEAMS.size())
		for c in state.characters:
			var input: SeatInput = state.inputs[c.seat]
			if input.get_script() != SeatInput or not input.horizontal in directions \
					or typeof(input.down) != TYPE_BOOL or typeof(input.button) != TYPE_BOOL \
					or (input.down and c.role != CharacterState.Role.QUEEN):
				fail("Seat %d's Bot input at tick %d is outside the Seat input shape" % [c.seat, state.tick])
				return


func test_easy_bots_never_run_faster_than_eight_tenths_of_max_horizontal_speed() -> void:
	# Blue's Bots are Easy and Gold's Normal; Seats 1 and 6 have the Speed
	# upgrade. Workers only, so nothing is killed and every Bot keeps running
	# Berries. A Bump can hand a character a faster enemy's speed, so ticks
	# that start or end in a Bump don't count.
	var t := Tuning.load_default()
	assert_int(t.bot_easy_speed_ratio).is_equal(8000)
	var config := _config(TEAMS, [], EVERY_SEAT, 21)
	config.bot_difficulties = [Bot.Difficulty.EASY, Bot.Difficulty.NORMAL]
	config.speed_seats = [1, 6]
	var state := Sim.create_match(config)
	var fastest := []
	fastest.resize(TEAMS.size())
	fastest.fill(0)
	for i in 600:
		var before := state
		state = Sim.step(state, _neutral(state.tick, TEAMS.size()))
		for c in state.characters:
			if before.characters[c.seat].bump_ticks == 0 and c.bump_ticks == 0:
				fastest[c.seat] = maxi(fastest[c.seat], absi(c.vx))

	var easy := t.worker_max_speed * 8000 / 10000
	var speed := t.speed_ratio
	assert_array(fastest).is_equal([easy, easy * speed / 10000, easy, easy, easy,
		t.worker_max_speed, t.worker_max_speed * speed / 10000, t.worker_max_speed, t.worker_max_speed,
		t.worker_max_speed])


func test_bot_workers_alone_on_a_team_reach_an_economic_win_within_40_seconds() -> void:
	# They run past the Gates on their way, spending no Berries in them.
	for team in [BLUE, GOLD]:
		var teams: Array[int] = [team, team, team, team, team]
		var no_queen: Array[int] = []
		var state := Sim.create_match(_config(teams, no_queen, [0, 1, 2, 3, 4], 5 + team))
		for i in 2000:
			state = Sim.step(state, _neutral(state.tick, teams.size()))
			assert_int(_count_events(state, MatchEvent.Type.TRANSFORM_START)).is_equal(0)
			if state.win != MatchState.Win.NONE:
				break
		assert_int(state.win).is_equal(MatchState.Win.ECONOMIC)
		assert_int(state.winner).is_equal(team)


func test_a_bot_worker_gets_off_the_snail_and_runs_berries() -> void:
	# On a floor, a Blue Bot Worker spawns on the Snail; a Berry pile and
	# Blue's Hive are off to the right.
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(300, 960)])
	cfg.set_value("snail", "start", Vector2i(300, 960))
	cfg.set_value("snail", "blue_goal", Vector2i(60, 960))
	cfg.set_value("snail", "gold_goal", Vector2i(1860, 960))
	cfg.set_value("berries", "piles", [Vector2i(900, 960)])
	cfg.set_value("hive", "blue_holes", [Vector2i(1500, 900), Vector2i(1560, 900)])
	var config := MatchConfig.new()
	config.map = MapData.from_config(cfg)
	config.seat_teams = [BLUE]
	config.bot_seats = [0]
	config.tuning = Tuning.load_default()
	var state := Sim.create_match(config)
	var seen := {}
	for i in 600:
		state = Sim.step(state, _neutral(state.tick, 1))
		for e in state.events:
			if not seen.has(e.type):
				seen[e.type] = state.tick
		if state.win != MatchState.Win.NONE:
			break

	assert_int(seen.get(MatchEvent.Type.SNAIL_MOUNT, -1)).is_equal(1)
	assert_int(seen.get(MatchEvent.Type.SNAIL_DISMOUNT, 99)).is_less_equal(3)
	assert_int(state.win).is_equal(MatchState.Win.ECONOMIC)


func _config(teams: Array[int], queens: Array[int], bots: Array[int], seed: int) -> MatchConfig:
	var config := MatchConfig.new()
	config.map = MapData.load_file("res://data/maps/day.cfg")
	config.seat_teams = teams
	config.queen_seats = queens
	config.bot_seats = bots
	config.tuning = Tuning.load_default()
	config.seed = seed
	return config


func test_a_bot_worker_lets_go_of_the_button_before_pressing_it_again() -> void:
	# A Berry pile sits under three holes of Blue's Hive, out of reach without
	# a jump. The Bot Worker takes a Berry, jumps to deposit it, and lands on
	# the pile with the button still held and a new Berry in hand: it must let
	# go before it can jump again.
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(300, 960)])
	cfg.set_value("berries", "piles", [Vector2i(300, 960)])
	cfg.set_value("hive", "blue_holes", [Vector2i(300, 860), Vector2i(300, 860), Vector2i(300, 860)])
	var config := MatchConfig.new()
	config.map = MapData.from_config(cfg)
	config.seat_teams = [BLUE]
	config.bot_seats = [0]
	config.tuning = Tuning.load_default()
	var state := Sim.create_match(config)
	for i in 300:
		state = Sim.step(state, _neutral(state.tick, 1))
		if state.win != MatchState.Win.NONE:
			break

	assert_int(state.win).is_equal(MatchState.Win.ECONOMIC)


func _count_events(state: MatchState, type: MatchEvent.Type) -> int:
	return state.events.filter(func(e: MatchEvent) -> bool: return e.type == type).size()


func _neutral(tick: int, seats: int) -> TickInput:
	var inputs: Array[SeatInput] = []
	for i in seats:
		inputs.append(SeatInput.of(SeatInput.NEUTRAL))
	return TickInput.of(tick, inputs)
