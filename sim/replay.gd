class_name Replay
extends RefCounted
## A Match's Replay: everything Sim.create_match was given (the Map's file,
## Seats, Bot Seats and Difficulties, seed and the whole tuning table) plus
## every tick's input for the human Seats, from which the Match can be
## reproduced exactly (ADR-0002). Bot Seats' input isn't kept: the sim makes it
## again.

const _VERSION := 6

var _map_source: String
var _seat_teams: Array[int]
var _queen_seats: Array[int]
var _warrior_seats: Array[int]
var _speed_seats: Array[int]
var _bot_seats: Array[int]
var _bot_difficulties: Array[int]
var _seed: int
var _tuning: Dictionary
## Ticks of input held.
var _length: int
## One byte per human Seat per tick, in tick then Seat order (see _encode).
var _seat_codes := PackedByteArray()


## An empty Replay of the Match `config` creates. add() each tick's input.
static func record(config: MatchConfig) -> Replay:
	var replay := Replay.new()
	replay._map_source = config.map.source
	replay._seat_teams = config.seat_teams.duplicate()
	replay._queen_seats = config.queen_seats.duplicate()
	replay._warrior_seats = config.warrior_seats.duplicate()
	replay._speed_seats = config.speed_seats.duplicate()
	replay._bot_seats = config.bot_seats.duplicate()
	replay._bot_difficulties = config.bot_difficulties.duplicate()
	replay._seed = config.seed
	replay._tuning = config.tuning.values()
	return replay


## Appends the input for the next tick, which must be length().
func add(input: TickInput) -> void:
	assert(input.tick == length(), "Replay expects tick %d, got %d" % [length(), input.tick])
	assert(input.seats.size() == _seat_teams.size(), "Replay input needs one SeatInput per Seat")
	for seat in input.seats.size():
		if not seat in _bot_seats:
			_seat_codes.append(_encode(input.seats[seat]))
	_length += 1


## How many ticks of input the Replay holds.
func length() -> int:
	return _length


## The config to create the recorded Match from.
func config() -> MatchConfig:
	var cfg := ConfigFile.new()
	var err := cfg.parse(_map_source)
	assert(err == OK, "Replay's map does not parse (error %d)" % err)
	var config := MatchConfig.new()
	config.map = MapData.from_config(cfg)
	config.seat_teams = _seat_teams.duplicate()
	config.queen_seats = _queen_seats.duplicate()
	config.warrior_seats = _warrior_seats.duplicate()
	config.speed_seats = _speed_seats.duplicate()
	config.bot_seats = _bot_seats.duplicate()
	config.bot_difficulties = _bot_difficulties.duplicate()
	config.seed = _seed
	config.tuning = Tuning.from_values(_tuning)
	return config


## The input recorded for `tick`, neutral for Bot Seats.
func input(tick: int) -> TickInput:
	var seats: Array[SeatInput] = []
	var code := tick * (_seat_teams.size() - _bot_seats.size())
	for seat in _seat_teams.size():
		if seat in _bot_seats:
			seats.append(SeatInput.of(SeatInput.NEUTRAL))
		else:
			seats.append(_decode(_seat_codes[code]))
			code += 1
	return TickInput.of(tick, seats)


func to_text() -> String:
	return var_to_str({
		"version": _VERSION,
		"map": _map_source,
		"seat_teams": _seat_teams,
		"queen_seats": _queen_seats,
		"warrior_seats": _warrior_seats,
		"speed_seats": _speed_seats,
		"bot_seats": _bot_seats,
		"bot_difficulties": _bot_difficulties,
		"seed": _seed,
		"tuning": _tuning,
		"length": _length,
		"seat_codes": _seat_codes,
	})


static func from_text(text: String) -> Replay:
	var data: Variant = str_to_var(text)
	assert(data is Dictionary and data.get("version") == _VERSION, "Not a version %d Replay" % _VERSION)
	var replay := Replay.new()
	replay._map_source = data.map
	replay._seat_teams.assign(data.seat_teams)
	replay._queen_seats.assign(data.queen_seats)
	replay._warrior_seats.assign(data.warrior_seats)
	replay._speed_seats.assign(data.speed_seats)
	replay._bot_seats.assign(data.bot_seats)
	replay._bot_difficulties.assign(data.bot_difficulties)
	replay._seed = data.seed
	replay._tuning = data.tuning
	replay._length = data.length
	replay._seat_codes = data.seat_codes
	return replay


## A Seat's input as one byte: horizontal + 1 in bits 0-1, Down in bit 2, the
## button in bit 3.
static func _encode(input: SeatInput) -> int:
	return (input.horizontal + 1) | (int(input.down) << 2) | (int(input.button) << 3)


static func _decode(code: int) -> SeatInput:
	return SeatInput.of((code & 3) - 1, code & 4 != 0, code & 8 != 0)
