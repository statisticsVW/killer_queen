class_name Sim
extends RefCounted
## The Match simulation's whole public interface: create a Match, then advance
## it one tick at a time. Pure GDScript and integer arithmetic only; nothing in
## here may touch Godot nodes, physics, floats or the clock (ADR-0001, ADR-0002).


static func create_match(config: MatchConfig) -> MatchState:
	var state := MatchState.new()
	state.map = config.map
	state.tuning = config.tuning
	# The nth Seat of a Team takes that Team's nth spawn point.
	var spawned_per_team := [0, 0]
	for seat in config.seat_teams.size():
		var c := CharacterState.new()
		c.seat = seat
		c.team = config.seat_teams[seat]
		var spawn: Vector2i = config.map.spawns[c.team][spawned_per_team[c.team]]
		spawned_per_team[c.team] += 1
		c.x = spawn.x
		c.y = spawn.y
		state.characters.append(c)
	return state


## Returns the state one tick after `state`. `input` must be tagged with
## state.tick, the tick it applies to.
static func step(state: MatchState, input: TickInput) -> MatchState:
	assert(input.tick == state.tick, "Input for tick %d applied at tick %d" % [input.tick, state.tick])
	var next := state.copy()
	next.tick += 1
	for c in next.characters:
		_run(c, input.seats[c.seat], next.tuning)
		_fall(c, next.tuning)
		_move(c, next.map, next.tuning)
	return next


static func _run(c: CharacterState, input: SeatInput, t: Tuning) -> void:
	var target := input.horizontal * t.worker_max_speed
	var rate := t.worker_run_decel if input.horizontal == SeatInput.NEUTRAL else t.worker_run_accel
	c.vx = _approach(c.vx, target, rate)
	if input.horizontal != SeatInput.NEUTRAL:
		c.facing = input.horizontal


static func _fall(c: CharacterState, t: Tuning) -> void:
	c.vy = mini(c.vy + t.worker_gravity, t.worker_max_fall_speed)


## Moves `c` by its velocity, horizontally then vertically, stopping it flush
## against the first solid tile in its way and zeroing that velocity. Crossing
## a wrapping side edge brings it in on the other side.
static func _move(c: CharacterState, map: MapData, t: Tuning) -> void:
	var half_width := t.worker_width / 2
	var height := t.worker_height
	var size := map.tile_size

	var first_row := map.tile_of(c.y - height)
	var last_row := map.tile_of(c.y - 1)
	var dx := c.vx
	if c.vx > 0:
		var right := c.x + half_width
		for column in range(map.tile_of(right), map.tile_of(right + c.vx - 1) + 1):
			if _column_blocked(map, column, first_row, last_row):
				dx = column * size - right
				c.vx = 0
				break
	elif c.vx < 0:
		var left := c.x - half_width
		for column in range(map.tile_of(left - 1), map.tile_of(left + c.vx) - 1, -1):
			if _column_blocked(map, column, first_row, last_row):
				dx = (column + 1) * size - left
				c.vx = 0
				break
	c.x = posmod(c.x + dx, MapData.WIDTH)

	var first_column := map.tile_of(c.x - half_width)
	var last_column := map.tile_of(c.x + half_width - 1)
	var dy := c.vy
	if c.vy > 0:
		for row in range(map.tile_of(c.y), map.tile_of(c.y + c.vy - 1) + 1):
			if _row_blocked(map, row, first_column, last_column):
				dy = row * size - c.y
				c.vy = 0
				break
	elif c.vy < 0:
		var top := c.y - height
		for row in range(map.tile_of(top - 1), map.tile_of(top + c.vy) - 1, -1):
			if _row_blocked(map, row, first_column, last_column):
				dy = (row + 1) * size - top
				c.vy = 0
				break
	c.y += dy


static func _column_blocked(map: MapData, column: int, first_row: int, last_row: int) -> bool:
	for row in range(first_row, last_row + 1):
		if map.is_solid(column, row):
			return true
	return false


static func _row_blocked(map: MapData, row: int, first_column: int, last_column: int) -> bool:
	for column in range(first_column, last_column + 1):
		if map.is_solid(column, row):
			return true
	return false


static func _approach(value: int, target: int, rate: int) -> int:
	if value < target:
		return mini(value + rate, target)
	return maxi(value - rate, target)
