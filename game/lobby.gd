class_name Lobby
extends RefCounted
## The Lobby: where players claim Seats and set each Team's Bot Difficulty
## with the cabinet's controls, from any device. A device's button joins its
## player; the stick then moves it along a row of slots, and the button locks
## it into a Seat (or unlocks it), or changes a Team's Bot Difficulty. Like
## Menu, a press counts when it is let go, and only if it began in the Lobby.
## Once every player is locked in, a countdown starts the Match, with Bots in
## the Seats nobody took.
##
## The row, left to right: Blue's Bot Difficulty, Blue's Queen Seat, Blue's
## four Worker Seats, Gold's four Worker Seats, Gold's Queen Seat, Gold's Bot
## Difficulty.

## Seats 0-4 are Blue and 5-9 Gold; each Team's first is its Queen's.
const SEAT_TEAMS: Array[int] = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1]
const QUEEN_SEATS: Array[int] = [0, 5]
## The Seat at each slot of the row, or -1 at each end for that Team's Bot
## Difficulty.
const SLOT_SEATS: Array[int] = [-1, 0, 1, 2, 3, 4, 6, 7, 8, 9, 5, -1]
## The peer of a device on this machine. v1 is local only; v2 can host Seats
## on other peers without changing how the Lobby keeps owners.
const LOCAL_PEER := 0
## How long the countdown to the Match lasts once everyone is locked in.
const START_TICKS := 150


## A player in the Lobby: the device it joined with, on which peer, where it
## is in the row, and whether it has locked into the Seat there.
class Player:
	var peer: int
	var device: int
	var slot: int
	var locked: bool


var players: Array[Player] = []
## Each Team's Bot Difficulty, indexed by Team.
var difficulties: Array[int] = [Bot.Difficulty.NORMAL, Bot.Difficulty.NORMAL]
## Ticks left before the Match starts, or 0 while anyone isn't locked in.
var start_ticks := 0
## Each device's input from the last update, or empty before the first.
var _last: Array[SeatInput] = []
## Per device: whether its button went down in the Lobby.
var _pressing: Array[bool] = []


## Reads one tick of every local device's input, in device order, with which
## devices are connected. Returns true on the tick the Match should start.
func update(inputs: Array[SeatInput], connected: Array[bool]) -> bool:
	players = players.filter(func(p: Player) -> bool: return p.peer != LOCAL_PEER or connected[p.device])
	if _last.is_empty():
		_last = inputs
		_pressing.resize(inputs.size())
		_pressing.fill(false)
		return false
	var starting := false
	if start_ticks > 0:
		start_ticks -= 1
		starting = start_ticks == 0
	for device in inputs.size():
		var now := inputs[device]
		var before := _last[device]
		var p := _player(LOCAL_PEER, device)
		if p != null and not p.locked and now.horizontal != SeatInput.NEUTRAL and now.horizontal != before.horizontal:
			p.slot = clampi(p.slot + now.horizontal, 0, SLOT_SEATS.size() - 1)
		if now.button and not before.button:
			_pressing[device] = true
		elif not now.button and _pressing[device]:
			_pressing[device] = false
			_choose(LOCAL_PEER, device)
	_last = inputs
	return starting


## The Seat a player is at, or -1 at a Bot Difficulty.
func seat_of(p: Player) -> int:
	return SLOT_SEATS[p.slot]


## The player locked into `seat`, or null.
func owner_of(seat: int) -> Player:
	for p in players:
		if p.locked and seat_of(p) == seat:
			return p
	return null


## The Match the Lobby sets up, without its Map, Tuning and seed: every Seat
## nobody locked into is a Bot.
func match_config() -> MatchConfig:
	var config := MatchConfig.new()
	config.seat_teams = SEAT_TEAMS
	config.queen_seats = QUEEN_SEATS
	for seat in SEAT_TEAMS.size():
		if owner_of(seat) == null:
			config.bot_seats.append(seat)
	config.bot_difficulties = difficulties.duplicate()
	return config


## The Seat each of this machine's locked-in devices plays, by device.
func local_seats() -> Dictionary:
	var seats := {}
	for p in players:
		if p.locked and p.peer == LOCAL_PEER:
			seats[p.device] = seat_of(p)
	return seats


## Back from a Match: everyone stays at their Seat, unlocked, so the next
## Match waits until they lock in again. A button already held doesn't count.
func reopen() -> void:
	for p in players:
		p.locked = false
	start_ticks = 0
	_last = []


func _player(peer: int, device: int) -> Player:
	for p in players:
		if p.peer == peer and p.device == device:
			return p
	return null


## A let-go press: joins a new player at the first Seat no other player is
## at, locks a player into a free Seat or unlocks it, or changes a Bot
## Difficulty. Anything that leaves someone unlocked stops the countdown; the
## last player locking in starts it.
func _choose(peer: int, device: int) -> void:
	var p := _player(peer, device)
	if p == null:
		p = Player.new()
		p.peer = peer
		p.device = device
		p.slot = _first_empty_slot()
		players.append(p)
	elif p.locked:
		p.locked = false
	elif seat_of(p) == -1:
		var team := 0 if p.slot == 0 else 1
		difficulties[team] = (difficulties[team] + 1) % Bot.Difficulty.size()
	elif owner_of(seat_of(p)) == null:
		p.locked = true
	start_ticks = START_TICKS if players.all(func(q: Player) -> bool: return q.locked) else 0


func _first_empty_slot() -> int:
	for slot in SLOT_SEATS.size():
		if SLOT_SEATS[slot] != -1 and players.all(func(q: Player) -> bool: return q.slot != slot):
			return slot
	return 1
