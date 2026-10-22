# Killer Queen (Arcade) — Rules & Feel Reference

Scope: the 10-player (5v5) two-cabinet arcade game by BumbleBear Games (Joshua DeBonis & Nikita Mikros, debuted 2013). **Not** Killer Queen Black (2019, Liquid Bit). Section 7 lists Black-only rules so they are not imported by accident.

Conventions used below:
- `[S#]` = source number in the Sources list. Every fact carries at least one.
- **(uncertain)** = single weak source, inferred, or community observation not confirmed by BumbleBear.
- **(conflict)** = sources disagree; both values given.
- "Drone" and "Worker" are synonyms (official site says Worker; community says Drone). "Gate" and "Maiden" are synonyms. "Form/forming" = becoming a warrior. "Tag" = queen touching a gate.
- Pixel values are in **monitor pixels of a 1920x1080 output** and "frame" = 1/50 s (physics tick), per the community Frame Data page [S14]. The art itself is drawn at half that resolution (one art pixel = 2x2 monitor pixels), so logical art resolution is 960x540 (see §5).

---

## 1. Win conditions

Any one of the three immediately ends the match (Economic has a small nuance, below). [S1][S2][S9]

### 1.1 Military victory
- Kill the enemy Queen **three times**. [S1][S2][S5]
- Each team has **3 eggs**; one hatches into the Queen at match start; each Queen death hatches the next egg; when no eggs remain, the next kill wins. [S1][S8][S20]
- The eggs physically sit at/around the team's hive and are the on-screen indicator of remaining Queen lives. [S8][S20]
- Only Queens and Warriors can kill a Queen. [S1][S8]
- Queen respawn: she hatches from the next egg at the hive; respawn is described as "shortly after" dying. **Exact delay unknown.** [S2][S20]
- Egg/lives progress is permanent (cannot be regained). [S22]

### 1.2 Economic victory
- Fill every hole in your hive with berries; the hive has **12 holes** on all four main maps. [S9][S8][S21][S23] **(conflict)**: Wikipedia says the required count "varies per arena" [S2]; every community/official-adjacent source says 12 on all current maps. Treat 12 as correct for Day/Night/Dusk/Twilight; bonus maps may differ.
- Only Workers carry berries, **one at a time**; a berry is picked up automatically by running into it. [S1][S8][S10]
- Depositing: the Worker touches an empty hole while carrying a berry, climbs in, deposits, and crawls back out of a different opening; the hole stays "occupied" while a drone is crawling out, which can block teammates. [S20][S15]
- Deposited berries can never be removed or stolen. [S8][S21]
- Victory is awarded as the final depositing drone begins to emerge from the hive, not instantly on entry (older builds had a glitch awarding it earlier). [S21]
- A loose (dropped/kicked) berry that crosses an empty hole in a hive auto-deposits ("kick-in"). [S10]
- Hole accessibility is map-specific: some holes can be filled by jumping from below ("bottom berries"), others only from above ("top berries"); e.g. Dusk's lowest three rows are bottom berries, Twilight's lowest two. [S15]

### 1.3 Snail victory
- A Worker rides the giant snail along its track into the team's **net/basket** (team-colored, soccer-net style, on the same side as that team's hive). [S1][S9][S24][S11]
- Only Workers may ride; Warriors and Queens cannot. [S1][S9]
- Mount by walking up to (walking in front of) a snail that has no rider; the rider can only move the snail toward their **own** goal. [S9][S8]
- Press jump to hop off at any time (except while the snail is eating). [S9][S8]
- Rider can jump only straight up off the snail, with less lateral control than a ground jump and a higher minimum jump height. **(uncertain, community observation)** [S25]
- A Worker may ride while carrying a berry; holding a berry does not change snail or drone speed. [S9][S23]
- Snail progress is zero-sum: one team's progress is the other's loss; killing the rider lets the enemy mount and reverse it. [S22][S8]
- **Snail speed (ridden, vanilla rider): ~0.446 px/frame ≈ 22 px/s at 1080p; mid-track to goal ≈ 43 s on Day/Dusk ("maximum-distance" snail maps).** [S14][S11] Night's snail distance is "significantly shorter". [S19]
- Snail with no rider does not move. [S24]
- Speed-buffed rider: snail moves **35% faster** (speed multiplier 1.35 applies to snail speed). [S14][S9] **(conflict)** one wiki page says 33%. [S12]
- **Eating:** if an enemy Worker walks into the front of a ridden snail, the snail stops and starts eating that Worker ("sacrifice"/"sack"/"snack"). While eating, the rider cannot move the snail or dismount. [S9][S8]
- Eat duration: **~3.67 s (184 physics frames)** measured [S14]; the community glossary says 3 s [S11] **(conflict)**. With a speed rider the eat takes **half** as long. [S14][S11]
- If the eat completes, the eaten Worker dies (respawns at hive); a berry they held is spat out as a loose berry. [S9][S8]
- If the rider is killed before the eat completes, the eaten Worker is released alive. [S9][S8][S11]
- Military units lose their spawn invulnerability if they touch a ridden snail. **(uncertain)** [S11]
- Snail is indestructible, so the snail strategy is always available (unlike Economic during famine). [S22]
- Snail track on Night/Twilight includes a "rope" segment that other characters can pass through. [S11]

### 1.4 Berry supply / Famine
- Berries start in static piles (triangular piles of six on current maps) placed symmetrically; Day has 66 berries total. [S11][S23][S13]
- Piles do not replenish normally. When the last berry on the map is consumed (deposited or spent in a gate), a **90-second** famine countdown appears; at zero, all piles refresh. [S10][S23][S11]
- v20.12+: if no berry has been picked up for some time while a stuck/inaccessible berry remains ("true famine"), the famine timer starts anyway. [S10]
- Re-entering a Speed gate while already sped does nothing and the berry is kept, so speed gates cannot cause famine. [S27]

### 1.5 Operator match settings (affect rules)
- **Sudden Death:** operator option Never / 3 / 4 / 5 / 10 minutes, "forces an early end to overtime games". **What sudden death actually does in-game is not documented in sources found.** [S3]
- **Bonus Game:** a short free game on a special map that cannot be selected directly; frequency Frequent (every 2–5 games) / Default (4–7) / Rare (7–10); can be disabled. Two bonus maps exist; some have no snail or multiple snails. [S3][S18][S9]
- Freeplay mode exists, including a variant with bonus game and sudden death disabled for leagues. [S3]

---

## 2. Roles and transitions

### 2.1 Roles at start
- Each team: 1 Queen (center cabinet position) + 4 Workers. [S1]
- Everyone spawns at the hive, which is highlighted at the start of every match. [S20]
- Each map starts with "starting barriers" (walls around the spawn/hive) that are present at game start and gone once play begins. Exact timing/sequence undocumented. **(uncertain)** [S13]
- When fewer than 10 humans play, AI bots control the remaining units (added with the 2016 Raw Thrills build); bots move at 0.8x player horizontal speed. [S2][S14]

### 2.2 Worker (Drone)
- Only unit that can carry berries, ride the snail, or use gates. Cannot kill. [S1][S9]
- Infinite lives; respawns at the hive. **Respawn delay not documented.** [S1]
- Dies on contact with an enemy Queen's or Warrior's sword (any angle; see §2.5). [S8]
- A carried berry drops where the Worker dies and becomes a loose, collidable, kickable object. [S8][S23][S10]
- Can "bump/boop" opponents (non-lethal shove): push drones out of gates, shove Warriors/Queens off ceilings, etc. [S15][S11][S26]
- Can change direction mid-air ("air strafe"). [S29][S26]
- Spawn invulnerability (blinking i-frames) ends early if the Worker grabs a berry, mounts the snail, or feeds the snail. [S11][S12]
- Four Worker skins per team (community names: Stripes, Abs, Ribs/Pants, Skull, Checkers). [S29]

### 2.3 Gates (Maidens)
- Every main map has **5 gates: 3 Warrior gates (wings icon) and 2 Speed gates (lightning-bolt icon)**. [S12][S8][S19]
- All gates start **neutral** (white/gray) and usable by both teams. [S12][S16] **(conflict on color word: "white" [S12][S8] vs "gray" [S28])**
- Only a Queen can claim a gate, by touching/flying in front of it; it turns her team color and only her team's Workers can use it, until the opposing Queen touches it. Gates can flip any number of times. Queens cannot use gates for upgrades. [S1][S12][S16][S8]
- "Lockout" = one team owns all 3 Warrior gates. [S12]
- Using a gate: Worker **with a berry** walks to a usable gate and stands still; it snaps into position and holds the berry overhead for **1 s** (vulnerable to kills and to being bumped out), then the doors close and the Worker is locked in, **invisible and invulnerable for 1 s**, then emerges upgraded with brief invincibility (blinking); picking up a berry ends that invincibility. [S12][S16][S28]
- Total transform ≈ 2 s; interruptible only during the first second. [S12]
- A Worker without a berry just poses in front of the gate and nothing happens. [S23]
- Upgrades are lost on death. [S12][S16]
- **Speed gate:** +35% to max horizontal speed, max vertical rise rate, and snail speed [S14][S11] **(conflict: 33% per [S12])**; also raises the rise-speed threshold at which a Warrior ricochets instead of sticking. [S14]
- **Warrior gate:** Worker becomes a Warrior. Speed then Warrior (in that order, since Warriors can't use gates) = "Speed Warrior", whose speed/maneuverability is comparable to a Queen. [S12][S16][S27]
- Berry spent in a gate is consumed (contributes to famine). [S10][S27]

### 2.4 Warrior
- Flies (tap jump button), has a sword, can kill Workers, Warriors, and the enemy Queen. [S1][S28]
- Cannot carry berries, ride the snail, use gates, or dive. [S1][S12][S28]
- On death: respawns as a **Worker** at the hive. [S1]
- Collider is the same size as the Queen's; Worker collider changes on transform. [S14]
- Winged units walking on the ground move at ~0.84x their airborne speed. [S14]

### 2.5 Combat rules (Joust-style)
- No attack button; the sword is always "out" (contrast with Black). Kills are decided by **height**: when two military units (Warrior/Queen) collide, the higher one kills the lower. [S9][S17][S31]
- Kill conditions as described by players: you kill if your sword contacts them from **above** while facing them, or from **behind**. Attacking from below or into their back-facing side does not kill. [S8][S28]
- Contact that is not a kill is a **bump**: both units briefly cannot turn around, then are repelled according to their prior velocities. [S11][S8] The non-turn window is what enables "pinch" plays (one unit bumps from the front, a teammate kills from behind). [S30][S11]
- Equal-height collisions under a ceiling ("50-50") bounce both repeatedly with roughly even survival odds. [S11]
- "Uber": bumped by two characters within ~0.25 s makes you stick to the second and lose control briefly. [S11]
- Workers die to any sword contact from a military unit regardless of angle (no height rule for them). [S8]
- Queen vs Warrior: same height rules; a Warrior can kill a Queen. [S1][S28]
- Incidental contact with a Warrior (non-sword) does not kill. **(uncertain wording)** [S28]
- Loose berries have collision and can wedge between two jousting warriors; the one pushing harder gets forced under and dies. [S10]

### 2.6 Queen
- Always has a sword, can fly, can tag gates, cannot carry berries or ride the snail. [S1][S9]
- Only unit that can **dive**: hold the joystick **down** to fall fast; the dive kills anything in its path below her ("dive cone" shifts with horizontal momentum). [S1][S16][S11]
- Her collider does not shrink while diving. [S14]
- 3 lives (eggs). Killed by enemy Queen or Warriors (from above/behind per §2.5). [S1]
- Only the Queen's joystick has a down direction on the hardware (see §6). [S16][S3]
- Queen deaths are the only limited resource; everything else respawns infinitely. [S8]

---

## 3. Movement feel

Numbers below are community measurements (Frame Data page, partly confirmed by Josh DeBonis in 2022) unless marked. [S14]

- **Physics tick: 50 Hz** (display 60 Hz). Jump buffer = 0 (pressing jump before landing does nothing). Coyote time = 1 physics frame (0.02 s). [S14]
- **Max horizontal speed: 5 px/frame = 250 px/s at 1920 wide** (a Worker crosses the full 1920-px screen in ~7.7 s). Applies to Workers running or airborne, and to airborne Queens/Warriors. [S14]
- Winged units walking: 0.8412x of that. Bots: 0.8x. Speed buff: 1.35x (horizontal max speed and max rise rate). [S14]
- Horizontal speed is the same whether walking, jumping, or falling (no air drag). [S15]
- Workers can reverse direction in mid-air (air strafe) and fight their momentum. [S29][S26]
- **Worker jump:** variable height — a short tap gives the minimum hop, holding longer gives a higher jump ("like classic Mario"). [S8][S15][S11]
- Players describe the jump as floaty with a weak sense of gravity. **(subjective)** [S33]
- **Flight (Queen/Warrior):** repeated tapping of the single button flaps the wings; faster tapping climbs faster; releasing drops. Players report 7–15 taps/second for sustained flight/hover. Walking on the ground is possible. [S8][S15] Older builds required faster tapping to hover; a later patch lowered the threshold ("EZ Hover"). [S11]
- **Sticking:** hitting a ceiling at the right (low) upward speed makes a unit adhere to the ceiling for a fixed time instead of bouncing; applies to Workers too. Tapping while stuck has no effect. "Scrape"/"hover" = tapping fast enough to stay pressed to a ceiling after the stick times out. [S15][S11][S32]
- **Ricochet:** hitting a ceiling too fast bounces the unit downward hard (Warriors use it to drop fast). The speed buff raises the rise-speed threshold between stick and ricochet. [S14][S11][S26]
- "Time-out" = the moment a stuck unit drops off the ceiling. [S32]
- "Triple tap"/"air brake": three rapid taps at max fall speed stop a Warrior/Queen in place. [S11]
- **Dive (Queen only):** hold down → faster fall; releasing down and tapping arrests the fall ("J-dive"); a "dive cancel" briefly dives while rising to kill upward momentum before a ceiling. [S11][S26]
- Springboard: jumping off another character's head shortly after contact gives extra height while keeping air control. [S26][S11]
- Snail rider: can only jump straight up off the snail; minimum jump higher than from ground. **(uncertain)** [S25]
- Speed Worker on snail: snail 35% faster and eats twice as fast. [S14]
- Loose berries are kicked when a berry-carrying Worker runs into them; kick speed/angle depends on the Worker's speed; landing on a berry with your back to it kicks it horizontally. [S15][S10]
- Hitboxes/colliders do not change per animation state (except Worker↔Warrior). [S14]
- Terminal fall velocity exists (tap window of ~half an inch of screen before landing is cited). [S11]

---

## 4. Maps

### 4.1 Official map list
- Four official ("non-bonus") maps, in the standard tournament set order: **Day, Night, Dusk, Twilight**. Tournament format commonly Day/Night/Dusk (best-of sets); Twilight is the least played. [S18][S11][S34][S8]
- Day = original map (2013); Night = 2nd; Dusk = 3rd; Twilight = 4th, introduced in release-candidate beta 17.17 (June 2017). [S13][S19][S35][S36][S37]
- Two **bonus maps** exist (short free "bonus game" between paid games; not selectable). Names/layouts undocumented in sources found; some bonus maps have no snail or multiple snails. [S18][S3][S9]
- Map switching: a service-menu/keyboard action inside the cabinet, or an operator-added map button. [S18]
- v20.12 (Dec 2020) added a tutorial mode with two tutorial levels. [S38][S39]

### 4.2 Shared layout rules
- Every official map has: 2 hives (one per team) with 12 holes each, 3 Warrior gates + 2 Speed gates, berry piles placed symmetrically, 1 snail on a horizontal track with a team-colored net at each end. [S2][S12][S23][S9]
- Maps are left/right symmetric (Blue vs Gold sides). [S23]
- Whole arena fits on one screen; no scrolling. [S2][S33]
- Screen **wrap**: walking off one side appears on the other. All four maps wrap horizontally; Night and Twilight also wrap vertically. Some wraps are **drone-only** (Workers can pass, winged units cannot). [S40][S8][S11]
- Snail track positions and goal nets: Day/Dusk are "maximum-distance" snail maps; Night (and Twilight) have a shorter run. [S11][S19]

### 4.3 Day
- Background: light blue sky; platforms; "Mario-like" look. [S11][S41]
- Hives at the **top** of the map; snail track along the **bottom**; nets at the bottom left/right. [S19]
- Horizontal wrap on the bottom three levels; walls at the top prevent wrapping. [S19][S40]
- A long platform spans the bottom with a "tunnel" underneath (snail runs through it). Tiny "baby ledges" sit just above the snail track. [S13][S11]
- Gates: left/mid/right Warrior gates; two Speed gates toward the outer edges. Queen can tag two gates in rapid succession from the middle. [S12][S13]
- 66 berries total; a berry pile near each Speed gate was added in a later revision. [S13][S19]
- Images: start state https://static.wikitide.net/killerqueenwiki/3/3e/Day-Start.png ; empty https://static.wikitide.net/killerqueenwiki/4/43/Day-Blank.png ; updated layout https://static.wikia.nocookie.net/killerqueenarcade/images/2/2c/Newdaymap.png [S13][S19]

### 4.4 Night ("Waterfall map")
- Background: dark blue / night. [S11]
- Hives at the **bottom**: Blue hive left, Gold hive right. Snail in the **middle** of the map; shorter snail run than Day. [S19]
- Horizontal **and vertical** wrap; vertical wrap positions are marked by waterfalls (bottom-middle waterfalls wrap to top-middle). Falling out of the hive off the bottom returns at the top. [S19][S40][S13]
- Hive outer wall has a small opening; combined with the horizontal wrap, berries can be kicked from one hive to the other (berry-only wrap). [S19][S10]
- A Worker-only passage in the lower center ("pineapple" block with a drone-only walkway). [S35][S11]
- Snail track includes a "rope" segment others can pass through; the snail can touch a waterfall. [S11]
- 2 Speed + 3 Warrior gates (side gates and a middle gate). [S19]
- "True famine" possible (berry stuck at bottom of a hive). [S10][S11]
- Images: https://static.wikitide.net/killerqueenwiki/0/0b/Night-Start.png ; https://static.wikitide.net/killerqueenwiki/3/32/Night-Blank.png [S19b]

### 4.5 Dusk
- Background: orange/dusk. Thick platforms. [S11][S35]
- Horizontal wrap only; "maximum-distance" snail map with a bottom tunnel the snail passes through. [S11][S25]
- First map with a **Worker-only wrap**, near the top-left/right berry piles ("cubby"). [S35][S11]
- Hive shape: multiple rows of holes; lowest three rows are "bottom berries" (fillable from below), remaining "top berries" (five uppermost) must be filled from above. A top-center berry pile reachable only by jumping straight up was removed in v20.12. [S15][S11][S10]
- Gates: "Near" and "Far" side gates close to each other plus a mid gate; speed gate on a "speed ledge". [S36]
- "True famine" possible (berries under corners). [S10][S11]
- Images: https://static.wikitide.net/killerqueenwiki/b/bb/Dusk-Start.png ; https://static.wikitide.net/killerqueenwiki/8/85/Dusk-Blank.png [S36]

### 4.6 Twilight ("Meat map")
- Background purple; purple ledges. Community historically disliked it; rarely in tournament rotation. [S8][S11]
- Horizontal and vertical wrap; features a Worker-only horizontal wrap. [S8][S35]
- Snail track has a "rope" section; a small walled platform ("nub") at bottom-middle above the vertical wrap. [S11]
- Hive: lowest two holes are "bottom berries". [S15]
- Added in beta 17.17 (June 2017). [S37]
- Image: https://static.wikitide.net/killerqueenwiki/c/c8/Twilight-Blank.png [S37b]

### 4.7 Not found
- No source gives exact pixel coordinates of hives, gates, snail track, or platforms. Use the images above as reference.
- Night and Twilight berry totals not found.

---

## 5. Presentation

### 5.1 Resolution, scale, timing
- Game runs in **Unity**. [S2]
- Output is **1920x1080 at 60 Hz** (cabinet PC: originally Intel NUC; current manual specifies GMKtec M5 Plus/Ultra). [S14][S3][S42]
- **Pixel art drawn at 2x: one art pixel = 2x2 monitor pixels**, so the logical art canvas is **960x540 (16:9)**; Unity allows sub-pixel positions. [S14]
- Physics at **50 Hz**, render at 60 Hz. [S14]

### 5.2 Cabinet / screens
- Two cabinets (Blue and Gold), each with its own 5 control positions and one large monitor; usually back-to-back or side-by-side. [S1][S2][S43]
- **One PC renders one image; an HDMI splitter sends the identical signal to both cabinet monitors** (plus optional spectator/stream outputs). So both teams see the exact same full-map view; there is no per-team camera or fog. [S42][S3]
- Monitor sizes over time: 46" (original) → 47" (Raw Thrills 2016) → 49"/50" (current; Samsung BE50D-H 50"). [S43][S3][S44]
- Hardware options include 4K monitors with a 4K splitter (same game image upscaled). [S44]
- Operator "Team Sides" setting flips which team is on which side in software to match the physical cabinet. [S3]

### 5.3 HUD / on-screen information
- The HUD is largely **diegetic**: queen lives = eggs at the hive; economic progress = filled holes in each hive; snail progress = snail position on its track; gate ownership = gate color (white/neutral, blue, gold). [S20][S8][S12]
- The famine countdown (90 s) appears on screen as a timer. [S23][S10]
- Attract mode shows a "NAG" pricing message top-left; freeplay sponsor name, happy hour and league-night info can also appear. [S3]
- A pre-game screen reads "Meet Thy Neighbor" / jokes that the game is best with 10 players and encourages talking to strangers. [S41][S45]
- Hive is highlighted at match start. [S20]
- Victory text used in marketing/wiki: "Military Victory", "Economic Victory", "Snail Victory". Victory-screen layout, announcer lines, or jingles: **not documented in sources found.** [S46]
- Starting barriers around the hives are visible at game start (see map images "…-Start.png"). Countdown/"GO" sequence: **not documented.** [S13]
- Raw Thrills version added an in-cabinet tutorial for new players; v20.12 added a tutorial mode and clearer first-time messaging. [S2][S38]

### 5.4 Audio
- Music composed by Josh DeBonis in **FamiTracker** (NES-style chiptune; his first chiptune work). [S47]
- A distinct "pop" sound plays when a unit is killed. [S45]
- Per-map music tracks, announcer voice: **no source found.** Live announcers at venues are human. [S48]

### 5.5 Visual style
- Retro 2x pixel art; art by Nikita Mikros; characters are humanoid bees (blue vs gold), Queen is wasp-like with wings, Workers have distinct outfits/skins, snail is pink/red, berries are purple orbs, gates look like doorways/iron-maidens with wings (warrior) or lightning bolts (speed). [S47][S8][S41][S16][S29]
- Warriors emerging from a gate and freshly spawned units blink (alternate visible/invisible frames) during invulnerability. [S28][S11]
- Cabinet side art (Raw Thrills) in late-70s/early-80s Midway/Williams style. [S43]

---

## 6. Controls

- Per player: **one joystick + one button**. [S1][S3]
- Hardware: Seimitsu LS-38 sticks (earlier LS-32); iL concave pushbuttons with 50 g Omron switches, blue/yellow. [S3][S49]
- **Worker positions: joystick restrictor set to 2-way (left/right only).** [S3][S16]
- **Queen position: restrictor removed (unrestricted), so Down is available.** [S3][S16]
- Joystick: left/right = move/face direction (all roles). Down (Queen only) = **dive** while airborne. Up: no documented gameplay function. [S16][S9]
- Button, by role:
  - Worker: **jump**; tap = small hop, hold = higher jump. Also: press to **dismount** the snail. [S8][S15][S9]
  - Warrior: **flap**; tap repeatedly to fly/rise; faster taps = faster rise; stop tapping to fall. [S8][S28]
  - Queen: same flap as Warrior; combined with Down for dive/dive-cancel. [S8][S16][S11]
- Mounting the snail is done by walking into it (no button); using a gate is done by standing still in front of it with a berry (no button). [S9][S12]
- Service/attract: the Queen stick and start button navigate the operator Adjustments menu. [S3]
- No hidden gameplay inputs documented. Known hardware quirk: Seimitsu LS-32 "snap-back" could register the opposite direction on release. [S49]

---

## 7. Arcade vs Killer Queen Black — differences to avoid importing

| Topic | Arcade (this doc) | Killer Queen Black |
|---|---|---|
| Team size | 5v5 (1 Queen + 4 Workers) [S1] | 4v4 (1 Queen + 3 Drones) [S31][S50] |
| Attack | No attack button; sword always out; height/Joust rule decides kills [S31][S9] | Has an attack button; Joust-style height rule and auto-attacking removed [S50][S51] |
| Gate upgrades | Exactly two: Speed, Warrior (speed can stack under warrior) [S12] | Each gate offers 2 of 5 power-ups: Speed, Shield, Sword, Mace (flail), Stinger/laser gun [S50][S51] |
| Queen movement | Flaps to fly, can walk, holds Down to dive [S8][S16] | Cannot jump; flaps; has horizontal **dash** plus dive, can cancel between them [S51][S41] |
| Maps | 4 official (Day, Night, Dusk, Twilight) + 2 bonus [S18] | 6 symmetric maps at launch, more via patches (e.g., Nesting Flats) [S52][S53] |
| Match format | Single game ends on any victory; operator sudden-death option [S1][S3] | Best-of-5 sets built in (first to 3) [S52] |
| Screens | One shared full-map image on two cabinet monitors [S42] | Single screen local play; online with per-player views [S50] |
| Bots/tutorial | AI fills empty seats (2016+); tutorial mode (20.12) [S2][S38] | Built-in tutorial, bots (1.60 "Hydra"), spectate (1.63) [S53] |
| Snail | Ridden snail ~0.446 px/f; eat 3–3.67 s; speed rider 35% faster [S14] | Numbers not researched here; do not reuse arcade numbers unverified |
| Berries to win | 12 holes [S9] | Not verified here |

Also: Black uses the term "Drone" officially; Arcade official text says "Worker" (community says Drone). [S1][S50]

---

## Sources

- [S1] Official How to Play — https://killerqueenarcade.com/howtoplay
- [S2] Wikipedia, Killer Queen (video game) — https://en.wikipedia.org/wiki/Killer_Queen_(video_game)
- [S3] Killer Queen Operator's Manual (BumbleBear, Google Doc, rev. 2026) — https://docs.google.com/document/d/1-g2z2cc-rp8izrDIAu-hcHVHM9RefjAeq5KcDh0Itgc/edit (linked from https://killerqueenarcade.com/leagueguide)
- [S5] Giant Bomb, Killer Queen — https://www.giantbomb.com/killer-queen/3030-43431/
- [S8] Killer Queen PDX, "Introduction to Killer Queen" (2016) — https://killerqueenpdx.buzz/blog/how-to-play
- [S9] KQ Wiki (Miraheze), Snail — https://killerqueenarcade.wiki/wiki/Snail ; Welcome page — https://killerqueenarcade.wiki/wiki/Welcome_to_Killer_Queen!
- [S10] KQ Wiki, Berry — https://killerqueenarcade.wiki/wiki/Berry
- [S11] Killer Queen Arcade Glossary (community Google Doc, Woody Stanfield/CHI et al.) — https://docs.google.com/document/d/15XErTb_T7OoXGHt3FbIzGbVAa-dGOc9Yn6M0V8sTJNQ/mobilebasic
- [S12] KQ Wiki, Gate — https://killerqueenarcade.wiki/wiki/Gate ; Speed — https://killerqueenarcade.wiki/wiki/Speed ; Speed Warrior — https://killerqueenarcade.wiki/wiki/Speed_Warrior
- [S13] KQ Wiki, Day — https://killerqueenarcade.wiki/wiki/Day
- [S14] Fandom KQ Arcade Wiki, Frame Data (cites Josh DeBonis 2019/2022) — https://killerqueenarcade.fandom.com/wiki/Frame_Data
- [S15] Jeff Kaufman, "Notes on Running Objective" — https://www.lesswrong.com/posts/5vTnp4sfrYoTRDpLg/notes-on-running-objective (also https://jefftkaufman.substack.com/p/notes-on-running-objective)
- [S16] Fandom, Queen — https://killerqueenarcade.fandom.com/wiki/Queen ; Maidens (Gates) — https://killerqueenarcade.fandom.com/wiki/Maidens_(Gates)
- [S17] Killer Queen Black Wiki, "Arcade Version" — https://killerqueenblack.wiki/releases/killer-queen-arcade/
- [S18] Fandom, Category:Maps — https://killerqueenarcade.fandom.com/wiki/Category:Maps
- [S19] Fandom, Day map — https://killerqueenarcade.fandom.com/wiki/Day_map ; Night Map — https://killerqueenarcade.fandom.com/wiki/Night_Map
- [S19b] KQ Wiki, Night — https://killerqueenarcade.wiki/wiki/Night
- [S20] Fandom, Hive — https://killerqueenarcade.fandom.com/wiki/Hive
- [S21] Fandom, Economic Victory — https://killerqueenarcade.fandom.com/wiki/Economic_Victory
- [S22] Fandom, Military Victory — https://killerqueenarcade.fandom.com/wiki/Military_Victory ; Snail Victory — https://killerqueenarcade.fandom.com/wiki/Snail_Victory
- [S23] Fandom, Berries — https://killerqueenarcade.fandom.com/wiki/Berries
- [S24] Outside Is Overrated (2018) — https://outsideisoverrated.com/killer-queen-the-arcade-phenomenon-thats-sweeping-the-nation/ ; Fandom, The Snail — https://killerqueenarcade.fandom.com/wiki/The_Snail
- [S25] Fandom, Dusk Snail Positions — https://killerqueenarcade.fandom.com/wiki/Dusk_Snail_Positions
- [S26] KQ Wiki technique pages: Drone Bump, Springboarding, Ricochet, Dive Cancel, J-Dive, Air Strafe — https://killerqueenarcade.wiki/wiki/Special:AllPages
- [S27] Fandom, Speed Maiden — https://killerqueenarcade.fandom.com/wiki/Speed_Maiden
- [S28] Fandom, Warrior/Knight — https://killerqueenarcade.fandom.com/wiki/Warrior/Knight ; Warrior Maiden — https://killerqueenarcade.fandom.com/wiki/Warrior_Maiden
- [S29] Fandom, Drones/Workers — https://killerqueenarcade.fandom.com/wiki/Drones/Workers
- [S30] KQ Wiki, Pinch — https://killerqueenarcade.wiki/wiki/Pinch
- [S31] KQ Wiki Welcome (Joust-like rule) — https://killerqueenarcade.wiki/wiki/Welcome_to_Killer_Queen! ; KQB Wiki Arcade Version [S17]
- [S32] KQ Wiki, Time-Out — https://killerqueenarcade.wiki/wiki/Time-Out
- [S33] consc.itch.io research devlog (player impressions) — https://consc.itch.io/assymetric-multiplayer/devlog/103459/research
- [S34] Fandom, FAQ — https://killerqueenarcade.fandom.com/wiki/FAQ
- [S35] Fandom, Dusk Map — https://killerqueenarcade.fandom.com/wiki/Dusk_Map ; Twilight / Meat Map — https://killerqueenarcade.fandom.com/wiki/Twilight_/_Meat_Map
- [S36] KQ Wiki, Dusk — https://killerqueenarcade.wiki/wiki/Dusk
- [S37] RePlay Magazine, "Killer Queen: New Beta Version Is Live" (beta 17.17, Twilight) — https://www.replaymag.com/killer-queen-new-beta-version-is-live/
- [S37b] KQ Wiki, Twilight — https://killerqueenarcade.wiki/wiki/Twilight
- [S38] RePlay Magazine, "Killer Queen Relaunched Featuring New Mode" (v20.12) — https://www.replaymag.com/killer-queen-relaunched-featuring-new-mode/
- [S39] KQ Wiki Berry page (20.12 famine/Dusk changes) — same as [S10]
- [S40] KQ Wiki, Wrap — https://killerqueenarcade.wiki/wiki/Wrap
- [S41] AV Club, "Inside Killer Queen…" — https://www.avclub.com/inside-killer-queen-the-addictive-arcade-sensation-tha-1836655254
- [S42] BumbleBear Helpdesk: Troubleshooting Displays — https://helpdesk.bumblebeargames.com/knowledgebase.php?article=5 ; 1080i/50Hz fix — https://helpdesk.bumblebeargames.com/knowledgebase.php?article=7
- [S43] Arcade Heroes, Raw Thrills Killer Queen (2016) — https://arcadeheroes.com/2016/03/02/killer-queen-arcade-raw-thrills/
- [S44] BumbleBear shop, Killer Queen / monitor — https://shop.bumblebeargames.com/products/killer-queen ; https://bumblebeargames.com/products/killer-queen-monitor
- [S45] Gear Patrol, Killer Queen arcade — https://www.gearpatrol.com/tech/a173369/killer-queen-arcade-game/
- [S46] Fandom, Three Paths to Victory — https://killerqueenarcade.fandom.com/wiki/Three_Paths_to_Victory
- [S47] Film Festival Traveler interview (credits: DeBonis code+music in FamiTracker, Mikros art) — https://filmfestivaltraveler.com/film-arts/film-arts-interviews/2670-killer-queen-arcade-wants-you
- [S48] DNAinfo Chicago, Logan Arcade (2015) — https://www.dnainfo.com/chicago/20150116/logan-square/rare-killer-queen-arcade-game-underground-hit-with-chicago-players/
- [S49] BumbleBear, Killer Queen Joystick 2024 model — https://bumblebeargames.com/products/killer-queen-joystick-2024-model
- [S50] Giant Bomb, Killer Queen Black — https://www.giantbomb.com/killer-queen-black/3030-68949/
- [S51] TV Tropes, Killer Queen — https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/KillerQueen (via search excerpts; page not directly fetchable)
- [S52] Killer Queen Black press release coverage — https://gamesmea.com/arcade-smash-hit-killer-queen-black-now-on-switch-pc-and-steam
- [S53] Nintendo Everything, KQB 1.62/1.63 patch notes — https://nintendoeverything.com/killer-queen-black-full-patch-notes-for-version-1-62-betelgeuse-update
- Other consulted: Fandom Opening Theory — https://killerqueenarcade.fandom.com/wiki/Opening_Theory ; Fandom Joust — https://killerqueenarcade.fandom.com/wiki/Joust ; Medium, "An Introduction to Everything Killer Queen Arcade" — https://medium.com/@alanwdang/an-introduction-to-everything-killer-queen-arcade-ad6034be047f ; fan clone README (not authoritative) — https://github.com/lukemcneil/killer-queen ; Fluid Project analysis — https://fluidproject.atlassian.net/wiki/spaces/C2LC/pages/7210475/Killer+Queen+video+game

---

## Open questions / uncertain

1. **Respawn delays** for Workers, Warriors (as Workers), and Queens (egg hatch) — no number found anywhere.
2. **Economic target per map** — 12 per all community sources; Wikipedia says it varies by arena. Bonus maps unknown.
3. **Snail eat duration** — 3.67 s measured [S14] vs 3 s in glossary [S11]; speed rider halves it (both agree).
4. **Speed buff magnitude** — 35% [S14][S11][S9] vs 33% [S12]. 1.35 is better sourced (cited to DeBonis).
5. **Neutral gate color** — "white" vs "gray"; verify from screenshots.
6. **Exact joust/kill geometry** — "higher sword wins", "from behind kills", "facing required" are player descriptions; the precise collider/sword-hitbox test is not published. Does a Queen's dive kill regardless of relative height? Sources imply yes for anything below her.
7. **Bump physics** — no-turn window duration and repel velocities are undocumented beyond "brief" and "based on prior velocities"; uber window ~0.25 s.
8. **Stick duration**, stick/ricochet velocity thresholds, hover tap-rate threshold, flap impulse, gravity, jump heights — all unquantified (only tap-rate 7–15 Hz anecdote).
9. **Snail speed with no rider** is zero; snail speed on Night/Twilight presumed identical per-pixel but not measured.
10. **Match start sequence** — starting barriers exist (map images) but their duration and any countdown/"GO"/announcer cue are undocumented.
11. **Victory screen**, per-map music, announcer/voice lines, sound effects beyond the kill "pop" — undocumented.
12. **Sudden Death** operator setting (3/4/5/10 min) — what the game does when it triggers is undocumented.
13. **Bonus maps** — two exist; names/rules not found ("Snail Bonus Map" mentioned once in a BumbleBear support snippet; unverified).
14. **Map geometry** — no coordinate data; rely on the linked PNGs (Day/Night/Dusk/Twilight Start/Blank) and the updated Day image.
15. **Up on the Queen stick** — hardware allows it; no gameplay function found.
16. **Whether Workers die to Warrior body contact** vs sword only — one wiki says incidental (non-sword) contact doesn't kill; other sources say any contact from above/facing kills. Likely the sword hitbox is forward/down of the sprite; unverified.
17. The fan clone (lukemcneil) adds rules (side contact: back-turned player dies) that match the "backstab" description but is not an official source.
