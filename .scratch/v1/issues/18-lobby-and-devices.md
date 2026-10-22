# 18: Lobby and devices

**What to build:** The arcade-style Lobby. Pressing the button on any pad or keyboard layout joins; the stick moves between the ten Seats (each Team's Queen Seat visibly separate from its four Worker Seats); pressing again locks the Seat in, and it can be unlocked to move again. Each Team's Bot Difficulty (Easy, Normal, Hard) is set in the Lobby. The screen shows which Seats are human and which will become Bots. Starting the Match fills every empty Seat with a Bot, so it's always 5v5. Each Seat's owner is identified by (peer, device), with the peer always local in v1.

**Blocked by:** 07, 16, 17

**Status:** ready-for-agent

- [ ] Any connected Xbox or Switch Pro controller, and either keyboard layout, can join, move, lock and unlock
- [ ] Two players can't lock the same Seat
- [ ] Bot Difficulty can be set separately for Blue and Gold
- [ ] Starting the Match puts Bots in every empty Seat; all-humans-on-one-Team works
- [ ] The Lobby model stores Seat owners as (peer, device)
- [ ] The victory screen's and pause menu's "return to Lobby" lands here with Seats kept
