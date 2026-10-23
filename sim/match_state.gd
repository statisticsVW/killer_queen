class_name MatchState
extends RefCounted
## Everything about a Match at one tick. Sim.step() never modifies a state it is
## given; it returns a new one. The Map and Tuning are immutable and shared
## between copies.

## How the Match was won, if it has been.
enum Win { NONE, MILITARY, ECONOMIC, SNAIL }

var tick: int
var characters: Array[CharacterState]
var map: MapData
var tuning: Tuning
## What happened during the tick that produced this state, in order.
var events: Array[MatchEvent]
## Eggs still waiting at each Team's Hive, indexed by Team. They sit at the
## first that many of the Map's Egg positions.
var eggs: Array[int]
var win: Win = Win.NONE
## The Team that won, or -1.
var winner: int = -1
## The random generator's state (see Rng).
var rng: int
## Every Berry on the Map, in a fixed order: the piles' in Map order, six each,
## then any added when Famine refilled the piles.
var berries: Array[BerryState]
## The Snail, or null on a Map without one.
var snail: SnailState
## Ticks left of Famine, counting this one; 0 when there is none.
var famine_ticks: int
## Every Gate on the Map: its Warrior Gates, then its Speed Gates, each in Map
## order.
var gates: Array[GateState]


## Ticks left in the countdown that starts the Match, during which the Map's
## starting barriers stand: the input for this state's tick is still held by
## them while this is above zero.
func countdown_ticks() -> int:
	return maxi(tuning.match_countdown_ticks - tick, 0)


func copy() -> MatchState:
	var s := MatchState.new()
	s.tick = tick
	for c in characters:
		s.characters.append(c.copy())
	s.events = events.duplicate()
	s.eggs = eggs.duplicate()
	s.win = win
	s.winner = winner
	s.rng = rng
	s.snail = snail.copy() if snail != null else null
	s.famine_ticks = famine_ticks
	for b in berries:
		s.berries.append(b.copy())
	for g in gates:
		s.gates.append(g.copy())
	s.map = map
	s.tuning = tuning
	return s


## A digest of every value in the state, characters and events included, but
## not the shared Map and Tuning. States that differ anywhere have different
## fingerprints, so comparing them tests determinism. It reads the properties
## themselves, so a new field is covered without changing this.
func fingerprint() -> String:
	return var_to_str(_values(self)).sha256_text()


static func _values(value: Variant) -> Variant:
	if value is Array:
		return value.map(_values)
	if not value is Object:
		return value
	var result := []
	for prop in value.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and not prop.name in ["map", "tuning"]:
			result.append([prop.name, _values(value.get(prop.name))])
	return result
