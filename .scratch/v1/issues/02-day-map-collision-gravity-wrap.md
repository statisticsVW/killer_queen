# 02: Day Map collision, gravity and wrap

**What to build:** The Day Map exists as data and is drawn on screen: collision tiles, wrap edges (including which wraps are Worker-only), Seat spawn points, and placeholder positions for Hive holes, Eggs, Gates, Berry piles and the Snail track. The Worker falls under gravity, lands on and walks along platforms, is blocked by walls, and wraps horizontally on the levels where Day allows it. Layout follows the reference images in the research doc §4.3.

**Blocked by:** 01

**Status:** ready-for-agent

- [x] Day is loaded from data; nothing Day-specific is hard-coded in the sim
- [x] Gravity and terminal fall speed are tuning-table values (placeholders until ticket 09)
- [x] Tests (on small test Maps): falling onto a platform lands; walking into a wall stops; walking off a wrap edge reappears on the opposite edge; walking into a non-wrap edge is blocked
- [x] On screen, the Worker can be walked around the whole Day Map and wraps on the bottom levels but not at the top
- [x] The layout is visibly close to the Day reference image (platform positions, the tunnel under the bottom platform, the baby ledges)

## Comments

Done. `data/maps/day.cfg` holds Day as data: 80x45 tiles of 24 px (each row starts with an edge char: `|` blocked, `~` wraps, `w` Workers-only wrap), per-Team spawn points, Hive holes, Eggs, Gates, Berry piles and the Snail start and goals. `MapData.load_file` parses it; the sim has nothing Day-specific. Platform positions come from pixel measurements of Day-Start.png (1920x1080). Every platform level sits on the 24 px grid, but the two 120 px centre platforms are 144 px here. Day wraps on rows y >= 480 (the bottom levels). Above that the side walls block.

The sim now applies gravity and terminal fall speed (`worker_gravity`, `worker_max_fall_speed`, both placeholders until 09). It then moves each axis in turn against the tiles: it lands on platforms, stops at walls and the screen top, and wraps across wrapping edges, including standing on floor across the edge. Tests: `test/sim/map_collision_test.gd` (small 120 px-tile maps via `test/sim/test_maps.gd`, plus a Day spawn check). Ticket 01's tests now use `TestMaps.flat_floor`. 19 tests pass.

Checked in the running game with injected keys: holding left from the Blue spawn walks down level by level, wraps at y 696, and reaches the floor; the floor wraps both ways; the top-level walls block at x 40 / 1880. Without a jump (ticket 03), the Worker can only go down. I checked the top levels by placing the Worker there.

Still placeholders: object positions (only drawn, no behaviour), spawn order, Snail Goal points, gravity and terminal speed. Workers-only wraps behave like normal wraps until winged units exist (ticket 08). Starting barriers aren't in the data yet (ticket 16).

Follow-up (requested by the user): Day now uses 12 px tiles (160x90). The two centre platforms are exactly their measured 900-1020 px, and every other platform end is within 6 px of Day-Start.png. Where two 12 px boundaries were equally close, the platform stays symmetric. The side walls are 12 px thick, so a Worker now stops at x 28 / 1892 px. Wrap rows still start at y 480, and no object or spawn moved. This replaces the "80x45 tiles of 24 px" and "144 px" details above.
