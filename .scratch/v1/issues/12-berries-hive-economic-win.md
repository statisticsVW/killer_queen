# 12: Berries and the Hive; Economic Win

**What to build:** Day's Berry piles (66 Berries) appear at Match start. A Worker picks up a Berry by touching it and carries one at a time; depositing it in an empty hole of their Team's Hive fills that hole. A carried Berry drops as a loose Berry where the Worker dies. Loose Berries have collision and are kicked when a Berry-carrying Worker runs into them. Filling all 12 holes is an Economic Win.

**Blocked by:** 10

**Status:** ready-for-agent

- [x] Test: touching a Berry picks it up; a Worker already carrying one doesn't pick up another
- [x] Test: depositing fills a hole in the Worker's own Hive only
- [x] Test: a Worker killed while carrying drops a loose Berry at their position
- [x] Test: running into a loose Berry while carrying one kicks it; loose Berries collide with characters and terrain
- [x] Test: the 12th deposit emits an Economic Win and ends the Match
- [x] Winged characters can't pick up Berries
- [x] Hive holes are drawn and visibly fill

## Comments

Done.

- Berries: `MatchState.berries` holds every Berry (`BerryState`), in a fixed order: each Map pile in turn, six per pile, built by `create_match` as a triangle (rows of 3, 2 and 1 from the bottom up, `berry_size` apart). Day has 66. A Berry is `PILE` (sits still), `LOOSE` (falls, slides, can be kicked), `CARRIED` (rides on its Worker's head) or `HIVE` (fills `team`'s hole `hole` for good). A Worker's carried Berry is `CharacterState.berry`, an index into `berries`, or -1.
- Tick order: after characters move and collide, loose Berries move (gravity, terrain, then friction on the ground). Then each living Worker, in Seat order: an empty-handed one picks up the first pile or loose Berry it touches; a carrying one deposits in the first empty hole of its own Hive whose centre is inside its collider, or else kicks any loose Berry it touches. Carried Berries then move to their Workers' heads. Nothing happens to Berries once the Match is won.
- Picking up a Berry ends invulnerability, as ticket 10 promised (reference: a Berry grab ends spawn invulnerability).
- Kick: the loose Berry flies away from the Worker (the Worker's facing, if level) at `berry_kick_speed` and up at `berry_kick_lift`, unless it is already moving away that fast. The arcade's speed- and angle-dependent kick is simplified to this.
- Drops: a carrying Worker that dies, or that the dev command makes a Warrior, drops its Berry loose at its feet.
- Not modelled, open for later:
  - Loose Berries don't block characters. Characters pass through them; only Workers interact (pick up or kick), and Queens and Warriors ignore them. The reference's Berries wedging between Jousting Warriors would need them to.
  - A loose Berry crossing an empty hole doesn't "kick in" (auto-deposit).
  - Depositing is instant. The arcade Worker climbs into the hole and crawls out, blocking it meanwhile, and the win comes as the last one emerges.
- Economic Win: the deposit that fills a Team's last hole sets `win = Win.ECONOMIC` and `winner`, emits `WIN`, and freezes the Match as the Military Win does.
- Events: `BERRY_PICKUP`, `BERRY_DEPOSIT`, `BERRY_DROP`, `BERRY_KICK`; `seat` is the Worker, `other` the Berry's index.
- Tuning: `[berry]` size 14 px, gravity, max fall speed, friction, kick speed and lift, all placeholders.
- Code: `Sim._move` now moves any body (character or Berry) given its collider size. `_boxes_overlap` is the shared overlap test. `TestMaps.config` gives tests a map file to add objects to.
- Presentation: Berries are drawn from state (piles, loose, carried, in holes), no longer from the Map's pile positions, and Hives visibly fill.
- Tests: `test/sim/berry_test.gd` (9 tests). Mutation checks: carrying Workers picking up more, winged characters picking up, depositing in Blue's Hive whatever the Team (needed the deposit test run for Gold too), filling a full hole (needed the 12-different-holes check), the Economic Win count and flag, the drop on death and its position, the kick, friction off the ground, invulnerability on pickup, and the dev command's drop. Each made a matching test fail.
- In the running game: a Blue Worker was moved between piles and the Blue Hive's holes in turn. Its 12 deposits filled the Hive and the 12th drew "BLUE ECONOMIC WIN".
