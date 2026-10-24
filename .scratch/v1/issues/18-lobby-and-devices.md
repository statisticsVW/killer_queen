# 18: Lobby and devices

**What to build:** The arcade-style Lobby. Pressing the button on any pad or keyboard layout joins; the stick moves between the ten Seats (each Team's Queen Seat visibly separate from its four Worker Seats); pressing again locks the Seat in, and it can be unlocked to move again. Each Team's Bot Difficulty (Easy, Normal, Hard) is set in the Lobby. The screen shows which Seats are human and which will become Bots. Starting the Match fills every empty Seat with a Bot, so it's always 5v5. Each Seat's owner is identified by (peer, device), with the peer always local in v1.

**Blocked by:** 07, 16, 17

**Status:** ready-for-agent

- [ ] Any connected Xbox or Switch Pro controller, and either keyboard layout, can join, move, lock and unlock
- [x] Two players can't lock the same Seat
- [x] Bot Difficulty can be set separately for Blue and Gold
- [x] Starting the Match puts Bots in every empty Seat; all-humans-on-one-Team works
- [x] The Lobby model stores Seat owners as (peer, device)
- [x] The victory screen's and pause menu's "return to Lobby" lands here with Seats kept

## Comments

Done, except one check only the user can do: joining, moving and locking with real Xbox and Switch Pro pads (as in ticket 07). Pads reach the Lobby through the same per-device SeatInput as the keyboards, so nothing in the Lobby is keyboard-specific, but no physical pad has been tried.

- Model (`game/lobby.gd`, `Lobby`): plain logic, no nodes. `update(inputs, connected)` takes one tick of every local device's SeatInput, in the game's device order (WASD, arrows, then pads by Godot id), and returns true on the tick the Match starts.
  - The row: Blue's Bot Difficulty, Blue's Queen Seat (0), Blue's Worker Seats (1-4), Gold's Worker Seats (6-9), Gold's Queen Seat (5), Gold's Bot Difficulty (`SLOT_SEATS`). Only left/right is needed, as on the cabinet. The stick moves one slot per push and stops at the ends.
  - Like Menu, a press counts when it is let go, and only if it began in the Lobby. A new Lobby, and one reopened after a Match, takes its first tick as the baseline, so a button already held does nothing.
  - A device's first press joins its player at the first Seat no other player is at.
  - After that, a press locks the player into the Seat (if nobody else has locked it), unlocks it, or, at a Bot Difficulty, cycles that Team's Difficulty Normal → Hard → Easy. The stick does nothing while locked.
  - `Lobby.Player` is (peer, device, slot, locked); `LOCAL_PEER` (0) is the only peer in v1. `owner_of(seat)` gives the player locked into a Seat. A player whose local device disconnects leaves.
  - Start: once every player is locked in, `start_ticks` counts down `START_TICKS` (150, 3 s). Any unlock, or a new player joining, stops it.
  - `match_config()` gives the Seat Teams, the Queen Seats (0 and 5) and the Bot Difficulties, with every Seat nobody locked into as a Bot Seat. `local_seats()` gives the Seat each locked-in device plays.
  - `reopen()` (back from a Match) keeps everyone at their Seat, unlocked, so the next Match waits until they lock in again rather than starting at once.
- Game (`game/main.gd`): the Lobby is the first screen. `SEAT_TEAMS`, `QUEEN_SEATS` and `DEVICE_SEATS` are gone; Seats come from the Lobby. A Match (and its rematches) plays each locked-in device's input on its Seat, leaves Bot Seats neutral, and highlights only the human Seats during the countdown. LOBBY from the pause or victory menu goes back with Seats kept. F8 in a dev build starts a Match with the Lobby's Seats as they are (all Bots if nobody has joined).
- Drawing: the row of Seats. Each Queen Seat is larger, crowned and set apart from its Team's Worker Seats. A locked Seat is filled in its Team colour with the device's name; an empty one is dark and marked BOT. Each Team's Bots panel shows its Difficulty, and players still choosing show as their device's name under their slot. Under the row: PRESS YOUR BUTTON TO JOIN, then the start rule, then STARTING IN n.
- Tests: `test/game/lobby_test.gd` (10), through `Lobby.update` and what the Lobby reports. This is a new folder: the sim suites still test only through the sim's interface. 143 in all.
  - A release joins as (local peer, device) on the first empty Seat; a held button doesn't.
  - The stick moves, the button locks, the stick does nothing while locked, and the button unlocks.
  - The row runs Blue Queen → Blue Workers → Gold Workers → Gold Queen, with each Bot Difficulty at its end.
  - Two players can't lock the same Seat.
  - Each Team's Difficulty is set separately.
  - Countdown: locking starts it, an unlock stops it, and a new player joining stops it.
  - Four humans on Blue: Blue's Queen and all of Gold are Bots.
  - Reopening keeps Seats, unlocks everyone, and ignores a held button.
  - A disconnected device's player leaves.
- Mutation checks: each of these made a matching test fail.
  - Locking an owned Seat.
  - The countdown never stopping.
  - Reopening keeping locks, or keeping the old input.
  - Gold's Difficulty slot setting Blue's.
  - Disconnected players staying.
  - The stick moving a locked player.
  - Joining on an occupied Seat.
- In the running game (injected keys): the Lobby showed first. WASD joined on Blue's Queen Seat, set Blue's Bots to HARD and locked in. The arrows joined, moved to Gold's Worker Seat 7 and locked in. "STARTING IN 3" counted down and the Match began with Seats 0 and 7 human and the other eight Bots, Blue's on Hard. In another run, Esc then LOBBY in the pause menu went back to the Lobby with both players at their Seats, unlocked.

Open questions:
- How does a player leave the Lobby once joined? Here only by unplugging the pad. A keyboard can't leave, and since every joined player must lock in before the Match starts, a keyboard joined by mistake has to take a Seat. Should Down, or a long hold of the button, leave?
- Should the Lobby be reachable with nobody locked in (an all-Bot "attract mode" Match)? F8 does that in dev builds only.
