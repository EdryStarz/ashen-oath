extends Node2D
## Original pixel presentation; consumes committed combat logs only.
signal battle_finished
signal battle_turn(index: int, hero_hp: int, enemy_hp: int)
signal combat_cue(id: String)
var current_mode := "camp"
var enemy_index := 0
var reduced_motion := false
var battle_active := false
var battle_generation := 0
var scene_active := true
var hero_level := 1
var hero_equipment := "worn_blade"
var preparation: Dictionary = {}
var high_quality := false
var clock := 0.0
var pose := 0
var hero_offset := 0.0
var enemy_offset := 0.0
var impact := 0.0
var damage_text := ""
var facing_left := false
var backdrop: Texture2D
var sheet: Texture2D
var font: Font

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backdrop = load("res://assets/pixel/camp.png")
	sheet = load("res://assets/pixel/actors.png")
	font = load("res://assets/fonts/NotoSans.ttf")
	queue_redraw()

func _process(delta: float) -> void:
	if not scene_active: return
	if not reduced_motion: clock += delta
	impact = maxf(0, impact - delta * 3)
	queue_redraw()

func set_hero(level: int, equipment: String, prep: Dictionary) -> void:
	hero_level = level
	hero_equipment = equipment
	preparation = prep.duplicate()
	queue_redraw()

func set_mode(mode: String, creature_index: int = 0) -> void:
	if battle_active: stop_battle()
	current_mode = mode
	enemy_index = clampi(creature_index, 0, 2)
	if mode != "battle": pose = 0
	queue_redraw()

func set_quality(value: bool) -> void: high_quality = value
func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value:
		hero_offset = 0
		enemy_offset = 0
		impact = 0
func set_scene_active(value: bool) -> void: scene_active = value
func rotate_hero(amount: float) -> void:
	if current_mode == "hero": facing_left = amount < 0

func stop_battle() -> void:
	battle_generation += 1
	var was_active := battle_active
	battle_active = false
	pose = 0
	hero_offset = 0
	enemy_offset = 0
	impact = 0
	damage_text = ""
	if was_active: battle_finished.emit()
	queue_redraw()

func play_battle(log_rows: Array, won: bool) -> void:
	stop_battle()
	current_mode = "battle"
	battle_active = true
	battle_generation += 1
	var generation := battle_generation
	var duration := 0.35 if reduced_motion else clampf(6.0 / maxf(log_rows.size(), 1), 0.25, 0.85)
	for i in range(log_rows.size()):
		if generation != battle_generation: return
		var row: Dictionary = log_rows[i] if log_rows[i] is Dictionary else {}
		pose = 1 if not reduced_motion else 0
		hero_offset = 14 if not reduced_motion else 0
		combat_cue.emit("strike")
		await get_tree().create_timer(duration * 0.4, false).timeout
		if generation != battle_generation: return
		pose = 2 if float(row.get("enemy_damage", 0)) > 0 and not reduced_motion else 0
		hero_offset = 0
		enemy_offset = 8 if not reduced_motion else 0
		impact = 1 if not reduced_motion else 0
		damage_text = str(row.get("hero_damage", 0))
		battle_turn.emit(int(row.get("turn", i+1)), int(row.get("hero_hp", 0)), int(row.get("enemy_hp", 0)))
		await get_tree().create_timer(duration * 0.6, false).timeout
		if generation != battle_generation: return
		enemy_offset = 0
		pose = 0
	if log_rows.is_empty(): await get_tree().create_timer(0.35, false).timeout
	if generation != battle_generation: return
	pose = 3 if won else 2
	battle_active = false
	battle_finished.emit()
	queue_redraw()

func _actor(cell: int, foot: Vector2, height: float, flip: bool = false) -> void:
	var bob := 0.0 if reduced_motion or battle_active else float(int(clock * 3) % 2)
	var rect := Rect2(foot.x - height * 0.5625, foot.y - height - bob, height * 1.125, height)
	if flip:
		rect.size.x *= -1
	var region := Rect2((cell % 4) * 144, floori(cell / 4.0) * 128, 144, 128)
	draw_texture_rect_region(sheet, rect, region)

func _draw() -> void:
	if not backdrop or not sheet: return
	var area := Vector2(get_viewport_rect().size)
	var scale_value := area.x / 384.0
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * scale_value)
	var height := area.y / scale_value
	draw_texture_rect(backdrop, Rect2(0, 0, 384, height), false, Color(1.08,1.16,1.24))
	var floor_y := height * 0.83
	var hero_x := 150.0 if current_mode != "battle" else 124.0
	var actor_height := minf(height * 0.58, 112) if current_mode == "hero" else minf(height * 0.5, 94)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * scale_value)
	draw_ellipse_shadow(Vector2(hero_x + hero_offset, floor_y), actor_height * 0.3)
	_actor(pose, Vector2(hero_x + hero_offset, floor_y), actor_height, facing_left and current_mode == "hero")
	if current_mode == "battle":
		draw_ellipse_shadow(Vector2(273 + enemy_offset, floor_y), 26)
		_actor(4 + enemy_index, Vector2(273 + enemy_offset, floor_y), actor_height * 1.15, true)
		if impact > 0:
			var origin := Vector2(259, floor_y - actor_height * 0.56)
			for i in range(8):
				var angle := i * TAU / 8
				draw_line(origin + Vector2.from_angle(angle)*6, origin + Vector2.from_angle(angle)* (12+impact*12), Color("fff2ad"), 2)
			draw_string(font, origin + Vector2(-4,-25), damage_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("fff2ad"))
	if hero_equipment == "ember_lantern":
		draw_rect(Rect2(hero_x-28, floor_y-38, 7, 10),Color("171b2e"))
		draw_rect(Rect2(hero_x-26, floor_y-36, 3, 5),Color("ffcb65"))
		draw_line(Vector2(hero_x-27,floor_y-40),Vector2(hero_x-23,floor_y-40),Color("ffcb65"),1)
	if hero_equipment == "oath_mantle":
		draw_rect(Rect2(hero_x-27, floor_y-61, 7, 30),Color("ed5682"))
	var flask_count := 0
	for value in preparation.values(): flask_count += int(value)
	for i in range(mini(3,flask_count)):
		draw_rect(Rect2(hero_x-11+i*6, floor_y-30,4,6),Color("93ebda"))
	if not reduced_motion:
		for i in range(7 if high_quality else 3):
			var t := fmod(clock * 14 + i * 7, 35)
			draw_rect(Rect2(298 + sin(float(i)*2+clock)*7, height*.68-t,2,2),Color("ffbf60"))

func draw_ellipse_shadow(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var a := i * TAU / 24
		points.append(center + Vector2(cos(a)*radius,sin(a)*radius*.23))
	draw_colored_polygon(points, Color("111627"))
