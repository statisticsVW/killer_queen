class_name TickInput
extends RefCounted
## Every Seat's input for one tick, tagged with the tick it applies to.

var tick: int
## Indexed by Seat.
var seats: Array[SeatInput]


static func of(p_tick: int, p_seats: Array[SeatInput]) -> TickInput:
	var input := TickInput.new()
	input.tick = p_tick
	input.seats = p_seats
	return input
