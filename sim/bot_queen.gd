class_name BotQueen
extends RefCounted
## A Bot Queen. Each tick she does the most urgent of these:
## - keep away from a close enemy Queen or Warrior that isn't below her (its
##   sword would win), backing off at her height; she keeps further away when
##   she's at risk: no Eggs left, or more enemy Warriors than hers;
## - kill an enemy Worker riding the Snail;
## - kill a close enemy Queen or Warrior below her, from above;
## - claim the nearest neutral Gate;
## - kill the nearest enemy Worker carrying a Berry;
## - steal the nearest enemy Gate;
## - kill the nearest enemy Worker;
## - otherwise wait at her Hive.
## She leaves alone a Gate or Worker that an enemy sword which isn't below her
## is guarding (close to it), rather than fly in and back off again.
## She comes at her prey from just above it and Dives once it is right below
## her. She flies with
## BotFlight.

## How close a sword that isn't below her has to be to make her keep away,
## and how close when she's at risk.
const _THREAT_RANGE := 120000
const _RISKY_THREAT_RANGE := 220000
## How far a close enemy Queen or Warrior below her can be for her to attack.
const _ATTACK_RANGE := 260000
## How far she backs away from a sword.
const _BACK_OFF := 200000
## Prey within this much horizontally and below her gets Dived on.
const _DIVE_REACH := 24000
## How far above her prey's head she lines up her feet before Diving.
const _OVER_PREY := 8000


static func input(state: MatchState, c: CharacterState) -> SeatInput:
	if not c.alive:
		return SeatInput.of(SeatInput.NEUTRAL)
	var t := state.tuning
	var threat := _threat(state, c)
	if threat != null:
		var away := -signi(Sim._wrapped_dx(c.x, threat.x))
		if away == 0:
			away = -threat.facing
		return BotFlight.toward(state, c, c.x + away * _BACK_OFF, _body_y(c, t))
	var prey := _snail_rider(state, c)
	if prey == null:
		prey = _winged_below(state, c)
	if prey == null:
		var gate := _gate_to_claim(state, c, -1)
		if gate != null:
			return BotFlight.toward(state, c, gate.x, gate.y - t.gate_height / 2)
		prey = _worker(state, c, true)
	if prey == null:
		var gate := _gate_to_claim(state, c, 1 - c.team)
		if gate != null:
			return BotFlight.toward(state, c, gate.x, gate.y - t.gate_height / 2)
		prey = _worker(state, c, false)
	if prey != null:
		return _attack(state, c, prey)
	return BotFlight.toward(state, c, c.spawn.x, c.spawn.y - t.winged_height / 2)


## Flies to just above `prey`, and Dives once it is right below her.
static func _attack(state: MatchState, c: CharacterState, prey: CharacterState) -> SeatInput:
	var t := state.tuning
	var below := prey.y > c.y and absi(Sim._wrapped_dx(c.x, prey.x)) < _DIVE_REACH
	var head := prey.y - (t.winged_height if prey.is_winged() else t.worker_height)
	return BotFlight.toward(state, c, prey.x, head - _OVER_PREY - t.winged_height / 2, below)


## The nearest dangerous enemy close enough to worry about; null if none.
static func _threat(state: MatchState, c: CharacterState) -> CharacterState:
	var range := _RISKY_THREAT_RANGE if _at_risk(state, c) else _THREAT_RANGE
	var nearest: CharacterState = null
	for e in _enemies(state, c):
		if not _dangerous(state, c, e):
			continue
		if _distance(c, e) < range and (nearest == null or _distance(c, e) < _distance(c, nearest)):
			nearest = e
	return nearest


## Whether enemy `e` could kill her: a Queen or Warrior whose sword isn't
## below hers, or one she can't kill (invulnerable).
static func _dangerous(state: MatchState, c: CharacterState, e: CharacterState) -> bool:
	return e.is_winged() and (e.y <= c.y + state.tuning.joust_height_margin or e.invulnerable_ticks > 0)


## Whether a dangerous enemy is close to (x, y).
static func _guarded(state: MatchState, c: CharacterState, x: int, y: int) -> bool:
	for e in _enemies(state, c):
		if _dangerous(state, c, e) and _distance_to(e, x, y) < _THREAT_RANGE:
			return true
	return false


## No Eggs left, or the other Team has more Warriors than hers.
static func _at_risk(state: MatchState, c: CharacterState) -> bool:
	var warriors := [0, 0]
	for o in state.characters:
		if o.alive and o.role == CharacterState.Role.WARRIOR:
			warriors[o.team] += 1
	return state.eggs[c.team] == 0 or warriors[1 - c.team] > warriors[c.team]


static func _snail_rider(state: MatchState, c: CharacterState) -> CharacterState:
	if state.snail == null or state.snail.rider == -1:
		return null
	var rider := state.characters[state.snail.rider]
	return rider if rider.team != c.team and not _guarded(state, c, rider.x, rider.y) else null


## The nearest enemy Queen or Warrior within attacking range whose sword is
## below hers, and that she can kill.
static func _winged_below(state: MatchState, c: CharacterState) -> CharacterState:
	var t := state.tuning
	var nearest: CharacterState = null
	for e in _enemies(state, c):
		if e.is_winged() and e.y > c.y + t.joust_height_margin and e.invulnerable_ticks == 0 \
				and _distance(c, e) < _ATTACK_RANGE \
				and (nearest == null or _distance(c, e) < _distance(c, nearest)):
			nearest = e
	return nearest


## The nearest Gate owned by `team` (-1: neutral) that no enemy guards, or
## null.
static func _gate_to_claim(state: MatchState, c: CharacterState, team: int) -> GateState:
	var best: GateState = null
	for g in state.gates:
		if g.team != team or _guarded(state, c, g.x, g.y):
			continue
		if best == null or _distance_to(c, g.x, g.y) < _distance_to(c, best.x, best.y):
			best = g
	return best


## The nearest unguarded enemy Worker, only among those carrying a Berry if
## `carrying`; null if none.
static func _worker(state: MatchState, c: CharacterState, carrying: bool) -> CharacterState:
	var nearest: CharacterState = null
	for e in _enemies(state, c):
		if e.is_winged() or e.is_locked_in(state.tuning) or (carrying and e.berry == -1) \
				or _guarded(state, c, e.x, e.y):
			continue
		if nearest == null or _distance(c, e) < _distance(c, nearest):
			nearest = e
	return nearest


## Living enemies.
static func _enemies(state: MatchState, c: CharacterState) -> Array[CharacterState]:
	var result: Array[CharacterState] = []
	for e in state.characters:
		if e.alive and e.team != c.team:
			result.append(e)
	return result


static func _distance(a: CharacterState, b: CharacterState) -> int:
	return _distance_to(a, b.x, b.y)


## The larger of the horizontal (the short way round) and vertical distances
## between `c`'s feet and (x, y).
static func _distance_to(c: CharacterState, x: int, y: int) -> int:
	return maxi(absi(Sim._wrapped_dx(c.x, x)), absi(y - c.y))


static func _body_y(c: CharacterState, t: Tuning) -> int:
	return c.y - (t.winged_height if c.is_winged() else t.worker_height) / 2
