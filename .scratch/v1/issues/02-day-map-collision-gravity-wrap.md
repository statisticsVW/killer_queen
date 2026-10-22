# 02: Day Map collision, gravity and wrap

**What to build:** The Day Map exists as data and is drawn on screen: collision tiles, wrap edges (including which wraps are Worker-only), Seat spawn points, and placeholder positions for Hive holes, Eggs, Gates, Berry piles and the Snail track. The Worker falls under gravity, lands on and walks along platforms, is blocked by walls, and wraps horizontally on the levels where Day allows it. Layout follows the reference images in the research doc §4.3.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Day is loaded from data; nothing Day-specific is hard-coded in the sim
- [ ] Gravity and terminal fall speed are tuning-table values (placeholders until ticket 09)
- [ ] Tests (on small test Maps): falling onto a platform lands; walking into a wall stops; walking off a wrap edge reappears on the opposite edge; walking into a non-wrap edge is blocked
- [ ] On screen, the Worker can be walked around the whole Day Map and wraps on the bottom levels but not at the top
- [ ] The layout is visibly close to the Day reference image (platform positions, the tunnel under the bottom platform, the baby ledges)
