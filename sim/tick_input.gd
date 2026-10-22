class_name TickInput
extends RefCounted
## Every Seat's input for one tick, tagged with the tick it applies to.

var tick: int
## Indexed by Seat.
var seats: Array[SeatInput]
## Dev command, standing in for Warrior Gates until ticket 13: Seats whose
## Worker becomes a Warrior at the start of this tick.
var dev_warrior_seats: Array[int]


static func of(p_tick: int, p_seats: Array[SeatInput]) -> TickInput:
	var input := TickInput.new()
	input.tick = p_tick
	input.seats = p_seats
	return input
