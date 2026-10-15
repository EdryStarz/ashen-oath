class_name CampWorld
extends Node3D
## Original cartoon camp and forest with CC0 creature anatomy.
## Presentation consumes a resolved battle log.
## It never rolls damage, changes game state, or grants rewards.

signal battle_finished
signal battle_turn(index: int, hero_hp: int, enemy_hp: int)
signal combat_cue(id: String)

var camera: Camera3D
var hero: Node3D
var enemy: Node3D
var hero_body: Node3D
var left_arm: Node3D
var right_arm: Node3D
var weapon: Node3D
var mantle: Node3D
var lantern: Node3D
var camp_upgrades: Node3D
var fire_light: OmniLight3D
var sun: DirectionalLight3D
var environment: Environment
var flame_material: ShaderMaterial
var materials: Dictionary = {}
var time_elapsed := 0.0
var reduced_motion := false
var high_quality := false
var location_root: Node3D
var location_profile := ""
var current_mode := "camp"
var enemy_index := 0
var hero_level := 1
var hero_equipment := "worn_blade"
var preparation: Dictionary = {}
var battle_active := false
var battle_generation := 0
var animation: Tween
var visual_rotation := 0.0
var noise := FastNoiseLite.new()
var impact_effects: Array[Node3D] = []
var impact_tweens: Array[Tween] = []
var foliage_scenes: Dictionary = {}
var coat_panels: Array[Node3D] = []
var hero_model: Node3D
var hero_skeleton: Skeleton3D
var hero_player: AnimationPlayer
var right_hand_basis := Basis.IDENTITY
var left_hand_basis := Basis.IDENTITY


func _ready() -> void:
	noise.seed = 7419
	noise.frequency = 1.9
	_build_materials()
	_build_cartoon_palette()
	_build_lighting()
	_build_camp()
	_build_hero()
	_build_enemy(0)
	set_hero(hero_level, hero_equipment, preparation)
	set_mode(current_mode, enemy_index)


func _build_materials() -> void:
	_material("ember", Color("ed8341"), 0.0, 0.45)
	materials["ember"].emission_enabled = true
	materials["ember"].emission = Color("ff722c")
	materials["ember"].emission_energy_multiplier = 0.7
	_material("spirit", Color("8dc4b4"), 0.0, 0.3)
	materials["spirit"].emission_enabled = true
	materials["spirit"].emission = Color("75cdb5")
	materials["spirit"].emission_energy_multiplier = 0.25
	flame_material = ShaderMaterial.new()
	flame_material.shader = load("res://assets/shaders/ember.gdshader")


func cartoon_material(color: Color, texture: Texture2D = null, _outline: bool = false, cutout: float = 0.0) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/cartoon.gdshader")
	mat.set_shader_parameter("base_color", color)
	mat.set_shader_parameter("use_detail", texture != null)
	if texture: mat.set_shader_parameter("detail_color", texture)
	mat.set_shader_parameter("cutout", cutout)
	return mat


func _build_cartoon_palette() -> void:
	var palette := {"stone":"858fba", "ground":"659953", "moss":"78b848", "wood":"925b39", "pine":"369b78", "far_pine":"408f83", "cloth":"ddae66", "canvas":"e8b96f", "cloak":"3f78ad", "leather":"b76b3f", "dark_leather":"485582", "skin":"f0bb8b", "ceramic":"a8e1dd", "bronze":"edbf50", "steel":"b5d5ec", "hair":"713f42", "monster":"8498be", "root":"ad7051", "bell":"71b6b1", "bone":"f2dfa7", "coal":"39415b"}
	for id in palette:
		materials[id] = cartoon_material(Color(palette[id]),null,id in ["stone","wood","canvas","cloth","cloak","leather","steel","root","bell","bone"])


func _material(id: String, color: Color, metallic: float, roughness: float,
		texture: Texture2D = null, normal: Texture2D = null) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if texture:
		mat.albedo_texture = texture
		mat.uv1_scale = Vector3(3, 3, 3)
	if normal:
		mat.normal_enabled = true
		mat.normal_texture = normal
		mat.normal_scale = 0.09
	materials[id] = mat


func _build_lighting() -> void:
	var world := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("59b9de")
	sky_mat.sky_horizon_color = Color("c4eeed")
	sky_mat.ground_horizon_color = Color("8d9a89")
	sky_mat.ground_bottom_color = Color("394238")
	sky.sky_material = sky_mat
	environment.sky = sky
	environment.background_color = Color("17262c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c4cec0")
	environment.ambient_light_energy = 0.35
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("83bab8")
	environment.fog_light_energy = 0.36
	environment.fog_density = 0.01
	environment.fog_sky_affect = 1.0
	world.environment = environment
	add_child(world)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 32.0
	camera.size = 4.0
	camera.near = 0.1
	camera.far = 55
	camera.position = Vector3(3.5, 3.0, 7.6)
	add_child(camera)
	camera.look_at(Vector3(0, 1.05, 0))
	camera.current = true
	sun = DirectionalLight3D.new()
	sun.light_color = Color("fff0d0")
	sun.light_energy = 0.4
	sun.rotation_degrees = Vector3(-48, -38, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 25
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-2, 3.5, -2)
	rim.light_color = Color("8fb9cf")
	rim.light_energy = 0.18
	rim.omni_range = 7
	add_child(rim)
	var face_fill := OmniLight3D.new()
	face_fill.position = Vector3(1.5, 2.8, 4)
	face_fill.light_color = Color("e9cfac")
	face_fill.light_energy = 0.16
	face_fill.omni_range = 6
	add_child(face_fill)


func _build_camp() -> void:
	_build_forest_floor()
	_load_location("low")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2181
	# Low tent, canvas tension and stakes avoid a geometrical triangle silhouette.
	var tent := Node3D.new()
	tent.position = Vector3(-2.0, 0, -0.8)
	tent.rotation.y = -0.35
	add_child(tent)
	_cloth(tent, [Vector3(-1.0, 0.12, 0.8), Vector3(-0.55, 0.74, 0.68), Vector3(0, 1.08, 0.53), Vector3(0.62, 0.64, 0.55), Vector3(0.94, 0.1, 0.55)], 1.45, "canvas")
	_tube(tent, [Vector3(0, 0, 0.6), Vector3(0, 1.17, 0.6)], [0.035, 0.035], "wood")
	_tube(tent, [Vector3(0, 1.08, 0.65), Vector3(0.35, 0.05, 1.3)], [0.009, 0.009], "leather", 6)
	_tent_rear_wall(tent)
	for side in [-1.0, 1.0]:
		for z in [-0.85, 0.65]:
			_tube(tent, [Vector3(side * 0.94, 0.13, z), Vector3(side * 1.28, 0.04, z + 0.12)], [0.008, 0.008], "leather", 6)
			_tube(tent, [Vector3(side * 1.28, -0.04, z + 0.12), Vector3(side * 1.28, 0.12, z + 0.12)], [0.017, 0.012], "wood", 6)
	# Hearth: ash, stones, blackened logs, a restrained animated flame.
	var hearth := Node3D.new()
	hearth.name = "Hearth"
	hearth.position = Vector3(1.35, 0, 0.7)
	add_child(hearth)
	_ellipsoid(hearth, Vector3(0, 0.01, 0), Vector3(0.64, 0.04, 0.52), "coal")
	for i in range(11):
		var angle := float(i) / 11.0 * TAU
		_rock(hearth, Vector3(cos(angle) * 0.54, 0.06, sin(angle) * 0.45), Vector3(0.15, 0.1, 0.13), "stone")
	for i in range(3):
		var angle := float(i) * 1.06
		_tube(hearth, [Vector3(-cos(angle) * 0.36, 0.12, -sin(angle) * 0.36), Vector3(cos(angle) * 0.36, 0.12, sin(angle) * 0.36)], [0.085, 0.065], "coal")
	for i in range(7):
		_ellipsoid(hearth, Vector3(rng.randf_range(-0.23, 0.23), 0.1, rng.randf_range(-0.23, 0.23)), Vector3(0.055, 0.025, 0.04), "ember")
	for i in range(3):
		var fire_quad := QuadMesh.new()
		fire_quad.size = Vector2(0.62, 0.78)
		var flame := _mesh(hearth, fire_quad, Vector3(0, 0.45, 0), "ember")
		flame.material_override = flame_material
		flame.rotation.y = i * PI / 3
	fire_light = OmniLight3D.new()
	fire_light.position = Vector3(1.35, 0.8, 0.7)
	fire_light.light_color = Color("ffa855")
	fire_light.light_energy = 0.45
	fire_light.omni_range = 5.0
	add_child(fire_light)
	# Restored camp objects are unlocked by level.
	camp_upgrades = Node3D.new()
	add_child(camp_upgrades)
	var rack := Node3D.new()
	rack.name = "Rack"
	rack.position = Vector3(1.7, 0, -1.4)
	camp_upgrades.add_child(rack)
	for x in [-0.4, 0.4]:
		_tube(rack, [Vector3(x, 0, 0), Vector3(x, 1.25, 0)], [0.045, 0.032], "wood")
	_tube(rack, [Vector3(-0.5, 1.05, 0), Vector3(0.5, 1.05, 0)], [0.035, 0.035], "wood")
	_cloth(rack, [Vector3(-0.3, 0.6, 0.05), Vector3(0, 0.56, 0.04), Vector3(0.3, 0.62, 0.05)], 0.47, "leather", true)
	var cairn := Node3D.new()
	cairn.name = "Cairn"
	cairn.position = Vector3(-2.4, 0, -1.75)
	camp_upgrades.add_child(cairn)
	for i in range(5):
		_rock(cairn, Vector3(0.03 * sin(i), 0.11 + i * 0.13, 0), Vector3(0.29 - i * 0.03, 0.09, 0.22 - i * 0.025), "stone")
	_ellipsoid(cairn, Vector3(0, 0.89, 0), Vector3(0.07, 0.1, 0.06), "spirit")


func _load_location(profile: String) -> void:
	if location_profile == profile: return
	if is_instance_valid(location_root):
		remove_child(location_root)
		location_root.queue_free()
	location_root = Node3D.new()
	location_root.name = "CartoonForest"
	add_child(location_root)
	location_profile = profile
	var rng := RandomNumberGenerator.new()
	rng.seed = 46193
	for i in range(42 if profile == "high" else 30):
		var x := rng.randf_range(-16,16)
		var z := rng.randf_range(-22,-5)
		var tree := Node3D.new()
		tree.position = Vector3(x,_forest_height(x,z),z)
		location_root.add_child(tree)
		var height := rng.randf_range(3.4,6.2)
		_tube(tree,[Vector3.ZERO,Vector3(0,height * 0.72,0)],[0.16,0.09],"wood",8)
		for layer in range(3):
			var radius := height * (0.23-float(layer)*0.035)
			_ellipsoid(tree,Vector3(0,height*(0.58+layer*0.14),0),Vector3(radius,height*0.22,radius*0.86),"pine" if i%3 else "moss")
	for i in range(14):
		var side := -1.0 if i%2==0 else 1.0
		var x := side*rng.randf_range(3.0,8.0)
		var z := rng.randf_range(-10,2)
		_rock(location_root,Vector3(x,_forest_height(x,z)+0.22,z),Vector3(rng.randf_range(0.4,0.8),rng.randf_range(0.3,0.6),0.5),"stone")
	for i in range(24):
		var side := -1.0 if i%2==0 else 1.0
		var x := side*rng.randf_range(2.5,7.5)
		var z := rng.randf_range(-12,3)
		_ellipsoid(location_root,Vector3(x,_forest_height(x,z)+0.22,z),Vector3(0.5,0.35,0.45),"moss")


func _tent_rear_wall(tent: Node3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := [Vector3(-0.9, 0.12, -0.9), Vector3(0, 1.03, -0.9), Vector3(0.9, 0.12, -0.9)]
	var uvs := [Vector2(0, 1), Vector2(0.5, 0), Vector2(1, 1)]
	for i in range(3):
		surface.set_uv(uvs[i])
		surface.add_vertex(points[i])
	surface.generate_normals()
	surface.generate_tangents()
	_mesh(tent, surface.commit(), Vector3.ZERO, "canvas")


func _forest_height(x: float, z: float) -> float:
	return (sin(x * 0.36) * cos(z * 0.24) * 0.3 + sin(z * 0.43) * 0.16) * smoothstep(3.7, 7.0, Vector2(x, z).length())


func _build_forest_floor() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 64
	var step := 80.0 / float(count)
	for z in range(count):
		for x in range(count):
			for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var px := -40.0 + float(x + corner.x) * step
				var pz := -40.0 + float(z + corner.y) * step
				surface.set_uv(Vector2(px, pz) * 0.5)
				surface.add_vertex(Vector3(px, _forest_height(px, pz) - 0.015, pz))
	surface.generate_normals()
	surface.generate_tangents()
	var floor := MeshInstance3D.new()
	floor.name = "ForestFloor"
	floor.mesh = surface.commit()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/cartoon_floor.gdshader")

	floor.material_override = mat
	add_child(floor)


func _build_hero() -> void:
	load("res://scripts/skinned_hero.gd").new().build(self)


func _build_weapon(upgraded: bool) -> void:
	for child in weapon.get_children():
		weapon.remove_child(child)
		child.queue_free()
	_tube(weapon, [Vector3(0, -0.65, 0), Vector3(0, 0.55, 0)], [0.027, 0.021], "wood")
	for y in [-0.25, -0.14, 0.01, 0.37]:
		_lathe(weapon, Vector3(0, y, 0), [Vector2(0.032, 0), Vector2(0.032, 0.035)], "bronze", 12)
	if upgraded:
		_tube(weapon, [Vector3(0, 0.45, 0), Vector3(-0.07, 0.7, 0), Vector3(-0.18, 0.84, 0), Vector3(-0.19, 0.99, 0), Vector3(-0.08, 1.10, 0)], [0.038, 0.044, 0.045, 0.025, 0.002], "bronze")
		_tube(weapon, [Vector3(0, 0.51, 0), Vector3(0.11, 0.8, 0), Vector3(0.10, 1.0, 0)], [0.038, 0.027, 0.002], "steel")
		_ellipsoid(weapon, Vector3(0, 0.55, 0.015), Vector3(0.05, 0.075, 0.036), "spirit")
	else:
		_tube(weapon, [Vector3(0, 0.43, 0), Vector3(-0.075, 0.61, 0), Vector3(-0.075, 0.88, 0)], [0.033, 0.032, 0.001], "steel")
		_tube(weapon, [Vector3(0, 0.43, 0), Vector3(0.07, 0.65, 0), Vector3(0.07, 0.88, 0)], [0.033, 0.025, 0.001], "steel")


func _coat_panel(parent: Node3D, side: float, length: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := 12
	var cols := 12
	for row in range(rows):
		for col in range(cols):
			for offset in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var u := float(col + offset.x) / cols
				var v := float(row + offset.y) / rows
				var angle := (u * 2.7 + 0.14) * side
				var radius := 0.235 + v * 0.105
				var p := Vector3(sin(angle) * radius, 0.12 - length * v, cos(angle) * radius * 0.7)
				p.z += sin(u * PI * 5 + v * 0.7) * v * 0.014
				p.y += sin(u * PI * 3) * v * v * 0.012
				st.set_uv(Vector2(u, v))
				st.add_vertex(p)
	st.generate_normals()
	_mesh(parent, st.commit(), Vector3.ZERO, "cloth")
	_tube(parent, [Vector3(side * 0.035, 0.12, 0.17), Vector3(side * 0.045, -length * 0.4, 0.2), Vector3(side * 0.06, 0.12 - length, 0.25)], [0.01, 0.01, 0.008], "leather", 8)


func _build_enemy(index: int) -> void:
	if is_instance_valid(enemy):
		remove_child(enemy)
		enemy.queue_free()
	enemy = Node3D.new()
	enemy.name = "Creature"
	add_child(enemy)
	match index:
		0:
			# Husk: hollow bone mask, stooping sinewy torso and split antler growth.
			var anatomy := Node3D.new()
			anatomy.position.y = 0.96
			anatomy.scale = Vector3(0.9, 0.9, 0.86)
			anatomy.rotation.x = 0.16
			enemy.add_child(anatomy)
			_mesh(anatomy, load("res://assets/models/iara/torso.obj"), Vector3.ZERO, "monster")
			for side in [-1.0, 1.0]:
				_tube(enemy, [Vector3(side * 0.13, 0.74, 0), Vector3(side * 0.2, 0.39, -0.13), Vector3(side * 0.18, 0.1, 0.12)], [0.13, 0.08, 0.042], "monster")
				_ellipsoid(enemy, Vector3(side * 0.18, 0.07, 0.18), Vector3(0.075, 0.065, 0.19), "root")
				_tube(enemy, [Vector3(side * 0.19, 1.34, 0), Vector3(side * 0.36, 0.94, 0.04), Vector3(side * 0.45, 0.55, 0.18)], [0.1, 0.055, 0.03], "monster")
				for digit in range(3):
					_tube(enemy, [Vector3(side * 0.44, 0.6, 0.18), Vector3(side * (0.41 + digit * 0.045), 0.41, 0.27)], [0.019, 0.002], "bone", 8)
				_tube(enemy, [Vector3(side * 0.10, 1.78, 0.06), Vector3(side * 0.24, 2.02, -0.03), Vector3(side * 0.29, 2.22, 0.06)], [0.05, 0.034, 0.002], "root")
				_tube(enemy, [Vector3(side * 0.22, 1.99, -0.03), Vector3(side * 0.44, 2.11, -0.1)], [0.028, 0.001], "root")
			_ellipsoid(enemy, Vector3(0, 1.66, 0.15), Vector3(0.15, 0.24, 0.16), "bone")
			_ellipsoid(enemy, Vector3(0, 1.66, 0.29), Vector3(0.085, 0.14, 0.025), "coal")
			_ellipsoid(enemy, Vector3(0, 1.72, 0.315), Vector3(0.04, 0.018, 0.013), "spirit")
			for i in range(5):
				_tube(enemy, [Vector3(-0.17, 1.29 - i * 0.09, 0.12), Vector3(0, 1.24 - i * 0.09, 0.2), Vector3(0.17, 1.29 - i * 0.09, 0.12)], [0.018, 0.017, 0.018], "bone")
		1:
			# Bellkeeper: patinated bell carapace hung above a long root-limbed body.
			_lathe(enemy, Vector3(0, 0.55, 0), [Vector2(0.44, 0), Vector2(0.48, 0.09), Vector2(0.37, 0.17), Vector2(0.25, 0.73), Vector2(0.18, 1.1), Vector2(0.01, 1.2)], "bell", 36)
			for side in [-1.0, 1.0]:
				_tube(enemy, [Vector3(side * 0.23, 0.62, 0), Vector3(side * 0.27, 0.1, 0.09), Vector3(side * 0.42, 0.05, 0.24)], [0.07, 0.045, 0.007], "root")
				_tube(enemy, [Vector3(side * 0.25, 1.33, 0), Vector3(side * 0.63, 0.79, 0.04), Vector3(side * 0.57, 0.22, 0.1)], [0.077, 0.055, 0.01], "root")
				_tube(enemy, [Vector3(side * 0.22, 1.31, 0.22), Vector3(side * 0.2, 0.92, 0.33), Vector3(side * 0.35, 0.66, 0.31)], [0.011, 0.012, 0.012], "bronze")
			_ellipsoid(enemy, Vector3(0, 1.29, 0.265), Vector3(0.11, 0.15, 0.022), "coal")
			_ellipsoid(enemy, Vector3(0, 1.3, 0.294), Vector3(0.06, 0.018, 0.015), "ember")
			_tube(enemy, [Vector3(-0.12, 1.69, 0), Vector3(-0.16, 1.92, 0), Vector3(0, 2.02, 0), Vector3(0.16, 1.92, 0), Vector3(0.12, 1.69, 0)], [0.028, 0.03, 0.03, 0.03, 0.028], "bronze")
		_:
			# Root-heart: broad multi-legged knot with exposed amber core and root crown.
			_rock(enemy, Vector3(0, 1.05, 0), Vector3(0.56, 0.67, 0.37), "root")
			for i in range(6):
				var a := float(i) / 6 * TAU
				_tube(enemy, [Vector3(cos(a) * 0.35, 0.84, sin(a) * 0.2), Vector3(cos(a) * 0.79, 0.45, sin(a) * 0.55), Vector3(cos(a) * 0.93, 0.03, sin(a) * 0.68)], [0.13, 0.095, 0.01], "root")
			for side in [-1.0, 1.0]:
				_tube(enemy, [Vector3(side * 0.35, 1.39, 0), Vector3(side * 0.69, 1.82, -0.07), Vector3(side * 0.48, 2.17, 0.04)], [0.13, 0.07, 0.002], "root")
				_tube(enemy, [Vector3(side * 0.64, 1.8, -0.04), Vector3(side * 0.86, 2.03, 0)], [0.047, 0.001], "root")
			_ellipsoid(enemy, Vector3(0, 1.17, 0.32), Vector3(0.23, 0.32, 0.09), "coal")
			_ellipsoid(enemy, Vector3(0, 1.18, 0.40), Vector3(0.125, 0.20, 0.065), "ember")
			for i in range(4):
				_tube(enemy, [Vector3(-0.32, 1.5 - i * 0.18, 0.27), Vector3(-0.06, 1.43 - i * 0.16, 0.49), Vector3(0.29, 1.52 - i * 0.18, 0.29)], [0.034, 0.022, 0.029], "root")
	enemy.position = Vector3(1.1, 0, -0.2)
	enemy.rotation.y = -0.5
	enemy.visible = current_mode == "battle"


func set_hero(level: int, equipment: String, prep: Dictionary) -> void:
	hero_level = level
	hero_equipment = equipment
	preparation = prep.duplicate()
	if not is_instance_valid(hero):
		return
	_build_weapon(equipment != "worn_blade")
	mantle.visible = equipment == "oath_mantle" or equipment == "ember_lantern"
	lantern.visible = equipment == "ember_lantern"
	camp_upgrades.get_node("Rack").visible = level >= 2
	camp_upgrades.get_node("Cairn").visible = level >= 4
	# Preparation is shown by small amber/ceramic flasks on the actual belt.
	var old := hero_body.get_node_or_null("Preparation")
	if old:
		hero_body.remove_child(old)
		old.queue_free()
	var flasks := Node3D.new()
	flasks.name = "Preparation"
	hero_body.add_child(flasks)
	var count := 0
	for value in prep.values():
		if value is int or value is float:
			count += int(value)
	for i in range(mini(count, 3)):
		_lathe(flasks, Vector3(0.12 - i * 0.075, 0.02, 0.17), [Vector2(0.025, 0), Vector2(0.029, 0.065), Vector2(0.015, 0.085), Vector2(0.015, 0.10)], "ceramic" if i % 2 == 0 else "bronze", 12)


func set_mode(mode: String, creature_index: int = 0) -> void:
	if battle_active:
		stop_battle()
	current_mode = mode
	if not is_instance_valid(hero):
		enemy_index = creature_index
		return
	if creature_index != enemy_index:
		enemy_index = creature_index
		_build_enemy(enemy_index)
	enemy.visible = mode == "battle"
	get_node("Hearth").visible = mode != "battle"
	fire_light.visible = mode != "battle"
	visual_rotation = 0.0
	hero.rotation = Vector3.ZERO
	hero_body.rotation = Vector3.ZERO
	right_arm.basis = right_hand_basis if hero_player else Basis.IDENTITY
	left_arm.basis = left_hand_basis if hero_player else Basis.IDENTITY
	enemy.rotation = Vector3(0, -0.5, 0)
	enemy.scale = Vector3.ONE
	enemy.position = Vector3(1.1, 0, -0.2)
	match mode:
		"hero":
			hero.position = Vector3(-0.2, 0, 0.45)
			camera.position = Vector3(1.5, 2.0, 7.7)
			camera.size = 2.82
			camera.fov = 25.0
			camera.look_at(Vector3(-0.15, 1.1, 0.45))
		"battle":
			hero.position = Vector3(-1.0, 0, 0.18)
			hero.rotation.y = 0.68
			camera.position = Vector3(1.2, 2.0, 8.3)
			camera.size = 3.9
			camera.fov = 32.0
			camera.look_at(Vector3(0, 1.02, 0))
		_:
			hero.position = Vector3(-0.6, 0, 0.3)
			hero.rotation.y = 0.12
			camera.position = Vector3(2.4, 2.35, 7.4)
			camera.size = 3.5
			camera.fov = 32.0
			camera.look_at(Vector3(0, 1.05, -0.5))


func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if hero_player:
		if value:
			hero_player.play("idle")
			hero_player.advance(0.0)
			hero_player.pause()
		elif not battle_active and not hero_player.is_playing(): hero_player.play("idle")
	if value:
		_clear_impacts()
		if is_instance_valid(hero_body): hero_body.position.y = 0.96
		if is_instance_valid(left_arm): left_arm.rotation.z = 0.0
		if is_instance_valid(mantle): mantle.rotation.x = 0.0
		for panel in coat_panels: panel.rotation = Vector3.ZERO
	if flame_material:
		flame_material.set_shader_parameter("motion", 0.0 if value else 1.0)


func set_quality(high: bool) -> void:
	high_quality = high
	_load_location("high" if high else "low")
	if sun:
		sun.shadow_enabled = true
		sun.directional_shadow_max_distance = 25.0 if high else 16.0
	# Depth fog has negligible overhead and keeps silhouette separation in both
	# quality presets; the economy mode disables the entire viewport in main.gd.


func _calibrate_gear() -> void:
	# Imported AnimationMixer applies bone transforms at the frame boundary.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree() or not is_instance_valid(right_arm): return
	right_hand_basis = right_arm.get_parent().global_basis.inverse() * hero.global_basis
	right_arm.basis = right_hand_basis
	left_hand_basis = left_arm.get_parent().global_basis.inverse() * hero.global_basis
	left_arm.basis = left_hand_basis


func _play_hero_hit(duration: float) -> void:
	if hero_player and not reduced_motion:
		hero_player.speed_scale = hero_player.get_animation("hit").length / maxf(duration, 0.05)
		hero_player.play("hit", 0.06)
		hero_player.queue("idle")


func set_scene_active(value: bool) -> void:
	if hero_player: hero_player.active = value


func rotate_hero(amount: float) -> void:
	if current_mode == "hero" and hero:
		visual_rotation += amount
		hero.rotation.y = visual_rotation


func stop_battle() -> void:
	battle_generation += 1
	_clear_impacts()
	var was_active := battle_active
	battle_active = false
	if hero_player and not reduced_motion:
		hero_player.speed_scale = 1.0
		hero_player.play("idle", 0.12)
	if animation and animation.is_valid():
		animation.kill()
	if is_instance_valid(hero):
		hero_body.rotation = Vector3.ZERO
		right_arm.basis = right_hand_basis if hero_player else Basis.IDENTITY
		left_arm.basis = left_hand_basis if hero_player else Basis.IDENTITY
	if was_active:
		battle_finished.emit()


func play_battle(log: Array, won: bool) -> void:
	stop_battle()
	set_mode("battle", enemy_index)
	battle_active = true
	battle_generation += 1
	var generation := battle_generation
	if reduced_motion or log.is_empty():
		await get_tree().create_timer(0.35, false).timeout
		if generation == battle_generation:
			if not log.is_empty() and log.back() is Dictionary:
				var final_turn: Dictionary = log.back()
				battle_turn.emit(int(final_turn.get("turn", log.size())), int(final_turn.get("hero_hp", 0)), int(final_turn.get("enemy_hp", 0)))
			battle_active = false
			battle_finished.emit()
		return
	var step := clampf(7.0 / maxf(log.size(), 1), 0.22, 1.2)
	var turn_index := 0
	for entry in log:
		if generation != battle_generation or not is_inside_tree():
			return
		# Damage values only determine which already-resolved impacts to show.
		var row: Dictionary = entry if entry is Dictionary else {}
		turn_index += 1
		combat_cue.emit("strike")
		if hero_player:
			hero_player.speed_scale = hero_player.get_animation("strike").length / step
			hero_player.play("strike", 0.08)
		animation = create_tween()
		animation.set_parallel(true)
		if not hero_player: animation.tween_property(right_arm, "rotation:z", -0.32, step * 0.23).set_trans(Tween.TRANS_SINE)
		animation.tween_property(hero_body, "rotation:y", -0.24, step * 0.23)
		animation.chain().set_parallel(true)
		if not hero_player: animation.tween_property(right_arm, "rotation:z", 0.42, step * 0.18)
		animation.tween_property(hero_body, "rotation:y", 0.35, step * 0.18)
		if float(row.get("hero_damage", 0)) > 0:
			animation.tween_property(enemy, "rotation:z", -0.13, step * 0.16)
		animation.chain().tween_callback(_show_impact.bind(row, turn_index))
		animation.chain().set_parallel(true)
		if not hero_player: animation.tween_property(right_arm, "rotation:z", 0.0, step * 0.21)
		animation.tween_property(hero_body, "rotation:y", 0.0, step * 0.21)
		animation.tween_property(enemy, "rotation:z", 0.0, step * 0.21)
		if float(row.get("enemy_damage", 0)) > 0:
			animation.tween_callback(_play_hero_hit.bind(step * 0.37))
			animation.tween_property(enemy, "position:x", 0.85, step * 0.15)
			animation.tween_property(hero_body, "rotation:z", 0.11, step * 0.16)
		animation.chain().set_parallel(true)
		animation.tween_property(enemy, "position:x", 1.1, step * 0.22)
		animation.tween_property(hero_body, "rotation:z", 0.0, step * 0.22)
		await get_tree().create_timer(step, false).timeout
	if generation != battle_generation:
		return
	animation = create_tween()
	if won:
		animation.tween_property(enemy, "rotation:z", -1.25, 0.6).set_trans(Tween.TRANS_SINE)
		animation.parallel().tween_property(enemy, "position:y", -0.20, 0.6)
	else:
		animation.tween_property(hero_body, "rotation:x", 0.23, 0.6)
	await get_tree().create_timer(0.7, false).timeout
	if generation == battle_generation:
		battle_active = false
		if hero_player and not reduced_motion:
			hero_player.speed_scale = 1.0
			hero_player.play("idle", 0.15)
		battle_finished.emit()


func _show_impact(row: Dictionary, fallback_turn: int) -> void:
	var turn := int(row.get("turn", fallback_turn))
	battle_turn.emit(turn, int(row.get("hero_hp", 0)), int(row.get("enemy_hp", 0)))
	var resonance := hero_level >= 3 and turn % 3 == 0
	combat_cue.emit("resonance" if resonance else "impact")
	if reduced_motion: return
	var damage := int(row.get("hero_damage", 0))
	if damage > 0:
		_impact_marker(enemy.position + Vector3(0, 1.4, 0), "−%d" % damage + (" · Резонанс" if resonance else ""), Color("8dc4b4") if resonance else Color("d1b480"), resonance)
	var incoming := int(row.get("enemy_damage", 0))
	if incoming > 0:
		_impact_marker(hero.position + Vector3(0, 1.55, 0), "−%d" % incoming, Color("c8a699"), false)


func _impact_marker(pos: Vector3, text: String, color: Color, resonance: bool) -> void:
	impact_effects = impact_effects.filter(func(node): return is_instance_valid(node))
	impact_tweens = impact_tweens.filter(func(tween): return tween.is_valid())
	# Cap transient geometry even if unusually long imported battle logs are used.
	if impact_effects.size() >= 6:
		var oldest: Node3D = impact_effects.pop_front()
		oldest.queue_free()
	var effect := Node3D.new()
	effect.position = pos
	add_child(effect)
	impact_effects.append(effect)
	var label := Label3D.new()
	label.text = text
	label.font = load("res://assets/fonts/NotoSans.ttf")
	label.font_size = 48 if resonance else 40
	label.pixel_size = 0.003
	label.modulate = color
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	effect.add_child(label)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.18 if resonance else 0.08
	torus.outer_radius = torus.inner_radius + 0.015
	torus.rings = 24
	torus.ring_segments = 8
	ring.mesh = torus
	ring.rotation.x = PI / 2
	ring.position.y = -0.27
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = material
	effect.add_child(ring)
	var tween := create_tween().set_parallel(true)
	impact_tweens.append(tween)
	tween.tween_property(effect, "position:y", pos.y + 0.16, 0.55)
	tween.tween_property(ring, "scale", Vector3.ONE * 1.8, 0.3)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.3)
	tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.25)
	tween.chain().tween_callback(effect.queue_free)


func _clear_impacts() -> void:
	for tween in impact_tweens:
		if tween.is_valid(): tween.kill()
	impact_tweens.clear()
	for effect in impact_effects:
		if is_instance_valid(effect): effect.queue_free()
	impact_effects.clear()


func _process(delta: float) -> void:
	if not visible or not is_instance_valid(hero_body):
		return
	time_elapsed += delta
	if reduced_motion:
		return
	if not battle_active:
		hero_body.position.y = 0.96 + sin(time_elapsed * 1.7) * 0.007
		left_arm.rotation.z = sin(time_elapsed * 1.7 + 0.2) * 0.012
		mantle.rotation.x = sin(time_elapsed * 0.85) * 0.018
	for i in range(coat_panels.size()):
		coat_panels[i].rotation.x = sin(time_elapsed * 1.1 + float(i) * 1.3) * 0.016
	if fire_light:
		fire_light.light_energy = 0.45 + sin(time_elapsed * 5.2) * 0.08 + sin(time_elapsed * 8.3) * 0.05
	if enemy.visible and not battle_active:
		enemy.position.y = sin(time_elapsed * 1.3) * 0.018


func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, material_id: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = materials[material_id]
	parent.add_child(instance)
	return instance


func _build_hood(parent: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile := [Vector2(0.15, 0.69), Vector2(0.205, 0.80), Vector2(0.20, 0.99), Vector2(0.15, 1.12), Vector2(0.015, 1.20)]
	for row in range(profile.size() - 1):
		for col in range(24):
			for offset in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var u := float(col + offset.x) / 24
				var ring: Vector2 = profile[row + offset.y]
				var angle := 0.70 + u * (TAU - 1.40)
				st.set_uv(Vector2(u, float(row + offset.y) / 4))
				st.add_vertex(Vector3(sin(angle) * ring.x, ring.y, cos(angle) * ring.x * 0.85 - 0.025))
	st.generate_normals()
	_mesh(parent, st.commit(), Vector3.ZERO, "cloak")
	_tube(parent, [Vector3(-0.095, 0.70, 0.07), Vector3(-0.135, 0.83, 0.115), Vector3(-0.135, 1.00, 0.112), Vector3(-0.09, 1.12, 0.079), Vector3(0, 1.17, 0.06), Vector3(0.09, 1.12, 0.079), Vector3(0.135, 1.0, 0.112), Vector3(0.135, 0.83, 0.115), Vector3(0.095, 0.7, 0.07)], [0.018, 0.02, 0.02, 0.025, 0.032, 0.025, 0.02, 0.02, 0.018], "dark_leather", 12)


func _build_mask(parent: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile := [Vector2(0.025, 0.78), Vector2(0.07, 0.82), Vector2(0.107, 0.91), Vector2(0.109, 1.01), Vector2(0.05, 1.085)]
	for row in range(profile.size() - 1):
		for col in range(16):
			for offset in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var u := float(col + offset.x) / 16
				var ring: Vector2 = profile[row + offset.y]
				var angle := (u - 0.5) * PI
				st.set_uv(Vector2(u, float(row + offset.y) / 4))
				st.add_vertex(Vector3(sin(angle) * ring.x, ring.y, 0.13 + cos(angle) * 0.052))
	st.generate_normals()
	_mesh(parent, st.commit(), Vector3.ZERO, "ceramic")
	for side in [-1.0, 1.0]:
		_ellipsoid(parent, Vector3(side * 0.048, 0.972, 0.18), Vector3(0.030, 0.009, 0.01), "coal")
		_ellipsoid(parent, Vector3(side * 0.048, 0.972, 0.19), Vector3(0.009, 0.004, 0.003), "spirit")
	_tube(parent, [Vector3(0, 1.08, 0.187), Vector3(0, 0.99, 0.187), Vector3(-0.018, 0.9, 0.183), Vector3(0, 0.8, 0.183)], [0.003, 0.003, 0.004, 0.002], "bronze", 8)


func _ellipsoid(parent: Node3D, pos: Vector3, size: Vector3, material_id: String) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	var instance := _mesh(parent, sphere, pos, material_id)
	instance.scale = size
	return instance


func _rock(parent: Node3D, pos: Vector3, size: Vector3, material_id: String) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := 10
	var cols := 16
	for row in range(rows):
		for col in range(cols):
			for offset in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var u := float(col + offset.x) / cols
				var v := float(row + offset.y) / rows
				var p := Vector3(sin(v * PI) * cos(u * TAU), cos(v * PI), sin(v * PI) * sin(u * TAU))
				p *= 1.0 + noise.get_noise_3dv(p * 2.7 + pos) * 0.23
				st.set_uv(Vector2(u, v))
				st.add_vertex(p)
	st.generate_normals()
	var instance := _mesh(parent, st.commit(), pos, material_id)
	instance.scale = size
	return instance


func _lathe(parent: Node3D, pos: Vector3, profile: Array, material_id: String, segments: int = 32, irregularity: float = 0.0) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(profile.size() - 1):
		for col in range(segments):
			for offset in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var ring: Vector2 = profile[row + offset.y]
				var u := float(col + offset.x) / segments
				var angle := u * TAU
				var radius := ring.x * (1.0 + irregularity * sin(angle * 5 + row * 2.0))
				st.set_uv(Vector2(u, float(row + offset.y) / (profile.size() - 1)))
				st.add_vertex(Vector3(cos(angle) * radius, ring.y, sin(angle) * radius))
	st.generate_normals()
	return _mesh(parent, st.commit(), pos, material_id)


func _tube(parent: Node3D, points: Array, radii: Array, material_id: String, segments: int = 12) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for i in range(points.size()):
		var point: Vector3 = points[i]
		var tangent: Vector3
		if i == 0:
			tangent = (points[1] - point).normalized()
		elif i == points.size() - 1:
			tangent = (point - points[i - 1]).normalized()
		else:
			tangent = (points[i + 1] - points[i - 1]).normalized()
		var reference := Vector3.RIGHT if absf(tangent.dot(Vector3.UP)) > 0.9 else Vector3.UP
		var axis_u := tangent.cross(reference).normalized()
		var axis_v := tangent.cross(axis_u).normalized()
		var ring: Array = []
		for j in range(segments + 1):
			var angle := float(j) / segments * TAU
			ring.append(point + (axis_u * cos(angle) + axis_v * sin(angle)) * float(radii[i]))
		rings.append(ring)
	for row in range(points.size() - 1):
		for col in range(segments):
			for offset in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				st.set_uv(Vector2(float(col + offset.x) / segments, float(row + offset.y) / (points.size() - 1)))
				st.add_vertex(rings[row + offset.y][col + offset.x])
	st.generate_normals()
	return _mesh(parent, st.commit(), Vector3.ZERO, material_id)


func _cloth(parent: Node3D, ridge: Array, length: float, material_id: String, down: bool = false) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var columns := (ridge.size() - 1) * 6
	var rows := 10
	for row in range(rows):
		for col in range(columns):
			for offset in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var u := float(col + offset.x) / columns
				var v := float(row + offset.y) / rows
				var index := mini(int(u * (ridge.size() - 1)), ridge.size() - 2)
				var fraction := u * (ridge.size() - 1) - index
				var p: Vector3 = ridge[index].lerp(ridge[index + 1], fraction)
				if down:
					p.y -= length * v
					p.z -= v * 0.13 + sin(u * PI * 6.0) * v * 0.028
					p.x *= 1.0 + v * 0.12
				else:
					p.z -= length * v
					p.y -= sin(v * PI) * 0.07
				p.y += sin(u * PI * 18.0 + v * 2.0) * sin(v * PI) * 0.012
				st.set_uv(Vector2(u, v))
				st.add_vertex(p)
	st.generate_normals()
	return _mesh(parent, st.commit(), Vector3.ZERO, material_id)
