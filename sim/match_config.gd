class_name MatchConfig
extends RefCounted
## Everything needed to create a Match.

var map: MapData
## Team of each Seat, indexed by Seat.
var seat_teams: Array[int]
## The Seats that play their Team's Queen, at most one per Team. Every other
## Seat starts as a Worker, unless it is in warrior_seats.
var queen_seats: Array[int]
## Seats that start the Match as Warriors, and Seats that start it with the
## Speed upgrade (Queen Seats ignore both). The arcade starts everyone as a
## plain Worker; these set up tests and dev builds.
var warrior_seats: Array[int]
var speed_seats: Array[int]
var tuning: Tuning
## Seeds the Match's random generator, the only source of randomness in the
## sim (ADR-0002).
var seed: int
