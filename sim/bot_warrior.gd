class_name BotWarrior
extends RefCounted
## A Bot Warrior. Each tick it does the most urgent of these:
## - keep away from a close enemy Queen or Warrior that isn't below it (its
##   sword would win), backing off and climbing to its height, from where a
##   Flap or two puts it above;
## - if it is its Team's Warrior nearest their own Snail rider, guard the
##   rider: go for the enemy nearest the rider, if one is close, or else hover
##   over it;
## - kill an enemy Worker riding the Snail;
## - kill a close enemy Queen or Warrior below it;
## - kill the nearest enemy Worker carrying a Berry;
## - get above the enemy Queen, to come down on her;
## - kill the nearest enemy Worker;
## - otherwise wait at its Hive.
## Like the Queen, it leaves alone a Worker that an enemy sword which isn't
## below it is guarding. It reads the Match through BotSword and flies with
## BotFlight.

## How close a sword that isn't below it has to be to make it keep away.
const _THREAT_RANGE := 120000
## How far a close enemy Queen or Warrior below it can be for it to attack.
const _ATTACK_RANGE := 260000
## How far it backs away from a sword.
const _BACK_OFF := 200000
## How far above the enemy Queen it gets before coming down on her.
const _OVER_QUEEN := 80000
## Guarding its Snail rider: how high above it it hovers, and how close to it
## an enemy has to be to be attacked.
const _GUARD_HEIGHT := 120000
const _GUARD_REACH := 300000


static func input(state: MatchState, c: CharacterState) -> SeatInput:
	if not c.alive:
		return SeatInput.of(SeatInput.NEUTRAL)
	var t := state.tuning
	var threat := BotSword.threat(state, c, _THREAT_RANGE)
	if threat != null:
		return BotSword.back_off(state, c, threat, _BACK_OFF, BotSword.body_y(threat, t))
	var rider := _own_rider(state, c)
	if rider != null:
		var intruder := _intruder(state, c, rider)
		if intruder != null:
			return _strike(state, c, intruder)
		return BotFlight.toward(state, c, rider.x, rider.y - _GUARD_HEIGHT - t.winged_height / 2)
	var prey := BotSword.snail_rider(state, c)
	if prey == null:
		prey = BotSword.winged_below(state, c, _ATTACK_RANGE)
	if prey == null:
		prey = BotSword.worker(state, c, true)
	if prey == null:
		var queen := _enemy_queen(state, c)
		if queen != null:
			return BotFlight.toward(state, c, queen.x, BotSword.body_y(queen, t) - _OVER_QUEEN)
		prey = BotSword.worker(state, c, false)
	if prey != null:
		return _strike(state, c, prey)
	return BotFlight.toward(state, c, c.spawn.x, c.spawn.y - t.winged_height / 2)


## Flies its body into `prey`: at a Worker's body, or at a Queen's or
## Warrior's head, so its own feet stay above the other's.
static func _strike(state: MatchState, c: CharacterState, prey: CharacterState) -> SeatInput:
	var t := state.tuning
	var y := prey.y - t.winged_height if prey.is_winged() else BotSword.body_y(prey, t)
	return BotFlight.toward(state, c, prey.x, y)


## Its Team's Worker riding the Snail, if no other Warrior of the Team is
## nearer it; else null.
static func _own_rider(state: MatchState, c: CharacterState) -> CharacterState:
	if state.snail == null or state.snail.rider == -1:
		return null
	var rider := state.characters[state.snail.rider]
	if rider.team != c.team:
		return null
	for o in state.characters:
		if o.team == c.team and o.alive and o.role == CharacterState.Role.WARRIOR \
				and BotSword.distance(o, rider) < BotSword.distance(c, rider):
			return null
	return rider


## The enemy nearest `rider` within _GUARD_REACH of it; null if none. (One
## whose sword is higher than `c`'s is kept off by keeping away from it.)
static func _intruder(state: MatchState, c: CharacterState, rider: CharacterState) -> CharacterState:
	var nearest: CharacterState = null
	for e in BotSword.enemies(state, c):
		if BotSword.distance(rider, e) >= _GUARD_REACH:
			continue
		if nearest == null or BotSword.distance(rider, e) < BotSword.distance(rider, nearest):
			nearest = e
	return nearest


## The enemy Queen, if she is alive.
static func _enemy_queen(state: MatchState, c: CharacterState) -> CharacterState:
	for e in BotSword.enemies(state, c):
		if e.role == CharacterState.Role.QUEEN:
			return e
	return null
