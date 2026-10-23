# 16: Match flow

**What to build:** A Match starts with a countdown while the starting barriers hold everyone around their Hives and each human's character is highlighted. When any win happens, a victory screen names the winning Team and the win type (Military, Economic or Snail) and offers a rematch with the same Seats or a return to the Lobby (a placeholder until ticket 18). Start/Menu (Esc on keyboard) pauses and opens a small menu: resume, rematch, quit to Lobby, and a fullscreen/windowed toggle. Borderless fullscreen is the default.

**Blocked by:** 11

**Status:** ready-for-agent

- [x] Starting barriers are added to the Map data (Day has none yet; see ticket 02) and drawn while they stand
- [x] Test: during the countdown, Seat input doesn't move characters past the starting barriers; when it ends, the barriers are gone
- [x] The victory screen shows the winning Team and win type for every win type that exists so far
- [x] Rematch starts a new Match with the same Seats; quit returns to the Lobby (or its placeholder)
- [x] Pause stops the sim; resume continues from the same tick
- [x] The display toggles between borderless fullscreen and windowed, keeping integer scaling

## Comments

Done.

- Starting barriers: a `[barriers] rects=[Rect2i(...)]` section in the map file, rectangles of whole tiles in whole pixels (`MapData.barriers`). Day's four, measured off Day-Start.png, are rope floors across the four gaps in the Hives' level (x 120-336, 480-696, 1224-1440, 1584-1800 at y 216-240). Together with Day's top walls they hold everyone on the Hives' level, the Speed Gates included. Ticket 02 had promised them.
- Countdown: the first `match_countdown_ticks` ticks of a Match (`[match] countdown_ticks=150`, a 3 s placeholder; reference open question 10). `MatchState.countdown_ticks()` is the number of ticks left, worked out from the tick, so it needs no new state. While it is above zero, the next step treats barrier tiles as solid for everything that moves: characters (walls, floors, ceilings, sticking) and loose Berries. Once it reaches zero the barriers are gone. That is the only thing the countdown changes. Characters move, Bump and fight as normal inside the barriers.
- `MapData.is_solid` takes a `barriers` flag, and `Sim._move` and its helpers pass it down.
- Replay version 3: the tuning table has a new constant, so a version 2 Replay would no longer load.
- Presentation (`game/main.gd`, `game/menu.gd`):
  - While the barriers stand they are drawn as two ropes. Seconds left show over the middle of the Map, then "GO!" for a second.
  - Each Seat a connected device drives (the keyboards always, pads when plugged in) gets a white outline and an arrow under its device's name: WASD, ARROWS, PAD n.
  - Victory screen: when the Match is won, the sim stops stepping, the screen dims and names the Team and "MILITARY / ECONOMIC / SNAIL VICTORY". After 1 s a menu offers REMATCH and LOBBY.
  - Rematch saves the Replay and starts a new live Match with the same Seats and a new seed. The Lobby is a placeholder screen with START MATCH until ticket 18. The game still starts straight into a Match; ticket 18 should make the Lobby the first screen.
  - Pause: Esc, or Start/Menu on a pad, during a Match not yet won. The sim stops stepping, so no ticks pass and none are recorded. Kill pops still finish. The menu offers RESUME, REMATCH, LOBBY and WINDOWED/FULLSCREEN, and Esc/Start again also resumes.
  - Menus (`Menu`) use the cabinet's controls from any device: the stick moves along a row of options, and letting go of the button chooses. Only a press that began while the menu was open counts. That way a button mashed as the Match ends, or held through the pause, doesn't choose, and the release that resumes a Match doesn't reach the sim as a Flap.
  - Display: borderless fullscreen by default (`window/size/mode=3`). Windowed is the largest whole multiple of 960x540 that fits the screen's usable area, centred. Integer scaling (already in project settings) applies to both.
- Tests: `test/sim/match_flow_test.gd` (6).
  - During the countdown a barrier wall stops a Worker and a Queen; they pass it on exactly the first tick after.
  - A Worker stands on a barrier over a gap and falls once it ends.
  - A Queen can't fly up through a barrier, and sticks under one as under a ceiling.
  - A loose Berry rests on a barrier until the countdown ends.
  - On Day, with alternate Seats running each way and pressing, nobody's feet go below the Hives' level until it ends, and then someone falls.
- Mutation checks: each of these made a matching test fail.
  - Barriers decided from the next tick.
  - Barriers never ending.
  - Characters' moves, walls only, floors and ceilings only, the ceiling-stick check and Berries' moves each ignoring the barriers.
  - Berries always blocked.
  - Barrier tiles always solid.
  - A barrier one row short or one column narrow.
  - The countdown one tick short.
  - Each of Day's four barriers removed.
- In the running game: started fullscreen. With both keyboard Queens held right through the countdown, nobody went below y 216 px. Esc paused at tick 200, the tick stayed there for 45 frames, and resuming continued from 200. The toggle went to a 1920x1080 window and back to fullscreen. Each win type's victory screen showed, and the button tapped before the menu appeared did nothing. REMATCH started a new Match at tick 0 with the same Seats. LOBBY showed the placeholder, and START MATCH began a new Match.

Open questions:
- Can players kill each other during the countdown? Right now they can: a Queen can cross the Hives' level and kill enemy Workers before play begins. The arcade's start sequence is undocumented (reference open question 10).
- How long is the countdown, and does the arcade show one (3-2-1, "GO")? Ticket 09.
- What does the arcade's victory screen show? The reference only has the "Military/Economic/Snail Victory" wording.
