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
	# following points in Seat order, as Workers unless the config starts them
	# upgraded.
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
			if seat in config.warrior_seats:
				c.role = CharacterState.Role.WARRIOR
			c.speed = seat in config.speed_seats
		if seat in config.bot_seats:
			c.bot = BotState.new()
			c.bot.difficulty = config.bot_difficulties[c.team] as Bot.Difficulty
		c.spawn = config.map.spawns[c.team][spawn_index]
		c.x = c.spawn.x
		c.y = c.spawn.y
		state.characters.append(c)
	state.eggs.assign([config.map.eggs[0].size(), config.map.eggs[1].size()])
	state.rng = Rng.start(config.seed)
	for type in [GateState.Type.WARRIOR, GateState.Type.SPEED]:
		var positions := config.map.warrior_gates if type == GateState.Type.WARRIOR else config.map.speed_gates
		for at in positions:
			var g := GateState.new()
			g.type = type
			g.x = at.x
			g.y = at.y
			state.gates.append(g)
	if config.map.has_snail:
		state.snail = SnailState.new()
		state.snail.x = config.map.snail_start.x
		state.snail.y = config.map.snail_start.y
	for slot in _pile_slots(config.map, config.tuning):
		var b := BerryState.new()
		b.x = slot.x
		b.y = slot.y
		state.berries.append(b)
	return state


## Where each Berry of each of the Map's piles sits when the pile is full, in
## Map order: a triangle of six, a Berry apart, in rows of three, two and one
## from the bottom up.
static func _pile_slots(map: MapData, t: Tuning) -> Array[Vector2i]:
	var slots: Array[Vector2i] = []
	var size := t.berry_size
	for pile in map.berry_piles:
		for row in 3:
			for i in 3 - row:
				slots.append(Vector2i(pile.x + (2 * i - (2 - row)) * size / 2, pile.y - row * size))
	return slots


## Returns the state one tick after `state`. `input` must be tagged with
## state.tick, the tick it applies to; a Bot Seat plays its Bot's input
## instead of the one `input` holds for it. During the countdown that starts the
## Match (MatchState.countdown_ticks), the Map's starting barriers are solid.
## Once a Team has won, the Match is over: stepping it changes nothing but the
## tick.
static func step(state: MatchState, input: TickInput) -> MatchState:
	assert(input.tick == state.tick, "Input for tick %d applied at tick %d" % [input.tick, state.tick])
	var next := state.copy()
	next.tick += 1
	next.events = []
	next.inputs = input.seats.duplicate()
	if next.win != MatchState.Win.NONE:
		return next
	next.seen = [state.characters] + state.seen.slice(0, Bot.memory_ticks(next.tuning) - 1)
	# Bots decide from the state as it stood, before anyone moves.
	for c in next.characters:
		if c.bot != null:
			next.inputs[c.seat] = Bot.input(next, c)
	# The starting barriers stand for inputs tagged within the countdown.
	var barriers := state.countdown_ticks() > 0
	for c in next.characters:
		var seat_input := next.inputs[c.seat]
		var pressed := seat_input.button and not c.button_held
		c.button_held = seat_input.button
		if not c.alive:
			if c.respawn_ticks > 0:
				c.respawn_ticks -= 1
				if c.respawn_ticks == 0:
					_respawn(c, next)
			continue
		# The Snail carries its rider and holds its victim; a press gets the
		# rider off, with a jump, unless the Snail is eating.
		if next.snail != null and c.seat == next.snail.rider:
			if not pressed or next.snail.victim != -1:
				continue
			_dismount(c, next)
		elif next.snail != null and c.seat == next.snail.victim:
			continue
		# A Worker transforming in a Gate stays put.
		if c.gate != -1:
			continue
		_advance(c, seat_input, pressed, next.map, next.tuning, barriers)
	_update_snail(next)
	if next.win == MatchState.Win.NONE:
		_collide_characters(state, next)
	if next.win == MatchState.Win.NONE:
		_update_gates(next)
	if next.win == MatchState.Win.NONE:
		_update_berries(next, barriers)
	if next.win == MatchState.Win.NONE:
		_update_famine(next)
	return next


## Moves a living character one tick by its own input, as if nothing else
## were on the Map: steering, jumping or Flapping, falling, then against the
## terrain. BotNav runs Workers through this too, to find their Moves.
static func _advance(c: CharacterState, input: SeatInput, pressed: bool, map: MapData, t: Tuning,
		barriers: bool) -> void:
	c.invulnerable_ticks = maxi(c.invulnerable_ticks - 1, 0)
	_run(c, input, t)
	if c.is_winged():
		# Gravity comes before the Flap, so an air brake ends the tick still.
		_fall(c, input, t)
		_flap(c, pressed, t)
	else:
		_jump(c, pressed, input.button, t)
		_fall(c, input, t)
	c.stuck_ticks = maxi(c.stuck_ticks - 1, 0)
	var rising_speed := -c.vy
	var contact := _move_character(c, map, t, barriers)
	c.airborne_ticks = 0 if contact == Contact.FLOOR else c.airborne_ticks + 1
	if contact == Contact.CEILING:
		_hit_ceiling(c, rising_speed, t)
	elif c.stuck_ticks > 0 and not _under_ceiling(c, map, t, barriers):
		c.stuck_ticks = 0
	c.on_head = false


static func _run(c: CharacterState, input: SeatInput, t: Tuning) -> void:
	if c.bump_ticks > 0:
		c.bump_ticks -= 1
		return
	var max_speed := _max_speed(c, t)
	if c.is_winged() and c.airborne_ticks == 0:
		max_speed = max_speed * t.winged_walk_speed_ratio / 10000
	var target := input.horizontal * max_speed
	var rate := t.worker_run_decel if input.horizontal == SeatInput.NEUTRAL else t.worker_run_accel
	c.vx = _approach(c.vx, target, rate)
	if input.horizontal != SeatInput.NEUTRAL:
		c.facing = input.horizontal


## A character's top horizontal speed, before winged walking slows it: raised
## by the Speed upgrade, and slowed to the arcade's Bot speed for an Easy Bot.
static func _max_speed(c: CharacterState, t: Tuning) -> int:
	var max_speed := t.worker_max_speed
	if c.speed:
		max_speed = max_speed * t.speed_ratio / 10000
	if c.bot != null and c.bot.difficulty == Bot.Difficulty.EASY:
		max_speed = max_speed * t.bot_easy_speed_ratio / 10000
	return max_speed


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
## max_rise_speed (raised by the Speed upgrade), and holding the button adds
## nothing more. Flaps do nothing while stuck to a ceiling or Diving. air_brake_flaps Flaps, the first made at
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
	var max_rise := t.winged_max_rise_speed
	if c.speed:
		max_rise = max_rise * t.speed_ratio / 10000
	c.vy = maxi(c.vy - t.winged_flap_impulse, -max_rise)


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
## sticking, higher with the Speed upgrade.
static func _ricochet_threshold(c: CharacterState, t: Tuning) -> int:
	return t.ceiling_speed_ricochet_threshold if c.speed else t.ceiling_ricochet_threshold


## Whether solid tile is directly above the top of `c`'s collider.
static func _under_ceiling(c: CharacterState, map: MapData, t: Tuning, barriers: bool) -> bool:
	var half_width := _width(c, t) / 2
	var row := map.tile_of(c.y - _height(c, t) - 1)
	return _row_blocked(map, row, map.tile_of(c.x - half_width), map.tile_of(c.x + half_width - 1),
		c.is_winged(), barriers)


## Resolves contact between living enemies after everyone has moved, in Seat
## order. A sword that wins (see _winner) kills; an enemy sword touching an
## invulnerable character passes through it. Otherwise a character that was
## above an enemy's head and comes down onto it stands there, and any other
## contact Bumps both. Teammates pass through each other, and everyone passes
## through a Worker locked in a Gate. Nothing more happens once the Match is
## won.
static func _collide_characters(before: MatchState, after: MatchState) -> void:
	var t := after.tuning
	var chars := after.characters
	for i in chars.size():
		for j in range(i + 1, chars.size()):
			if after.win != MatchState.Win.NONE:
				return
			var a := chars[i]
			var b := chars[j]
			if a.team == b.team or not a.alive or not b.alive or a.is_locked_in(t) or b.is_locked_in(t) \
					or not _overlapping(a, b, t):
				continue
			var winner := _winner(a, b, t)
			if winner != null:
				var loser := b if winner == a else a
				_kill(loser, winner, after)
			elif (a.is_winged() and b.invulnerable_ticks > 0) or (b.is_winged() and a.invulnerable_ticks > 0):
				continue
			elif _came_down_on(before.characters[i], before.characters[j], a, t):
				_land_on_head(a, b, before.characters[i], t)
			elif _came_down_on(before.characters[j], before.characters[i], b, t):
				_land_on_head(b, a, before.characters[j], t)
			else:
				_bump(a, b, after)


## Which of two touching enemies kills the other with its sword, or null.
## Queens and Warriors always have their swords out; Workers have none. A sword
## kills a Worker from any side. Two swords Joust: the higher wins, then, if
## they are level, the one that ran into the other's back. Nothing kills an
## invulnerable character.
static func _winner(a: CharacterState, b: CharacterState, t: Tuning) -> CharacterState:
	var winner: CharacterState = null
	if a.is_winged() != b.is_winged():
		winner = a if a.is_winged() else b
	elif not a.is_winged():
		return null
	elif _above(a, b, t):
		winner = a
	elif _above(b, a, t):
		winner = b
	elif _behind(a, b):
		winner = a
	elif _behind(b, a):
		winner = b
	if winner == null or (b if winner == a else a).invulnerable_ticks > 0:
		return null
	return winner


## Whether `top`'s sword is higher than `under`'s: its feet are more than the
## Joust height margin above, or above at all if it is a Diving Queen (the Dive
## kills anything beneath her).
static func _above(top: CharacterState, under: CharacterState, t: Tuning) -> bool:
	var margin := 0 if top.diving else t.joust_height_margin
	return top.y < under.y - margin


## Whether `attacker` faces `victim` and `victim` faces away from it.
static func _behind(attacker: CharacterState, victim: CharacterState) -> bool:
	var towards_victim := signi(_wrapped_dx(attacker.x, victim.x))
	return towards_victim != 0 and attacker.facing == towards_victim and victim.facing == towards_victim


## `victim` dies where it stands, killed by `killer` (null when the Snail ate
## it), dropping any Berry and leaving the Snail or a Gate. Anyone but a Queen
## respawns after respawn_ticks. A Queen hatches from her Team's next waiting
## Egg after respawn_queen_ticks; with none left she stays dead and the other
## Team wins.
static func _kill(victim: CharacterState, killer: CharacterState, state: MatchState) -> void:
	var t := state.tuning
	_leave_snail(victim, state)
	_leave_gate(victim, state)
	victim.alive = false
	victim.respawn_ticks = t.respawn_ticks
	victim.vx = 0
	victim.vy = 0
	victim.jumping = false
	victim.stuck_ticks = 0
	victim.bump_ticks = 0
	victim.on_head = false
	victim.springboard_ticks = 0
	victim.diving = false
	victim.air_brake_flaps = 0
	victim.air_brake_ticks = 0
	_drop_berry(victim, state)
	var killer_seat := -1
	if killer != null:
		killer_seat = killer.seat
		state.events.append(MatchEvent.of(MatchEvent.Type.KILL, killer.seat, victim.seat))
	state.events.append(MatchEvent.of(MatchEvent.Type.DEATH, victim.seat, killer_seat))
	if victim.role != CharacterState.Role.QUEEN:
		return
	if state.eggs[victim.team] > 0:
		state.eggs[victim.team] -= 1
		victim.spawn = state.map.eggs[victim.team][state.eggs[victim.team]]
		victim.respawn_ticks = t.respawn_queen_ticks
		return
	victim.respawn_ticks = 0
	if state.win == MatchState.Win.NONE:
		state.win = MatchState.Win.MILITARY
		state.winner = 1 - victim.team
		state.events.append(MatchEvent.win(state.winner))


## Brings a dead character back at its spawn point (a Queen at the Egg she
## hatches from), invulnerable. Anyone else comes back as a plain Worker,
## without its upgrades. It doesn't move on the tick it reappears.
static func _respawn(c: CharacterState, state: MatchState) -> void:
	c.alive = true
	c.x = c.spawn.x
	c.y = c.spawn.y
	c.airborne_ticks = 0
	c.invulnerable_ticks = state.tuning.respawn_invulnerable_ticks
	if c.role == CharacterState.Role.WARRIOR:
		c.role = CharacterState.Role.WORKER
	c.speed = false
	var type := MatchEvent.Type.HATCH if c.role == CharacterState.Role.QUEEN else MatchEvent.Type.RESPAWN
	state.events.append(MatchEvent.of(type, c.seat))


## The Snail, after characters have moved and before they collide. An eat
## counts down and completes. Otherwise a ridden Snail moves toward its
## rider's Snail Goal (faster for a Speed Worker), and reaching it is a Snail
## Win. Then, in Seat order, an unridden Snail is mounted by the first living
## Worker touching it (but not one that dismounted and hasn't yet stood on the
## ground clear of it), and a ridden one that isn't eating starts to eat the
## first enemy Worker touching its front. Its rider sits on top of it, facing
## its goal.
static func _update_snail(state: MatchState) -> void:
	var s := state.snail
	if s == null:
		return
	var t := state.tuning
	if s.victim != -1:
		s.eat_ticks -= 1
		if s.eat_ticks == 0:
			var eaten := state.characters[s.victim]
			state.events.append(MatchEvent.of(MatchEvent.Type.EAT_COMPLETE, s.rider, s.victim))
			s.victim = -1
			_kill(eaten, null, state)
	elif s.rider != -1:
		var rider := state.characters[s.rider]
		var goal: int = state.map.snail_goals[rider.team].x
		var speed := t.snail_speed
		if rider.speed:
			speed = speed * t.snail_speed_rider_ratio / 10000
		s.x += signi(goal - s.x) * mini(speed, absi(goal - s.x))
		if s.x == goal:
			state.win = MatchState.Win.SNAIL
			state.winner = rider.team
			state.events.append(MatchEvent.win(rider.team))
	if s.dismounted != -1:
		var left := state.characters[s.dismounted]
		if not left.alive or (left.airborne_ticks == 0 and not _touches_snail(left, s, t)):
			s.dismounted = -1
	for c in state.characters:
		if not c.alive or c.is_winged() or c.seat == s.rider or c.gate != -1 or not _touches_snail(c, s, t):
			continue
		if s.rider == -1 and c.seat != s.dismounted:
			s.rider = c.seat
			c.invulnerable_ticks = 0
			state.events.append(MatchEvent.of(MatchEvent.Type.SNAIL_MOUNT, c.seat))
		elif s.rider != -1 and s.victim == -1 and c.team != state.characters[s.rider].team \
				and (c.x - s.x) * _snail_heading(state) > 0:
			s.victim = c.seat
			s.eat_ticks = t.snail_speed_rider_eat_ticks if state.characters[s.rider].speed else t.snail_eat_ticks
			c.vx = 0
			c.vy = 0
			c.invulnerable_ticks = 0
			state.events.append(MatchEvent.of(MatchEvent.Type.EAT_START, s.rider, c.seat))
	if s.rider != -1:
		var rider := state.characters[s.rider]
		rider.x = s.x
		rider.y = s.y - t.snail_height
		rider.vx = 0
		rider.vy = 0
		rider.jumping = false
		rider.airborne_ticks = 0
		if _snail_heading(state) != 0:
			rider.facing = _snail_heading(state)


## The way a ridden Snail moves: toward its rider's Snail Goal (-1 or 1), or 0
## at the goal or unridden.
static func _snail_heading(state: MatchState) -> int:
	var s := state.snail
	if s.rider == -1:
		return 0
	return signi(state.map.snail_goals[state.characters[s.rider].team].x - s.x)


static func _touches_snail(c: CharacterState, s: SnailState, t: Tuning) -> bool:
	return _boxes_overlap(c.x, c.y, _width(c, t), _height(c, t), s.x, s.y, t.snail_width, t.snail_height)


## The rider gets off by the button: it is left standing on the Snail, to jump
## off this tick as from the ground, and can't remount until it has stood on
## the ground clear of the Snail.
static func _dismount(c: CharacterState, state: MatchState) -> void:
	state.snail.rider = -1
	state.snail.dismounted = c.seat
	c.airborne_ticks = 0
	state.events.append(MatchEvent.of(MatchEvent.Type.SNAIL_DISMOUNT, c.seat))


## `c` stops riding or being eaten by the Snail, if it was; an eat in
## progress is interrupted, and its victim is free.
static func _leave_snail(c: CharacterState, state: MatchState) -> void:
	var s := state.snail
	if s == null or (c.seat != s.rider and c.seat != s.victim):
		return
	if s.victim != -1:
		state.events.append(MatchEvent.of(MatchEvent.Type.EAT_INTERRUPT, s.rider, s.victim))
		s.victim = -1
	if c.seat == s.rider:
		s.rider = -1


## Gates, after characters have collided and before Berries. First, in Seat
## order, each living Queen claims every Gate she touches for her Team. Then
## each transform goes on: as the doors close after gate_hold_ticks the Berry
## is spent, and after gate_locked_ticks more the Worker emerges upgraded and
## invulnerable. Then, in Seat order, a living Worker carrying a Berry who
## stands still on the ground (not on the Snail) touching a Gate that would
## upgrade it, that its Team can use and that nobody else is in, starts
## transforming there, snapped to the Gate's centre. Until it emerges it
## ignores its stick, picks nothing up and is out of the Snail's reach.
static func _update_gates(state: MatchState) -> void:
	var t := state.tuning
	for c in state.characters:
		if not c.alive or c.role != CharacterState.Role.QUEEN:
			continue
		for i in state.gates.size():
			var g := state.gates[i]
			if g.team != c.team and _touches_gate(c, g, t):
				g.team = c.team
				state.events.append(MatchEvent.of(MatchEvent.Type.GATE_CLAIM, c.seat, i))
	for c in state.characters:
		if c.gate == -1:
			continue
		c.gate_ticks += 1
		if c.gate_ticks == t.gate_hold_ticks:
			state.berries[c.berry].where = BerryState.Where.SPENT
			c.berry = -1
		if c.gate_ticks == t.gate_hold_ticks + t.gate_locked_ticks:
			_emerge(c, state)
	for c in state.characters:
		if not c.alive or c.is_winged() or c.berry == -1 or c.gate != -1 or c.vx != 0 or c.airborne_ticks != 0 \
				or (state.snail != null and (c.seat == state.snail.rider or c.seat == state.snail.victim)):
			continue
		for i in state.gates.size():
			var g := state.gates[i]
			if _can_use(c, g) and not _gate_in_use(state, i) and _touches_gate(c, g, t):
				c.gate = i
				c.gate_ticks = 0
				c.x = g.x
				state.events.append(MatchEvent.of(MatchEvent.Type.TRANSFORM_START, c.seat, i))
				break


## Whether Worker `c` could transform at `g`: its Team can use the Gate, and
## the Gate would change it (a Speed Gate does nothing for a Speed Worker).
static func _can_use(c: CharacterState, g: GateState) -> bool:
	return (g.team == -1 or g.team == c.team) and not (g.type == GateState.Type.SPEED and c.speed)


static func _gate_in_use(state: MatchState, gate: int) -> bool:
	for c in state.characters:
		if c.gate == gate:
			return true
	return false


## `c` comes out of its Gate upgraded, standing where it went in and
## invulnerable for gate_invulnerable_ticks.
static func _emerge(c: CharacterState, state: MatchState) -> void:
	if state.gates[c.gate].type == GateState.Type.WARRIOR:
		c.role = CharacterState.Role.WARRIOR
	else:
		c.speed = true
	c.invulnerable_ticks = state.tuning.gate_invulnerable_ticks
	state.events.append(MatchEvent.of(MatchEvent.Type.TRANSFORM_COMPLETE, c.seat, c.gate))
	c.gate = -1
	c.gate_ticks = 0


## `c` stops transforming in a Gate, if it was, keeping any Berry it holds.
static func _leave_gate(c: CharacterState, state: MatchState) -> void:
	if c.gate == -1:
		return
	state.events.append(MatchEvent.of(MatchEvent.Type.TRANSFORM_INTERRUPT, c.seat, c.gate))
	c.gate = -1
	c.gate_ticks = 0


static func _touches_gate(c: CharacterState, g: GateState, t: Tuning) -> bool:
	return _boxes_overlap(c.x, c.y, _width(c, t), _height(c, t), g.x, g.y, t.gate_width, t.gate_height)


## Berries, after characters have moved and collided: loose Berries move;
## then, in Seat order, each living Worker carrying a Berry deposits it in an
## empty hole of its Team's Hive that it touches, or else kicks any loose Berry
## it runs into, and each empty-handed Worker picks up the first Berry it
## touches (which ends its invulnerability). A Worker in a Gate does neither.
## Carried Berries then ride on their Workers' heads. Queens and Warriors pass
## through Berries.
static func _update_berries(state: MatchState, barriers: bool) -> void:
	var t := state.tuning
	for b in state.berries:
		if b.where == BerryState.Where.LOOSE:
			_move_berry(b, state, barriers)
	for c in state.characters:
		if not c.alive or c.is_winged() or c.gate != -1:
			continue
		if c.berry == -1:
			_pick_up(c, state)
		elif not _deposit(c, state):
			_kick(c, state)
		if state.win != MatchState.Win.NONE:
			return
	for c in state.characters:
		if c.berry != -1:
			state.berries[c.berry].x = c.x
			state.berries[c.berry].y = c.y - _height(c, t)


## Famine, last in the tick. While it lasts it counts down, and as it ends
## every pile is refilled. Otherwise, on a Map that has Berries, Famine starts
## once every one of them is in a Hive or spent at a Gate: none is left in a
## pile, loose or carried.
static func _update_famine(state: MatchState) -> void:
	if state.famine_ticks > 0:
		state.famine_ticks -= 1
		if state.famine_ticks == 0:
			_refill_piles(state)
			state.events.append(MatchEvent.of(MatchEvent.Type.FAMINE_END, -1))
		return
	if state.berries.is_empty():
		return
	for b in state.berries:
		if b.where != BerryState.Where.HIVE and b.where != BerryState.Where.SPENT:
			return
	state.famine_ticks = state.tuning.famine_countdown_ticks
	state.events.append(MatchEvent.of(MatchEvent.Type.FAMINE_START, -1))


## Puts a Berry back in every pile slot: the spent Berries first, in index
## order, then new ones appended to MatchState.berries for the slots left.
## Berries in Hives stay there.
static func _refill_piles(state: MatchState) -> void:
	var spent := range(state.berries.size()).filter(
		func(i: int) -> bool: return state.berries[i].where == BerryState.Where.SPENT)
	for slot in _pile_slots(state.map, state.tuning):
		var b: BerryState
		if spent.is_empty():
			b = BerryState.new()
			state.berries.append(b)
		else:
			b = state.berries[spent.pop_front()]
		b.where = BerryState.Where.PILE
		b.x = slot.x
		b.y = slot.y


## Gravity, then movement against terrain, then friction while on the ground.
static func _move_berry(b: BerryState, state: MatchState, barriers: bool) -> void:
	var t := state.tuning
	b.vy = mini(b.vy + t.berry_gravity, maxi(b.vy, t.berry_max_fall_speed))
	if _move(b, t.berry_size / 2, t.berry_size, false, state.map, barriers) == Contact.FLOOR:
		b.vx = _approach(b.vx, 0, t.berry_friction)


static func _pick_up(c: CharacterState, state: MatchState) -> void:
	for i in state.berries.size():
		var b := state.berries[i]
		if (b.where == BerryState.Where.PILE or b.where == BerryState.Where.LOOSE) \
				and _touches_berry(c, b, state.tuning):
			b.where = BerryState.Where.CARRIED
			b.vx = 0
			b.vy = 0
			c.berry = i
			c.invulnerable_ticks = 0
			state.events.append(MatchEvent.of(MatchEvent.Type.BERRY_PICKUP, c.seat, i))
			return


## Deposits `c`'s Berry in the first empty hole of its Team's Hive whose centre
## is inside `c`'s collider, if any; filling the last hole is an Economic Win.
## Returns whether it deposited.
static func _deposit(c: CharacterState, state: MatchState) -> bool:
	var t := state.tuning
	var holes: Array[Vector2i] = state.map.hive_holes[c.team]
	var filled := _filled_holes(state, c.team)
	for h in holes.size():
		var hole := holes[h]
		if filled.has(h) or absi(_wrapped_dx(c.x, hole.x)) >= _width(c, t) / 2 \
				or hole.y < c.y - _height(c, t) or hole.y >= c.y:
			continue
		var b := state.berries[c.berry]
		b.where = BerryState.Where.HIVE
		b.team = c.team
		b.hole = h
		b.x = hole.x
		b.y = hole.y + t.berry_size / 2
		state.events.append(MatchEvent.of(MatchEvent.Type.BERRY_DEPOSIT, c.seat, c.berry))
		c.berry = -1
		if filled.size() + 1 == holes.size():
			state.win = MatchState.Win.ECONOMIC
			state.winner = c.team
			state.events.append(MatchEvent.win(c.team))
		return true
	return false


## The holes of `team`'s Hive that hold a Berry.
static func _filled_holes(state: MatchState, team: int) -> Array[int]:
	var filled: Array[int] = []
	for b in state.berries:
		if b.where == BerryState.Where.HIVE and b.team == team:
			filled.append(b.hole)
	return filled


## A Worker carrying a Berry who runs into a loose one kicks it away from
## itself (the way it faces, if level) at berry_kick_speed, unless it is
## already flying away that fast.
static func _kick(c: CharacterState, state: MatchState) -> void:
	var t := state.tuning
	for i in state.berries.size():
		var b := state.berries[i]
		if b.where != BerryState.Where.LOOSE or not _touches_berry(c, b, t):
			continue
		var away := signi(_wrapped_dx(c.x, b.x))
		if away == 0:
			away = c.facing
		if b.vx * away >= t.berry_kick_speed:
			continue
		b.vx = away * t.berry_kick_speed
		b.vy = -t.berry_kick_lift
		state.events.append(MatchEvent.of(MatchEvent.Type.BERRY_KICK, c.seat, i))


## A Berry `c` carries drops where it stands, as a loose Berry.
static func _drop_berry(c: CharacterState, state: MatchState) -> void:
	if c.berry == -1:
		return
	var b := state.berries[c.berry]
	b.where = BerryState.Where.LOOSE
	b.x = c.x
	b.y = c.y
	b.vx = 0
	b.vy = 0
	state.events.append(MatchEvent.of(MatchEvent.Type.BERRY_DROP, c.seat, c.berry))
	c.berry = -1


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
## bump_speed. Either way neither can steer or turn for bump_ticks, and a
## Worker holding its Berry up in a Gate is Bumped out of it.
static func _bump(a: CharacterState, b: CharacterState, state: MatchState) -> void:
	var t := state.tuning
	_leave_gate(a, state)
	_leave_gate(b, state)
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
	return _boxes_overlap(a.x, a.y, _width(a, t), _height(a, t), b.x, b.y, _width(b, t), _height(b, t))


static func _touches_berry(c: CharacterState, b: BerryState, t: Tuning) -> bool:
	return _boxes_overlap(c.x, c.y, _width(c, t), _height(c, t), b.x, b.y, t.berry_size, t.berry_size)


## Whether two colliders, each given by its bottom-centre and size, overlap
## (across the wrap too).
static func _boxes_overlap(ax: int, ay: int, aw: int, ah: int, bx: int, by: int, bw: int, bh: int) -> bool:
	return absi(_wrapped_dx(ax, bx)) < (aw + bw) / 2 and ay - ah < by and by - bh < ay


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


static func _move_character(c: CharacterState, map: MapData, t: Tuning, barriers: bool) -> Contact:
	return _move(c, _width(c, t) / 2, _height(c, t), c.is_winged(), map, barriers)


## Moves `c` (a character or a Berry: anything with x, y, vx and vy) with a
## collider of the given size by its velocity, horizontally then vertically,
## stopping it flush against the first solid tile in its way and zeroing that
## velocity. Crossing a wrapping side edge brings it in on the other side;
## `winged` bodies are blocked at Workers-only wraps, and starting barriers
## block everything while `barriers` stand. Returns which surface, if any,
## stopped its vertical movement.
static func _move(c, half_width: int, height: int, winged: bool, map: MapData, barriers: bool) -> Contact:
	var size := map.tile_size

	var first_row := map.tile_of(c.y - height)
	var last_row := map.tile_of(c.y - 1)
	var dx: int = c.vx
	if c.vx > 0:
		var right: int = c.x + half_width
		for column in range(map.tile_of(right), map.tile_of(right + c.vx - 1) + 1):
			if _column_blocked(map, column, first_row, last_row, winged, barriers):
				dx = column * size - right
				c.vx = 0
				break
	elif c.vx < 0:
		var left: int = c.x - half_width
		for column in range(map.tile_of(left - 1), map.tile_of(left + c.vx) - 1, -1):
			if _column_blocked(map, column, first_row, last_row, winged, barriers):
				dx = (column + 1) * size - left
				c.vx = 0
				break
	c.x = posmod(c.x + dx, MapData.WIDTH)

	var first_column := map.tile_of(c.x - half_width)
	var last_column := map.tile_of(c.x + half_width - 1)
	var dy: int = c.vy
	var contact := Contact.NONE
	if c.vy > 0:
		for row in range(map.tile_of(c.y), map.tile_of(c.y + c.vy - 1) + 1):
			if _row_blocked(map, row, first_column, last_column, winged, barriers):
				dy = row * size - c.y
				c.vy = 0
				contact = Contact.FLOOR
				break
	elif c.vy < 0:
		var top: int = c.y - height
		for row in range(map.tile_of(top - 1), map.tile_of(top + c.vy) - 1, -1):
			if _row_blocked(map, row, first_column, last_column, winged, barriers):
				dy = (row + 1) * size - top
				c.vy = 0
				contact = Contact.CEILING
				break
	c.y += dy
	return contact


static func _column_blocked(map: MapData, column: int, first_row: int, last_row: int,
		winged: bool, barriers: bool) -> bool:
	for row in range(first_row, last_row + 1):
		if map.is_solid(column, row, winged, barriers):
			return true
	return false


static func _row_blocked(map: MapData, row: int, first_column: int, last_column: int,
		winged: bool, barriers: bool) -> bool:
	for column in range(first_column, last_column + 1):
		if map.is_solid(column, row, winged, barriers):
			return true
	return false


static func _approach(value: int, target: int, rate: int) -> int:
	if value < target:
		return mini(value + rate, target)
	return maxi(value - rate, target)
