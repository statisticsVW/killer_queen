# Spec: Killer Queen Arcade clone, v1

Status: ready-for-agent

## Problem Statement

I love Killer Queen, but the arcade game only exists on two linked cabinets in a handful of bars, and the console version (Killer Queen Black) is a different game: 4v4, an attack button, different Gates and maps. I want the arcade game at home, on my PC, with the rules, movement and pacing of the real cabinet. On a normal night there are only 2–4 of us, so the game has to be just as good when most of the ten Seats are Bots, and Bots that are dumb (especially a dumb Queen) would make every Match a walkover.

## Solution

A Windows desktop game, built in Godot 4, that recreates Killer Queen Arcade on the Day Map. Up to five humans (three gamepads plus two keyboard players on my machine, more with more pads) claim Seats in an arcade-style Lobby; every empty Seat is filled by a Bot, so every Match is a full 5v5. Each player has a joystick and one button, exactly like the cabinet. A Match ends on the first Military, Economic or Snail Win, then offers a rematch.

Movement and timing come from the arcade's published community frame data, plus a measurement pass from footage for the numbers nobody has published. The game runs a deterministic 50 Hz simulation (the arcade's own rate) rendered at 60 Hz, so Matches can be replayed exactly from their inputs, and so online play with friends can be added in v2 without a rewrite.

Art and sound are original placeholders made to the right sizes, frame counts and timings. The game is personal and is never distributed.

## User Stories

### Starting a Match

1. As a player, I want to press my pad's button to join the Lobby, so that I don't need a menu to get into a game.
2. As a keyboard player, I want two keyboard layouts (WASD + Space, arrows + Enter), so that two of us can play on one keyboard alongside the pads.
3. As a player, I want to move between the ten Seats with my stick and lock one in with my button, so that I pick my Team and role the way I would by walking up to a cabinet.
4. As a player, I want each Team's Queen Seat visibly separate from its four Worker Seats, so that it's obvious who is choosing to be Queen.
5. As a player, I want to see which Seats are held by humans and which will become Bots, so that we can arrange humans before starting.
6. As a player, I want to un-lock my Seat and move again before the Match starts, so that we can rearrange teams without restarting the game.
7. As a group, I want to put all humans on one Team against Bots, so that we can play co-op against the computer.
8. As a group, I want to split humans across both Teams with Bot fill, so that we can play against each other.
9. As a player, I want to set Bot Difficulty (Easy, Normal, Hard) separately for Blue and Gold, so that we can handicap one side.
10. As a player, I want the Match to always be 5v5, so that the Day Map plays as designed regardless of how many humans showed up.
11. As a player, I want a short countdown with the starting barriers around the Hives before play begins, so that everyone has a moment to find their character.
12. As a player, I want my character highlighted at the start of the Match, so that I can find myself among ten bees.

### Controls

13. As a player, I want exactly one button and a joystick, so that the game feels like the cabinet.
14. As a Worker or Warrior, I want only left and right on my stick to do anything, so that my input matches the cabinet's 2-way restricted stick.
15. As a Queen, I want Down on my stick to Dive, so that I have the Queen's only extra input.
16. As a player using a Switch Pro or Xbox controller, I want it to work without configuration, so that we can just plug in and play.
17. As a player, I want the Start/Menu button (Esc on keyboard) to pause and open a small menu (resume, rematch, quit to Lobby), so that someone can step away in a living room.

### Movement

18. As a Worker, I want to run at the arcade's speed (5 px per tick at 1920-wide), so that crossing the Map takes the same time as on the cabinet.
19. As a Worker, I want a tap of the button to give a short hop and a hold to give a full jump, so that jumping feels like the arcade's variable jump.
20. As a Worker, I want to change direction in mid-air at full horizontal speed, so that I can air-strafe like on the cabinet.
21. As a Worker, I want one tick of coyote time and no jump buffer, so that edge jumps are as precise and as unforgiving as the arcade's.
22. As a Queen or Warrior, I want each button press to be one Flap, with faster tapping climbing faster and no hold-to-fly, so that flight feels like the arcade.
23. As a Queen or Warrior, I want to walk on the ground at 0.84× my airborne speed, so that grounded winged units feel right.
24. As any player, I want to stick to a ceiling when I hit it slowly and ricochet down when I hit it fast, so that ceiling play (sticking, scraping, ricochets) works as on the cabinet.
25. As a Queen or Warrior, I want three rapid Flaps at terminal fall speed to stop my fall, so that the air brake works.
26. As a player, I want to springboard off another character's head, so that that movement trick exists.
27. As a player, I want to wrap from one side of the Map to the other where the Day Map allows it, so that the lower levels connect horizontally.
28. As a Speed Worker or Speed Warrior, I want 1.35× horizontal speed and rise rate, so that the Speed Gate is worth using.
29. As a Queen, I want Dive to make me fall fast and kill anything beneath me, with releasing and Flapping arresting the Dive, so that I have the Queen's attack.

### Berries and the Hive

30. As a Worker, I want to pick up a Berry by touching it, carrying one at a time, so that Berry running works.
31. As a Worker, I want to deposit a Berry into an empty hole in my Team's Hive, so that I advance toward an Economic Win.
32. As any player, I want to see each Hive's 12 holes fill up, so that I can read Economic progress at a glance.
33. As a Worker carrying a Berry, I want running into a loose Berry to kick it, so that Berries can be knocked around as on the cabinet.
34. As a Worker, I want a Berry I'm carrying to drop as a loose Berry where I die, so that Berries change hands in fights.
35. As any player, I want loose Berries to have collision, so that they behave like the physical objects they are on the cabinet.
36. As any player, I want Famine to start when the Map's last Berry is taken, with a visible 90-second countdown, after which all Berry piles refresh, so that long Matches don't stall.

### Gates and upgrades

37. As a Queen, I want to claim a Gate by touching it, turning it my Team's colour, so that my Workers can use it.
38. As a Queen, I want to steal an enemy-owned Gate by touching it, so that Gate control is contested.
39. As any player, I want neutral Gates usable by both Teams, so that the opening of a Match works as on the cabinet.
40. As a Worker with a Berry, I want to stand still at a Gate my Team can use and transform: one second holding the Berry overhead (killable and bumpable), then one second locked in (invisible and invulnerable), so that upgrading has the arcade's risk window.
41. As a Worker who has just emerged from a Gate, I want brief blinking invulnerability that ends early if I pick up a Berry, so that I'm not killed the instant I come out.
42. As a Worker without a Berry, I want standing at a Gate to do nothing, so that Gates only cost Berries when used.
43. As a Worker, I want a Speed Gate to make me a Speed Worker and a Warrior Gate to make me a Warrior, so that both upgrade paths exist.
44. As a Speed Worker, I want a Warrior Gate to make me a Speed Warrior, so that upgrades stack in the arcade's order.
45. As a Speed Worker, I want entering a Speed Gate again to do nothing and keep my Berry, so that Speed Gates can't waste Berries.
46. As a Warrior, I want to lose my upgrades on death and respawn as a Worker at my Hive, so that dying has the arcade's cost.

### Combat

47. As a Warrior or Queen, I want the higher sword to win a Joust, so that combat is decided by height as on the cabinet.
48. As a Warrior or Queen, I want contact from behind to kill, so that flanking works.
49. As a Warrior or Queen, I want a Joust nobody wins to Bump both of us apart, briefly unable to turn, so that pinch plays are possible.
50. As a Worker, I want any enemy sword contact to kill me regardless of angle, so that Workers are as fragile as on the cabinet.
51. As a Worker, I want to Bump other characters without killing them, so that I can shove enemies out of Gates and off ceilings.
52. As any player, I want a distinct sound and visual pop on every kill, so that I notice kills in a ten-player scramble.
53. As a player who just respawned, I want brief blinking invulnerability, so that I'm not spawn-killed.

### The Snail

54. As a Worker, I want to mount the Snail by walking into it when nobody is riding, so that riding needs no button.
55. As a Snail rider, I want the Snail to move toward my Team's Snail Goal at the arcade's speed (~0.446 px per tick, 1.35× for a Speed Worker), so that a Snail Win takes as long as on the cabinet.
56. As a Snail rider, I want to dismount by pressing the button, so that I can leave the Snail.
57. As a Snail rider, I want the Snail to eat an enemy Worker who walks into its front, stopping for the eat duration (half that for a Speed Worker rider), during which I can't move or dismount, so that the Snail has the arcade's eat mechanic.
58. As a Worker being eaten, I want to be released alive if the rider is killed before the eat finishes, so that teammates can rescue me.
59. As a Worker who gets eaten, I want my Berry spat out as a loose Berry, so that eating doesn't delete Berries.
60. As any player, I want an unridden Snail to stay still, so that Snail progress only moves when someone rides.
61. As a Snail rider, I want to reach my Team's Snail Goal for a Snail Win, so that the third win condition exists.

### Winning

62. As a Team, I want killing the enemy Queen when she has no Eggs left to give a Military Win, so that the first win condition works.
63. As any player, I want each Team's remaining Eggs shown at its Hive, so that I can read Queen lives at a glance.
64. As a Queen, I want to hatch from my next Egg at my Hive after dying, so that I return to the Match.
65. As a Team, I want filling all 12 Hive holes to give an Economic Win, so that the second win condition works.
66. As a player, I want a victory screen naming the winning Team and win type (Military, Economic, Snail), so that it's clear how the Match ended.
67. As a group, I want the victory screen to offer rematch with the same Seats or return to the Lobby, so that we can keep playing without re-joining.

### Bots

68. As a group of 2–4 humans, I want Bots in every empty Seat, so that every Match is a full 5v5.
69. As a player, I want a Bot Queen who claims Gates early, defends her Hive, hunts Workers on the Snail and flees when she's in danger, so that Military pressure is real even when no human plays Queen.
70. As a player, I want Bot Workers to choose between running Berries, transforming at Gates and riding the Snail based on the state of the Match, so that Bots pursue all three win conditions.
71. As a player, I want Bot Warriors to hunt enemy Workers and the enemy Queen and to use height in Jousts, so that enemy Warriors are threatening.
72. As a new player, I want Easy Bots to move at the arcade's Bot speed (0.8×) and make more mistakes, so that I can win while learning.
73. As an experienced group, I want Hard Bots at full speed with quick reactions and good objective choices, so that 2 humans vs 8 Bots is still a challenge.
74. As a player, I want Bots to act only through the same stick-and-button input a human has, so that Bots can never do anything a human can't.

### Presentation

75. As a player, I want the game drawn at 960×540 and scaled up by whole numbers, so that the pixel art stays crisp on my TV or monitor.
76. As a player, I want borderless fullscreen by default and a windowed option, so that the game fits how I'm playing.
77. As a player, I want the HUD to carry the same information in the same places as the arcade (Hive holes, Eggs, Gate colours, Snail position, Famine countdown), so that I read the Match the way arcade players do.
78. As a player, I want placeholder art that matches the arcade's silhouettes, sizes, palette direction and animation frame counts, so that the game reads correctly before the proper art pass.
79. As a player, I want sound cues at the right moments (kill, Queen death, Berry deposit, Gate claim, Gate transform, Snail eat, Famine start and end, each win), so that the Match is readable by ear.
80. As a player, I want everyone to see the whole Day Map on one screen with no Team-specific view, so that it plays like the shared image on both cabinets.

### Feel tuning and development

81. As the developer, I want every movement and timing constant in one tunable table, so that feel can be adjusted without touching rules code.
82. As the developer, I want a dev overlay showing hitboxes, velocities and the tick counter, so that I can compare movement against footage.
83. As the developer, I want frame-step (pause and advance one tick) and slow motion, so that I can inspect individual ticks.
84. As the developer, I want to change movement constants live in a dev build without restarting, so that tuning sessions are fast.
85. As the developer, I want the last Match's Replay saved automatically, so that any bug can be reproduced exactly.
86. As the developer, I want to play back a Replay, so that I can watch a bug or re-run the same inputs under changed constants.
87. As the developer, I want all dev tools stripped from the normal build, so that the game I play on game night is clean.
88. As the tester, I want a one-Worker movement sandbox on the Day Map before any other systems exist, so that the movement can be judged on its own first.

## Implementation Decisions

### Architecture (ADR-0001, ADR-0002)

- Godot 4 with GDScript. The simulation is plain GDScript with no dependency on Godot nodes, scenes or physics; Godot only renders sim state and turns devices into input.
- The sim's whole public interface is two operations: create a Match from a Map, the ten Seat assignments, per-Team Bot Difficulty and a seed; and advance a Match by one tick given that tick's input for all ten Seats. The Match state is a single copyable value.
- Fixed 50 ticks per second. Rendering runs at 60 Hz and interpolates between the two most recent sim states.
- All sim arithmetic is integer/fixed-point. Positions use the arcade's 1920×1080 monitor-pixel coordinate space (so community frame data applies unchanged) at 1/1000-pixel resolution. Multipliers (1.35, 0.8412, 0.8) are applied as integer ratios.
- All randomness, including Bot decisions, comes from a seeded generator stored in the Match state. The sim never reads wall-clock time.
- Each tick's resulting state carries the list of events that happened during that tick (kill, Queen death, Egg hatch, Berry pickup/deposit/drop/kick, Gate claimed, transform started/interrupted/completed, Snail mount/dismount, eat started/completed/interrupted, Famine started/ended, win). Presentation (SFX, kill pops, HUD flashes) reacts only to these events and to state, never to its own copy of the rules.

### Modules

- **Match simulation** (the deep module): owns Match state and the tick. Internally split into movement and collision, roles and transitions, combat, objectives (Berries, Hive, Gates, Snail, Famine) and win detection. These internal parts are not a public interface; nothing outside the sim calls them.
- **Map data**: the Day Map as data, not code: collision tiles, wrap edges (and which wraps are Worker-only), Hive holes per Team, Egg positions, Gates with type and position, Berry pile positions (66 Berries), Snail track and both Snail Goals, Seat spawn points, starting barriers. Built from the reference images in `docs/research/killer-queen-arcade-reference.md` §4.3. Adding Night/Dusk later must be new data only.
- **Tuning constants**: one table of every movement and timing constant, loaded into the sim at Match creation. In dev builds it can be edited live; the change applies from the next tick.
- **Bots**: run inside the sim tick, read only Match state, and produce the same per-Seat input a device would, using the Match's seeded randomness. One behaviour per role (Queen, Worker, Warrior), Queen built first and given the most effort. Bot Difficulty varies reaction delay, objective-choice mistake rate and threat awareness; Easy also applies the arcade's 0.8× Bot speed.
- **Input**: each Seat's input per tick is `{horizontal: left | right | neutral, down: bool, button: bool}`, where `down` is only ever read for a Queen and `button` is the held state (the sim derives presses and releases). Up is never represented. Device mapping (pads via Godot's SDL mappings, two keyboard layouts) lives in the presentation layer. Every input is tagged with the tick it applies to.
- **Replay**: Map, Seats, Bot Difficulties, seed, constants table, and the tick-tagged human input stream. Bot input is not stored; it's reproduced by the sim. Dev builds save the last Match's Replay automatically and can play one back.
- **Lobby**: ten Seats, each held by a device or empty, plus Bot Difficulty per Team. A Seat's owner is identified by (peer, device) rather than device alone, so v2 can host Seats on another machine without changing the model; in v1 the peer is always local.
- **Presentation**: renders state at 960×540 logical resolution with integer scaling, borderless fullscreen by default with a windowed toggle. Diegetic HUD as on the cabinet (Hive holes, Eggs, Gate colours, Snail position) plus the Famine countdown. Countdown, victory screen, pause menu, SFX triggered from sim events.
- **Dev tools**: overlay (hitboxes, velocities, tick counter), frame-step, slow motion, live constants editor, Replay auto-save and playback. Excluded from the normal build.

### Rule values

Taken from the research reference; where sources conflict, the community frame data (measured, partly confirmed by the designer) wins.

| Rule | Value |
|---|---|
| Max horizontal speed (Workers; airborne Queens/Warriors) | 5 px/tick |
| Winged units walking | 0.8412× |
| Speed upgrade (horizontal max, max rise rate, Snail speed) | 1.35× |
| Easy Bot speed | 0.8× |
| Coyote time / jump buffer | 1 tick / 0 |
| Ridden Snail speed | ~0.446 px/tick |
| Snail eat duration | 184 ticks (92 with a Speed Worker rider) |
| Gate transform | 50 ticks holding the Berry (interruptible) + 50 ticks locked in (invulnerable) |
| Famine countdown | 4500 ticks (90 s) |
| Hive holes / Queen Eggs | 12 / 3 |
| Gates on Day | 3 Warrior, 2 Speed |
| Berries on Day | 66 |

Unknown and to be measured from footage before feel tuning: gravity, terminal velocity, Worker jump heights (tap and hold), Flap impulse and Flap rate threshold for hovering, ceiling stick vs ricochet threshold and stick duration, Bump repel strength and no-turn window, Joust hitbox geometry, Dive speed, Worker and Queen respawn delays, invulnerability durations, countdown length. Each measured value goes into the tuning table with a note of how it was measured.

### Scope rulings from design

- Arcade rules, not Killer Queen Black. When the arcade reference and Black-based feel memory disagree, the arcade reference wins.
- Workers' and Warriors' Up/Down input is ignored; only the Queen reads Down.
- Bots exist only to fill empty Seats; Matches are always 5v5.
- A Match is a single game; no sets.

## Testing Decisions

- **One seam:** the sim's public interface (create Match, advance one tick). Every test builds a Match (often on a small test Map made for the case), feeds scripted per-tick input, and asserts on the resulting state and events. No test reaches into the sim's internal parts, and no test needs a Godot scene.
- **What makes a good test:** it states a rule from the player's point of view in glossary terms ("a Worker with a Berry at an owned Warrior Gate becomes a Warrior after 100 ticks"; "a kill in the first 50 ticks interrupts the transform and drops the Berry") and checks only observable state and events. Tests of feel values read the expected numbers from the tuning table rather than hard-coding them, so retuning doesn't break rules tests.
- **Movement tests:** run speed per tick, coyote and buffer windows, tap vs hold jump giving different apexes, Flap impulse, ceiling stick vs ricochet, wrap edges, Speed multipliers.
- **Rules tests:** every user story under Berries, Gates, Combat, Snail and Winning gets at least one scenario, including the edge cases (rescue from a Snail eat, Speed Gate re-entry keeps the Berry, Berry dropped on death, Famine refresh, Military Win only on the last Egg).
- **Bot tests:** an all-Bot Match on a fixed seed ends in a win within a time limit and always ends the same way on the same tick; Bot input never contains anything outside the Seat input shape (no Down for non-Queens); Easy Bots never exceed 0.8× speed.
- **Determinism tests (ADR-0002):** record a Match's Replay, play it back, and the final state hash matches; copying a state mid-Match and stepping both copies with the same input gives identical results. These are generated within the test run, not stored golden files, so retuning doesn't invalidate them.
- **Not automated:** rendering, device mapping, Lobby UI, HUD, audio. These are checked by playing each milestone build.
- **Framework and prior art:** gdUnit4, run headless from the command line. The repo has no code yet, so these tests set the pattern.

## Out of Scope

- Online play (v2; v1 only follows the ADR-0002 constraints that keep it possible).
- Maps other than Day: Night, Dusk, Twilight, bonus maps, tutorial maps.
- Sudden Death and other operator settings; bonus games.
- Music. The "Meet Thy Neighbor" pre-game screen.
- A player-facing Replay UI (dev playback only).
- Best-of-N sets, map rotation, scoreboards.
- Matches smaller than 5v5 or with empty Seats.
- Per-Seat Bot Difficulty; full Bot-team coordination.
- Second-monitor or Team-specific views.
- Mouse input; any extra buttons during play.
- Final art and final sound (placeholders only).
- The v20.12 "true famine" rule (no stuck-Berry spots on Day).
- Exporting or distributing builds to anyone else.

## Further Notes

- Suggested build order, so each milestone gives a playable build to judge: (1) one-Worker movement sandbox on Day with the dev overlay; (2) measurement pass and movement tuning; (3) Queen and Warrior flight and combat; (4) Berries, Hive and Gates; (5) Snail; (6) wins, countdown and victory screen; (7) Lobby and devices; (8) Bots, Queen first; (9) HUD, SFX and placeholder art pass.
- Glossary: `CONTEXT.md`. Decisions: `docs/adr/0001-*`, `docs/adr/0002-*`. Rules and sources: `docs/research/killer-queen-arcade-reference.md`, including its open questions.
- Godot isn't installed on the development machine yet; install the latest stable Godot 4.x as the first implementation step.
