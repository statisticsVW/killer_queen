class_name BotSword
extends RefCounted
## What a winged Bot (a Queen or a Warrior) reads of the Match before using
## its sword. An enemy Queen or Warrior is dangerous to it when its sword
## isn't below the Bot's, or the Bot can't kill it (it's invulnerable); one
## whose sword is below can be attacked from above. A Worker or Gate is
## guarded when a dangerous enemy is close to it. Distances are the larger of
## the horizontal (the short way round) and vertical distances between feet.
## A Bot sees its enemies late, by its Difficulty's reaction delay (Bot.view).

## How close a dangerous enemy has to be to something to guard it.
const GUARD_RANGE := 120000


## The nearest dangerous enemy within `range` of `c` that `c` has noticed;
## null if none. When one first comes that close, `c` notices it its
## Difficulty's awareness_percent of the time; one it misses it ignores until
## it is no longer a threat.
static func threat(state: MatchState, c: CharacterState, range: int) -> CharacterState:
	var t := state.tuning
	var b := c.bot
	var nearest: CharacterState = null
	# Bits by Seat of the enemies that are threats now.
	var threats := 0
	for e in enemies(state, c):
		if not dangerous(state, c, e) or distance(c, e) >= range:
			continue
		var bit := 1 << e.seat
		threats |= bit
		if (b.noticed | b.missed) & bit == 0:
			var aware := Bot.by_level(c, t.bot_easy_awareness_percent, t.bot_normal_awareness_percent,
				t.bot_hard_awareness_percent)
			if Rng.below(state, 100) < aware:
				b.noticed |= bit
			else:
				b.missed |= bit
		if b.noticed & bit != 0 and (nearest == null or distance(c, e) < distance(c, nearest)):
			nearest = e
	b.noticed &= threats
	b.missed &= threats
	return nearest


## Whether enemy `e` could kill `c`: a Queen or Warrior whose sword isn't
## below `c`'s, or one `c` can't kill (invulnerable).
static func dangerous(state: MatchState, c: CharacterState, e: CharacterState) -> bool:
	return e.is_winged() and (e.y <= c.y + state.tuning.joust_height_margin or e.invulnerable_ticks > 0)


## Whether an enemy dangerous to `c` is close to (x, y).
static func guarded(state: MatchState, c: CharacterState, x: int, y: int) -> bool:
	for e in enemies(state, c):
		if dangerous(state, c, e) and distance_to(e, x, y) < GUARD_RANGE:
			return true
	return false


## `c`'s input to fly `back` away from `e` horizontally, its body at
## height `y`.
static func back_off(state: MatchState, c: CharacterState, e: CharacterState, back: int,
		y: int) -> SeatInput:
	return BotFlight.toward(state, c, c.x + away(c, e) * back, y)


## The way from `e` to `c` (-1 or 1); if level, the way `e` is facing away
## from.
static func away(c: CharacterState, e: CharacterState) -> int:
	var way := -signi(Sim._wrapped_dx(c.x, e.x))
	return way if way != 0 else -e.facing


## The enemy Worker riding the Snail, unless it is guarded; null if none.
static func snail_rider(state: MatchState, c: CharacterState) -> CharacterState:
	if state.snail == null or state.snail.rider == -1:
		return null
	var rider: CharacterState = Bot.view(state, c)[state.snail.rider]
	return rider if rider.team != c.team and not guarded(state, c, rider.x, rider.y) else null


## The nearest enemy Queen or Warrior within `range` whose sword is below
## `c`'s, and that `c` can kill.
static func winged_below(state: MatchState, c: CharacterState, range: int) -> CharacterState:
	var t := state.tuning
	var nearest: CharacterState = null
	for e in enemies(state, c):
		if e.is_winged() and e.y > c.y + t.joust_height_margin and e.invulnerable_ticks == 0 \
				and distance(c, e) < range \
				and (nearest == null or distance(c, e) < distance(c, nearest)):
			nearest = e
	return nearest


## The nearest unguarded enemy Worker, only among those carrying a Berry if
## `carrying`; null if none.
static func worker(state: MatchState, c: CharacterState, carrying: bool) -> CharacterState:
	var nearest: CharacterState = null
	for e in enemies(state, c):
		if e.is_winged() or e.is_locked_in(state.tuning) or (carrying and e.berry == -1) \
				or guarded(state, c, e.x, e.y):
			continue
		if nearest == null or distance(c, e) < distance(c, nearest):
			nearest = e
	return nearest


## Living enemies, as `c` sees them.
static func enemies(state: MatchState, c: CharacterState) -> Array[CharacterState]:
	var result: Array[CharacterState] = []
	for e: CharacterState in Bot.view(state, c):
		if e.alive and e.team != c.team:
			result.append(e)
	return result


static func distance(a: CharacterState, b: CharacterState) -> int:
	return distance_to(a, b.x, b.y)


static func distance_to(c: CharacterState, x: int, y: int) -> int:
	return maxi(absi(Sim._wrapped_dx(c.x, x)), absi(y - c.y))


## The height of `c`'s body centre.
static func body_y(c: CharacterState, t: Tuning) -> int:
	return c.y - (t.winged_height if c.is_winged() else t.worker_height) / 2
