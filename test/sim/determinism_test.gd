extends GdUnitTestSuite
## ADR-0002's determinism guarantees: Replays reproduce a Match exactly, copies
## of a state step identically, and the sim reads no clock and no unseeded
## randomness. Matches run on Day with all ten Seats and scripted input that
## looks random but comes from a fixed sequence, so every run is the same.

const QUEENS: Array[int] = [0, 5]
## Seats that start as Warriors, and with the Speed upgrade (one of them a
## Speed Warrior).
const WARRIORS: Array[int] = [1, 6]
const SPEED: Array[int] = [2, 6, 7]
const TICKS := 1500
const ALL_SEATS: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
## Matches with Bots are shorter, and compare states every CHECK_TICKS ticks:
## fingerprints are slow.
const BOT_TICKS := 1000
const CHECK_TICKS := 4


func test_a_replay_played_back_reproduces_the_match() -> void:
	var config := _config(1234)
	var state := Sim.create_match(config)
	var replay := Replay.record(config)
	var kills := 0
	for tick in TICKS:
		var input := _scripted_input(state)
		replay.add(input)
		state = Sim.step(state, input)
		kills += state.events.filter(func(e: MatchEvent) -> bool: return e.type == MatchEvent.Type.KILL).size()
	# The scripted Match should exercise combat as well as movement.
	assert_int(kills).is_greater(0)

	var loaded := Replay.from_text(replay.to_text())
	var played := Sim.create_match(loaded.config())
	for tick in loaded.length():
		played = Sim.step(played, loaded.input(tick))

	assert_int(loaded.length()).is_equal(TICKS)
	assert_int(played.tick).is_equal(state.tick)
	assert_str(played.fingerprint()).is_equal(state.fingerprint())


func test_a_replay_keeps_its_own_tuning_and_map() -> void:
	var config := _config(7)
	config.tuning = config.tuning.with_values({"worker_max_speed": 3000})
	var replay := Replay.record(config)

	var loaded := Replay.from_text(replay.to_text()).config()

	assert_int(loaded.tuning.worker_max_speed).is_equal(3000)
	assert_int(loaded.seed).is_equal(7)
	assert_array(loaded.seat_teams).is_equal(config.seat_teams)
	assert_array(loaded.queen_seats).is_equal(config.queen_seats)
	assert_array(loaded.warrior_seats).is_equal(WARRIORS)
	assert_array(loaded.speed_seats).is_equal(SPEED)
	assert_str(Sim.create_match(loaded).fingerprint()).is_equal(Sim.create_match(config).fingerprint())


func test_copies_of_a_state_mid_match_step_identically() -> void:
	var state := Sim.create_match(_config(99))
	for tick in TICKS / 2:
		state = Sim.step(state, _scripted_input(state))
	var a := state.copy()
	var b := state.copy()

	for tick in TICKS / 2:
		var input := _scripted_input(a)
		a = Sim.step(a, input)
		b = Sim.step(b, input)
		state = Sim.step(state, input)

	assert_str(a.fingerprint()).is_equal(b.fingerprint())
	assert_str(a.fingerprint()).is_equal(state.fingerprint())


func test_a_copy_keeps_everything_in_the_state() -> void:
	# A field copy() forgot would come back at its default and change the
	# fingerprint, as soon as the Match gives it any other value. Every fifth
	# tick is checked, to keep the test quick.
	var state := Sim.create_match(_config(5))
	for tick in TICKS:
		state = Sim.step(state, _scripted_input(state))
		if tick % 5 != 0:
			continue
		var copy := state.copy()
		if copy.fingerprint() != state.fingerprint():
			fail("The copy at tick %d differs from its original" % state.tick)
			return


func test_the_seed_is_part_of_the_match_state_and_stays_in_it() -> void:
	var a := Sim.create_match(_config(1))
	var same := Sim.create_match(_config(1))
	var other := Sim.create_match(_config(2))

	for tick in 10:
		var input := _scripted_input(a)
		a = Sim.step(a, input)
		same = Sim.step(same, input)
		other = Sim.step(other, input)

	assert_str(a.fingerprint()).is_equal(same.fingerprint())
	assert_str(a.fingerprint()).is_not_equal(other.fingerprint())


func test_the_same_seed_and_seats_give_the_same_match_tick_for_tick_with_bots() -> void:
	var config := _bot_config(31, ALL_SEATS)
	var start := Sim.create_match(config)
	var a := start
	var b := Sim.create_match(config)

	for tick in BOT_TICKS:
		a = Sim.step(a, _scripted_input(a))
		b = Sim.step(b, _scripted_input(b))
		if tick % CHECK_TICKS == 0 and a.fingerprint() != b.fingerprint():
			fail("The Matches differ at tick %d" % a.tick)
			return
		# A copy keeps every Bot's state too.
		if tick % CHECK_TICKS == 1 and a.copy().fingerprint() != a.fingerprint():
			fail("The copy at tick %d differs from its original" % a.tick)
			return

	# The Bots drew from the Match's random generator.
	assert_int(a.rng).is_not_equal(start.rng)


func test_copies_of_a_state_mid_match_with_bots_step_identically() -> void:
	# Bots see their enemies as they stood a few ticks before, which a copy
	# keeps too.
	var state := Sim.create_match(_bot_config(13, ALL_SEATS))
	for tick in 300:
		state = Sim.step(state, _scripted_input(state))
	var copy := state.copy()

	for tick in 100:
		state = Sim.step(state, _scripted_input(state))
		copy = Sim.step(copy, _scripted_input(copy))

	assert_str(copy.fingerprint()).is_equal(state.fingerprint())


func test_a_replay_keeps_only_human_input_and_reproduces_a_match_with_bots() -> void:
	# The Queens are human; every other Seat is a Bot, whose scripted input is
	# ignored and not recorded.
	var bots: Array[int] = [1, 2, 3, 4, 6, 7, 8, 9]
	var config := _bot_config(57, bots)
	var state := Sim.create_match(config)
	var replay := Replay.record(config)
	# The same Match recorded with the Bot Seats' input left neutral.
	var without_bots := Replay.record(config)
	for tick in BOT_TICKS:
		var input := _scripted_input(state)
		replay.add(input)
		var humans_only := _scripted_input(state)
		for seat in bots:
			humans_only.seats[seat] = SeatInput.of(SeatInput.NEUTRAL)
		without_bots.add(humans_only)
		state = Sim.step(state, input)

	var text := replay.to_text()
	assert_str(text).is_equal(without_bots.to_text())
	var loaded := Replay.from_text(text)
	var loaded_config := loaded.config()
	assert_array(loaded_config.bot_seats).is_equal(bots)
	assert_array(loaded_config.bot_difficulties).is_equal(config.bot_difficulties)
	var played := Sim.create_match(loaded_config)
	for tick in loaded.length():
		var input := loaded.input(tick)
		for seat in bots:
			assert_int(input.seats[seat].horizontal).is_equal(SeatInput.NEUTRAL)
		played = Sim.step(played, input)

	assert_int(loaded.length()).is_equal(BOT_TICKS)
	assert_str(played.fingerprint()).is_equal(state.fingerprint())


func test_a_replay_of_an_all_bot_match_keeps_its_length() -> void:
	var config := _bot_config(3, ALL_SEATS)
	var state := Sim.create_match(config)
	var replay := Replay.record(config)
	for tick in 200:
		var input := _scripted_input(state)
		replay.add(input)
		state = Sim.step(state, input)

	var loaded := Replay.from_text(replay.to_text())
	var played := Sim.create_match(loaded.config())
	for tick in loaded.length():
		played = Sim.step(played, loaded.input(tick))

	assert_int(loaded.length()).is_equal(200)
	assert_str(played.fingerprint()).is_equal(state.fingerprint())


func test_the_sim_reads_no_clock_and_no_unseeded_randomness() -> void:
	var forbidden := RegEx.create_from_string(
		"\\b(Time|OS|RandomNumberGenerator|randi|randf|randi_range|randf_range|randomize|seed|rand_from_seed)\\s*[.(]")
	for file in DirAccess.get_files_at("res://sim"):
		if not file.ends_with(".gd"):
			continue
		var lines := FileAccess.get_file_as_string("res://sim/" + file).split("\n")
		for n in lines.size():
			var code := lines[n].get_slice("#", 0)
			if forbidden.search(code) != null:
				fail("sim/%s:%d reads the clock or unseeded randomness: %s" % [file, n + 1, code.strip_edges()])


func _config(seed: int) -> MatchConfig:
	var config := MatchConfig.new()
	config.map = MapData.load_file("res://data/maps/day.cfg")
	config.seat_teams = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1]
	config.queen_seats = QUEENS
	config.warrior_seats = WARRIORS
	config.speed_seats = SPEED
	config.tuning = Tuning.load_default()
	config.seed = seed
	return config


## A Match on Day with `bots` as Bot Seats, Blue's Easy and Gold's Hard, and
## no Seats starting upgraded.
func _bot_config(seed: int, bots: Array[int]) -> MatchConfig:
	var config := _config(seed)
	config.warrior_seats = []
	config.speed_seats = []
	config.bot_seats = bots
	config.bot_difficulties = [Bot.Difficulty.EASY, Bot.Difficulty.HARD]
	return config


## Every Seat's input for `state`'s tick, from a fixed hash of the tick and
## Seat: each Seat holds a stick direction for a while, presses the button in
## bursts and, for the Queens, sometimes Dives.
func _scripted_input(state: MatchState) -> TickInput:
	var seats: Array[SeatInput] = []
	for seat in state.characters.size():
		var phase := _mix(state.tick / 25 * 16 + seat)
		var horizontal: int = [SeatInput.LEFT, SeatInput.NEUTRAL, SeatInput.RIGHT, SeatInput.RIGHT][phase % 4]
		var button := (state.tick + seat * 3) % (4 + phase % 9) == 0
		var down := seat in QUEENS and phase % 7 == 0
		seats.append(SeatInput.of(horizontal, down, button))
	return TickInput.of(state.tick, seats)


func _mix(n: int) -> int:
	n = (n * 2654435761 + 12345) & 0xFFFFFFFF
	return (n ^ (n >> 13)) & 0xFFFF
