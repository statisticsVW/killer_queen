class_name BotFlight
extends RefCounted
## How a winged Bot flies to a point. The Map is cut into square cells; a cell
## is open if a winged collider centred in it touches no solid tile. For a
## target cell, every cell's distance to it in steps between open cells is
## worked out once and remembered. A flyer heads for the cell a few steps
## nearer along those distances, steering with the stick and Flapping to climb
## or to hold its height. Like BotNav, this comes from the Map and Tuning
## alone and is never Match state.

const CELL := 24000
## The distance from a cell the target can't be reached from.
const FAR := 1 << 30
## How many steps along the way a flyer aims ahead of its own cell.
const _AIM_STEPS := 2
## Within this much horizontally a flyer stops steering.
const _CLOSE := 4000
## Distance fields remembered per BotFlight, and BotFlights remembered.
const _REMEMBERED_FIELDS := 512
const _REMEMBERED := 4

static var _built := {}

var columns: int
var rows: int
## Per cell, 1 if open.
var open: PackedByteArray
## Per row of cells, 1 if winged characters wrap round its side edges.
var wraps: PackedByteArray
var _fields := {}


## The cells of `map` for a winged collider, built once for each Map and
## Tuning.
static func of(map: MapData, t: Tuning) -> BotFlight:
	var key := var_to_str([map.source, t.winged_width, t.winged_height]).sha256_text()
	if not _built.has(key):
		if _built.size() >= _REMEMBERED:
			_built.clear()
		_built[key] = build(map, t)
	return _built[key]


static func build(map: MapData, t: Tuning) -> BotFlight:
	var f := BotFlight.new()
	f.columns = MapData.WIDTH / CELL
	f.rows = MapData.HEIGHT / CELL
	f.open.resize(f.columns * f.rows)
	f.wraps.resize(f.rows)
	var half_width := t.winged_width / 2
	var half_height := t.winged_height / 2
	for row in f.rows:
		var top := row * CELL + CELL / 2 - half_height
		var first_tile := map.tile_of(top)
		var last_tile := map.tile_of(top + 2 * half_height - 1)
		f.wraps[row] = 1
		for tile_row in range(maxi(first_tile, 0), mini(last_tile, map.rows - 1) + 1):
			if map.edges[tile_row] != MapData.Edge.WRAP:
				f.wraps[row] = 0
		for column in f.columns:
			var left := column * CELL + CELL / 2 - half_width
			f.open[row * f.columns + column] = 1
			for tile_row in range(first_tile, last_tile + 1):
				for tile_column in range(map.tile_of(left), map.tile_of(left + 2 * half_width - 1) + 1):
					if map.is_solid(tile_column, tile_row, true):
						f.open[row * f.columns + column] = 0
	return f


## The Map's BotFlight, kept with the Match's other Bot data.
static func of_match(state: MatchState) -> BotFlight:
	if not state.navs.has("flight"):
		state.navs["flight"] = of(state.map, state.tuning)
	return state.navs["flight"]


## Winged character `c`'s input to fly its body's centre to (x, y): the stick
## toward the next cell on the way there, and a Flap whenever it is sinking
## faster than it should to reach that height. Diving, it holds Down instead
## and doesn't Flap.
static func toward(state: MatchState, c: CharacterState, x: int, y: int, dive := false) -> SeatInput:
	var t := state.tuning
	var f := of_match(state)
	var body_y := c.y - t.winged_height / 2
	var aim := f._aim(c.x, body_y, x, y)
	var dx := Sim._wrapped_dx(c.x, aim.x)
	var stick := 0 if absi(dx) < _CLOSE else signi(dx)
	var down := dive and c.airborne_ticks > 0
	var rise := t.winged_max_rise_speed * (t.speed_ratio if c.speed else 10000) / 10000
	var wanted_vy := clampi((aim.y - body_y) / 4, -rise, t.winged_max_fall_speed)
	var flap := not down and c.vy > wanted_vy and not c.button_held
	return SeatInput.of(stick, down, flap)


## Where to head for, from (x, y) to (to_x, to_y): a cell a few steps along
## the way, or the target itself once that near or if it can't be reached.
func _aim(x: int, y: int, to_x: int, to_y: int) -> Vector2i:
	var from := _open_cell_near(x, y)
	var to := _open_cell_near(to_x, to_y)
	if from == -1 or to == -1 or from == to:
		return Vector2i(to_x, to_y)
	var field := _field(to)
	if field[from] == FAR:
		return Vector2i(to_x, to_y)
	var cell := from
	for i in _AIM_STEPS:
		cell = _nearer(cell, field)
		if cell == to:
			return Vector2i(to_x, to_y)
	return Vector2i((cell % columns) * CELL + CELL / 2, (cell / columns) * CELL + CELL / 2)


## The open cell (x, y) is in, or else the nearest open one around it, looking
## up first; -1 if there is none close.
func _open_cell_near(x: int, y: int) -> int:
	var column := posmod(x, MapData.WIDTH) / CELL
	var row := clampi(y / CELL, 0, rows - 1)
	for offset in [Vector2i(0, 0), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1),
			Vector2i(0, -2), Vector2i(-1, -1), Vector2i(1, -1)]:
		var r: int = row + offset.y
		if r < 0 or r >= rows:
			continue
		var cell := r * columns + posmod(column + offset.x, columns)
		if open[cell] == 1:
			return cell
	return -1


## The open neighbour of `cell` nearest the target of `field`, or `cell`.
func _nearer(cell: int, field: PackedInt32Array) -> int:
	var best := cell
	for next in _neighbours(cell):
		if field[next] < field[best]:
			best = next
	return best


## Every cell's distance in steps to `target`, through open cells.
func _field(target: int) -> PackedInt32Array:
	if _fields.has(target):
		return _fields[target]
	var field := PackedInt32Array()
	field.resize(columns * rows)
	field.fill(FAR)
	field[target] = 0
	var queue := PackedInt32Array([target])
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for next in _neighbours(cell):
			if field[next] == FAR:
				field[next] = field[cell] + 1
				queue.append(next)
	if _fields.size() >= _REMEMBERED_FIELDS:
		_fields.clear()
	_fields[target] = field
	return field


## The open cells next to `cell`: up, down, left and right, across a side
## edge only on a row winged characters wrap round.
func _neighbours(cell: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	var row := cell / columns
	var column := cell % columns
	if row > 0 and open[cell - columns] == 1:
		result.append(cell - columns)
	if row < rows - 1 and open[cell + columns] == 1:
		result.append(cell + columns)
	for step in [-1, 1]:
		var c: int = column + step
		if c < 0 or c >= columns:
			if wraps[row] == 0:
				continue
			c = posmod(c, columns)
		if open[row * columns + c] == 1:
			result.append(row * columns + c)
	return result
