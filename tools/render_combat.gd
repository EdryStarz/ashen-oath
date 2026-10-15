extends SceneTree
## A resolved three-turn fixture, for inspecting effects in a real renderer.
const World = preload("res://scripts/world.gd")
const Sound = preload("res://scripts/soundscape.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(864, 700)
	var world := World.new()
	root.add_child(world)
	world.set_hero(3, "ash_hook", {"force": 1})
	world.set_mode("battle", 1)
	var sound := Sound.new()
	root.add_child(sound)
	sound.configure({}, "hunt")
	world.combat_cue.connect(sound.play_cue)
	await create_timer(0.5).timeout
	world.play_battle([
		{"turn": 1, "hero_damage": 8, "enemy_damage": 3, "hero_hp": 45, "enemy_hp": 30},
		{"turn": 2, "hero_damage": 8, "enemy_damage": 3, "hero_hp": 42, "enemy_hp": 22},
		{"turn": 3, "hero_damage": 10, "enemy_damage": 3, "hero_hp": 39, "enemy_hp": 12}
	], false)
	await create_timer(2.96).timeout
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://artifacts/combat-resonance.png")
	print("COMBAT_RENDER saved=", result)
	if "--hold" in OS.get_cmdline_user_args():
		await create_timer(25).timeout
	await create_timer(1.0).timeout
	world.queue_free()
	sound.queue_free()
	await create_timer(0.1).timeout
	quit(result)
