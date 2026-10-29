extends GdUnitTestSuite
## Sound cues: which cues a Match state plays, from the events of the tick that
## produced it and the countdown's seconds. Driven only through Cues.of, on
## states made by Sim.create_match with that tick's events set by hand.
##
## Seats 0-4 are Blue and 5-9 Gold; Seats 0 and 5 are the Queens.

const TICKS_PER_SECOND := 50
const QUEEN := 0
const WORKER := 3
const ENEMY_WORKER := 7

const Cue := Cues.Cue
const Type := MatchEvent.Type

## The Match's first state, made once.
var _start: MatchState


func test_each_listed_event_plays_its_own_cue() -> void:
	var cases := [
		[MatchEvent.of(Type.HATCH, QUEEN), Cue.HATCH],
		[MatchEvent.of(Type.BERRY_PICKUP, WORKER, 2), Cue.BERRY_PICKUP],
		[MatchEvent.of(Type.BERRY_DEPOSIT, WORKER, 2), Cue.BERRY_DEPOSIT],
		[MatchEvent.of(Type.GATE_CLAIM, QUEEN, 1), Cue.GATE_CLAIM],
		[MatchEvent.of(Type.TRANSFORM_START, WORKER, 1), Cue.TRANSFORM_START],
		[MatchEvent.of(Type.TRANSFORM_COMPLETE, WORKER, 1), Cue.TRANSFORM_COMPLETE],
		[MatchEvent.of(Type.SNAIL_MOUNT, WORKER), Cue.SNAIL_MOUNT],
		[MatchEvent.of(Type.EAT_START, WORKER, ENEMY_WORKER), Cue.EAT_START],
		[MatchEvent.of(Type.EAT_COMPLETE, WORKER, ENEMY_WORKER), Cue.EAT_COMPLETE],
		[MatchEvent.of(Type.FAMINE_START, -1), Cue.FAMINE_START],
		[MatchEvent.of(Type.FAMINE_END, -1), Cue.FAMINE_END],
	]
	for case: Array in cases:
		var e: MatchEvent = case[0]
		assert_array(_cues([e])).override_failure_message(
			"%s should play %s" % [Type.keys()[e.type], Cue.keys()[case[1]]]).is_equal([case[1]])


func test_every_death_pops_and_a_queens_death_also_plays_her_own_cue() -> void:
	assert_array(_cues([MatchEvent.of(Type.DEATH, WORKER, ENEMY_WORKER)])).is_equal([Cue.KILL])
	# Eaten by the Snail: no killer, still a pop.
	assert_array(_cues([MatchEvent.of(Type.DEATH, ENEMY_WORKER)])).is_equal([Cue.KILL])
	assert_array(_cues([MatchEvent.of(Type.DEATH, QUEEN, ENEMY_WORKER)])).is_equal([Cue.KILL, Cue.QUEEN_DEATH])
	assert_array(_cues([MatchEvent.of(Type.DEATH, 5, QUEEN)])).is_equal([Cue.KILL, Cue.QUEEN_DEATH])


func test_events_without_a_cue_play_nothing() -> void:
	# A kill comes with its victim's DEATH, which plays the pop.
	for e: MatchEvent in [
		MatchEvent.of(Type.KILL, ENEMY_WORKER, WORKER),
		MatchEvent.of(Type.RESPAWN, WORKER),
		MatchEvent.of(Type.BERRY_DROP, WORKER, 2),
		MatchEvent.of(Type.BERRY_KICK, WORKER, 2),
		MatchEvent.of(Type.SNAIL_DISMOUNT, WORKER),
		MatchEvent.of(Type.EAT_INTERRUPT, WORKER, ENEMY_WORKER),
		MatchEvent.of(Type.TRANSFORM_INTERRUPT, WORKER, 1),
	]:
		assert_array(_cues([e])).override_failure_message(
			"%s should play nothing" % Type.keys()[e.type]).is_empty()


func test_each_win_type_plays_its_own_cue() -> void:
	var cases := {
		MatchState.Win.MILITARY: Cue.MILITARY_WIN,
		MatchState.Win.ECONOMIC: Cue.ECONOMIC_WIN,
		MatchState.Win.SNAIL: Cue.SNAIL_WIN,
	}
	for win: MatchState.Win in cases:
		var state := _state(1000, [MatchEvent.win(1)])
		state.win = win
		state.winner = 1
		assert_array(Cues.of(state, TICKS_PER_SECOND)).is_equal([cases[win]])


func test_a_cue_plays_once_a_tick_however_often_its_moment_happened() -> void:
	# Ten kills at once: one pop, not ten stacked. Cues come in Cue order.
	var deaths: Array[MatchEvent] = [MatchEvent.of(Type.BERRY_PICKUP, 2, 0)]
	for seat in 10:
		if seat != QUEEN and seat != 5:
			deaths.append(MatchEvent.of(Type.DEATH, seat, (seat + 5) % 10))
	deaths.append(MatchEvent.of(Type.DEATH, 5))
	deaths.append(MatchEvent.of(Type.DEATH, QUEEN))
	deaths.append(MatchEvent.of(Type.BERRY_PICKUP, WORKER, 1))
	deaths.append(MatchEvent.of(Type.BERRY_PICKUP, ENEMY_WORKER, 4))
	assert_array(_cues(deaths)).is_equal([Cue.KILL, Cue.QUEEN_DEATH, Cue.BERRY_PICKUP])


func test_the_countdown_beeps_on_its_last_three_whole_seconds_then_plays_go_once() -> void:
	var countdown := _state(0, []).tuning.match_countdown_ticks
	var heard := {}
	for tick in countdown + 3 * TICKS_PER_SECOND:
		var cues := Cues.of(_state(tick, []), TICKS_PER_SECOND)
		if not cues.is_empty():
			heard[tick] = cues.map(func(cue: Cue) -> String: return Cue.keys()[cue])
	var expected := {}
	for left in [3, 2, 1]:
		expected[countdown - left * TICKS_PER_SECOND] = ["COUNTDOWN"]
	expected[countdown] = ["GO"]
	assert_dict(heard).is_equal(expected)


func test_the_countdown_follows_the_tick_rate_it_is_shown_at() -> void:
	var countdown := _state(0, []).tuning.match_countdown_ticks
	var heard: Array[int] = []
	for tick in countdown:
		if Cues.of(_state(tick, []), 30).has(Cue.COUNTDOWN):
			heard.append(tick)
	# At 30 ticks a second, 3, 2 and 1 seconds left are 90, 60 and 30 ticks.
	assert_array(heard).is_equal([countdown - 90, countdown - 60, countdown - 30])


## The cues of a state just after the countdown with `events` as its tick's.
func _cues(events: Array) -> Array[Cues.Cue]:
	return Cues.of(_state(1000, events), TICKS_PER_SECOND)


## A state of a Match on the day Map at `tick`, `events` its tick's events.
func _state(tick: int, events: Array) -> MatchState:
	if _start == null:
		var config := MatchConfig.new()
		config.map = MapData.load_file("res://data/maps/day.cfg")
		config.tuning = Tuning.load_default()
		config.seat_teams = Lobby.SEAT_TEAMS
		config.queen_seats = Lobby.QUEEN_SEATS
		_start = Sim.create_match(config)
	var state := _start.copy()
	state.tick = tick
	state.events.assign(events)
	return state
