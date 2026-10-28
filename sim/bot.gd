class_name Bot
extends RefCounted
## Bots: Seats the sim drives itself. Each tick, before anyone moves, a Bot
## reads the Match state and gives its Seat's input: the stick and button a
## device gives a human, so a Bot can do nothing a human can't. Its choices
## draw on the Match's random generator, so a Match with Bots plays out the
## same from the same seed and human input. Each role has its own behaviour:
## BotQueen, BotWorker and BotWarrior.

## A Team's Bot Difficulty. Easy Bots move at the arcade's Bot speed
## (bot_easy_speed_ratio); otherwise the levels play alike, for now.
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
