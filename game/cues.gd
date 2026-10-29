class_name Cues
extends RefCounted
## Which sound cues a Match state plays: one for each kind of moment in the
## events of the tick that produced it, and the countdown's seconds. A cue
## plays once a tick however many times its moment happened, so ten kills at
## once are one pop, not ten stacked. Cues follow sim ticks, never the clock,
## so they keep their place in a Replay or at any playback speed.

enum Cue {
	COUNTDOWN,
	GO,
	KILL,
	QUEEN_DEATH,
	HATCH,
	BERRY_PICKUP,
	BERRY_DEPOSIT,
	GATE_CLAIM,
	TRANSFORM_START,
	TRANSFORM_COMPLETE,
	SNAIL_MOUNT,
	EAT_START,
	EAT_COMPLETE,
	FAMINE_START,
	FAMINE_END,
	MILITARY_WIN,
	ECONOMIC_WIN,
	SNAIL_WIN,
}

## How many of the countdown's last whole seconds are counted down, as the
## arcade's 3, 2, 1 (reference section 3.1); the seconds before them pass in
## silence.
const COUNTED_SECONDS := 3

## The cue each event plays; events not listed play none. A death plays the
## kill pop (Queens' also play QUEEN_DEATH); its KILL event plays nothing more.
const EVENT_CUES := {
	MatchEvent.Type.DEATH: Cue.KILL,
	MatchEvent.Type.HATCH: Cue.HATCH,
	MatchEvent.Type.BERRY_PICKUP: Cue.BERRY_PICKUP,
	MatchEvent.Type.BERRY_DEPOSIT: Cue.BERRY_DEPOSIT,
	MatchEvent.Type.GATE_CLAIM: Cue.GATE_CLAIM,
	MatchEvent.Type.TRANSFORM_START: Cue.TRANSFORM_START,
	MatchEvent.Type.TRANSFORM_COMPLETE: Cue.TRANSFORM_COMPLETE,
	MatchEvent.Type.SNAIL_MOUNT: Cue.SNAIL_MOUNT,
	MatchEvent.Type.EAT_START: Cue.EAT_START,
	MatchEvent.Type.EAT_COMPLETE: Cue.EAT_COMPLETE,
	MatchEvent.Type.FAMINE_START: Cue.FAMINE_START,
	MatchEvent.Type.FAMINE_END: Cue.FAMINE_END,
}

## The cue each way of winning plays.
const WIN_CUES := {
	MatchState.Win.MILITARY: Cue.MILITARY_WIN,
	MatchState.Win.ECONOMIC: Cue.ECONOMIC_WIN,
	MatchState.Win.SNAIL: Cue.SNAIL_WIN,
}


## The cues `state` plays, in Cue order, each once. The countdown beeps as each
## of its last COUNTED_SECONDS whole seconds is first shown at
## `ticks_per_second`, and plays GO on the state it ends.
static func of(state: MatchState, ticks_per_second: int) -> Array[Cue]:
	var playing := {}
	var left := state.countdown_ticks()
	if left > 0 and left <= COUNTED_SECONDS * ticks_per_second and left % ticks_per_second == 0:
		playing[Cue.COUNTDOWN] = true
	elif left == 0 and state.tick == state.tuning.match_countdown_ticks:
		playing[Cue.GO] = true
	for e in state.events:
		if EVENT_CUES.has(e.type):
			playing[EVENT_CUES[e.type]] = true
		if e.type == MatchEvent.Type.DEATH and state.characters[e.seat].role == CharacterState.Role.QUEEN:
			playing[Cue.QUEEN_DEATH] = true
		elif e.type == MatchEvent.Type.WIN:
			playing[WIN_CUES[state.win]] = true
	var cues: Array[Cue] = []
	cues.assign(playing.keys())
	cues.sort()
	return cues
