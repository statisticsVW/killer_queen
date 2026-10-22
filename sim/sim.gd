class_name Sim
extends RefCounted
## The Match simulation's whole public interface: create a Match, then advance
## it one tick at a time. Pure GDScript and integer arithmetic only; nothing in
## here may touch Godot nodes, physics, floats or the clock (ADR-0001, ADR-0002).

## The surface, if any, that stopped a character's vertical movement this tick.
enum Contact { NONE, FLOOR, CEILING }


static func create_match(config: MatchConfig) -> MatchState:
	var state := MatchState.new()
	state.map = config.map
	state.tuning = config.tuning
	# A Team's Queen takes its first spawn point; its other Seats take the
	# following points in Seat order.
	var next_spawn := [0, 0]
	for seat in config.queen_seats:
		next_spawn[config.seat_teams[seat]] = 1
	for seat in config.seat_teams.size():
		var c := CharacterState.new()
		c.seat = seat
		c.team = config.seat_teams[seat]
		var spawn_index := 0
		if seat in config.queen_seats:
			c.role = CharacterState.Role.QUEEN
		else:
			spawn_index = next_spawn[c.team]
			next_spawn[c.team] += 1
		var spawn: Vector2i = config.map.spawns[c.team][spawn_index]
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
	for seat in input.dev_warrior_seats:
		var warrior := next.characters[seat]
		if warrior.role == CharacterState.Role.WORKER:
			warrior.role = CharacterState.Role.WARRIOR
			warrior.jumping = false
	for c in next.characters:
		var seat_input := input.seats[c.seat]
		var pressed := seat_input.button and not c.button_held
		c.button_held = seat_input.button
		_run(c, seat_input, next.tuning)
		if c.is_winged():
			# Gravity comes before the Flap, so an air brake ends the tick still.
			_fall(c, seat_input, next.tuning)
			_flap(c, pressed, next.tuning)
		else:
			_jump(c, pressed, seat_input.button, next.tuning)
			_fall(c, seat_input, next.tuning)
		c.stuck_ticks = maxi(c.stuck_ticks - 1, 0)
		var rising_speed := -c.vy
		var contact := _move(c, next.map, next.tuning)
		c.airborne_ticks = 0 if contact == Contact.FLOOR else c.airborne_ticks + 1
		if contact == Contact.CEILING:
			_hit_ceiling(c, rising_speed, next.tuning)
		elif c.stuck_ticks > 0 and not _under_ceiling(c, next.map, next.tuning):
			c.stuck_ticks = 0
		c.on_head = false
	_collide_characters(state, next)
	return next


static func _run(c: CharacterState, input: SeatInput, t: Tuning) -> void:
	if c.bump_ticks > 0:
		c.bump_ticks -= 1
		return
	var max_speed := t.worker_max_speed
	if c.is_winged() and c.airborne_ticks == 0:
		max_speed = max_speed * t.winged_walk_speed_ratio / 10000
	var target := input.horizontal * max_speed
	var rate := t.worker_run_decel if input.horizontal == SeatInput.NEUTRAL else t.worker_run_accel
	c.vx = _approach(c.vx, target, rate)
	if input.horizontal != SeatInput.NEUTRAL:
		c.facing = input.horizontal


## A press (not a hold) jumps while standing or within the coyote window after
## leaving the ground; there is no buffer, so a press in the air is lost.
## Releasing the button while rising from a jump cuts the rise to
## jump_release_speed, so a tap gives a short hop and a hold a full jump.
## Within the springboard window after landing on a head, a jump starts at
## springboard_jump_speed instead.
static func _jump(c: CharacterState, pressed: bool, held: bool, t: Tuning) -> void:
	var springboard := c.springboard_ticks > 0
	c.springboard_ticks = maxi(c.springboard_ticks - 1, 0)
	if c.stuck_ticks > 0:
		return
	if pressed and c.airborne_ticks <= t.worker_coyote_ticks:
		c.vy = -(t.worker_springboard_jump_speed if springboard else t.worker_jump_speed)
		c.jumping = true
		# A jump uses up the coyote window.
		c.airborne_ticks = t.worker_coyote_ticks + 1
	elif c.jumping and (not held or c.vy >= 0):
		c.jumping = false
		c.vy = maxi(c.vy, -t.worker_jump_release_speed)


## A winged press is one Flap: it adds flap_impulse of upward speed, up to
## max_rise_speed, and holding the button adds nothing more. Flaps do nothing
## while stuck to a ceiling or Diving. air_brake_flaps Flaps, the first made at
## terminal fall speed and the last fewer than air_brake_ticks ticks after it,
## stop the fall dead.
static func _flap(c: CharacterState, pressed: bool, t: Tuning) -> void:
	c.air_brake_ticks = maxi(c.air_brake_ticks - 1, 0)
	if not pressed or c.stuck_ticks > 0 or c.diving:
		return
	if c.air_brake_ticks > 0:
		c.air_brake_flaps += 1
	elif c.vy >= t.winged_max_fall_speed:
		c.air_brake_flaps = 1
		c.air_brake_ticks = t.winged_air_brake_ticks
	if c.air_brake_ticks > 0 and c.air_brake_flaps >= t.winged_air_brake_flaps:
		c.air_brake_flaps = 0
		c.air_brake_ticks = 0
		c.vy = 0
		return
	c.vy = maxi(c.vy - t.winged_flap_impulse, -t.winged_max_rise_speed)


## Gravity, unless stuck to a ceiling. A Queen holding Down in the air Dives:
## stronger gravity and a higher terminal speed. Speed past terminal, left over
## from a Dive, is kept rather than cut.
static func _fall(c: CharacterState, input: SeatInput, t: Tuning) -> void:
	c.diving = c.role == CharacterState.Role.QUEEN and input.down and c.airborne_ticks > 0
	if c.stuck_ticks > 0:
		return
	var gravity := t.worker_gravity
	var max_fall := t.worker_max_fall_speed
	if c.diving:
		gravity = t.queen_dive_gravity
		max_fall = t.queen_dive_max_fall_speed
	elif c.is_winged():
		gravity = t.winged_gravity
		max_fall = t.winged_max_fall_speed
	if c.vy < max_fall:
		c.vy = mini(c.vy + gravity, max_fall)


## Hitting a ceiling slowly sticks to it for ceiling_stick_ticks: no falling,
## jumping or Flapping, though the stick still steers sideways. Hitting it faster
## than the ricochet threshold bounces down at ceiling_ricochet_speed.
static func _hit_ceiling(c: CharacterState, rising_speed: int, t: Tuning) -> void:
	c.jumping = false
	if rising_speed > _ricochet_threshold(c, t):
		c.vy = t.ceiling_ricochet_speed
	else:
		c.stuck_ticks = t.ceiling_stick_ticks


## The upward speed above which hitting a ceiling ricochets instead of
## sticking. The Speed upgrade raises it: ticket 13 applies its multiplier here.
static func _ricochet_threshold(_c: CharacterState, t: Tuning) -> int:
	return t.ceiling_ricochet_threshold


## Whether solid tile is directly above the top of `c`'s collider.
static func _under_ceiling(c: CharacterState, map: MapData, t: Tuning) -> bool:
	var half_width := _width(c, t) / 2
	var row := map.tile_of(c.y - _height(c, t) - 1)
	return _row_blocked(map, row, map.tile_of(c.x - half_width), map.tile_of(c.x + half_width - 1),
		c.is_winged())


## Resolves contact between enemies after everyone has moved, in Seat order.
## A character that was above an enemy's head and comes down onto it stands
## there; any other contact Bumps both. Teammates pass through each other.
static func _collide_characters(before: MatchState, after: MatchState) -> void:
	var t := after.tuning
	var chars := after.characters
	for i in chars.size():
		for j in range(i + 1, chars.size()):
			var a := chars[i]
			var b := chars[j]
			if a.team == b.team or not _overlapping(a, b, t):
				continue
			if _came_down_on(before.characters[i], before.characters[j], a, t):
				_land_on_head(a, b, before.characters[i], t)
			elif _came_down_on(before.characters[j], before.characters[i], b, t):
				_land_on_head(b, a, before.characters[j], t)
			else:
				_bump(a, b, t)


## Whether `top` (last tick: `top_before`) has come down onto the head of the
## character that was `under_before` last tick.
static func _came_down_on(top_before: CharacterState, under_before: CharacterState,
		top: CharacterState, t: Tuning) -> bool:
	return top.vy >= 0 and top_before.y <= under_before.y - _height(under_before, t)


static func _land_on_head(top: CharacterState, under: CharacterState,
		top_before: CharacterState, t: Tuning) -> void:
	top.y = under.y - _height(under, t)
	top.vy = 0
	top.jumping = false
	top.airborne_ticks = 0
	if not top_before.on_head:
		top.springboard_ticks = t.worker_springboard_ticks
	top.on_head = true


## Bumped characters swap horizontal velocities (repelled according to how
## they were moving). If that wouldn't part them, both are pushed apart at
## bump_speed. Either way neither can steer or turn for bump_ticks.
static func _bump(a: CharacterState, b: CharacterState, t: Tuning) -> void:
	# Direction from a to b; a is treated as the left one when level.
	var towards_b := 1 if _wrapped_dx(a.x, b.x) >= 0 else -1
	var a_vx := b.vx
	var b_vx := a.vx
	if (b_vx - a_vx) * towards_b <= 0:
		a_vx = -towards_b * t.bump_speed
		b_vx = towards_b * t.bump_speed
	a.vx = a_vx
	b.vx = b_vx
	a.bump_ticks = t.bump_ticks
	b.bump_ticks = t.bump_ticks


static func _overlapping(a: CharacterState, b: CharacterState, t: Tuning) -> bool:
	return absi(_wrapped_dx(a.x, b.x)) < (_width(a, t) + _width(b, t)) / 2 \
		and a.y - _height(a, t) < b.y and b.y - _height(b, t) < a.y


## Collider size: Queens and Warriors share one, Workers have their own.
static func _width(c: CharacterState, t: Tuning) -> int:
	return t.winged_width if c.is_winged() else t.worker_width


static func _height(c: CharacterState, t: Tuning) -> int:
	return t.winged_height if c.is_winged() else t.worker_height


## The horizontal offset from x `from` to x `to`, the short way round the
## Map's width.
static func _wrapped_dx(from: int, to: int) -> int:
	var dx := to - from
	if dx > MapData.WIDTH / 2:
		dx -= MapData.WIDTH
	elif dx < -MapData.WIDTH / 2:
		dx += MapData.WIDTH
	return dx


## Moves `c` by its velocity, horizontally then vertically, stopping it flush
## against the first solid tile in its way and zeroing that velocity. Crossing
## a wrapping side edge brings it in on the other side. Returns which surface,
## if any, stopped its vertical movement.
static func _move(c: CharacterState, map: MapData, t: Tuning) -> Contact:
	var half_width := _width(c, t) / 2
	var height := _height(c, t)
	var size := map.tile_size
	var winged := c.is_winged()

	var first_row := map.tile_of(c.y - height)
	var last_row := map.tile_of(c.y - 1)
	var dx := c.vx
	if c.vx > 0:
		var right := c.x + half_width
		for column in range(map.tile_of(right), map.tile_of(right + c.vx - 1) + 1):
			if _column_blocked(map, column, first_row, last_row, winged):
				dx = column * size - right
				c.vx = 0
				break
	elif c.vx < 0:
		var left := c.x - half_width
		for column in range(map.tile_of(left - 1), map.tile_of(left + c.vx) - 1, -1):
			if _column_blocked(map, column, first_row, last_row, winged):
				dx = (column + 1) * size - left
				c.vx = 0
				break
	c.x = posmod(c.x + dx, MapData.WIDTH)

	var first_column := map.tile_of(c.x - half_width)
	var last_column := map.tile_of(c.x + half_width - 1)
	var dy := c.vy
	var contact := Contact.NONE
	if c.vy > 0:
		for row in range(map.tile_of(c.y), map.tile_of(c.y + c.vy - 1) + 1):
			if _row_blocked(map, row, first_column, last_column, winged):
				dy = row * size - c.y
				c.vy = 0
				contact = Contact.FLOOR
				break
	elif c.vy < 0:
		var top := c.y - height
		for row in range(map.tile_of(top - 1), map.tile_of(top + c.vy) - 1, -1):
			if _row_blocked(map, row, first_column, last_column, winged):
				dy = (row + 1) * size - top
				c.vy = 0
				contact = Contact.CEILING
				break
	c.y += dy
	return contact


static func _column_blocked(map: MapData, column: int, first_row: int, last_row: int,
		winged: bool) -> bool:
	for row in range(first_row, last_row + 1):
		if map.is_solid(column, row, winged):
			return true
	return false


static func _row_blocked(map: MapData, row: int, first_column: int, last_column: int,
		winged: bool) -> bool:
	for column in range(first_column, last_column + 1):
		if map.is_solid(column, row, winged):
			return true
	return false


static func _approach(value: int, target: int, rate: int) -> int:
	if value < target:
		return mini(value + rate, target)
	return maxi(value - rate, target)
