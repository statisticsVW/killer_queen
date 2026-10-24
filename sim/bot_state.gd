class_name BotState
extends RefCounted
## What a Bot remembers between ticks, within its Seat's CharacterState: what
## it is going for and the route it is taking there. Ledges and Moves are
## indices in the Match's BotNav.

var difficulty: Bot.Difficulty = Bot.Difficulty.NORMAL
## What it is going for: a hole of its Team's Hive while carrying a Berry
## (`carrying`), else a Berry, by index; -1 for nothing.
var target: int = -1
var carrying: bool
## The Ledge under the target when it was chosen.
var target_ledge: int = -1
## The Ledge the route was planned from, and the route's first Move off it (-1
## when the target is on that Ledge).
var ledge: int = -1
var move: int = -1


func copy() -> BotState:
	var b := BotState.new()
	b.difficulty = difficulty
	b.target = target
	b.carrying = carrying
	b.target_ledge = target_ledge
	b.ledge = ledge
	b.move = move
	return b
