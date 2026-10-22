class_name TestMaps
extends RefCounted
## Small purpose-built Maps for sim tests, written in the map file's tile-row
## format (see data/maps/day.cfg) with 120 px tiles: 9 rows of an edge
## character plus 16 tiles.

const TILE_PX := 120


## A Map from tile rows, with Blue's spawn points given in whole pixels.
static func build(tiles: Array[String], blue_spawns_px: Array[Vector2i]) -> MapData:
	var cfg := ConfigFile.new()
	cfg.set_value("map", "tile_size", TILE_PX)
	cfg.set_value("map", "tiles", tiles)
	cfg.set_value("spawns", "blue", blue_spawns_px)
	return MapData.from_config(cfg)


## A floor across the whole screen (top at y 960 px) with blocked side edges.
## Every Seat spawns standing on it at the centre.
static func flat_floor(seat_count: int) -> MapData:
	var spawns: Array[Vector2i] = []
	for i in seat_count:
		spawns.append(Vector2i(960, 960))
	return build([
		"|................",
		"|................",
		"|................",
		"|................",
		"|................",
		"|................",
		"|................",
		"|................",
		"|################",
	], spawns)
