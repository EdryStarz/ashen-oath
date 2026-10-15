extends RefCounted
## Cartoon Sintel derivative with original rig and animations.

func build(w) -> void:
	w.hero = Node3D.new()
	w.hero.name = "Iara"
	w.add_child(w.hero)
	w.hero_body = Node3D.new()
	w.hero_body.position.y = 0.96
	w.hero.add_child(w.hero_body)
	w.hero_model = load("res://assets/models/iara_skinned/iara.glb").instantiate()
	w.hero_model.position.y = -0.96
	w.hero_model.scale = Vector3.ONE * 1.12
	w.hero_body.add_child(w.hero_model)
	w.hero_skeleton = w.hero_model.find_children("*", "Skeleton3D", true, false)[0]
	w.hero_player = w.hero_model.find_children("*", "AnimationPlayer", true, false)[0]
	w.hero_player.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
	w.hero_player.play("idle")
	w.hero_player.advance(0.0)
	for node in w.hero_model.find_children("*", "MeshInstance3D", true, false):
		for index in range(node.mesh.get_surface_count()):
			var source: Material = node.mesh.surface_get_material(index)
			if not source is StandardMaterial3D: continue
			var tint: Color = source.albedo_color
			var id := source.resource_name.to_lower()
			if "woven" in id: tint = Color("365d89")
			elif "jerkin" in id: tint = Color("387e8e")
			elif "boots" in id: tint = Color("81533d")
			var mat = w.cartoon_material(tint)
			node.set_surface_override_material(index, mat)
	# Gear sockets follow the skin's real hand bones, including the attack clip.
	for side in ["L", "R"]:
		var socket := BoneAttachment3D.new()
		socket.bone_name = "hand." + side
		w.hero_skeleton.add_child(socket)
		var arm := Node3D.new()
		socket.add_child(arm)
		var index: int = w.hero_skeleton.find_bone(socket.bone_name)
		arm.basis = (w.hero_skeleton.global_basis * w.hero_skeleton.get_bone_global_pose(index).basis).inverse() * w.hero.global_basis
		if side == "R": w.right_arm = arm
		else: w.left_arm = arm
	w.weapon = Node3D.new()
	w.right_arm.add_child(w.weapon)
	w.weapon.position = Vector3(0.015, 0.12, 0.035)
	w.weapon.scale = Vector3.ONE * 0.85
	w._build_weapon(false)
	w.call_deferred("_calibrate_gear")
	w.mantle = Node3D.new()
	w.hero_body.add_child(w.mantle)
	w._cloth(w.mantle, [Vector3(-0.2, 0.49, -0.10), Vector3(-0.1, 0.59, -0.12), Vector3(0, 0.6, -0.14), Vector3(0.16, 0.49, -0.10)], 0.95, "cloak", true)
	w.lantern = Node3D.new()
	w.lantern.position = Vector3(-0.17, 0.08, 0.13)
	w.hero_body.add_child(w.lantern)
	w._lathe(w.lantern, Vector3.ZERO, [Vector2(0.035, 0), Vector2(0.042, 0.02), Vector2(0.035, 0.12)], "bronze", 20)
	w._ellipsoid(w.lantern, Vector3(0, 0.065, 0.038), Vector3(0.022, 0.036, 0.01), "ember")
