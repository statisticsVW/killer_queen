extends GdUnitTestSuite
## The Lobby: players join with their button, move between the ten Seats and
## each Team's Bot Difficulty with the stick, and lock a Seat in; once every
## player is locked in, a short countdown starts the Match with Bots in the
## empty Seats. Driven only through Lobby.update and what the Lobby reports.
##
## Devices here are 0-3. The row of slots, left to right: Blue's Bot
## Difficulty, Blue's Queen Seat (0), Blue's Worker Seats (1-4), Gold's Worker
## Seats (6-9), Gold's Queen Seat (5), Gold's Bot Difficulty.

const DEVICES := 4


func test_releasing_the_button_joins_a_player_on_the_first_empty_seat_as_peer_and_device() -> void:
	var lobby := _lobby()
	_tap(lobby, 2)

	assert_int(lobby.players.size()).is_equal(1)
	var p := lobby.players[0]
	assert_int(p.peer).is_equal(Lobby.LOCAL_PEER)
	assert_int(p.device).is_equal(2)
	assert_int(lobby.seat_of(p)).is_equal(0)
	assert_bool(p.locked).is_false()
	# A held button joins nobody until it is let go.
	_hold(lobby, {3: SeatInput.of(SeatInput.NEUTRAL, false, true)})
	assert_int(lobby.players.size()).is_equal(1)


func test_a_player_moves_with_the_stick_locks_a_seat_in_and_unlocks_it_to_move_again() -> void:
	var lobby := _lobby()
	_tap(lobby, 0)
	_push(lobby, 0, SeatInput.RIGHT)
	_push(lobby, 0, SeatInput.RIGHT)
	var p := lobby.players[0]
	assert_int(lobby.seat_of(p)).is_equal(2)

	_tap(lobby, 0)
	assert_bool(p.locked).is_true()
	assert_object(lobby.owner_of(2)).is_same(p)
	# The stick does nothing while locked in.
	_push(lobby, 0, SeatInput.RIGHT)
	assert_int(lobby.seat_of(p)).is_equal(2)

	_tap(lobby, 0)
	assert_bool(p.locked).is_false()
	assert_object(lobby.owner_of(2)).is_null()
	_push(lobby, 0, SeatInput.LEFT)
	assert_int(lobby.seat_of(p)).is_equal(1)


func test_moving_crosses_from_blue_to_gold_with_each_queen_seat_at_its_end() -> void:
	var lobby := _lobby()
	_tap(lobby, 0)
	var p := lobby.players[0]
	var seats := []
	for i in 12:
		seats.append(lobby.seat_of(p))
		_push(lobby, 0, SeatInput.RIGHT)
	# It stops at the right-hand end: Gold's Bot Difficulty (no Seat).
	assert_array(seats).is_equal([0, 1, 2, 3, 4, 6, 7, 8, 9, 5, -1, -1])
	for i in 11:
		_push(lobby, 0, SeatInput.LEFT)
	assert_int(lobby.seat_of(p)).is_equal(-1)
	assert_int(p.slot).is_equal(0)


func test_two_players_cannot_lock_the_same_seat() -> void:
	var lobby := _lobby()
	_tap(lobby, 0)
	_tap(lobby, 0)
	_tap(lobby, 1)
	var first := lobby.players[0]
	var second := lobby.players[1]
	# The second player joins on the first Seat no other player is on.
	assert_int(lobby.seat_of(second)).is_equal(1)

	_push(lobby, 1, SeatInput.LEFT)
	assert_int(lobby.seat_of(second)).is_equal(0)
	_tap(lobby, 1)

	assert_bool(second.locked).is_false()
	assert_object(lobby.owner_of(0)).is_same(first)


func test_each_teams_bot_difficulty_is_set_separately() -> void:
	var lobby := _lobby()
	assert_array(lobby.difficulties).is_equal([Bot.Difficulty.NORMAL, Bot.Difficulty.NORMAL])
	_tap(lobby, 0)
	_push(lobby, 0, SeatInput.LEFT)
	_tap(lobby, 0)
	assert_array(lobby.difficulties).is_equal([Bot.Difficulty.HARD, Bot.Difficulty.NORMAL])
	_tap(lobby, 0)
	assert_array(lobby.difficulties).is_equal([Bot.Difficulty.EASY, Bot.Difficulty.NORMAL])
	assert_bool(lobby.players[0].locked).is_false()

	for i in 11:
		_push(lobby, 0, SeatInput.RIGHT)
	_tap(lobby, 0)
	assert_array(lobby.difficulties).is_equal([Bot.Difficulty.EASY, Bot.Difficulty.HARD])


func test_once_everyone_is_locked_in_a_countdown_starts_the_match_and_an_unlock_stops_it() -> void:
	var lobby := _lobby()
	_tap(lobby, 0)
	_tap(lobby, 1)
	_tap(lobby, 0)
	assert_int(lobby.start_ticks).is_equal(0)
	_tap(lobby, 1)
	assert_int(lobby.start_ticks).is_equal(Lobby.START_TICKS)

	for i in 30:
		assert_bool(_hold(lobby, {})).is_false()
	_tap(lobby, 1)
	assert_int(lobby.start_ticks).is_equal(0)
	_tap(lobby, 1)
	for i in Lobby.START_TICKS - 1:
		assert_bool(_hold(lobby, {})).is_false()
	assert_bool(_hold(lobby, {})).is_true()


func test_a_new_player_joining_stops_the_countdown() -> void:
	var lobby := _lobby()
	_tap(lobby, 0)
	_tap(lobby, 0)
	assert_int(lobby.start_ticks).is_greater(0)
	_tap(lobby, 3)
	assert_int(lobby.start_ticks).is_equal(0)


func test_every_seat_nobody_locked_is_a_bot_and_all_humans_can_share_a_team() -> void:
	var lobby := _lobby()
	# Four players lock Blue's Seats 1-4; Blue's Queen and all of Gold are Bots.
	for device in DEVICES:
		_tap(lobby, device)
		for i in device + 1:
			_push(lobby, device, SeatInput.RIGHT)
		_tap(lobby, device)

	var config := lobby.match_config()
	assert_array(config.seat_teams).is_equal([0, 0, 0, 0, 0, 1, 1, 1, 1, 1])
	assert_array(config.queen_seats).is_equal([0, 5])
	assert_array(config.bot_seats).is_equal([0, 5, 6, 7, 8, 9])
	assert_array(config.bot_difficulties).is_equal(lobby.difficulties)
	assert_dict(lobby.local_seats()).is_equal({0: 1, 1: 2, 2: 3, 3: 4})


func test_coming_back_from_a_match_keeps_everyone_on_their_seat_unlocked() -> void:
	var lobby := _lobby()
	_tap(lobby, 0)
	_push(lobby, 0, SeatInput.RIGHT)
	_tap(lobby, 0)
	_tap(lobby, 1)
	_tap(lobby, 1)
	for i in Lobby.START_TICKS:
		_hold(lobby, {})

	lobby.reopen()

	assert_array(lobby.players.map(func(p: Lobby.Player) -> int: return lobby.seat_of(p))).is_equal([1, 0])
	assert_array(lobby.players.map(func(p: Lobby.Player) -> bool: return p.locked)).is_equal([false, false])
	assert_int(lobby.start_ticks).is_equal(0)
	# A button held as the Lobby reopens doesn't count as a press.
	_hold(lobby, {0: SeatInput.of(SeatInput.NEUTRAL, false, true)})
	_hold(lobby, {})
	assert_bool(lobby.players[0].locked).is_false()


func test_a_player_whose_device_goes_away_leaves_the_lobby() -> void:
	var lobby := _lobby()
	_tap(lobby, 0)
	_tap(lobby, 0)
	_tap(lobby, 2)

	lobby.update(_inputs({}), [true, true, false, true])

	assert_int(lobby.players.size()).is_equal(1)
	assert_int(lobby.players[0].device).is_equal(0)


## A new Lobby that has seen one tick of every device idle, as the game's
## has before anyone presses.
func _lobby() -> Lobby:
	var lobby := Lobby.new()
	_hold(lobby, {})
	return lobby


## One tick with each device's input from `held` (neutral otherwise). Returns
## whether the Match starts.
func _hold(lobby: Lobby, held: Dictionary) -> bool:
	var connected: Array[bool] = []
	connected.resize(DEVICES)
	connected.fill(true)
	return lobby.update(_inputs(held), connected)


## Presses and lets go of `device`'s button.
func _tap(lobby: Lobby, device: int) -> void:
	_hold(lobby, {device: SeatInput.of(SeatInput.NEUTRAL, false, true)})
	_hold(lobby, {})


## Pushes `device`'s stick one way and lets it go.
func _push(lobby: Lobby, device: int, horizontal: int) -> void:
	_hold(lobby, {device: SeatInput.of(horizontal)})
	_hold(lobby, {})


func _inputs(held: Dictionary) -> Array[SeatInput]:
	var inputs: Array[SeatInput] = []
	for device in DEVICES:
		inputs.append(held.get(device, SeatInput.of(SeatInput.NEUTRAL)))
	return inputs
