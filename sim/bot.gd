class_name Bot
extends RefCounted
## Bots: Seats the sim drives itself. Each tick, before anyone moves, a Bot
## reads the Match state and gives its Seat's input: the stick and button a
## device gives a human, so a Bot can do nothing a human can't. Its choices
## draw on the Match's random generator, so a Match with Bots plays out the
## same from the same seed and human input.
##
## Bot Workers run Berries. Each goes for the Berry it can reach soonest, then
## carries it to the nearest empty hole of its Hive and jumps into it. Queen and Warrior Bots stand idle for now.

## A Team's Bot Difficulty. Easy Bots move at the arcade's Bot speed
## (bot_easy_speed_ratio); otherwise the levels play alike, for now.
enum Difficulty { EASY, NORMAL, HARD }

## An idle Bot, with nothing to go for, looks again this often.
const _IDLE_LOOK_TICKS := 10


## Bot `c`'s input for the tick after `state`, which it may change only in
## `c.bot` and the random generator.
static func input(state: MatchState, c: CharacterState) -> SeatInput:
	return _past_gates(state, c, _input(state, c))


static func _input(state: MatchState, c: CharacterState) -> SeatInput:
	var idle := SeatInput.of(SeatInput.NEUTRAL)
	var s := state.snail
	if not c.alive or c.role != CharacterState.Role.WORKER or c.gate != -1 \
			or (s != null and c.seat == s.victim):
		return idle
	# The Snail is no use for running Berries: get off it.
	if s != null and c.seat == s.rider:
		return _press(c, SeatInput.NEUTRAL)
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
		return _press(c, m.stick)
	var dx := nav.along(on, c.x, to)
	if b.carrying and absi(dx) < nav.speed:
		return _press(c, SeatInput.NEUTRAL)
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


## Whether the target is still worth going for: the hole is still empty, or
## the Berry is still free and where it was.
static func _still_there(state: MatchState, c: CharacterState, nav: BotNav) -> bool:
	var b := c.bot
	if b.target == -1 or b.carrying != (c.berry != -1):
		return false
	if b.carrying:
		return not Sim._filled_holes(state, c.team).has(b.target)
	var berry := state.berries[b.target]
	return (berry.where == BerryState.Where.PILE or berry.where == BerryState.Where.LOOSE) \
		and nav.ledge_below(berry.x, berry.y) == b.target_ledge


## Chooses the target `route` reaches soonest, each one's time made a little
## longer at random: an empty hole of its Hive while carrying, else a Berry in
## a pile or loose. None if nothing can be reached.
static func _choose(state: MatchState, c: CharacterState, nav: BotNav, route: BotNav.Route) -> void:
	var b := c.bot
	b.target = -1
	b.carrying = c.berry != -1
	var points: Array[Vector2i] = []
	if b.carrying:
		var filled := Sim._filled_holes(state, c.team)
		for h in state.map.hive_holes[c.team].size():
			points.append(Vector2i(-1, -1) if filled.has(h) else state.map.hive_holes[c.team][h])
	else:
		for berry in state.berries:
			var free := berry.where == BerryState.Where.PILE or berry.where == BerryState.Where.LOOSE
			points.append(Vector2i(berry.x, berry.y) if free else Vector2i(-1, -1))
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
	if c.bot.carrying:
		return state.map.hive_holes[c.team][c.bot.target].x
	return state.berries[c.bot.target].x


## A Worker carrying a Berry that stops at a Gate it could use starts to
## transform, and turning round stops it for a tick. A Berry-running Bot on the
## ground keeps going past such a Gate instead, and turns once clear of it.
static func _past_gates(state: MatchState, c: CharacterState, input: SeatInput) -> SeatInput:
	if c.berry == -1 or c.airborne_ticks > 0 or c.vx == 0 or input.horizontal == signi(c.vx):
		return input
	for g in state.gates:
		if Sim._can_use(c, g) and Sim._touches_gate(c, g, state.tuning):
			return SeatInput.of(signi(c.vx), input.down, input.button)
	return input


## Presses the button, with the stick at `stick`; if it is still held from
## before, lets go of it first, to press on the next tick.
static func _press(c: CharacterState, stick: int) -> SeatInput:
	return SeatInput.of(stick, false, not c.button_held)


## The Match's BotNav for a Worker of `c`'s speed, built the first time one is
## needed.
static func _nav(state: MatchState, c: CharacterState) -> BotNav:
	var easy := c.bot.difficulty == Difficulty.EASY
	var key := int(easy) + 2 * int(c.speed)
	if not state.navs.has(key):
		state.navs[key] = BotNav.of(state.map, state.tuning, easy, c.speed)
	return state.navs[key]
