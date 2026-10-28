class_name BotState
extends RefCounted
## What a Bot remembers between ticks, within its Seat's CharacterState: what
## it is going for and the route it is taking there. Ledges and Moves are
## indices in the Match's BotNav.

var difficulty: Bot.Difficulty = Bot.Difficulty.NORMAL
## What a Bot Worker is going for: a Berry, a hole of its Team's Hive or a
## Gate, by index, or the Snail (0); -1 for nothing.
var objective: BotWorker.Objective = BotWorker.Objective.BERRY
var target: int = -1
## The Ledge under the target when it was chosen.
var target_ledge: int = -1
## The Ledge the route was planned from, and the route's first Move off it (-1
## when the target is on that Ledge).
var ledge: int = -1
var move: int = -1


func copy() -> BotState:
	var b := BotState.new()
	b.difficulty = difficulty
	b.objective = objective
	b.target = target
	b.target_ledge = target_ledge
	b.ledge = ledge
	b.move = move
	return b
