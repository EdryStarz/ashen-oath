extends SceneTree
const World = preload("res://scripts/pixel_world.gd")
var failures := 0
var passed := 0
var completions := 0
var turns := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if value:
		passed += 1
		print("PASS ",message)
	else:
		failures += 1
		push_error(message)
func run() -> void:
	var w := World.new()
	root.add_child(w)
	check(w.backdrop != null and w.sheet != null, "pixel resources load")
	check(w.backdrop.get_size() == Vector2(384,256), "environment has the production pixel grid")
	check(w.sheet.get_size() == Vector2(576,256), "actor atlas has eight aligned frames")
	w.battle_finished.connect(func(): completions += 1)
	w.battle_turn.connect(func(_i,_h,_e): turns += 1)
	var rows := [{"turn":1,"hero_damage":12,"enemy_damage":3,"hero_hp":81,"enemy_hp":30},{"turn":2,"hero_damage":30,"enemy_damage":0,"hero_hp":81,"enemy_hp":0}]
	w.play_battle(rows,true)
	await create_timer(.1).timeout
	w.set_mode("hero")
	check(not w.battle_active and completions == 1, "navigation cancels a pending pixel attack once")
	await create_timer(.9).timeout
	check(completions == 1 and turns == 0, "stale presentation cannot emit turns or completion")
	w.set_reduced_motion(true)
	w.play_battle(rows,true)
	paused = true
	await create_timer(.4).timeout
	check(w.battle_active and turns == 0, "combat timers freeze while the application is paused")
	paused = false
	await create_timer(.9).timeout
	check(not w.battle_active and turns == 2 and completions == 2, "reduced-motion combat preserves committed turns")
	check(w.impact == 0 and w.hero_offset == 0, "reduced motion removes flashes and lunges")
	w.set_reduced_motion(false)
	w.play_battle(rows,false)
	await create_timer(2).timeout
	check(not w.battle_active and turns == 4 and completions == 3, "animated combat resolves exactly once")
	w.stop_battle()
	check(completions == 3, "idle stop is idempotent")
	w.set_hero(4,"ember_lantern",{"force":1})
	check(w.hero_level == 4 and w.hero_equipment == "ember_lantern", "equipment presentation consumes the current snapshot")
	w.set_mode("battle",2)
	check(w.enemy_index == 2, "hunt selection switches the enemy sprite")
	w.set_scene_active(false)
	var before := w.clock
	w._process(.5)
	check(w.clock == before, "hidden scene stops animation work")
	print("PIXEL_WORLD_TEST_DONE passed=",passed," failures=",failures)
	quit(failures)
