# 17: Bot framework and Berry-running Bot Workers

**What to build:** Any Seat can be a Bot. Bots run inside the sim tick, read only Match state, use the Match's seeded randomness, and produce the same Seat input a device does. This ticket's Bot Workers run Berries: find the nearest reachable Berry, carry it to their Hive, deposit it. Easy Bots move at 0.8× speed; Normal and Hard (whose behaviour is otherwise identical for now) move at full speed.

**Blocked by:** 12

**Status:** ready-for-agent

- [x] Bot Seats are set when the Match is created; a Bot produces input only through the Seat input shape
- [x] Test: Bot input never sets Down for a non-Queen and never contains anything outside the Seat input shape
- [x] Test: Easy Bots never exceed 0.8× max horizontal speed
- [x] Test: a Match with only Bot Workers on one Team reaches an Economic Win within a time limit
- [x] Test: the same seed and Seats produce the same Match, tick for tick (the Replay determinism test extended to Bots)
- [x] On screen, Bot Workers visibly run Berries

## Comments

Done.

- Bot Seats: `MatchConfig.bot_seats`, and `bot_difficulties` per Team (`Bot.Difficulty` EASY, NORMAL, HARD; NORMAL unless set). `create_match` gives each Bot Seat's character a `CharacterState.bot` (`BotState`: its Difficulty and what it remembers between ticks: target, the Ledge its route was planned from, the route's first Move). It is copied and fingerprinted with the rest of the state.
- Tick: at the start of `Sim.step`, after the copy and before anyone moves, each Bot Seat's input is `Bot.input(next, c)`. It reads the state as it stood, and changes only its own `BotState` and `MatchState.rng`. That input replaces whatever the `TickInput` holds for the Seat, so a Bot Seat's `TickInput` entry is ignored.
- `MatchState.inputs`: the `SeatInput` each Seat actually played in the tick that produced the state, a Bot's own for a Bot Seat. Tests check Bot input through it, and the dev overlay (ticket 04) could show it.
- The movement step of `Sim.step` is now `Sim._advance(c, input, pressed, map, tuning, barriers)`, unchanged, so BotNav can run a lone Worker through the real movement.
- Easy: `Sim._max_speed` slows an Easy Bot's max horizontal speed (running, flying, walking; with Speed it's 0.8 × 1.35) by `[bot] easy_speed_ratio=8000` (reference section 3). Easy can't be done through the stick: it's digital, and acceleration is instant. Rise speed, jumps and the Snail aren't slowed.
- BotNav (`sim/bot_nav.gd`): Bot Workers' map of Day.
  - A Ledge is a run of solid tiles with room above for a Worker.
  - A Move goes from a point on one Ledge to another, found by running `Sim._advance` from it until the Worker lands. There are two kinds: walking off an end with the stick held, and a held jump with the stick left or right, tried every 24 px along each Ledge. Straight-up jumps never landed anywhere new on Day, so they're not tried. Day has 35 Ledges and 447 Moves.
  - `route()` is a Dijkstra over Ledges in ticks: walk to a Move's launch point, then its airtime.
  - It is derived from the Map and Tuning, not state: `MatchState.navs` shares it between copies like `map` and `tuning`, the fingerprint skips it, and `BotNav.of` memoises it by Map and Tuning content (16 kept). One build takes ~0.6 s per Worker speed (plain, Speed, Easy, Easy Speed), once per game session.
- Bot Workers (`sim/bot.gd`):
  - Empty-handed, a Bot Worker goes for the pile or loose Berry it can reach soonest. Carrying, it goes for the nearest empty hole of its own Hive. Each choice's travel time gets `Rng.below(state, choice_jitter_ticks + 1)` added (`[bot] choice_jitter_ticks=50`, placeholder), so teammates spread over Berries about as near as each other.
  - Choices draw from the RNG only when a Bot chooses a new target, so Matches with Bots replay from the seed.
  - A target is kept while it's still there. The Bot re-routes after landing on a new Ledge, and an idle Bot with nothing to go for looks again every 10 ticks.
  - On a Ledge it walks to the route's next Move and takes it, or, under a hole, presses to jump into it. In the air it holds the Move's stick and button. A press always comes after a tick with the button up.
  - Off any Ledge (on a starting barrier, a head) it heads straight for the target.
  - It gets off the Snail by pressing.
  - Dead, transforming, eaten or winged Bots stand idle. Queen and Warrior Bots are tickets 19 and 20.
- Gates: a Worker carrying a Berry who stops at a Gate it can use starts transforming, and turning round passes through `vx` 0 for one tick. Before this rule, Bots turning round on the middle Warrior Gate transformed by accident (1–4 per Match). Now a Bot carrying a Berry and touching a Gate it could use doesn't stop or turn round; it keeps going and turns once clear. Ticket 20 decides when Bots transform on purpose.
- Replay version 6: it records `bot_seats` and `bot_difficulties`, keeps human Seats' input only (`input()` gives neutral for Bot Seats), and stores its length, so an all-Bot Replay works.
- Game (`game/main.gd`): until ticket 18's Lobby, each Seat whose device isn't connected when a Match starts is a Normal Bot. With no pads, that's Seats 1–4 and 6–9; the keyboards play the Queens.
- Tests: `test/sim/bot_test.gd` (6), plus 3 in `determinism_test.gd`. 133 in all; the suite now takes about 80 s.
  - A Bot Seat plays its own input whatever the tick input holds for it, and every Bot moves.
  - Over 1000 ticks of an all-Bot Match on Day (Queens included, Easy against Hard), every Bot input is a SeatInput with a left/neutral/right stick, bools, and Down never set for a non-Queen.
  - Easy Blue against Normal Gold, Seats 1 and 6 with Speed. Over ticks without a Bump (a Bump hands a character its enemy's speed), each Seat's top speed is exactly 0.8×, 0.8 × 1.35, 1× or 1.35×.
  - Five Bot Workers alone on Blue, and again on Gold, reach an Economic Win within 2000 ticks with no transforms. They take about 1100.
  - A Bot Worker spawned on the Snail mounts it, gets off within 2 ticks, and fills its Hive.
  - A Bot Worker that lands on a pile under its Hive's hole with the button still held lets go and jumps again.
  - Determinism: two all-Bot Matches step identically, compared every 4 ticks with a copy check in between, and the Bots moved the RNG. A Replay with human Queens and Bot Workers is the same text whatever the Bot Seats' input was, and plays back to the same fingerprint. An all-Bot Replay keeps its length.
- Mutation checks: each of these made a matching test fail.
  - Bot input setting Down; a stick of ±2.
  - No Gate rule.
  - No choice jitter.
  - Gold's Bots going for Blue's Hive.
  - Staying on the Snail.
  - Pressing without letting go.
  - Never re-routing after landing.
  - Releasing the button during a jump into a hole.
  - Bot input computed but not played; the tick input played instead.
  - Easy not slowed; every Bot given Blue's Difficulty.
  - The Replay recording Bot Seats' input, dropping the Difficulties, or not counting its length.
  - Dropping `bot`, `BotState.move` or `inputs` from `copy()`.
  - No walk-off Moves; a route's first Move taken from the wrong Ledge; a Move "landing" on its own Ledge.
- Survivors:
  - The idle Bot's look-every-10-ticks throttle. It only saves time: without it, idle Bots would route every tick.
  - Re-choosing when a target loose Berry moves to another Ledge. That only happens when a resting loose Berry is kicked off its Ledge, which nothing here produces. Ticket 20's Warriors make loose Berries; test it there.
  - Removed as untested and not needed:
    - Bots skipping Berries a teammate Bot was going for.
    - Drop-past-the-end Moves (walk-offs do the same job).
    - Straight-up jump Moves (none exist on Day).
    - A Gate-in-use detail in the Gate rule.
- In the running game (no pads, so 8 Bots): from the countdown's end the Bot Workers took Berries from piles on both sides, climbed back with them and jumped them into their Hives. By tick 700, Blue had 4 holes filled and Gold 5, with no transforms or Snail rides.

Open questions:
- Should Easy Bots also rise, jump or ride the Snail slower? The reference only says "0.8x player horizontal speed".
- Bots read Match state directly (positions of every Berry and hole, the Map's shape). That is everything a player sees on screen, but a human doesn't plan routes this precisely; ticket 21's reaction delay and mistakes are where that evens out.
