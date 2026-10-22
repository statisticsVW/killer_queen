class_name MatchConfig
extends RefCounted
## Everything needed to create a Match.

var map: MapData
## Team of each Seat, indexed by Seat.
var seat_teams: Array[int]
## The Seats that play their Team's Queen, at most one per Team. Every other
## Seat starts as a Worker.
var queen_seats: Array[int]
var tuning: Tuning
