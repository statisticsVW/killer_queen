extends GdUnitTestSuite
## Poses: which look, action and animation frame a character is drawn in,
## read from its Match state alone. Driven only through Pose.of, on states
## made by Sim.create_match on the day Map with characters set by hand.
##
## Seats 0-4 are Blue and 5-9 Gold; Seats 0 and 5 are the Queens.

const QUEEN := 0
const WORKER := 3
const ENEMY_WORKER := 7
## Milli-pixels per pixel.
const PX := 2000

const Look := Pose.Look
const Action := Pose.Action

## The Match's first state, made once.
var _start: MatchState


func test_each_role_and_upgrade_has_its_own_look() -> void:
	var state := _state()
	var warrior := state.characters[2]
	warrior.role = CharacterState.Role.WARRIOR
	var speed_warrior := state.characters[4]
	speed_warrior.role = CharacterState.Role.WARRIOR
	speed_warrior.speed = true
	state.characters[1].speed = true
	var looks := []
	for seat in 5:
		looks.append(Pose.of(state, seat).look)
	assert_array(looks).is_equal([Look.QUEEN, Look.SPEED_WORKER, Look.WARRIOR, Look.WORKER, Look.SPEED_WARRIOR])


func test_a_worker_stands_runs_jumps_and_falls() -> void:
	var state := _state()
	var c := state.characters[WORKER]
	assert_int(Pose.of(state, WORKER).action).is_equal(Action.STAND)
	c.vx = 3 * PX
	assert_int(Pose.of(state, WORKER).action).is_equal(Action.RUN)
	c.airborne_ticks = 4
	c.vy = -5 * PX
	assert_int(Pose.of(state, WORKER).action).is_equal(Action.JUMP)
	c.vy = 0
	assert_int(Pose.of(state, WORKER).action).is_equal(Action.FALL)
	c.vy = 5 * PX
	assert_int(Pose.of(state, WORKER).action).is_equal(Action.FALL)


func test_running_steps_through_its_frames_with_distance_whichever_way_it_faces() -> void:
	var state := _state()
	var c := state.characters[WORKER]
	c.vx = 3 * PX
	var start := 20 * Pose.RUN_FRAMES * Pose.RUN_STRIDE
	var frames := []
	for step in 2 * Pose.RUN_FRAMES:
		c.x = start + step * Pose.RUN_STRIDE
		frames.append(Pose.of(state, WORKER).frame)
	assert_array(frames).is_equal([0, 1, 2, 3, 0, 1, 2, 3].map(
		func(f: int) -> int: return (f + frames[0]) % Pose.RUN_FRAMES))
	# Within a stride the frame holds.
	c.x = start + Pose.RUN_STRIDE - 1
	assert_int(Pose.of(state, WORKER).frame).is_equal(frames[0])
	# Running left, the frames go the same way round.
	c.facing = SeatInput.LEFT
	c.vx = -3 * PX
	var left := []
	for step in Pose.RUN_FRAMES:
		c.x = start - step * Pose.RUN_STRIDE
		left.append(Pose.of(state, WORKER).frame)
	for i in range(1, left.size()):
		assert_int(left[i]).is_equal((left[i - 1] + 1) % Pose.RUN_FRAMES)
	# Standing still shows the first frame.
	c.vx = 0
	assert_int(Pose.of(state, WORKER).frame).is_equal(0)


func test_a_worker_with_a_berry_carries_it_and_holds_it_up_at_a_gate() -> void:
	var state := _state()
	var c := state.characters[WORKER]
	assert_bool(Pose.of(state, WORKER).carrying).is_false()
	c.berry = 0
	var pose := Pose.of(state, WORKER)
	assert_bool(pose.carrying).is_true()
	assert_int(pose.action).is_equal(Action.STAND)
	c.gate = 1
	c.gate_ticks = 3
	assert_int(Pose.of(state, WORKER).action).is_equal(Action.HOLD_UP)


func test_the_snail_rider_rides_then_eats_and_its_victim_is_eaten() -> void:
	var state := _state()
	state.snail.rider = WORKER
	assert_int(Pose.of(state, WORKER).action).is_equal(Action.RIDE)
	state.snail.victim = ENEMY_WORKER
	assert_int(Pose.of(state, WORKER).action).is_equal(Action.EAT)
	assert_int(Pose.of(state, ENEMY_WORKER).action).is_equal(Action.EATEN)
	# The eat chomps: its frames alternate every few ticks.
	var frames := []
	for tick in 4 * Pose.EAT_FRAME_TICKS:
		state.tick = 1200 + tick
		frames.append(Pose.of(state, WORKER).frame)
	assert_array(frames).is_equal(_alternating(frames[0], Pose.EAT_FRAME_TICKS, 4))


func test_a_winged_character_stands_walks_flaps_glides_and_a_queen_dives() -> void:
	var state := _state()
	var c := state.characters[QUEEN]
	assert_int(Pose.of(state, QUEEN).action).is_equal(Action.STAND)
	c.vx = 2 * PX
	assert_int(Pose.of(state, QUEEN).action).is_equal(Action.RUN)
	c.airborne_ticks = 10
	c.vy = -4 * PX
	assert_int(Pose.of(state, QUEEN).action).is_equal(Action.FLAP)
	c.vy = 0
	assert_int(Pose.of(state, QUEEN).action).is_equal(Action.GLIDE)
	c.vy = 2 * PX
	assert_int(Pose.of(state, QUEEN).action).is_equal(Action.GLIDE)
	c.diving = true
	assert_int(Pose.of(state, QUEEN).action).is_equal(Action.DIVE)
	c.vy = -4 * PX
	assert_int(Pose.of(state, QUEEN).action).is_equal(Action.DIVE)


func test_flapping_beats_its_wings_every_few_ticks() -> void:
	var state := _state()
	var c := state.characters[QUEEN]
	c.airborne_ticks = 10
	c.vy = -4 * PX
	var frames := []
	for tick in 4 * Pose.FLAP_FRAME_TICKS:
		state.tick = 1200 + tick
		frames.append(Pose.of(state, QUEEN).frame)
	assert_array(frames).is_equal(_alternating(frames[0], Pose.FLAP_FRAME_TICKS, 4))


## `runs` runs of `length` frames, alternating 0 and 1 from `first`.
func _alternating(first: int, length: int, runs: int) -> Array:
	var frames := []
	for run in runs:
		for i in length:
			frames.append((first + run) % 2)
	return frames


## A copy of the Match's first state on the day Map, past its countdown.
func _state() -> MatchState:
	if _start == null:
		var config := MatchConfig.new()
		config.map = MapData.load_file("res://data/maps/day.cfg")
		config.tuning = Tuning.load_default()
		config.seat_teams = Lobby.SEAT_TEAMS
		config.queen_seats = Lobby.QUEEN_SEATS
		_start = Sim.create_match(config)
	var state := _start.copy()
	state.tick = 1000
	for c in state.characters:
		c.vx = 0
		c.vy = 0
		c.airborne_ticks = 0
	return state
