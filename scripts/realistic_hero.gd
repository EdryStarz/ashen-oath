extends RefCounted
## CC0 anatomy derivative in metres. Clothing/gear remains original to Iara.

func build(w) -> void:
	w.hero = Node3D.new()
	w.hero.name = "Iara"
	w.add_child(w.hero)
	w._mesh(w.hero, load("res://assets/models/iara/legs.obj"), Vector3.ZERO, "cloth")
	w._mesh(w.hero, load("res://assets/models/iara/boots.obj"), Vector3.ZERO, "dark_leather")
	w.hero_body = Node3D.new()
	w.hero_body.position.y = 0.96
	w.hero.add_child(w.hero_body)
	w._mesh(w.hero_body, load("res://assets/models/iara/torso.obj"), Vector3.ZERO, "cloth")
	w._mesh(w.hero_body, load("res://assets/models/iara/head.obj"), Vector3.ZERO, "skin")
	# Fitted leather cuirass, stitched seams, brass closures, asymmetric coat.
	var cuirass: MeshInstance3D = w._lathe(w.hero_body, Vector3.ZERO, [Vector2(0.17, 0.05), Vector2(0.16, 0.22), Vector2(0.18, 0.40), Vector2(0.23, 0.57), Vector2(0.13, 0.66)], "dark_leather", 40, 0.025)
	cuirass.scale.z = 0.94
	cuirass.position.z = 0.015
	for side in [-1.0, 1.0]:
		var panel := Node3D.new()
		panel.name = "CoatLeft" if side < 0 else "CoatRight"
		w.hero_body.add_child(panel)
		w.coat_panels.append(panel)
		w._coat_panel(panel, side, 0.76 if side < 0 else 0.58)
	for side in [-1.0, 1.0]:
		w._tube(w.hero_body, [Vector3(side * 0.06, 0.10, 0.14), Vector3(side * 0.13, 0.31, 0.16), Vector3(side * 0.20, 0.53, 0.10)], [0.003, 0.003, 0.003], "leather", 6)
		for i in range(5):
			w._ellipsoid(w.hero_body, Vector3(side * (0.08 + i * 0.025), 0.18 + i * 0.08, 0.15), Vector3(0.005, 0.005, 0.003), "bronze")
		w._ellipsoid(w.hero, Vector3(side * 0.235, 0.085, 0.085), Vector3(0.09, 0.08, 0.18), "dark_leather")
		w._ellipsoid(w.hero, Vector3(side * 0.235, 0.035, 0.09), Vector3(0.095, 0.035, 0.19), "coal")
		for y in [0.15, 0.31, 0.48]:
			w._lathe(w.hero, Vector3(side * 0.235, y, 0), [Vector2(0.066, 0), Vector2(0.065, 0.026)], "leather", 24)
	var belt: MeshInstance3D = w._lathe(w.hero_body, Vector3(0, 0.13, 0), [Vector2(0.182, 0), Vector2(0.185, 0.045)], "leather", 40)
	belt.scale.z = 0.78
	w._ellipsoid(w.hero_body, Vector3(0, 0.15, 0.156), Vector3(0.026, 0.022, 0.009), "bronze")
	w._tube(w.hero_body, [Vector3(-0.19, 0.57, 0.12), Vector3(-0.08, 0.34, 0.16), Vector3(0.16, 0.14, 0.13)], [0.020, 0.022, 0.020], "leather")
	for side in [-1.0, 1.0]:
		w._ellipsoid(w.hero_body, Vector3(side * 0.20, 0.12, 0.06), Vector3(0.052, 0.07, 0.045), "dark_leather")
	var hood := Node3D.new()
	hood.scale = Vector3.ONE * 0.82
	hood.position.z = 0.055
	w.hero_body.add_child(hood)
	w._build_hood(hood)
	w._build_mask(hood)
	w.left_arm = Node3D.new()
	w.left_arm.position = Vector3(-0.23, 0.57, 0)
	w.hero_body.add_child(w.left_arm)
	w._mesh(w.left_arm, load("res://assets/models/iara/arm_left.obj"), Vector3.ZERO, "ceramic")
	w.right_arm = Node3D.new()
	w.right_arm.position = Vector3(0.23, 0.57, 0)
	w.hero_body.add_child(w.right_arm)
	w._mesh(w.right_arm, load("res://assets/models/iara/arm_right.obj"), Vector3.ZERO, "cloth")
	for side in [-1.0, 1.0]:
		var arm: Node3D = w.right_arm if side > 0 else w.left_arm
		w._ellipsoid(arm, Vector3(0, -0.02, 0), Vector3(0.085, 0.075, 0.092), "dark_leather" if side > 0 else "ceramic")
		w._lathe(arm, Vector3(side * 0.045, -0.27, 0.04), [Vector2(0.055, 0), Vector2(0.045, 0.15)], "leather" if side > 0 else "bronze", 24)
		w._ellipsoid(arm, Vector3(side * 0.06, -0.42, 0.17), Vector3(0.032, 0.047, 0.037), "dark_leather" if side > 0 else "ceramic")
		for i in range(4):
			var z: float = 0.145 + i * 0.014
			w._tube(arm, [Vector3(side * 0.044, -0.43, z), Vector3(side * 0.075, -0.45, z + 0.007), Vector3(side * 0.08, -0.42, z + 0.02)], [0.008, 0.008, 0.006], "dark_leather" if side > 0 else "ceramic", 8)
	w.weapon = Node3D.new()
	w.weapon.position = Vector3(0.06, -0.44, 0.19)
	w.weapon.rotation.z = -0.10
	w.right_arm.add_child(w.weapon)
	w._build_weapon(false)
	w.weapon.scale = Vector3.ONE * 0.88
	w.mantle = Node3D.new()
	w.hero_body.add_child(w.mantle)
	w._cloth(w.mantle, [Vector3(-0.28, 0.47, -0.04), Vector3(-0.20, 0.63, -0.08), Vector3(0, 0.65, -0.13), Vector3(0.20, 0.57, -0.09), Vector3(0.26, 0.43, -0.04)], 0.91, "cloak", true)
	w._tube(w.mantle, [Vector3(-0.22, 0.52, 0.1), Vector3(-0.08, 0.47, 0.17), Vector3(0.12, 0.53, 0.1)], [0.007, 0.007, 0.007], "bronze")
	w.lantern = Node3D.new()
	w.lantern.position = Vector3(-0.26, -0.12, 0.05)
	w.hero_body.add_child(w.lantern)
	w._lathe(w.lantern, Vector3.ZERO, [Vector2(0.045, 0), Vector2(0.05, 0.03), Vector2(0.045, 0.14), Vector2(0.027, 0.16)], "bronze", 24)
	w._ellipsoid(w.lantern, Vector3(0, 0.08, 0.048), Vector3(0.03, 0.045, 0.012), "ember")
	var lantern_light := OmniLight3D.new()
	lantern_light.position = Vector3(0, 0.08, 0.08)
	lantern_light.light_color = Color("ffc17f")
	lantern_light.light_energy = 0.4
	lantern_light.omni_range = 1.3
	w.lantern.add_child(lantern_light)
