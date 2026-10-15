extends Node
## A small local audio pool. No state changes, network or microphone.
const IDS = ["camp", "hunt", "reward", "strike", "impact", "resonance", "victory"]
var streams: Dictionary = {}
var ambience: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var enabled := true
var gain := 0.6
var paused := false
var context := ""
var voice_index := 0

func _ready() -> void:
	for id in IDS:
		var stream: AudioStreamWAV = load("res://assets/audio/%s.wav" % id)
		if id in ["camp", "hunt"]:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
		streams[id] = stream
	ambience = AudioStreamPlayer.new()
	add_child(ambience)
	for i in range(4):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

func configure(settings: Dictionary, page: String) -> void:
	enabled = bool(settings.get("sound_enabled", true))
	gain = clampf(float(settings.get("sound_volume", 0.6)), 0.0, 1.0)
	var wanted := ""
	if enabled and gain > 0 and not settings.get("economy", false):
		if page in ["today", "hero"]: wanted = "camp"
		elif page == "hunt": wanted = "hunt"
	if wanted != context:
		ambience.stop()
		context = wanted
		if context != "":
			ambience.stream = streams[context]
			ambience.play()
	ambience.volume_db = linear_to_db(maxf(gain, 0.0001)) - 16.0
	ambience.stream_paused = paused
	if not enabled or gain == 0:
		for voice in voices: voice.stop()

func play_cue(id: String) -> void:
	if paused or not enabled or gain <= 0 or not streams.has(id): return
	var voice: AudioStreamPlayer = voices[voice_index % voices.size()]
	voice_index += 1
	voice.stream = streams[id]
	voice.volume_db = linear_to_db(gain) - 9.0
	voice.play()

func set_paused(value: bool) -> void:
	paused = value
	ambience.stream_paused = value
	# Old one-shots do not restart when returning from the background.
	if value:
		for voice in voices: voice.stop()

func _exit_tree() -> void:
	if is_instance_valid(ambience):
		ambience.stop()
		ambience.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null
	streams.clear()
