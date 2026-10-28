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
## her. She reads the Match through BotSword and flies with BotFlight.

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
	var threat := BotSword.threat(state, c, _RISKY_THREAT_RANGE if _at_risk(state, c) else _THREAT_RANGE)
	if threat != null:
		return BotSword.back_off(state, c, threat, _BACK_OFF, BotSword.body_y(c, t))
	var prey := BotSword.snail_rider(state, c)
	if prey == null:
		prey = BotSword.winged_below(state, c, _ATTACK_RANGE)
	if prey == null:
		var gate := _gate_to_claim(state, c, -1)
		if gate != null:
			return BotFlight.toward(state, c, gate.x, gate.y - t.gate_height / 2)
		prey = BotSword.worker(state, c, true)
	if prey == null:
		var gate := _gate_to_claim(state, c, 1 - c.team)
		if gate != null:
			return BotFlight.toward(state, c, gate.x, gate.y - t.gate_height / 2)
		prey = BotSword.worker(state, c, false)
	if prey != null:
		return _attack(state, c, prey)
	return BotFlight.toward(state, c, c.spawn.x, c.spawn.y - t.winged_height / 2)


## Flies to just above `prey`, and Dives once it is right below her.
static func _attack(state: MatchState, c: CharacterState, prey: CharacterState) -> SeatInput:
	var t := state.tuning
	var below := prey.y > c.y and absi(Sim._wrapped_dx(c.x, prey.x)) < _DIVE_REACH
	var head := prey.y - (t.winged_height if prey.is_winged() else t.worker_height)
	return BotFlight.toward(state, c, prey.x, head - _OVER_PREY - t.winged_height / 2, below)


## No Eggs left, or the other Team has more Warriors than hers.
static func _at_risk(state: MatchState, c: CharacterState) -> bool:
	var warriors := [0, 0]
	for o in state.characters:
		if o.alive and o.role == CharacterState.Role.WARRIOR:
			warriors[o.team] += 1
	return state.eggs[c.team] == 0 or warriors[1 - c.team] > warriors[c.team]


## The nearest Gate owned by `team` (-1: neutral) that no enemy guards, or
## null.
static func _gate_to_claim(state: MatchState, c: CharacterState, team: int) -> GateState:
	var best: GateState = null
	for g in state.gates:
		if g.team != team or BotSword.guarded(state, c, g.x, g.y):
			continue
		if best == null or BotSword.distance_to(c, g.x, g.y) < BotSword.distance_to(c, best.x, best.y):
			best = g
	return best
