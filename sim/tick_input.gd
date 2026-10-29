class_name TickInput
extends RefCounted
## Every Seat's input for one tick, tagged with the tick it applies to.

var tick: int
## Indexed by Seat.
var seats: Array[SeatInput]
## A new tuning table for the Match from this tick on, or null to keep its
## own. Dev builds' live editor changes the tuning this way, so a Replay
## records the change with the rest of the input.
var tuning: Tuning


static func of(p_tick: int, p_seats: Array[SeatInput]) -> TickInput:
	var input := TickInput.new()
	input.tick = p_tick
	input.seats = p_seats
	return input
