# 23: Placeholder art and HUD pass

**What to build:** Original placeholder art that reads like the arcade: Worker, Warrior, Speed variants and Queen sprites in each Team's colours with arcade-like silhouettes, sizes and animation frame counts; Berries, Hive holes, Eggs, Gates (Warrior and Speed looks, neutral/Blue/Gold), the Snail and the Day background in the arcade's palette direction. The HUD carries the arcade's information in the arcade's places: Hive holes, Eggs, Gate colours, Snail position, plus the Famine countdown. Blinking for invulnerability. Nothing is copied from the original game's assets.

**Blocked by:** 13, 14, 15

**Status:** ready-for-agent

- [x] Every character state (Worker, Speed Worker, Warrior, Speed Warrior, Queen; running, jumping, Flapping, Diving, carrying, riding, eating) has a distinct readable sprite
- [x] Sprite sizes match the sim's colliders at 960×540
- [x] Each human's character can be found within a second at Match start (highlight) and during play (Team colour plus Seat marking)
- [x] The HUD shows Hive holes, Eggs, Gate ownership, Snail position and the Famine countdown with no Team-specific view
- [x] All art is original to this project

## Comments

Done. Rendering isn't automated (spec), so which sprite a character shows and what each sprite looks like are tested models, and the rest was checked on frames saved from the running game.

- `game/pose.gd` (`Pose.of(state, seat)`): how a character is drawn this tick, from the state alone.
  - Look: Worker, Speed Worker, Warrior, Speed Warrior or Queen.
  - Action, first that applies: HOLD_UP (at a Gate with its Berry); RIDE, or EAT while the Snail eats; EATEN (the Snail's victim); then on the ground STAND or RUN; in the air a winged character DIVEs (a diving Queen), FLAPs (rising) or GLIDEs, and a Worker JUMPs (rising) or FALLs.
  - Carrying: has a Berry.
  - Frames (placeholders; the arcade's counts aren't documented): RUN 4, one per 4 px run, so the legs keep pace with the ground at any speed, facing either way; FLAP 2, 3 ticks each; EAT 2, 8 ticks each.
- `game/sprites.gd` (`Sprites`): original pixel art, written as text in the file, one character per art pixel.
  - Humanoid bees: a Team-coloured striped body, light face and big eye, black limbs.
  - Each sprite is its collider: Workers 16x20, Queens and Warriors 20x24 (the art pixels of the 960x540 canvas). The feet stand on the bottom row; sprites are drawn facing right and mirrored.
  - Parts are layered by Pose: legs (stand, 4 run frames, jump tuck, fall, tiptoe holding up, sitting to ride), arms (down, up to carry or hold up or flail, forward), wings (folded, up and down beats, spread to glide, tucked to dive), head (a squeezed eye while eaten).
  - Queens have a crown and a stinger; Warriors a helmet and a sword held out front; Speed characters white stripes instead of black.
  - Seat marking: each Worker Seat in a Team has its own hat, in its own colour: red antennae (1), green cap (2), white beanie (3), cyan headband (4). A Warrior keeps its Seat's hat over its helmet. With Team colour, that's how a player finds themself during play; the countdown highlight from ticket 16 still marks humans at the start.
  - The Snail is drawn in code: a pink body and head with eye stalks under a red spiral shell, its collider's 48x26, its mouth gaping while it eats. It faces its rider's heading, or the middle of the Map unridden.
  - Textures are built once per look, pose, Team colour and Seat, as first needed.
- `main.gd`, HUD and scenery (all the cabinet's diegetic HUD, one view for both Teams):
  - Hives: a honeycomb panel in the Team's colour with hexagonal holes; deposited Berries show in their holes.
  - Eggs: outlined egg shapes with a shine; a dead Queen due to hatch still shows as hers.
  - Gates: arched doorways in neutral grey, Blue or Gold, doors shut while a Worker is locked in; a pair of wings over Warrior Gates, a lightning bolt over Speed Gates.
  - Snail: its track along the floor between the two Teams' goal flags, ticked every tenth of the way, with a taller tick at its start, so its position reads at a glance.
  - Famine countdown as before (ticket 14).
  - Day: the sky darkens toward the top, with clouds and a line of far green hills; dirt tiles get fixed specks, grass a fringe. Berries are outlined with a shine.
  - Invulnerable characters still blink (ticket 10).
- Nothing in `sim/` changed. All art is original to this project: text pixel art and code-drawn shapes, no assets.
- Tests: `test/game/pose_test.gd` (7) and `test/game/sprites_test.gd` (4). 198 in all.
  - Each role and upgrade has its own look. A Worker stands, runs, jumps and falls (vy 0 is falling); a winged character stands, walks, flaps, glides (vy 0 too) and a Queen dives, even while rising.
  - Running frames advance once per stride and hold within it, the same way round facing left; standing shows frame 0. Flapping and eating alternate every few ticks.
  - A Berry makes a Worker carry; at a Gate it holds up. The rider rides, then eats; its victim is eaten.
  - Every sprite of every pose is its collider's size, and standing ones touch the bottom row.
  - Within each look, every pose (and every frame, carrying or not) has its own picture; the five looks differ; the four Worker Seats' markings differ for Workers and Warriors, in colour as well as shape; Blue differs from Gold.
  - Gliding is wider than standing (spread wings) with the legs trailing; diving is narrower than gliding with the legs reaching the bottom row.
- Mutation checks: each of these made a test fail. In `Pose`: no Speed looks; Queens as Warriors; no hold-up, eat or eaten; air as ground; only rightward running; facing ignored in run frames; wrong cycle length; no flap or chomp alternation; chomps at the flap rate; vy 0 rising for winged or Worker. In `Sprites`: Warriors drawn as Workers; no Speed stripes; one marking colour; run or walk stuck on one frame; jump, hold-up or sit legs as others; no forward arms or hurt head; one wing beat; folded glide wings; dive legs or wings as gliding; Warriors drawn as Queens.
- In the running game (scratch script): WASD locked into Blue's first Worker Seat, Bots in the rest, Military win at tick 3813. Frames saved during the countdown (the WASD highlight on the antennae Worker), at a Gate claim, a transform, a Snail mount (a Blue rider carrying a Berry, the Snail heading for Blue's flag), and ticks 1200 and 2400.
  - Read at 2x-4x zoom, each Seat's hat, the Queens' crowns and the Warriors' swords and wings tell everyone apart; Gate colours, filled Hive holes, Eggs and the Snail on its ticked track read at a glance.
  - The Snail eating wasn't caught on a frame in that Match; its sprite and the rider's EAT pose are tested.
- Not judged here: whether it reads like the arcade to someone who knows it. That's the user's milestone playtest.
