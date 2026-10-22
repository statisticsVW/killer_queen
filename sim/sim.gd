class_name Sim
extends RefCounted
## The Match simulation's whole public interface: create a Match, then advance
## it one tick at a time. Pure GDScript and integer arithmetic only; nothing in
## here may touch Godot nodes, physics, floats or the clock (ADR-0001, ADR-0002).


static func create_match(config: MatchConfig) -> MatchState:
	var state := MatchState.new()
	state.map = config.map
	state.tuning = config.tuning
	for seat in config.seat_teams.size():
		var c := CharacterState.new()
		c.seat = seat
		c.team = config.seat_teams[seat]
		c.x = config.map.spawns[seat].x
		c.y = config.map.spawns[seat].y
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
	return next


static func _run(c: CharacterState, input: SeatInput, t: Tuning) -> void:
	var target := input.horizontal * t.worker_max_speed
	var rate := t.worker_run_decel if input.horizontal == SeatInput.NEUTRAL else t.worker_run_accel
	c.vx = _approach(c.vx, target, rate)
	if input.horizontal != SeatInput.NEUTRAL:
		c.facing = input.horizontal

	var half_width := t.worker_width / 2
	c.x += c.vx
	if c.x < half_width or c.x > MapData.WIDTH - half_width:
		c.x = clampi(c.x, half_width, MapData.WIDTH - half_width)
		c.vx = 0


static func _approach(value: int, target: int, rate: int) -> int:
	if value < target:
		return mini(value + rate, target)
	return maxi(value - rate, target)
