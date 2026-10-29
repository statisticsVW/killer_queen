class_name Sounds
extends Node
## Plays sound cues. Every cue's placeholder sound is original, synthesised
## here once at start-up from a few notes. Each cue has a few voices of its
## own: a cue played while all of them are busy restarts the one that has
## played longest, so a run of kills never piles up into noise. A hard limiter
## on the master bus keeps different cues sounding at once from clipping.

const MIX_RATE := 22050
## Voices each cue has.
const VOICES := 3
## Every note's fade in and out, in seconds, so none clicks.
const EDGE := 0.004

enum Wave { SINE, SQUARE, TRIANGLE, NOISE, REST }

## Each cue's voices, by Cue.
var _voices := {}


func _ready() -> void:
	if AudioServer.get_bus_effect_count(0) == 0:
		AudioServer.add_bus_effect(0, AudioEffectHardLimiter.new())
	var notes := _notes()
	for cue: Cues.Cue in Cues.Cue.values():
		var stream := _synthesise(notes[cue])
		var voices: Array[AudioStreamPlayer] = []
		for i in VOICES:
			var voice := AudioStreamPlayer.new()
			voice.stream = stream
			add_child(voice)
			voices.append(voice)
		_voices[cue] = voices


## Starts each of `cues`.
func play(cues: Array[Cues.Cue]) -> void:
	for cue in cues:
		_voice_for(cue).play()


func stop() -> void:
	for voices: Array[AudioStreamPlayer] in _voices.values():
		for voice in voices:
			voice.stop()


## A voice of `cue` that isn't playing, or else the one that has played longest.
func _voice_for(cue: Cues.Cue) -> AudioStreamPlayer:
	var oldest: AudioStreamPlayer = null
	for voice: AudioStreamPlayer in _voices[cue]:
		if not voice.playing:
			return voice
		if oldest == null or voice.get_playback_position() > oldest.get_playback_position():
			oldest = voice
	return oldest


## Each cue's sound, by Cue: notes played one after another, each [wave, start
## pitch, end pitch (Hz), seconds, volume, fade]. A note slides from its start
## pitch to its end pitch; `fade` is how far its volume falls by its end (0
## holds, 1 dies away). A NOISE note's pitch is how often its noise changes.
static func _notes() -> Dictionary:
	var c := Cues.Cue
	return {
		c.COUNTDOWN: [[Wave.SQUARE, 660, 660, 0.12, 0.3, 0.3]],
		c.GO: [[Wave.SQUARE, 880, 880, 0.08, 0.3, 0.0], [Wave.SQUARE, 1320, 1320, 0.35, 0.3, 1.0]],
		c.KILL: [[Wave.SQUARE, 1400, 180, 0.07, 0.4, 1.0], [Wave.NOISE, 3000, 1000, 0.04, 0.25, 1.0]],
		c.QUEEN_DEATH: [[Wave.SQUARE, 523, 494, 0.12, 0.35, 0.2], [Wave.SQUARE, 392, 370, 0.12, 0.35, 0.2],
			[Wave.SQUARE, 262, 98, 0.5, 0.4, 1.0]],
		c.HATCH: [[Wave.TRIANGLE, 200, 800, 0.18, 0.45, 0.3], [Wave.TRIANGLE, 1047, 1047, 0.15, 0.4, 1.0]],
		c.BERRY_PICKUP: [[Wave.SINE, 1400, 1800, 0.05, 0.3, 1.0]],
		c.BERRY_DEPOSIT: [[Wave.SINE, 988, 988, 0.07, 0.35, 0.5], [Wave.SINE, 1319, 1319, 0.15, 0.35, 1.0]],
		c.GATE_CLAIM: [[Wave.TRIANGLE, 523, 523, 0.06, 0.4, 0.2], [Wave.TRIANGLE, 659, 659, 0.06, 0.4, 0.2],
			[Wave.TRIANGLE, 784, 784, 0.16, 0.4, 1.0]],
		c.TRANSFORM_START: [[Wave.SQUARE, 150, 450, 0.35, 0.2, 0.2]],
		c.TRANSFORM_COMPLETE: [[Wave.SQUARE, 392, 392, 0.05, 0.25, 0.0], [Wave.SQUARE, 523, 523, 0.05, 0.25, 0.0],
			[Wave.SQUARE, 659, 659, 0.05, 0.25, 0.0], [Wave.SQUARE, 1047, 1047, 0.2, 0.25, 1.0]],
		c.SNAIL_MOUNT: [[Wave.TRIANGLE, 180, 360, 0.12, 0.45, 0.5], [Wave.TRIANGLE, 360, 270, 0.1, 0.4, 1.0]],
		c.EAT_START: [[Wave.NOISE, 600, 300, 0.1, 0.4, 0.6], [Wave.REST, 0, 0, 0.05, 0.0, 0.0],
			[Wave.NOISE, 500, 250, 0.1, 0.4, 1.0]],
		c.EAT_COMPLETE: [[Wave.SINE, 320, 70, 0.35, 0.5, 1.0]],
		c.FAMINE_START: [[Wave.SQUARE, 330, 330, 0.25, 0.25, 0.3], [Wave.SQUARE, 247, 247, 0.25, 0.25, 0.3],
			[Wave.SQUARE, 165, 165, 0.5, 0.25, 1.0]],
		c.FAMINE_END: [[Wave.SQUARE, 165, 165, 0.12, 0.25, 0.2], [Wave.SQUARE, 247, 247, 0.12, 0.25, 0.2],
			[Wave.SQUARE, 330, 330, 0.12, 0.25, 0.2], [Wave.SQUARE, 494, 494, 0.35, 0.25, 1.0]],
		c.MILITARY_WIN: [[Wave.SQUARE, 392, 392, 0.12, 0.3, 0.2], [Wave.SQUARE, 523, 523, 0.12, 0.3, 0.2],
			[Wave.SQUARE, 659, 659, 0.12, 0.3, 0.2], [Wave.SQUARE, 784, 784, 0.25, 0.3, 0.2],
			[Wave.SQUARE, 659, 659, 0.12, 0.3, 0.2], [Wave.SQUARE, 784, 784, 0.6, 0.3, 1.0]],
		c.ECONOMIC_WIN: [[Wave.SINE, 1047, 1047, 0.1, 0.4, 0.3], [Wave.SINE, 1319, 1319, 0.1, 0.4, 0.3],
			[Wave.SINE, 1568, 1568, 0.1, 0.4, 0.3], [Wave.SINE, 2093, 2093, 0.7, 0.4, 1.0]],
		c.SNAIL_WIN: [[Wave.TRIANGLE, 200, 600, 0.5, 0.45, 0.1], [Wave.TRIANGLE, 600, 300, 0.2, 0.45, 0.1],
			[Wave.TRIANGLE, 300, 900, 0.6, 0.45, 1.0]],
	}


## A 16-bit mono sound of `notes` (see _notes).
static func _synthesise(notes: Array) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var data := PackedByteArray()
	var phase := 0.0
	var noise := 0.0
	for note: Array in notes:
		var wave: Wave = note[0]
		var count := int(note[3] * MIX_RATE)
		var edge := EDGE * MIX_RATE
		for i in count:
			var p := float(i) / count
			var pitch: float = note[1] * pow(float(note[2]) / note[1], p) if note[1] > 0 else 0.0
			var last := phase
			phase = fmod(phase + pitch / MIX_RATE, 1.0)
			var sample := 0.0
			match wave:
				Wave.SINE:
					sample = sin(phase * TAU)
				Wave.SQUARE:
					sample = 1.0 if phase < 0.5 else -1.0
				Wave.TRIANGLE:
					sample = 4.0 * absf(phase - 0.5) - 1.0
				Wave.NOISE:
					if phase < last:
						noise = rng.randf_range(-1.0, 1.0)
					sample = noise
			var envelope: float = note[4] * (1.0 - note[5] * p) * minf(minf(i / edge, (count - i) / edge), 1.0)
			var value := clampi(int(sample * envelope * 32767.0), -32768, 32767)
			data.append(value & 0xff)
			data.append((value >> 8) & 0xff)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
