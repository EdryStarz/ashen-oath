extends SceneTree
## Run with a real render driver, not --headless:
## Godot --path . --script tools/render_world.gd -- --mode=hero
const World = preload("res://scripts/world.gd")

func _initialize() -> void:
	call_deferred("render_probe")

func render_probe() -> void:
	var mode := "camp"
	var high := "--high" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			mode = arg.trim_prefix("--mode=")
	root.size = Vector2i(864, 700)
	root.msaa_3d = Viewport.MSAA_4X
	var scene := World.new()
	root.add_child(scene)
	scene.set_quality(high)
	scene.set_hero(4, "ember_lantern", {"force": 1, "insight": 1, "craft": 1})
	scene.set_reduced_motion(true)
	scene.set_mode(mode, 2)
	await create_timer(2).timeout
	await RenderingServer.frame_post_draw
	var output := "res://artifacts/world_%s%s.png" % [mode, "_high" if high else ""]
	var result := root.get_texture().get_image().save_png(output)
	print("WORLD_RENDER ", mode, " saved=", result, " nodes=", root.get_child_count(), " primitives=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	if "--hold" in OS.get_cmdline_user_args():
		await create_timer(25).timeout
	quit(result)
