extends SceneTree
const World = preload("res://scripts/pixel_world.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1152,768)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(384,256)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var w := World.new()
	viewport.add_child(w)
	w.set_hero(4,"ember_lantern",{"force":1})
	var mode := "hero"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
	w.set_mode(mode,0)
	w.set_reduced_motion(true)
	var display := TextureRect.new()
	display.texture = viewport.get_texture()
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	display.size = Vector2(1152,768)
	root.add_child(display)
	await create_timer(.7).timeout
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://artifacts/pixel_%s.png" % mode)
	print("PIXEL_RENDER ",mode," saved=",error)
	quit(error)
