class_name MapData
extends RefCounted
## A Map's fixed layout, loaded from a data file (see data/maps/day.cfg for the
## format). Shared, never modified, by every MatchState on it.
## Coordinates are milli-pixels in 1920x1080 space, y pointing down.

const WIDTH := 1920 * 1000
const HEIGHT := 1080 * 1000

## What a row's side edges do to a character crossing them.
enum Edge { BLOCKED, WRAP, WRAP_WORKERS_ONLY }

const _EDGE_CHARS := {"|": Edge.BLOCKED, "~": Edge.WRAP, "w": Edge.WRAP_WORKERS_ONLY}
const _PX := 1000

var name: String
## The map file this Map was built from, as text, so a Replay can carry it.
var source: String
## Side length of one collision tile.
var tile_size: int
var columns: int
var rows: int
## Row-major, one byte per tile: 1 if solid.
var solid: PackedByteArray
## Edge behaviour of each tile row.
var edges: Array[Edge]

## Spawn points per Team (indexed by Team, each an Array[Vector2i]): the nth
## Seat of a Team spawns at its nth point. Bottom-centre of the character.
var spawns: Array
## Hive hole centres per Team (indexed by Team, each an Array[Vector2i]).
var hive_holes: Array
## Waiting Egg positions per Team (indexed by Team, each an Array[Vector2i]).
var eggs: Array
var warrior_gates: Array[Vector2i]
var speed_gates: Array[Vector2i]
## Bottom-centre of each Berry pile.
var berry_piles: Array[Vector2i]
## Whether the Map has a Snail ([snail] start).
var has_snail: bool
var snail_start: Vector2i
## Each Team's Snail Goal on the Snail track, indexed by Team.
var snail_goals: Array[Vector2i]
## The starting barriers, solid only during a Match's countdown: rectangles
## of whole tiles (position is the top-left corner).
var barriers: Array[Rect2i]
## Row-major, one byte per tile: 1 if a starting barrier covers it.
var _barrier_tiles: PackedByteArray


static func load_file(path: String) -> MapData:
	var cfg := ConfigFile.new()
	var err := cfg.load(path)
	assert(err == OK, "Could not load map file %s (error %d)" % [path, err])
	return from_config(cfg)


## Builds a Map from a parsed map file. Only [map] tile_size and tiles are
## required; every object list is empty if left out.
static func from_config(cfg: ConfigFile) -> MapData:
	var map := MapData.new()
	map.name = cfg.get_value("map", "name", "")
	map.source = cfg.encode_to_text()
	map.tile_size = cfg.get_value("map", "tile_size") * _PX
	assert(WIDTH % map.tile_size == 0 and HEIGHT % map.tile_size == 0,
		"tile_size must divide 1920 and 1080")
	map.columns = WIDTH / map.tile_size
	map.rows = HEIGHT / map.tile_size
	map._parse_tiles(cfg.get_value("map", "tiles"))

	map.spawns = [_points(cfg, "spawns", "blue"), _points(cfg, "spawns", "gold")]
	map.hive_holes = [_points(cfg, "hive", "blue_holes"), _points(cfg, "hive", "gold_holes")]
	map.eggs = [_points(cfg, "hive", "blue_eggs"), _points(cfg, "hive", "gold_eggs")]
	map.warrior_gates = _points(cfg, "gates", "warrior")
	map.speed_gates = _points(cfg, "gates", "speed")
	map.berry_piles = _points(cfg, "berries", "piles")
	map.has_snail = cfg.has_section_key("snail", "start")
	map.snail_start = cfg.get_value("snail", "start", Vector2i.ZERO) * _PX
	map.snail_goals.assign([
		cfg.get_value("snail", "blue_goal", Vector2i.ZERO) * _PX,
		cfg.get_value("snail", "gold_goal", Vector2i.ZERO) * _PX,
	])
	map._parse_barriers(cfg.get_value("barriers", "rects", []))
	return map


## Whether tile (column, row) is solid. Above and below the Map is solid; past
## a side edge is solid on a BLOCKED row and the other side's tile on a
## wrapping row. A WRAP_WORKERS_ONLY row is blocked for `winged` characters.
## Starting barriers are solid only while `barriers` stand.
func is_solid(column: int, row: int, winged := false, barriers := false) -> bool:
	if row < 0 or row >= rows:
		return true
	if column < 0 or column >= columns:
		if edges[row] == Edge.BLOCKED or (winged and edges[row] == Edge.WRAP_WORKERS_ONLY):
			return true
		column = posmod(column, columns)
	var i := row * columns + column
	return solid[i] == 1 or (barriers and _barrier_tiles[i] == 1)


## The tile index containing coordinate `v`, rounding toward negative infinity.
func tile_of(v: int) -> int:
	if v >= 0:
		return v / tile_size
	return -((-v + tile_size - 1) / tile_size)


func _parse_tiles(lines: Array) -> void:
	assert(lines.size() == rows, "Map needs %d tile rows, has %d" % [rows, lines.size()])
	solid.resize(rows * columns)
	for row in rows:
		var line: String = lines[row]
		assert(line.length() == columns + 1, "Tile row %d needs an edge char and %d tiles" % [row, columns])
		assert(_EDGE_CHARS.has(line[0]), "Tile row %d has unknown edge '%s'" % [row, line[0]])
		edges.append(_EDGE_CHARS[line[0]])
		for column in columns:
			var tile := line[column + 1]
			assert(tile == "#" or tile == ".", "Unknown tile '%s' in row %d" % [tile, row])
			solid[row * columns + column] = 1 if tile == "#" else 0


func _parse_barriers(rects: Array) -> void:
	_barrier_tiles.resize(rows * columns)
	for r in rects:
		var rect := Rect2i(r.position * _PX, r.size * _PX)
		assert(rect.position.x % tile_size == 0 and rect.position.y % tile_size == 0
			and rect.size.x % tile_size == 0 and rect.size.y % tile_size == 0,
			"Barrier %s must cover whole tiles" % r)
		barriers.append(rect)
		for row in range(rect.position.y / tile_size, rect.end.y / tile_size):
			for column in range(rect.position.x / tile_size, rect.end.x / tile_size):
				_barrier_tiles[row * columns + column] = 1


static func _points(cfg: ConfigFile, section: String, key: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for p in cfg.get_value(section, key, []):
		result.append(p * _PX)
	return result
