# 16: Match flow

**What to build:** A Match starts with a countdown while the starting barriers hold everyone around their Hives and each human's character is highlighted. When any win happens, a victory screen names the winning Team and the win type (Military, Economic or Snail) and offers a rematch with the same Seats or a return to the Lobby (a placeholder until ticket 18). Start/Menu (Esc on keyboard) pauses and opens a small menu: resume, rematch, quit to Lobby, and a fullscreen/windowed toggle. Borderless fullscreen is the default.

**Blocked by:** 11

**Status:** ready-for-agent

- [ ] Test: during the countdown, Seat input doesn't move characters past the starting barriers; when it ends, the barriers are gone
- [ ] The victory screen shows the winning Team and win type for every win type that exists so far
- [ ] Rematch starts a new Match with the same Seats; quit returns to the Lobby (or its placeholder)
- [ ] Pause stops the sim; resume continues from the same tick
- [ ] The display toggles between borderless fullscreen and windowed, keeping integer scaling
