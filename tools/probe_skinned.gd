extends SceneTree
func _initialize():
 call_deferred("run")
func run():
 root.size = Vector2i(864, 900)
 root.msaa_3d = Viewport.MSAA_4X
 var world = load("res://scripts/world.gd").new()
 root.add_child(world)
 world.hero.visible = false
 var model = load("res://assets/models/iara_skinned/iara.glb").instantiate()
 model.scale = Vector3.ONE * 1.12
 world.add_child(model)
 for node in model.find_children("*", "AnimationPlayer", true, false):
  print("ANIMATIONS ", node.get_animation_list())
  for id in node.get_animation_list():
   if "idle" in id: node.play(id)
 for node in model.find_children("*", "Skeleton3D", true, false):
  for i in range(node.get_bone_count()): print("BONE ", node.get_bone_name(i))
 world.camera.position = Vector3(1.5, 1.8, 6.8)
 world.camera.fov = 23
 world.camera.look_at(Vector3(0,1,0))
 await create_timer(2).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/skinned-preview.png")
 quit()
