extends SceneTree

const State = preload("res://scripts/game_state.gd")
var passed: int = 0
var failed: int = 0
var epoch: int = Time.get_unix_time_from_datetime_string("2026-10-05T10:00:00")
var save_path: String = "user://core_tests_save.json"

func _initialize() -> void:
	_test_rewards_and_undo()
	_test_schedules()
	_test_dates()
	_test_battle()
	_test_abilities()
	_test_persistence()
	_test_imports_and_rollback()
	print("CORE TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func expect(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + label)
	else:
		failed += 1
		push_error("FAIL: " + label)

func fresh() -> GameState:
	var state: GameState = State.new()
	state.configure_clock(epoch, 180)
	return state

func add(state: GameState, title: String = "Прогулка", branch: String = "force", schedule: Dictionary = {"type": "daily"}) -> String:
	var result: Dictionary = state.add_habit(title, branch, "Две минуты", schedule)
	expect(bool(result.ok), "create habit: " + title)
	return str(result.get("id", ""))

func _test_rewards_and_undo() -> void:
	var state: GameState = fresh()
	var id: String = add(state)
	expect(int(state.data.xp) == 0 and state.stats().visual_stage == 0, "opening gives no rewards")
	var completion: Dictionary = state.complete_habit(id)
	expect(bool(completion.ok) and int(state.data.xp) == 20, "full completion grants 20 XP")
	expect(str(state.data.equipped) == "ash_hook" and state.stats().visual_stage == 1, "first action visibly equips new weapon")
	expect(not bool(state.complete_habit(id).ok) and int(state.data.xp) == 20, "double tap cannot duplicate reward")
	expect(bool(state.undo_completion(id).ok) and int(state.data.xp) == 0 and str(state.data.equipped) == "worn_blade", "undo reverses XP and unearned equipment")
	expect(not bool(state.undo_completion(id).ok), "second undo is rejected")
	expect(bool(state.complete_habit(id, true).ok) and int(state.data.xp) == 20, "redo restores original award and slot")
	var ids: Array[String] = [id]
	for i: int in range(1, 7):
		ids.append(add(state, "Действие %d" % i, "insight"))
		state.complete_habit(ids[i])
	expect(int(state.data.xp) == 75, "daily reward ceiling: 20+20+20+5+5+5+0 = 75")
	expect(int(state.data.resources) == 3, "only first three actions grant supplies")
	expect(int(state.stats().prep.force) + int(state.stats().prep.insight) == 6, "only first six actions grant prep")
	state.undo_completion(ids[1])
	var eighth: String = add(state, "Восьмая")
	var eighth_result: Dictionary = state.complete_habit(eighth)
	expect(int(eighth_result.reward.xp) == 0, "undo cannot reopen high reward slots")
	var minimum_state: GameState = fresh()
	var minimum_id: String = add(minimum_state)
	expect(int(minimum_state.complete_habit(minimum_id, true).reward.xp) == 10, "minimum action earns half XP")
	expect(bool(minimum_state.edit_habit(minimum_id, {"title": "Чтение", "branch": "craft"}).ok), "habit editable after completion")
	expect(str(minimum_state.data.events[0].title) == "Прогулка" and str(minimum_state.data.events[0].branch) == "force", "history keeps original title and branch")
	expect(not bool(minimum_state.complete_habit(minimum_id).ok), "editing cannot repeat a completed habit")

func _test_schedules() -> void:
	var state: GameState = fresh()
	var weekdays: String = add(state, "Пн и Ср", "force", {"type": "weekdays", "days": [1, 3]})
	expect(bool(state.complete_habit(weekdays).ok), "Monday weekday schedule is due")
	state.configure_clock(epoch + 86400, 180)
	expect(not bool(state.complete_habit(weekdays).ok), "Tuesday weekday schedule is not due")
	state.configure_clock(epoch + 2 * 86400, 180)
	expect(bool(state.complete_habit(weekdays).ok), "Wednesday schedule is due")
	var weekly: String = add(state, "Дважды в неделю", "craft", {"type": "weekly", "count": 2})
	expect(bool(state.complete_habit(weekly).ok), "weekly target first action")
	state.configure_clock(epoch + 3 * 86400, 180)
	expect(bool(state.complete_habit(weekly).ok), "weekly target second action")
	state.configure_clock(epoch + 4 * 86400, 180)
	expect(not bool(state.complete_habit(weekly).ok), "weekly target stops at N")
	state.configure_clock(epoch + 7 * 86400, 180)
	expect(bool(state.complete_habit(weekly).ok), "weekly counter resets on Monday")
	state.pause_habit(weekdays, true)
	expect(not bool(state.complete_habit(weekdays).ok), "paused action cannot earn")
	state.pause_habit(weekdays, false)
	state.plan_rest()
	var xp_before: int = int(state.data.xp)
	expect(not bool(state.complete_habit(weekdays).ok) and int(state.data.xp) == xp_before, "planned rest preserves progress without XP")
	state.plan_rest()
	expect(bool(state.complete_habit(weekdays).ok), "rest can be cancelled")
	expect(not bool(state.add_habit("Bad", "force", "", {"type": "weekly", "count": 0}).ok), "invalid weekly target rejected")
	expect(not bool(state.add_habit("Bad", "force", "", {"type": "weekdays", "days": [8]}).ok), "invalid weekday rejected")

func _test_dates() -> void:
	var state: GameState = fresh()
	state.configure_clock(Time.get_unix_time_from_datetime_string("2026-10-05T00:59:59"), 180)
	var id: String = add(state)
	expect(state.today() == "2026-10-04", "04:00 local boundary: 03:59 belongs to yesterday")
	state.complete_habit(id)
	state.configure_clock(Time.get_unix_time_from_datetime_string("2026-10-05T01:00:00"), 180)
	expect(state.today() == "2026-10-05" and bool(state.complete_habit(id).ok), "new logical day at 04:00")
	state.configure_clock(Time.get_unix_time_from_datetime_string("2026-10-04T10:00:00"), 180)
	expect(state.today() == "2026-10-05" and not bool(state.complete_habit(id).ok), "backwards clock never reopens reward day")
	var travel: GameState = fresh()
	travel.configure_clock(Time.get_unix_time_from_datetime_string("2026-10-05T23:30:00"), 180)
	var travel_id: String = add(travel)
	travel.complete_habit(travel_id)
	travel.configure_clock(Time.get_unix_time_from_datetime_string("2026-10-05T23:30:00"), 360)
	expect(travel.today() == "2026-10-05" and not bool(travel.complete_habit(travel_id).ok), "timezone travel does not manufacture an extra day")
	travel.configure_clock(Time.get_unix_time_from_datetime_string("2026-10-06T22:00:00"), 360)
	expect(travel.today() == "2026-10-07" and bool(travel.complete_habit(travel_id).ok), "timezone day resumes at next local boundary")
	var dst: GameState = fresh()
	dst.configure_clock(Time.get_unix_time_from_datetime_string("2026-10-25T00:30:00"), 120)
	var dst_id: String = add(dst)
	dst.complete_habit(dst_id)
	dst.configure_clock(Time.get_unix_time_from_datetime_string("2026-10-25T01:30:00"), 60)
	expect(not bool(dst.complete_habit(dst_id).ok), "DST repeated hour cannot duplicate completion")
	dst.configure_clock(Time.get_unix_time_from_datetime_string("2026-10-25T03:00:00"), 60)
	expect(bool(dst.complete_habit(dst_id).ok), "DST new 04:00 boundary accepts next day")
	var boundary_state: GameState = fresh()
	var boundary_id: String = add(boundary_state)
	boundary_state.complete_habit(boundary_id)
	boundary_state.set_boundary(18)
	expect(not bool(boundary_state.complete_habit(boundary_id).ok), "changing boundary cannot reissue today's reward")
	expect(not bool(boundary_state.set_boundary(24).ok), "invalid boundary rejected")

func _test_battle() -> void:
	var state: GameState = fresh()
	expect(not bool(state.start_hunt("husk").ok), "hunt requires a real action")
	var id: String = add(state)
	state.complete_habit(id)
	var snapshot: String = state.export_json()
	var battle: Dictionary = state.start_hunt("husk", "balanced").battle
	expect(bool(battle.victory) and int(battle.xp) == 20, "first action and hook win the first hunt")
	expect(battle.turns.size() > 1 and int(battle.hero_snapshot.prep_used.force) == 1, "battle has actual turns and used preparation")
	var earned: int = int(state.data.xp)
	var event_count: int = state.data.events.size()
	var replay: Dictionary = state.start_hunt("husk", "aggressive").battle
	expect(bool(replay.replay) and int(replay.xp) == 0 and int(state.data.xp) == earned and state.data.events.size() == event_count, "battle replay cannot reward or spend again")
	expect(replay.turns == battle.turns, "replay shows saved result, not new tactic")
	expect(not bool(state.start_hunt("bellkeeper").ok), "new hunt requires fresh preparation; replay needs none")
	expect(not bool(state.undo_completion(id).ok), "cannot undo completion causally used in battle")
	var duplicate: GameState = fresh()
	expect(bool(duplicate.import_json(snapshot).ok), "battle input snapshot imports")
	var second: Dictionary = duplicate.start_hunt("husk", "balanced").battle
	expect(second.turns == battle.turns, "identical stats and tactic give deterministic battle")
	var weaker: GameState = fresh()
	weaker.import_json(snapshot)
	weaker.equip("worn_blade")
	var weak_battle: Dictionary = weaker.start_hunt("husk", "balanced").battle
	expect(not bool(weak_battle.victory) and weak_battle.turns != battle.turns, "equipment changes the outcome")
	var guarded: GameState = fresh()
	guarded.import_json(snapshot)
	var guarded_battle: Dictionary = guarded.start_hunt("husk", "guarded").battle
	expect(guarded_battle.turns != battle.turns, "tactic changes combat log")
	expect(not bool(state.start_hunt("root_heart").ok), "contract chain locks boss")
	var ids: Array[String] = [id, add(state, "Чтение", "insight"), add(state, "Порядок", "craft")]
	for day: int in range(1, 31):
		state.configure_clock(epoch + day * 86400, 180)
		for habit_id: String in ids:
			state.complete_habit(habit_id)
	var bell: Dictionary = state.start_hunt("bellkeeper", "guarded").battle
	expect(bool(bell.victory) and state.data.inventory.has("oath_mantle"), "consistent three habits unlock second contract equipment")
	state.equip("oath_mantle")
	var boss: Dictionary = state.start_hunt("root_heart", "guarded").battle
	expect(bool(boss.victory) and state.data.inventory.has("ember_lantern") and int(state.stats().visual_stage) == 3, "month of three habits can finish prototype contract chain")
	expect(bool(fresh().import_json(state.export_json()).ok), "full campaign export imports consistently")

func cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp", ".damaged"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(save_path + suffix)

func ability_ids(state: GameState) -> Array:
	var result: Array = []
	for ability: Dictionary in state.stats().abilities:
		result.append(ability.id)
	return result

func _test_abilities() -> void:
	var state: GameState = fresh()
	var ids: Array[String] = [add(state, "Тренировка", "force"), add(state, "Учёба", "insight"), add(state, "Дом", "craft")]
	expect(ability_ids(state).is_empty(), "no passive abilities are given on opening")
	for day: int in range(3):
		state.configure_clock(epoch + day * 86400, 180)
		for id: String in ids:
			state.complete_habit(id)
	expect(ability_ids(state) == ["resonance"], "level 3 unlocks named Resonance ability")
	var battle: Dictionary = state.start_hunt("husk", "balanced").battle
	var base_damage: int = int(battle.hero_snapshot.attack) + 2 * int(battle.hero_snapshot.prep_used.force) - 2
	var insight: int = int(battle.hero_snapshot.prep_used.insight)
	expect(int(battle.turns[2].hero_damage) == base_damage + insight + 2, "Resonance adds 2 actual damage on third strike")
	expect(str(battle.hero_snapshot.abilities[0].id) == "resonance", "battle snapshot records the unlocked ability")
	var replay: Dictionary = state.start_hunt("husk").battle
	expect(replay.turns == battle.turns and replay.hero_snapshot.abilities == battle.hero_snapshot.abilities, "replay preserves passive ability snapshot and original damage")
	for day: int in range(3, 6):
		state.configure_clock(epoch + day * 86400, 180)
		for id: String in ids:
			state.complete_habit(id)
	expect(ability_ids(state) == ["resonance", "ceramic_guard"], "level 5 unlocks Ceramic Guard")
	var bell: Dictionary = state.start_hunt("bellkeeper", "balanced").battle
	var unreduced: int = 25 - int(bell.hero_snapshot.defense) - 2 * int(bell.hero_snapshot.prep_used.insight)
	expect(int(bell.turns[0].enemy_damage) == maxi(1, unreduced - 2), "Ceramic Guard reduces actual incoming damage by 2")
	for day: int in range(6, 15):
		state.configure_clock(epoch + day * 86400, 180)
		for id: String in ids:
			state.complete_habit(id)
	expect(ability_ids(state) == ["resonance", "ceramic_guard", "steady_breath"], "level 8 unlocks Steady Breath")
	var stats: Dictionary = state.stats()
	expect(int(stats.hp) == 84 + 8 * (int(stats.level) - 1) + 8, "Steady Breath adds 8 permanent HP")
	state.configure_clock(epoch + 60 * 86400, 180)
	expect(ability_ids(state).size() == 3 and state.stats().hp == stats.hp, "missed days never remove unlocked abilities")
	# Existing schema-1 battle snapshots predate abilities; do not recalculate them.
	var legacy: Dictionary = state.data.duplicate(true)
	for old: Dictionary in legacy.battles:
		old.hero_snapshot.erase("abilities")
	var restored: GameState = fresh()
	expect(bool(restored.import_json(JSON.stringify(legacy)).ok), "legacy snapshots without abilities remain importable")
	var legacy_turns: Array = restored.start_hunt("husk").battle.turns
	var same_turns: bool = legacy_turns.size() == battle.turns.size()
	for i: int in range(mini(legacy_turns.size(), battle.turns.size())):
		for key: String in ["turn", "hero_hp", "enemy_hp", "hero_damage", "enemy_damage"]:
			same_turns = same_turns and int(legacy_turns[i][key]) == int(battle.turns[i][key])
		same_turns = same_turns and str(legacy_turns[i].text) == str(battle.turns[i].text)
	expect(same_turns, "legacy replay keeps exact saved damage")
	var threshold: GameState = fresh()
	var threshold_ids: Array[String] = [add(threshold, "A"), add(threshold, "B"), add(threshold, "C")]
	for day: int in range(2):
		threshold.configure_clock(epoch + day * 86400, 180)
		for id: String in threshold_ids:
			threshold.complete_habit(id)
	threshold.configure_clock(epoch + 2 * 86400, 180)
	threshold.complete_habit(threshold_ids[0])
	expect(ability_ids(threshold) == ["resonance"], "crossing level threshold opens ability immediately")
	threshold.undo_completion(threshold_ids[0])
	expect(ability_ids(threshold).is_empty(), "undo before hunt reverses an unearned level ability")

func _test_persistence() -> void:
	cleanup()
	var state: GameState = fresh()
	expect(bool(state.load_game(save_path).ok), "new offline save initializes")
	var id: String = add(state)
	state.complete_habit(id)
	state.set_settings({"economy": true, "text_scale": 1.2})
	var restarted: GameState = fresh()
	expect(bool(restarted.load_game(save_path).ok), "save reloads after restart")
	expect(int(restarted.data.xp) == 20 and str(restarted.data.equipped) == "ash_hook" and bool(restarted.data.settings.economy), "XP, equipment and settings survive restart")
	expect(not bool(restarted.complete_habit(id).ok), "restart cannot duplicate today's reward")
	restarted.start_hunt("husk", "balanced")
	var post_battle: GameState = fresh()
	post_battle.load_game(save_path)
	var earned: int = int(post_battle.data.xp)
	expect(bool(post_battle.start_hunt("husk").battle.replay) and int(post_battle.data.xp) == earned, "reward committed before animation survives restart")
	# Ensure backup contains final state, then simulate corruption of main file.
	post_battle.save_game()
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string("{ interrupted")
	file.close()
	var recovered: GameState = fresh()
	var result: Dictionary = recovered.load_game(save_path)
	expect(bool(result.ok) and recovered.recovered_backup and int(recovered.data.xp) == earned, "corrupt main recovers valid backup")
	expect(bool(recovered.save_game().ok), "recovered state can be saved again")
	# Simulate interruption between main->bak and temp->main.
	DirAccess.remove_absolute(save_path)
	var missing_main: GameState = fresh()
	expect(bool(missing_main.load_game(save_path).ok) and missing_main.recovered_backup, "missing main recovers backup after interrupted rename")
	cleanup()

func _test_imports_and_rollback() -> void:
	var state: GameState = fresh()
	var id: String = add(state)
	state.complete_habit(id)
	var original: String = state.export_json()
	expect(not bool(state.import_json("not json").ok) and state.export_json() == original, "malformed import does not change current game")
	var corrupt: Dictionary = state.data.duplicate(true)
	corrupt.xp = 999
	expect(not bool(state.import_json(JSON.stringify(corrupt)).ok), "import rejects reward mismatch")
	corrupt = state.data.duplicate(true)
	corrupt.events.append(corrupt.events[0].duplicate(true))
	expect(not bool(state.import_json(JSON.stringify(corrupt)).ok), "import rejects duplicate events")
	corrupt = state.data.duplicate(true)
	corrupt.habits[0].schedule = {"type": "weekly", "count": {}}
	expect(not bool(state.import_json(JSON.stringify(corrupt)).ok), "malformed nested schedule rejected safely")
	corrupt = state.data.duplicate(true)
	corrupt.settings.text_scale = "large"
	expect(not bool(state.import_json(JSON.stringify(corrupt)).ok), "bad settings import rejected")
	var failure: GameState = fresh()
	failure.load_game("user://a_missing_core_test_directory/save.json")
	var before: String = failure.export_json()
	expect(not bool(failure.add_habit("Cannot save").ok) and failure.export_json() == before, "failed durable write rolls back transaction")
	expect(bool(state.set_settings({"reduced_motion": true, "high_quality": true, "auto_timezone": false}).ok), "accessibility settings transaction")
	expect(not bool(state.set_settings({"text_scale": 9}).ok), "out of range text size rejected")
	cleanup()
	var bad_file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	bad_file.store_string("interrupted")
	bad_file.close()
	var broken: GameState = fresh()
	expect(not bool(broken.load_game(save_path).ok), "only corrupt copy reports failure")
	expect(not bool(broken.add_habit("Must not silently lose changes").ok), "failed load blocks unsaved progress")
	expect(bool(broken.import_json(original).ok), "explicit import repairs failed load durably")
	var repaired: GameState = fresh()
	expect(bool(repaired.load_game(save_path).ok) and int(repaired.data.xp) == 20, "repaired import survives restart")
	cleanup()
