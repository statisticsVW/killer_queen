# 17: Bot framework and Berry-running Bot Workers

**What to build:** Any Seat can be a Bot. Bots run inside the sim tick, read only Match state, use the Match's seeded randomness, and produce the same Seat input a device does. This ticket's Bot Workers run Berries: find the nearest reachable Berry, carry it to their Hive, deposit it. Easy Bots move at 0.8× speed; Normal and Hard (whose behaviour is otherwise identical for now) move at full speed.

**Blocked by:** 12

**Status:** ready-for-agent

- [ ] Bot Seats are set when the Match is created; a Bot produces input only through the Seat input shape
- [ ] Test: Bot input never sets Down for a non-Queen and never contains anything outside the Seat input shape
- [ ] Test: Easy Bots never exceed 0.8× max horizontal speed
- [ ] Test: a Match with only Bot Workers on one Team reaches an Economic Win within a time limit
- [ ] Test: the same seed and Seats produce the same Match, tick for tick (the Replay determinism test extended to Bots)
- [ ] On screen, Bot Workers visibly run Berries
