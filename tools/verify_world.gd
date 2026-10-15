extends SceneTree
## Presentation lifecycle regression test. Does not access GameState or user files.
const World = preload("res://scripts/world.gd")
var finished_count := 0
var failures := 0
var passed_count := 0
var turn_count := 0

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, label: String) -> void:
	if condition:
		passed_count += 1
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

func run() -> void:
	var world := World.new()
	root.add_child(world)
	expect(world.get_node("ForestFloor").mesh.get_surface_count() == 1, "terrain has an actual ground surface")
	expect(world.location_root.get_child_count() >= 68, "cartoon forest includes trees, rocks and bushes")
	expect(world.get_node_or_null("GroundCover") == null, "cartoon forest does not load old photographic ground cover")
	expect(world.location_profile == "low", "Android defaults to lightweight location")
	world.set_quality(true)
	expect(world.location_profile == "high", "quality setting loads detailed location")
	world.set_quality(false)
	await process_frame
	expect(world.location_profile == "low" and world.location_root.get_child_count() > 0, "quality setting restores lightweight location")
	expect(world.camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "realistic scene uses perspective depth")
	expect(world.materials.stone is ShaderMaterial, "stone uses the cartoon shader")
	expect(world.hero_skeleton.get_bone_count() == 19, "hero has an actual deformation skeleton")
	expect(world.foliage_scenes.is_empty(), "cartoon forest does not load photographic foliage")
	expect(world.hero_player.has_animation("idle") and world.hero_player.has_animation("strike") and world.hero_player.has_animation("hit"), "hero has three skeletal clips")
	world._process(0.5)
	expect(world.hero_player.is_playing(), "skeletal idle is running")
	world.set_reduced_motion(true)
	expect(not world.hero_player.is_playing() and is_equal_approx(world.hero_body.position.y, 0.96), "reduced motion freezes skeleton and resets breathing pose")
	world.set_reduced_motion(false)
	await process_frame
	await process_frame
	world.set_mode("hero")
	expect(world.right_arm.basis.is_equal_approx(world.right_hand_basis), "navigation preserves calibrated hand socket")
	world.set_scene_active(false)
	expect(not world.hero_player.active, "hidden scene disables skeletal mixer")
	world.set_scene_active(true)
	expect(world.hero_player.active, "visible scene restores skeletal mixer")
	world.battle_finished.connect(func(): finished_count += 1)
	world.battle_turn.connect(func(_index: int, _hero_hp: int, _enemy_hp: int): turn_count += 1)
	var log_rows := [{"turn": 1, "hero_damage": 14, "enemy_damage": 5}, {"turn": 2, "hero_damage": 16, "enemy_damage": 0}]
	world.play_battle(log_rows, true)
	await create_timer(0.08).timeout
	world.set_mode("hero")
	expect(not world.battle_active and not world.enemy.visible, "navigation immediately cancels battle presentation")
	expect(world.impact_effects.is_empty() and world.impact_tweens.is_empty(), "navigation clears all transient impacts")
	expect(finished_count == 1, "cancel emits completion once")
	await create_timer(1.4).timeout
	expect(finished_count == 1, "stale battle coroutine cannot emit completion again")
	world.set_reduced_motion(true)
	world.play_battle(log_rows, false)
	await create_timer(0.45).timeout
	expect(not world.battle_active and finished_count == 2, "reduced motion resolves presentation once")
	world.stop_battle()
	expect(finished_count == 2, "stopping idle scene is idempotent")
	world.set_hero(4, "ember_lantern", {"force": 2, "insight": 1})
	expect(world.mantle.visible and world.lantern.visible, "equipped upgrades change hero meshes")
	world.set_hero(1, "worn_blade", {})
	expect(not world.mantle.visible and not world.lantern.visible, "restoring base equipment removes extra meshes")
	world.set_mode("battle")
	world._show_impact({"turn": 3, "hero_damage": 8, "enemy_damage": 2}, 3)
	expect(world.impact_effects.is_empty(), "reduced motion suppresses floating damage and rings")
	world.set_reduced_motion(false)
	world.set_hero(3, "ash_hook", {})
	world._show_impact({"turn": 3, "hero_damage": 8, "enemy_damage": 2}, 3)
	expect(world.impact_effects.size() == 2 and "Резонанс" in world.impact_effects[0].get_child(0).text, "actual unlocked resonance and incoming damage have distinct markers")
	world.stop_battle()
	world.set_reduced_motion(false)
	world.play_battle(log_rows, true)
	await create_timer(3.5).timeout
	expect(not world.battle_active and finished_count == 3, "animated playback completes once")
	# SceneTreeTimer defaults to process_always=true. A battle must override this:
	# finishing while backgrounded could re-enable main's viewport via its signal.
	world.set_reduced_motion(true)
	world.play_battle(log_rows, true)
	await create_timer(0.05).timeout
	paused = true
	await create_timer(0.5, true).timeout
	expect(world.battle_active and finished_count == 3, "reduced-motion battle cannot finish while application is paused")
	paused = false
	await create_timer(0.4).timeout
	expect(not world.battle_active and finished_count == 4, "reduced-motion battle resumes and finishes once")
	world.set_reduced_motion(false)
	world.play_battle(log_rows, true)
	await create_timer(0.08).timeout
	var held_turn_count: int = turn_count
	var held_arm_rotation: Vector3 = world.right_arm.rotation
	paused = true
	await create_timer(1.35, true).timeout
	expect(world.battle_active and turn_count == held_turn_count and finished_count == 4, "animated turn timer freezes in background")
	expect(world.right_arm.rotation.is_equal_approx(held_arm_rotation), "battle tween also freezes in background")
	paused = false
	await create_timer(2.45).timeout
	# Both 1.2-second turns have now finished; the final 0.7-second fall remains.
	paused = true
	await create_timer(0.9, true).timeout
	expect(world.battle_active and finished_count == 4, "final battle resolution timer also freezes in background")
	paused = false
	await create_timer(0.85).timeout
	expect(not world.battle_active and finished_count == 5, "animated battle resumes without duplicate completion")
	world.queue_free()
	await process_frame
	print("WORLD_TEST_DONE passed=", passed_count, " failures=", failures)
	quit(failures)
