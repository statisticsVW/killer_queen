class_name MapData
extends RefCounted
## A Map's fixed layout. Shared, never modified, by every MatchState on it.
## Coordinates are milli-pixels in 1920x1080 space, y pointing down.

const WIDTH := 1920 * 1000
const HEIGHT := 1080 * 1000

## y of the floor surface.
var floor_y: int
## Where each Seat's character starts (bottom-centre of its collider), by Seat.
var spawns: Array[Vector2i]


## A flat floor across the whole screen with every Seat spawning at the centre.
static func test_floor(seat_count: int) -> MapData:
	var map := MapData.new()
	map.floor_y = 1000 * 1000
	for i in seat_count:
		map.spawns.append(Vector2i(WIDTH / 2, map.floor_y))
	return map
