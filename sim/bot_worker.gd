class_name BotWorker
extends RefCounted
## A Bot Worker picks an objective from a read of the Match, then routes to it
## over the Map's BotNav:
## - ride the Snail, when it stands unridden on its Team's half of the track
##   and it is its Team's Bot Worker nearest it. A rider stays on while the
##   Snail is on its Team's half, and gets off on the other;
## - carrying a Berry, spend it at a free Warrior Gate its Team owns, while its
##   Team has no more Warriors (counting its Bots going to a Gate or in one)
##   than the enemy, and more than _HIVE_NEARLY_FULL holes of its Hive are
##   still empty;
## - otherwise run Berries: go for the Berry it can reach soonest, then carry
##   it to the nearest empty hole of its Hive and jump into it.
## It keeps going past every other Gate rather than stop in one by accident.

enum Objective { BERRY, HOLE, GATE, SNAIL }

## An idle Bot, with nothing to go for, looks again this often.
const _IDLE_LOOK_TICKS := 10
## A Team with no more than this many holes left to fill runs Berries rather
## than make Warriors.
const _HIVE_NEARLY_FULL := 3


## Bot Worker `c`'s input for the tick after `state`.
static func input(state: MatchState, c: CharacterState) -> SeatInput:
	return _past_gates(state, c, _input(state, c))


static func _input(state: MatchState, c: CharacterState) -> SeatInput:
	var idle := SeatInput.of(SeatInput.NEUTRAL)
	var s := state.snail
	if not c.alive or c.gate != -1 or (s != null and c.seat == s.victim):
		return idle
	if s != null and c.seat == s.rider:
		return idle if _snail_ours(state, c.team) else Bot.press(c, SeatInput.NEUTRAL)
	var nav := _nav(state, c)
	var b := c.bot
	var on := nav.ledge_at(c.x, c.y) if c.airborne_ticks == 0 else BotNav.NONE
	if on != BotNav.NONE:
		_plan(state, c, nav, on)
	if c.airborne_ticks > 0:
		# Keep to the Move under way; a jump into a hole keeps its button held.
		if b.move != BotNav.NONE:
			var m := nav.moves[b.move]
			return SeatInput.of(m.stick, false, m.jump)
		return SeatInput.of(SeatInput.NEUTRAL, false, c.button_held)
	if b.target == -1:
		return idle
	var to := _target_x(state, c)
	# Standing off the Ledges (on a starting barrier, or a head): head for it.
	if on == BotNav.NONE:
		return SeatInput.of(signi(Sim._wrapped_dx(c.x, to)))
	if b.move != BotNav.NONE:
		var m := nav.moves[b.move]
		if not m.jump:
			return SeatInput.of(m.stick)
		var dx := nav.along(on, c.x, m.launch_x)
		if absi(dx) > nav.speed:
			return SeatInput.of(signi(dx))
		return Bot.press(c, m.stick)
	var dx := nav.along(on, c.x, to)
	if absi(dx) < nav.speed:
		# Under a hole, jump into it; at a Gate, stand still to transform.
		if b.objective == Objective.HOLE:
			return Bot.press(c, SeatInput.NEUTRAL)
		if b.objective == Objective.GATE:
			return idle
	return SeatInput.of(signi(dx))


## On Ledge `on`: keeps going for the target while it is still there, routing
## again after landing on a new Ledge; otherwise chooses a new target.
static func _plan(state: MatchState, c: CharacterState, nav: BotNav, on: int) -> void:
	var b := c.bot
	var kept := _still_there(state, c, nav)
	if kept and on == b.ledge:
		return
	if b.target == -1 and on == b.ledge and (state.tick + c.seat) % _IDLE_LOOK_TICKS != 0:
		return
	var route := nav.route(on, c.x)
	if not kept or route.ticks[b.target_ledge] == BotNav.UNREACHABLE:
		_choose(state, c, nav, route)
	b.ledge = on
	b.move = route.first[b.target_ledge] if b.target != -1 else BotNav.NONE


## Whether the target is still worth going for: the objective is still the
## one to pick, and the hole is still empty, the Gate still free, or the Berry
## still free and where it was.
static func _still_there(state: MatchState, c: CharacterState, nav: BotNav) -> bool:
	var b := c.bot
	if b.target == -1 or b.objective != _objective(state, c):
		return false
	match b.objective:
		Objective.HOLE:
			return not Sim._filled_holes(state, c.team).has(b.target)
		Objective.GATE:
			return _free_gate(state, c, b.target)
		Objective.SNAIL:
			return true
	var berry := state.berries[b.target]
	return (berry.where == BerryState.Where.PILE or berry.where == BerryState.Where.LOOSE) \
		and nav.ledge_below(berry.x, berry.y) == b.target_ledge


## What `c` should go for now (see the class description).
static func _objective(state: MatchState, c: CharacterState) -> Objective:
	if _rides(state, c):
		return Objective.SNAIL
	if c.berry == -1:
		return Objective.BERRY
	if _short_of_warriors(state, c):
		for i in state.gates.size():
			if _free_gate(state, c, i):
				return Objective.GATE
	return Objective.HOLE


## Chooses, for the objective, the target `route` reaches soonest, each one's
## time made a little longer at random: an empty hole of its Hive, a free
## Warrior Gate of its Team, a Berry in a pile or loose, or the Snail. None if
## nothing can be reached.
static func _choose(state: MatchState, c: CharacterState, nav: BotNav, route: BotNav.Route) -> void:
	var b := c.bot
	b.target = -1
	b.objective = _objective(state, c)
	var none := Vector2i(-1, -1)
	var points: Array[Vector2i] = []
	match b.objective:
		Objective.SNAIL:
			points.append(Vector2i(state.snail.x, state.snail.y))
		Objective.GATE:
			for i in state.gates.size():
				points.append(Vector2i(state.gates[i].x, state.gates[i].y) if _free_gate(state, c, i) else none)
		Objective.HOLE:
			var filled := Sim._filled_holes(state, c.team)
			for h in state.map.hive_holes[c.team].size():
				points.append(none if filled.has(h) else state.map.hive_holes[c.team][h])
		Objective.BERRY:
			for berry in state.berries:
				var free := berry.where == BerryState.Where.PILE or berry.where == BerryState.Where.LOOSE
				points.append(Vector2i(berry.x, berry.y) if free else none)
	var best := BotNav.UNREACHABLE
	for i in points.size():
		if points[i].y < 0:
			continue
		var ledge := nav.ledge_below(points[i].x, points[i].y)
		if ledge == BotNav.NONE or route.ticks[ledge] == BotNav.UNREACHABLE:
			continue
		var ticks := route.ticks[ledge] + nav.walk_ticks(ledge, route.at[ledge], points[i].x) \
			+ Rng.below(state, state.tuning.bot_choice_jitter_ticks + 1)
		if ticks < best:
			best = ticks
			b.target = i
			b.target_ledge = ledge


static func _target_x(state: MatchState, c: CharacterState) -> int:
	match c.bot.objective:
		Objective.HOLE:
			return state.map.hive_holes[c.team][c.bot.target].x
		Objective.GATE:
			return state.gates[c.bot.target].x
		Objective.SNAIL:
			return state.snail.x
	return state.berries[c.bot.target].x


## Whether `c` is the one to go and ride the Snail: it stands unridden on
## `c`'s Team's half of the track, and of the Team's living Bot Workers `c` is
## the nearest it (horizontally plus vertically), or the lowest Seat of those
## as near.
static func _rides(state: MatchState, c: CharacterState) -> bool:
	var s := state.snail
	if s == null or s.rider != -1 or not _snail_ours(state, c.team):
		return false
	var mine := _snail_distance(state, c)
	for o in state.characters:
		if o.team != c.team or o.bot == null or not o.alive or o.is_winged():
			continue
		var theirs := _snail_distance(state, o)
		if theirs < mine or (theirs == mine and o.seat < c.seat):
			return false
	return true


static func _snail_distance(state: MatchState, c: CharacterState) -> int:
	return absi(Sim._wrapped_dx(c.x, state.snail.x)) + absi(state.snail.y - c.y)


## Whether the Snail stands no further from `team`'s Snail Goal than from the
## other Team's.
static func _snail_ours(state: MatchState, team: int) -> bool:
	var s := state.snail
	return absi(state.map.snail_goals[team].x - s.x) <= absi(state.map.snail_goals[1 - team].x - s.x)


## Whether `c`'s Team should make another Warrior: more than _HIVE_NEARLY_FULL
## holes of its Hive are empty, and it has no more Warriors than the enemy,
## counting its other Bots going to a Gate or in one.
static func _short_of_warriors(state: MatchState, c: CharacterState) -> bool:
	var empty: int = state.map.hive_holes[c.team].size() - Sim._filled_holes(state, c.team).size()
	if empty <= _HIVE_NEARLY_FULL:
		return false
	var warriors := [0, 0]
	for o in state.characters:
		if not o.alive:
			continue
		if o.role == CharacterState.Role.WARRIOR:
			warriors[o.team] += 1
		elif o.team == c.team and o.seat != c.seat and o.bot != null and o.bot.objective == Objective.GATE \
				and o.bot.target != -1:
			warriors[o.team] += 1
	return warriors[c.team] <= warriors[1 - c.team]


## Whether Gate `gate` is a Warrior Gate `c`'s Team owns that nobody is in.
static func _free_gate(state: MatchState, c: CharacterState, gate: int) -> bool:
	var g := state.gates[gate]
	return g.type == GateState.Type.WARRIOR and g.team == c.team and not Sim._gate_in_use(state, gate)


## A Worker carrying a Berry that stops at a Gate it could use starts to
## transform, and turning round stops it for a tick. A Bot on the ground keeps
## going past such a Gate instead, and turns once clear of it, unless it is
## the Gate it is going to transform in.
static func _past_gates(state: MatchState, c: CharacterState, input: SeatInput) -> SeatInput:
	if c.berry == -1 or c.airborne_ticks > 0 or c.vx == 0 or input.horizontal == signi(c.vx):
		return input
	for i in state.gates.size():
		if c.bot.objective == Objective.GATE and i == c.bot.target:
			continue
		var g := state.gates[i]
		if Sim._can_use(c, g) and Sim._touches_gate(c, g, state.tuning):
			return SeatInput.of(signi(c.vx), input.down, input.button)
	return input


## The Match's BotNav for a Worker of `c`'s speed, built the first time one is
## needed.
static func _nav(state: MatchState, c: CharacterState) -> BotNav:
	var easy := c.bot.difficulty == Bot.Difficulty.EASY
	var key := int(easy) + 2 * int(c.speed)
	if not state.navs.has(key):
		state.navs[key] = BotNav.of(state.map, state.tuning, easy, c.speed)
	return state.navs[key]
