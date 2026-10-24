class_name BotNav
extends RefCounted
## How a Worker can get around a Map, for Bots. A Ledge is a run of floor a
## Worker can stand on. A Move takes a Worker from a point on one Ledge to
## another Ledge with the stick held one way: walking off an end, or jumping
## with the button held. Moves are found by running the sim's own movement from
## points along each Ledge until the Worker lands, so they hold for the Map and
## Tuning they were built from and a Worker of the given speed. None of this
## is Match state: it is the same for every Match on that Map and Tuning, so
## Matches share it (MatchState.navs) and it is never copied or replayed.

const NONE := -1
## Longer than any route: the cost of a Ledge that can't be reached.
const UNREACHABLE := 1 << 40
## A Move is followed for at most this many ticks.
const _MAX_TICKS := 200
## A walk toward a Ledge's end still on the Ledge after this many ticks has
## run into a wall.
const _MAX_WALK_TICKS := 20
## Jumps are tried from points this far apart along each Ledge.
const _LAUNCH_SPACING := 24000
## How many BotNavs of() remembers.
const _REMEMBERED := 16

## BotNavs already built, by the Map's and Tuning's contents and the Worker's
## speed: building one takes most of a second, and every Match on the same Map
## and Tuning would build the same one.
static var _built := {}


class Ledge:
	## The tile row stood on; `y` is its top, where a standing Worker's feet are.
	var row: int
	var y: int
	## The left and right edges of the row's solid run.
	var left: int
	var right: int
	## Covers the whole width of a row that Workers wrap around, so it has no
	## ends.
	var wraps: bool

	func centre() -> int:
		return (left + right) / 2


class Move:
	var from: int
	var to: int
	## Where on `from` it starts: for a walk, the end it walks off.
	var launch_x: int
	var stick: int
	## Pressed on the first tick and held throughout.
	var jump: bool
	## Where on `to` it lands, and how many ticks it takes.
	var land_x: int
	var ticks: int


## The quickest routes from a point on a Ledge to every Ledge (see route()).
class Route:
	## Ticks to reach each Ledge, or UNREACHABLE.
	var ticks: Array[int]
	## Where the route arrives on each Ledge.
	var at: Array[int]
	## The route's first Move off the starting Ledge, for each Ledge; NONE for
	## the starting Ledge and Ledges that can't be reached.
	var first: Array[int]


var ledges: Array[Ledge]
var moves: Array[Move]
## Indices in `moves` of the Moves off each Ledge.
var moves_from: Array[PackedInt32Array]
## The Worker's horizontal distance per tick.
var speed: int
var _map: MapData
var _half_width: int
## Ledge indices by tile row.
var _by_row := {}


## The Ledges and Moves of `map` for a Worker with the Speed upgrade or not,
## and an Easy Bot or not, built once for each Map and Tuning.
static func of(map: MapData, t: Tuning, easy: bool, speed_upgrade: bool) -> BotNav:
	var key := var_to_str([map.source, t.values(), easy, speed_upgrade]).sha256_text()
	if not _built.has(key):
		if _built.size() >= _REMEMBERED:
			_built.clear()
		_built[key] = build(map, t, easy, speed_upgrade)
	return _built[key]


static func build(map: MapData, t: Tuning, easy: bool, speed_upgrade: bool) -> BotNav:
	var nav := BotNav.new()
	nav._map = map
	nav._half_width = t.worker_width / 2
	var walker := CharacterState.new()
	walker.speed = speed_upgrade
	walker.bot = BotState.new()
	walker.bot.difficulty = Bot.Difficulty.EASY if easy else Bot.Difficulty.NORMAL
	nav.speed = Sim._max_speed(walker, t)
	nav._find_ledges(t)
	for i in nav.ledges.size():
		nav.moves_from.append(PackedInt32Array())
	for i in nav.ledges.size():
		nav._find_moves(i, walker, t)
	return nav


## The Ledge a Worker standing with its feet at (x, y) stands on, or NONE.
func ledge_at(x: int, y: int) -> int:
	if posmod(y, _map.tile_size) != 0:
		return NONE
	for i in _by_row.get(y / _map.tile_size, []):
		if _holds(ledges[i], x):
			return i
	return NONE


## The first Ledge at or below (x, y) that a Worker standing at x would be on:
## where something at that point rests or will land.
func ledge_below(x: int, y: int) -> int:
	for row in range(maxi(y + _map.tile_size - 1, 0) / _map.tile_size, _map.rows):
		for i in _by_row.get(row, []):
			if _holds(ledges[i], x):
				return i
	return NONE


## The horizontal distance along Ledge `ledge` from x `from` to x `to`, both on
## it: the short way round only if the Ledge wraps.
func along(ledge: int, from: int, to: int) -> int:
	var l := ledges[ledge]
	if l.wraps:
		return Sim._wrapped_dx(from, to)
	return Sim._wrapped_dx(l.centre(), to) - Sim._wrapped_dx(l.centre(), from)


## Ticks to walk along Ledge `ledge` from x `from` to x `to`.
func walk_ticks(ledge: int, from: int, to: int) -> int:
	return (absi(along(ledge, from, to)) + speed - 1) / speed


## The quickest routes from x `x` on Ledge `from` to every Ledge, walking along
## Ledges to the Moves between them.
func route(from: int, x: int) -> Route:
	var r := Route.new()
	for i in ledges.size():
		r.ticks.append(UNREACHABLE)
		r.at.append(0)
		r.first.append(NONE)
	var done := PackedByteArray()
	done.resize(ledges.size())
	r.ticks[from] = 0
	r.at[from] = x
	for _i in ledges.size():
		var next := NONE
		for l in ledges.size():
			if done[l] == 0 and r.ticks[l] < UNREACHABLE and (next == NONE or r.ticks[l] < r.ticks[next]):
				next = l
		if next == NONE:
			break
		done[next] = 1
		for m in moves_from[next]:
			var move := moves[m]
			var ticks := r.ticks[next] + walk_ticks(next, r.at[next], move.launch_x) + move.ticks
			if ticks < r.ticks[move.to]:
				r.ticks[move.to] = ticks
				r.at[move.to] = move.land_x
				r.first[move.to] = m if next == from else r.first[next]
	return r


## Every run of solid tiles with room above it for a Worker to stand.
func _find_ledges(t: Tuning) -> void:
	var size := _map.tile_size
	var room := (t.worker_height + size - 1) / size
	for row in range(1, _map.rows):
		var first := NONE
		for column in _map.columns + 1:
			var floor := column < _map.columns and _map.is_solid(column, row) and _room_above(column, row, room)
			if floor and first == NONE:
				first = column
			elif not floor and first != NONE:
				var l := Ledge.new()
				l.row = row
				l.y = row * size
				l.left = first * size
				l.right = column * size
				l.wraps = first == 0 and column == _map.columns and _map.edges[row - 1] != MapData.Edge.BLOCKED
				if not _by_row.has(row):
					_by_row[row] = []
				_by_row[row].append(ledges.size())
				ledges.append(l)
				first = NONE


func _room_above(column: int, row: int, room: int) -> bool:
	for r in range(row - room, row):
		if _map.is_solid(column, r):
			return false
	return true


## Tries walking off each end of Ledge `from`, and jumping left and right from
## points along it. (A jump straight up only ever lands back where it started
## on Day.)
func _find_moves(from: int, walker: CharacterState, t: Tuning) -> void:
	var l := ledges[from]
	var low := l.left + _half_width
	var high := l.right - _half_width
	if low > high:
		low = l.centre()
		high = low
	if not l.wraps:
		_try(from, low, SeatInput.LEFT, false, walker, t)
		_try(from, high, SeatInput.RIGHT, false, walker, t)
	var x := low
	while true:
		for stick in [SeatInput.LEFT, SeatInput.RIGHT]:
			_try(from, x, stick, true, walker, t)
		if x == high:
			break
		x = mini(x + _LAUNCH_SPACING, high)


## Runs a Worker from x `x` on Ledge `from` with the given stick and button
## until it lands, and keeps the Move if it lands on another Ledge.
func _try(from: int, x: int, stick: int, jump: bool, walker: CharacterState, t: Tuning) -> void:
	var c := walker.copy()
	c.x = posmod(x, MapData.WIDTH)
	c.y = ledges[from].y
	var left_ground := false
	for tick in _MAX_TICKS:
		Sim._advance(c, SeatInput.of(stick, false, jump), jump and tick == 0, _map, t, false)
		if c.airborne_ticks > 0:
			left_ground = true
			continue
		var on := ledge_at(c.x, c.y)
		if on != from and on != NONE:
			var m := Move.new()
			m.from = from
			m.to = on
			m.launch_x = x
			m.stick = stick
			m.jump = jump
			m.land_x = c.x
			m.ticks = tick + 1
			moves_from[from].append(moves.size())
			moves.append(m)
			return
		if on == NONE or left_ground or tick >= _MAX_WALK_TICKS:
			return


func _holds(l: Ledge, x: int) -> bool:
	return l.wraps or absi(Sim._wrapped_dx(l.centre(), x)) < (l.right - l.left) / 2 + _half_width
