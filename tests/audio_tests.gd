extends SceneTree
const State = preload("res://scripts/game_state.gd")
const Sound = preload("res://scripts/soundscape.gd")
var failures := 0
var passed := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS AUDIO: ", label)
	else:
		failures += 1
		push_error("FAIL AUDIO: " + label)

func run() -> void:
	var game := State.new()
	var original: String = game.export_json()
	check(game.import_json(original).ok, "previous save without audio settings remains valid")
	check(game.set_settings({"sound_enabled": false, "sound_volume": 0.35}).ok, "audio preferences can be saved")
	var restored := State.new()
	check(restored.import_json(game.export_json()).ok and restored.data.settings.sound_volume == 0.35 and not restored.data.settings.sound_enabled, "audio preferences survive export/import")
	var before: String = game.export_json()
	check(not game.set_settings({"sound_enabled": true, "sound_volume": 2.0}).ok and game.export_json() == before, "invalid volume rolls back entire patch")
	var invalid: Dictionary = JSON.parse_string(original)
	invalid.settings.sound_volume = "loud"
	check(not game.import_json(JSON.stringify(invalid)).ok, "invalid imported audio preferences rejected")
	var sound := Sound.new()
	root.add_child(sound)
	sound.configure({}, "today")
	check(sound.streams.size() == 7 and sound.ambience.playing and sound.context == "camp", "seven real streams decode and camp loop starts")
	sound.play_cue("reward")
	check(sound.voices[0].playing, "reward cue plays through pool")
	sound.set_paused(true)
	check(sound.ambience.stream_paused and not sound.voices[0].playing, "background pauses loop and stops one-shots")
	var held: int = sound.voice_index
	sound.play_cue("impact")
	check(sound.voice_index == held, "background rejects new sound cues")
	sound.set_paused(false)
	sound.configure({"sound_enabled": false}, "hunt")
	sound.play_cue("victory")
	check(not sound.ambience.playing and sound.voice_index == held, "mute disables loop and all cues")
	sound.configure({"economy": true}, "today")
	check(sound.context == "" and not sound.ambience.playing, "economy mode avoids ambient playback")
	sound.configure({}, "journal")
	check(sound.context == "", "journal is quiet")
	sound.queue_free()
	await process_frame
	print("AUDIO_TEST_DONE passed=", passed, " failures=", failures)
	quit(failures)
