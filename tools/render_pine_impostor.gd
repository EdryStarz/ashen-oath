extends SceneTree
func _initialize():
 call_deferred("run")
func run():
 root.size = Vector2i(512,1024)
 root.transparent_bg = true
 var holder=Node3D.new()
 root.add_child(holder)
 var tree=load("res://assets/models/foliage/pine_sapling_small/model.gltf").instantiate()
 holder.add_child(tree)
 var nodes=tree.find_children("*","MeshInstance3D",true,false)
 # Match the single complete mesh already used in the world.
 for i in range(1,nodes.size()): nodes[i].visible=false
 var node=nodes[0]
 var box: AABB=node.global_transform * node.mesh.get_aabb()
 tree.scale*=6.0/box.size.y
 box=node.global_transform * node.mesh.get_aabb()
 tree.position-=Vector3(box.get_center().x,box.position.y,box.get_center().z)
 var light=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-48,-38,0)
 light.light_energy=0.7
 holder.add_child(light)
 var env=WorldEnvironment.new()
 env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR
 env.environment.background_color=Color(0,0,0,0)
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color("acbdaf")
 env.environment.ambient_light_energy=0.5
 holder.add_child(env)
 var camera=Camera3D.new()
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=7.0
 camera.position=Vector3(0,3,10)
 holder.add_child(camera)
 camera.look_at(Vector3(0,3,0))
 await create_timer(1).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://assets/models/foliage/pine_impostor.png")
 quit()
