extends GdUnitTestSuite
## Bot Difficulty: per-level reaction delay (Bots see their enemies late),
## mistakes (a Bot Worker sometimes picks a worse target) and threat awareness
## (a Bot may fail to notice an enemy sword), on top of Easy's 0.8x speed.
## Driven only through Sim.create_match and Sim.step.

const PX := 1000
const BLUE := CharacterState.BLUE
const GOLD := CharacterState.GOLD
const EASY := Bot.Difficulty.EASY
const NORMAL := Bot.Difficulty.NORMAL
const HARD := Bot.Difficulty.HARD


func test_each_level_has_its_own_reaction_delay_mistake_rate_and_threat_awareness() -> void:
	var t := Tuning.load_default()
	assert_array([t.bot_easy_reaction_ticks, t.bot_normal_reaction_ticks, t.bot_hard_reaction_ticks]) \
		.is_equal([18, 10, 4])
	assert_array([t.bot_easy_mistake_percent, t.bot_normal_mistake_percent, t.bot_hard_mistake_percent]) \
		.is_equal([30, 10, 0])
	assert_array([t.bot_easy_awareness_percent, t.bot_normal_awareness_percent, t.bot_hard_awareness_percent]) \
		.is_equal([50, 85, 100])


func test_an_easy_bot_queen_reacts_more_slowly_than_a_hard_one_to_the_same_higher_warrior() -> void:
	var hard := _reaction_tick(HARD, Tuning.load_default())
	var easy := _reaction_tick(EASY, Tuning.load_default())

	assert_int(hard).is_not_equal(-1)
	# Later, or not at all.
	if easy != -1:
		assert_int(easy).is_greater(hard)


func test_a_bot_reacts_exactly_its_levels_reaction_delay_after_a_threat_comes_in_range() -> void:
	# Every level notices every threat, so only the delay differs.
	var t := Tuning.load_default().with_values({"bot_easy_awareness_percent": 100,
		"bot_normal_awareness_percent": 100})
	var hard := _reaction_tick(HARD, t)
	var normal := _reaction_tick(NORMAL, t)
	var easy := _reaction_tick(EASY, t)

	assert_int(normal - hard).is_equal(t.bot_normal_reaction_ticks - t.bot_hard_reaction_ticks)
	assert_int(easy - hard).is_equal(t.bot_easy_reaction_ticks - t.bot_hard_reaction_ticks)


func test_a_bot_queen_that_fails_to_notice_a_higher_warrior_never_backs_off_from_it() -> void:
	var t := Tuning.load_default().with_values({"bot_hard_awareness_percent": 0})
	assert_int(_reaction_tick(HARD, t)).is_equal(-1)


func test_a_bot_noticing_half_the_threats_gets_a_fresh_chance_each_time_one_comes_back() -> void:
	# Gold's human Warrior flies back and forth past Blue's waiting Bot Queen,
	# 100 px up: in range of her, out again, eight times. She notices it on
	# some passes and not others.
	var t := Tuning.load_default().with_values({"bot_hard_awareness_percent": 50})
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(400, 960)], [Vector2i(1100, 960)])
	var config := _config(MapData.from_config(cfg), [BLUE, GOLD], [0], [0], HARD, t, 3)
	config.warrior_seats = [1]
	var state := Sim.create_match(config)
	var heading := SeatInput.LEFT
	var passes := 0
	var noticed := {}
	for i in 2000:
		var w := state.characters[1]
		if heading == SeatInput.LEFT and w.x < 550 * PX:
			heading = SeatInput.RIGHT
		elif heading == SeatInput.RIGHT and w.x > 1100 * PX:
			heading = SeatInput.LEFT
			passes += 1
			if passes == 8:
				break
		var inputs := _hover(state, 1, 860 * PX)
		inputs.seats[1] = SeatInput.of(heading, false, inputs.seats[1].button)
		state = Sim.step(state, inputs)
		if state.inputs[0].horizontal == SeatInput.LEFT and state.characters[0].x < 450 * PX:
			noticed[passes] = true

	assert_int(passes).is_equal(8)
	# A pass she missed is followed by one she noticed: missing a threat once
	# doesn't blind her to it for good.
	var missed := range(8).filter(func(p: int) -> bool: return not noticed.has(p))
	assert_array(missed).is_not_empty()
	var first_missed: int = missed.min()
	assert_bool(noticed.keys().any(func(p: int) -> bool: return p > first_missed)).is_true()


func test_a_bot_worker_aware_of_an_enemy_warrior_coming_at_it_runs_away() -> void:
	assert_bool(_worker_flees(Tuning.load_default())).is_true()
	assert_bool(_worker_flees(Tuning.load_default().with_values({"bot_hard_awareness_percent": 0}))).is_false()


func test_a_bot_worker_that_makes_mistakes_sometimes_goes_for_a_worse_berry() -> void:
	# A Berry pile 200 px to the right of the Bot Worker, another 600 px to
	# its left. Without mistakes it always goes right first.
	var careful := Tuning.load_default()
	var careless := careful.with_values({"bot_hard_mistake_percent": 100})
	var far := [0, 0]
	for seed in 12:
		far[0] += int(_first_berry_is_far(careful, seed))
		far[1] += int(_first_berry_is_far(careless, seed))

	assert_int(far[0]).is_equal(0)
	assert_int(far[1]).is_greater(0)


func test_hard_bots_beat_normal_bots_and_normal_beat_easy_more_often_than_not() -> void:
	# All-Bot Matches on Day, each pairing played with each Team on each side.
	var wins := {"hard over normal": 0, "normal over easy": 0}
	for seed in [1, 2]:
		for better_team in [BLUE, GOLD]:
			if _winner(HARD, NORMAL, better_team, seed) == better_team:
				wins["hard over normal"] += 1
			if _winner(NORMAL, EASY, better_team, seed) == better_team:
				wins["normal over easy"] += 1

	assert_int(wins["hard over normal"]).is_greater(2)
	assert_int(wins["normal over easy"]).is_greater(2)


## The tick Blue's Bot Queen, of `level`, first steers away from Gold's human
## Warrior flying at her 100 px above the floor; -1 if she never does. She waits
## at her spawn point on a floor with nothing to do. With no Eggs she is at
## risk, so she keeps away once it is within 220 px.
func _reaction_tick(level: Bot.Difficulty, t: Tuning) -> int:
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(400, 960)], [Vector2i(1400, 960)])
	var config := _config(MapData.from_config(cfg), [BLUE, GOLD], [0], [0], level, t, 1)
	config.warrior_seats = [1]
	var state := Sim.create_match(config)
	for i in 400:
		var inputs := _hover(state, 1, 860 * PX)
		inputs.seats[1] = SeatInput.of(SeatInput.LEFT, false, inputs.seats[1].button)
		state = Sim.step(state, inputs)
		if state.inputs[0].horizontal == SeatInput.LEFT:
			return state.tick
		if not state.characters[0].alive:
			break
	return -1


## Whether Blue's Hard Bot Worker, on its way right to a Berry pile, runs back
## left from Gold's human Warrior flying at it low over the floor.
func _worker_flees(t: Tuning) -> bool:
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(700, 960)], [Vector2i(1500, 960)])
	cfg.set_value("berries", "piles", [Vector2i(1700, 960)])
	var config := _config(MapData.from_config(cfg), [BLUE, GOLD], [], [0], HARD, t, 1)
	config.warrior_seats = [1]
	var state := Sim.create_match(config)
	for i in 200:
		var inputs := _hover(state, 1, 930 * PX)
		inputs.seats[1] = SeatInput.of(SeatInput.LEFT, false, inputs.seats[1].button)
		state = Sim.step(state, inputs)
		if state.inputs[0].horizontal == SeatInput.LEFT:
			return true
		if not state.characters[0].alive:
			break
	return false


## Whether Blue's Hard Bot Worker at x 900 picks its first Berry from the far
## pile at x 300 rather than the near one at 1100.
func _first_berry_is_far(t: Tuning, seed: int) -> bool:
	var cfg := TestMaps.config(TestMaps.floor_tiles(), [Vector2i(900, 960)])
	cfg.set_value("berries", "piles", [Vector2i(1100, 960), Vector2i(300, 960)])
	var state := Sim.create_match(_config(MapData.from_config(cfg), [BLUE], [], [0], HARD, t, seed))
	for i in 300:
		state = Sim.step(state, _neutral(state))
		if state.characters[0].berry != -1:
			return state.characters[0].x < 900 * PX
	return false


## Which Team wins an all-Bot Match on Day with `better` Bots on
## `better_team` and `worse` ones on the other.
func _winner(better: Bot.Difficulty, worse: Bot.Difficulty, better_team: int, seed: int) -> int:
	var config := _config(MapData.load_file("res://data/maps/day.cfg"), [0, 0, 0, 0, 0, 1, 1, 1, 1, 1],
		[0, 5], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], NORMAL, Tuning.load_default(), seed)
	config.bot_difficulties[better_team] = better
	config.bot_difficulties[1 - better_team] = worse
	var state := Sim.create_match(config)
	for i in 9000:
		state = Sim.step(state, _neutral(state))
		if state.win != MatchState.Win.NONE:
			break
	return state.winner


func _config(map: MapData, teams: Array[int], queens: Array[int], bots: Array[int], level: Bot.Difficulty,
		t: Tuning, seed: int) -> MatchConfig:
	var config := MatchConfig.new()
	config.map = map
	config.seat_teams = teams
	config.queen_seats = queens
	config.bot_seats = bots
	config.bot_difficulties = [level, level]
	config.tuning = t
	config.seed = seed
	return config


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
