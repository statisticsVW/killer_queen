# Killer Queen (Arcade clone)

A local-multiplayer recreation of the Killer Queen arcade game (BumbleBear, 2013): 5v5, one joystick and one button per player, three independent ways to win. Personal, non-distributed project; vocabulary follows the arcade game's own terms, not Killer Queen Black's.

## Language

### Teams and roles

**Team**:
One of the two sides in a match, Blue or Gold. Every player, Hive, Gate claim and Snail goal belongs to exactly one Team.
_Avoid_: Side, colour, faction

**Queen**:
The single flying, stinging player on each Team. The only player whose death counts toward a Military Win.
_Avoid_: Leader, boss

**Worker**:
A non-Queen player who has not passed through a Gate. Workers carry Berries, ride the Snail and can become Warriors; they cannot attack.
_Avoid_: Drone, grunt, bee

**Warrior**:
A Worker who has transformed at a Warrior Gate held by their Team. Warriors fly and kill with their sword; they cannot carry Berries or ride the Snail. A Warrior who dies respawns as a Worker.
_Avoid_: Soldier, fighter, sword guy

**Speed Worker**:
A Worker who has used a Speed Gate and moves faster. Still a Worker in every other respect.
_Avoid_: Fast drone

**Speed Warrior**:
A Speed Worker who has then used a Warrior Gate. A faster Warrior; otherwise identical.
_Avoid_: Fast warrior

**Bot**:
A Team slot driven by the computer instead of a human. A Bot occupies a role exactly as a human would and acts only through the same joystick-and-button input.
_Avoid_: AI, CPU, NPC

### Setting up a Match

**Lobby**:
The pre-Match screen where players claim Seats and the Bot Difficulty for each Team is chosen.
_Avoid_: Menu, character select

**Seat**:
One of the ten player positions in a Match, five per Team, one of which is that Team's Queen Seat. A Seat is held by a human or, once the Match starts, by a Bot.
_Avoid_: Slot, station, player number

**Bot Difficulty**:
The per-Team setting (Easy, Normal, Hard) that governs how well that Team's Bots decide and, on Easy only, slows them to the arcade's Bot speed. It never grants a Bot an ability a human lacks.
_Avoid_: AI level, CPU strength

**Replay**:
The recorded input stream of a Match, from which the whole Match can be reproduced exactly.
_Avoid_: Recording, video

### Objectives

**Berry**:
A collectible a Worker carries one at a time to their Team's Hive. A Worker holding a Berry can spend it at a Gate to transform.
_Avoid_: Fruit, coin, resource

**Hive**:
The set of Berry slots belonging to one Team. Filling every slot is an Economic Win.
_Avoid_: Base, bank, nest

**Snail**:
The single shared creature on the bottom of the map that a Worker rides toward their Team's Snail Goal. The Snail eats enemy Workers in its path.
_Avoid_: Slug

**Snail Goal**:
The end of the Snail's track on one Team's side. The Snail arriving there is a Snail Win for that Team.
_Avoid_: Goal line, snail net

**Gate**:
A station where a Worker spends a Berry to upgrade. A Gate is neutral until a Queen claims it for her Team by touching it, and only that Team's Workers can use it until the other Queen touches it.
_Avoid_: Portal, upgrade station, warrior hole

**Warrior Gate**:
A Gate that turns a Worker into a Warrior (or a Speed Worker into a Speed Warrior).
_Avoid_: Wings gate, sword gate

**Speed Gate**:
A Gate that turns a Worker into a Speed Worker.
_Avoid_: Lightning gate

**Egg**:
One of the Queen's remaining lives, shown at her Team's Hive. A Queen's death hatches an Egg; a Queen with no Eggs left dies for good.
_Avoid_: Life, respawn token

**Famine**:
The state after the Map's last Berry has been taken, ending when the Berry piles refresh after a fixed countdown.
_Avoid_: Berry drought, refill timer

### Combat and movement

**Flap**:
A single press of the button by a winged player (Queen or Warrior), giving one upward impulse. Flight is repeated Flaps; there is no "hold to fly".
_Avoid_: Fly, thrust

**Joust**:
Sword contact between two Warriors (or a Warrior and a Queen). The higher sword wins and kills; attacking from behind also kills.
_Avoid_: Duel, clash

**Bump**:
The outcome of a Joust nobody wins: both players are briefly repelled and unable to turn.
_Avoid_: Clang, parry

**Dive**:
The Queen's downward attack, triggered by holding the stick down while airborne. Kills anything beneath her.
_Avoid_: Stomp, ground pound

**Respawn**:
A dead player's return after a fixed delay, at their spawn point in front of their Team's Hive, blinking and Invulnerable. A dead Queen instead hatches from her next Egg.
_Avoid_: Revive, reset

**Invulnerable**:
Unable to be killed, for a short window shown by blinking: after a Respawn, and after emerging from a Gate. Enemy swords pass through an Invulnerable player.
_Avoid_: I-frames, spawn protection, shielded

### Outcomes

**Military Win**:
Victory by killing the enemy Queen enough times to exhaust her lives.
_Avoid_: Queen kill win, combat win

**Economic Win**:
Victory by filling every slot of your Team's Hive with Berries.
_Avoid_: Berry win

**Snail Win**:
Victory by riding the Snail into your Team's Snail Goal.

**Match**:
One game from start to the moment a Team achieves any win condition. Matches are played on a single Map.
_Avoid_: Round, game, set

**Map**:
A fixed arena layout (the arcade's Day, Night, Dusk, and later additions). The whole Map is visible on screen at once.
_Avoid_: Level, stage, arena
