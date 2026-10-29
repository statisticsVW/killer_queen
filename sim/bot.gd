class_name Bot
extends RefCounted
## Bots: Seats the sim drives itself. Each tick, before anyone moves, a Bot
## reads the Match state and gives its Seat's input: the stick and button a
## device gives a human, so a Bot can do nothing a human can't. Its choices
## draw on the Match's random generator, so a Match with Bots plays out the
## same from the same seed and human input. Each role has its own behaviour:
## BotQueen, BotWorker and BotWarrior.

## A Team's Bot Difficulty. Each level has its own reaction delay (a Bot sees
## its enemies as they stood that many ticks ago), mistake rate and threat
## awareness, in the tuning table's [bot] section; Easy Bots also move at the
## arcade's Bot speed (bot_easy_speed_ratio).
enum Difficulty { EASY, NORMAL, HARD }


## Bot `c`'s input for the tick after `state`, which it may change only in
## `c.bot` and the random generator.
static func input(state: MatchState, c: CharacterState) -> SeatInput:
	match c.role:
		CharacterState.Role.QUEEN:
			return BotQueen.input(state, c)
		CharacterState.Role.WARRIOR:
			return BotWarrior.input(state, c)
	return BotWorker.input(state, c)


## Presses the button, with the stick at `stick`; if it is still held from
## before, lets go of it first, to press on the next tick.
static func press(c: CharacterState, stick: int, down := false) -> SeatInput:
	return SeatInput.of(stick, down, not c.button_held)


## Bot `c`'s value of a per-level constant: `easy`, `normal` or `hard` by its
## Difficulty.
static func by_level(c: CharacterState, easy: int, normal: int, hard: int) -> int:
	match c.bot.difficulty:
		Difficulty.EASY:
			return easy
		Difficulty.HARD:
			return hard
	return normal


## How many ticks back the Match keeps what Bots see: enough for the slowest
## level.
static func memory_ticks(t: Tuning) -> int:
	return maxi(t.bot_easy_reaction_ticks, maxi(t.bot_normal_reaction_ticks, t.bot_hard_reaction_ticks)) + 1


## The characters as Bot `c` sees them: as they stood its reaction delay
## ago, or at the Match's start if that is longer ago. Index by Seat.
static func view(state: MatchState, c: CharacterState) -> Array:
	var t := state.tuning
	var delay := by_level(c, t.bot_easy_reaction_ticks, t.bot_normal_reaction_ticks, t.bot_hard_reaction_ticks)
	return state.seen[mini(delay, state.seen.size() - 1)]
