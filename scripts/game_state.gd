class_name GameState
extends RefCounted
## Offline progression. UI animations only play AFTER a successful transaction.

const SCHEMA: int = 1
const DAY: int = 86400
const BRANCHES: Array[String] = ["force", "insight", "craft"]
const TACTICS: Array[String] = ["balanced", "aggressive", "guarded"]
const ABILITIES: Dictionary = {
	"resonance": {"id": "resonance", "name": "Резонанс", "description": "Каждый третий удар наносит ещё 2 урона.", "level": 3},
	"ceramic_guard": {"id": "ceramic_guard", "name": "Керамический заслон", "description": "Каждый ответ врага наносит на 2 урона меньше (минимум 1).", "level": 5},
	"steady_breath": {"id": "steady_breath", "name": "Ровное дыхание", "description": "+8 к постоянному здоровью.", "level": 8}
}
const ITEMS: Dictionary = {
	"worn_blade": {"id": "worn_blade", "name": "Дорожный клинок", "attack": 0, "defense": 0, "hp": 0, "description": "Сталь, которая помнит дорогу."},
	"ash_hook": {"id": "ash_hook", "name": "Пепельный крюк", "attack": 4, "defense": 0, "hp": 0, "description": "+4 к атаке. Открывается первым реальным действием."},
	"oath_mantle": {"id": "oath_mantle", "name": "Мантия обета", "attack": 1, "defense": 4, "hp": 16, "description": "+1 атака, +4 защита, +16 здоровье. Награда Звонаря."},
	"ember_lantern": {"id": "ember_lantern", "name": "Жаровой фонарь", "attack": 3, "defense": 2, "hp": 8, "description": "+3 атака, +2 защита, +8 здоровье. Свет освобождённого леса."}
}
const ENEMIES: Dictionary = {
	"husk": {"id": "husk", "name": "Пустотник", "hp": 82, "attack": 17, "defense": 2, "xp": 20, "resources": 3, "requires": "", "item": "", "description": "Пепел научился ходить. Подготовь хотя бы одно действие."},
	"bellkeeper": {"id": "bellkeeper", "name": "Звонарь топи", "hp": 150, "attack": 25, "defense": 5, "xp": 35, "resources": 5, "requires": "husk", "item": "oath_mantle", "description": "Третий удар особенно тяжёл. Защита и подготовка дают время."},
	"root_heart": {"id": "root_heart", "name": "Корень-пожиратель", "hp": 240, "attack": 26, "defense": 6, "xp": 60, "resources": 8, "requires": "bellkeeper", "item": "ember_lantern", "description": "Сердце чащи. Долгая подготовка важнее спешки."}
}

var data: Dictionary = {}
var last_error: String = ""
var recovered_backup: bool = false
var _path: String = ""
var _recovery_path: String = ""
var _clock_now: int = -1
var _clock_offset: int = 180

func _init() -> void:
	_clock_offset = int(Time.get_time_zone_from_system().get("bias", 180))
	data = _fresh_data()

func _fresh_data() -> Dictionary:
	return {
		"schema": SCHEMA, "xp": 0, "resources": 0, "habits": [], "events": [],
		"battles": [], "inventory": ["worn_blade"], "equipped": "worn_blade",
		"completed_contracts": [], "rest_days": [], "next_id": 1,
		"settings": {"boundary_hour": 4, "timezone_offset": _clock_offset, "tactic": "balanced", "economy": false, "reduced_motion": false, "text_scale": 1.0, "high_quality": false, "auto_timezone": true},
		"clock": {"day": "", "last_epoch": 0, "offset": _clock_offset, "boundary": 4, "guard_until": 0}
	}

func configure_clock(now_epoch: int = -1, offset_minutes: int = 180) -> void:
	_clock_now = now_epoch
	_clock_offset = clampi(offset_minutes, -840, 840)
	data.settings.timezone_offset = _clock_offset

func _now() -> int:
	return _clock_now if _clock_now >= 0 else int(Time.get_unix_time_from_system())

func _raw_day(epoch: int, offset: int, boundary: int) -> String:
	return Time.get_date_string_from_unix_time(epoch + offset * 60 - boundary * 3600)

func today() -> String:
	var now: int = _now()
	var boundary: int = int(data.settings.boundary_hour)
	var clock_data: Dictionary = data.clock
	var previous: String = str(clock_data.day)
	# Clock settings cannot manufacture an extra reward day. Keep today's key until
	# the NEXT boundary in the new offset. A backward system clock never rewinds it.
	if previous != "" and (int(clock_data.offset) != _clock_offset or int(clock_data.boundary) != boundary):
		var local_shifted: int = now + _clock_offset * 60 - boundary * 3600
		clock_data.guard_until = (int(floor(float(local_shifted) / DAY)) + 1) * DAY - _clock_offset * 60 + boundary * 3600
	clock_data.offset = _clock_offset
	clock_data.boundary = boundary
	var raw: String = _raw_day(now, _clock_offset, boundary)
	if now < int(clock_data.guard_until) and previous != "":
		raw = previous
	if previous != "" and raw < previous:
		raw = previous
	clock_data.day = raw
	clock_data.last_epoch = maxi(int(clock_data.last_epoch), now)
	return raw

func _new_id(prefix: String) -> String:
	var value: String = prefix + str(int(data.next_id))
	data.next_id = int(data.next_id) + 1
	return value

func _ok(extra: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {"ok": true}
	result.merge(extra)
	last_error = ""
	return result

func _fail(message: String) -> Dictionary:
	last_error = message
	return {"ok": false, "error": message}

func _commit(before: Dictionary, extra: Dictionary = {}) -> Dictionary:
	if _path == "" and _recovery_path != "":
		data = before
		return _fail("Сохранение повреждено. Сначала восстановите исправный JSON; изменения не сохранены.")
	if _path != "":
		var saved: Dictionary = _write_atomic(_path, data)
		if not bool(saved.ok):
			data = before
			return _fail(str(saved.error))
	return _ok(extra)

func _habit(id: String) -> Dictionary:
	for habit: Dictionary in data.habits:
		if str(habit.id) == id:
			return habit
	return {}

func _valid_schedule(schedule: Dictionary) -> bool:
	var kind: String = str(schedule.get("type", ""))
	if kind == "daily":
		return true
	if kind == "weekly":
		if not _integer(schedule.get("count", null)):
			return false
		var count: int = int(schedule.get("count", 0))
		return count >= 1 and count <= 7
	if kind == "weekdays":
		var days: Variant = schedule.get("days", [])
		if not days is Array or days.is_empty() or days.size() > 7:
			return false
		var unique: Array = []
		for day: Variant in days:
			if not _integer(day) or int(day) < 1 or int(day) > 7 or unique.has(int(day)):
				return false
			unique.append(int(day))
		return true
	return false

func add_habit(title: String, branch: String = "force", minimum: String = "2 минуты", schedule: Dictionary = {"type": "daily"}) -> Dictionary:
	title = title.strip_edges()
	if title.is_empty() or title.length() > 120:
		return _fail("Название должно содержать от 1 до 120 символов.")
	if not BRANCHES.has(branch) or not _valid_schedule(schedule):
		return _fail("Проверьте ветку и расписание привычки.")
	if minimum.length() > 160:
		return _fail("Минимальная версия: не более 160 символов.")
	if data.habits.size() >= 100:
		return _fail("В первой версии доступно до 100 привычек.")
	var before: Dictionary = data.duplicate(true)
	var habit: Dictionary = {"id": _new_id("h"), "title": title, "branch": branch, "minimum": minimum, "schedule": schedule.duplicate(true), "paused": false, "created_day": today()}
	data.habits.append(habit)
	return _commit(before, {"habit": habit.duplicate(true), "id": habit.id})

func edit_habit(id: String, patch: Dictionary) -> Dictionary:
	var habit: Dictionary = _habit(id)
	if habit.is_empty():
		return _fail("Привычка не найдена.")
	var before: Dictionary = data.duplicate(true)
	for key: String in ["title", "branch", "minimum", "schedule"]:
		if patch.has(key):
			habit[key] = patch[key]
	if not habit.title is String or not habit.minimum is String or not habit.schedule is Dictionary:
		data = before
		return _fail("Неверный формат привычки.")
	habit.title = str(habit.title).strip_edges()
	if str(habit.title).is_empty() or str(habit.title).length() > 120 or str(habit.minimum).length() > 160 or not BRANCHES.has(str(habit.branch)) or not _valid_schedule(habit.schedule):
		data = before
		return _fail("Проверьте название, ветку и расписание.")
	return _commit(before)

func pause_habit(id: String, paused: bool) -> Dictionary:
	var habit: Dictionary = _habit(id)
	if habit.is_empty():
		return _fail("Привычка не найдена.")
	var before: Dictionary = data.duplicate(true)
	habit.paused = paused
	return _commit(before)

func _weekday(day: String) -> int:
	var parts: Dictionary = Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_datetime_string(day + "T12:00:00"))
	var weekday: int = int(parts.weekday)
	return 7 if weekday == 0 else weekday

func _week_key(day: String) -> int:
	var epoch: int = Time.get_unix_time_from_datetime_string(day + "T12:00:00")
	return int(floor(float(epoch) / DAY)) - (_weekday(day) - 1)

func _completion(id: String, day: String, include_undone: bool = false) -> Dictionary:
	for event: Dictionary in data.events:
		if str(event.get("kind", "")) == "completion" and str(event.habit_id) == id and str(event.day) == day and (include_undone or not bool(event.undone)):
			return event
	return {}

func _weekly_count(id: String, day: String) -> int:
	var total: int = 0
	var week: int = _week_key(day)
	for event: Dictionary in data.events:
		if str(event.kind) == "completion" and str(event.habit_id) == id and not bool(event.undone) and _week_key(str(event.day)) == week:
			total += 1
	return total

func _is_due(habit: Dictionary, day: String) -> bool:
	if bool(habit.paused) or data.rest_days.has(day):
		return false
	var schedule: Dictionary = habit.schedule
	if str(schedule.type) == "weekdays":
		return schedule.days.has(_weekday(day))
	if str(schedule.type) == "weekly":
		return _weekly_count(str(habit.id), day) < int(schedule.count)
	return true

func habits_today() -> Array:
	var result: Array = []
	var day: String = today()
	for habit: Dictionary in data.habits:
		var row: Dictionary = habit.duplicate(true)
		row.done = not _completion(str(habit.id), day).is_empty()
		row.weekly_done = _weekly_count(str(habit.id), day)
		row.weekly_target = int(habit.schedule.get("count", 0))
		row.due = _is_due(habit, day)
		result.append(row)
	return result

func complete_habit(id: String, minimum_only: bool = false) -> Dictionary:
	var habit: Dictionary = _habit(id)
	if habit.is_empty():
		return _fail("Привычка не найдена.")
	var before: Dictionary = data.duplicate(true)
	var day: String = today()
	if not _completion(id, day).is_empty():
		return _fail("Сегодня это действие уже отмечено. Награда начислена один раз.")
	if not _is_due(habit, day):
		return _fail("Сегодня отдых, пауза или цель по расписанию уже выполнена.")
	var event: Dictionary = _completion(id, day, true)
	if event.is_empty():
		var ordinal: int = 0
		for existing: Dictionary in data.events:
			if str(existing.kind) == "completion" and str(existing.day) == day:
				ordinal += 1
		var xp: int = 20 if ordinal < 3 else (5 if ordinal < 6 else 0)
		if minimum_only:
			xp = int(floor(float(xp) / 2.0))
		event = {"id": _new_id("e"), "kind": "completion", "habit_id": id, "title": habit.title, "day": day, "timestamp": _now(), "branch": habit.branch, "minimum": minimum_only, "xp": xp, "resources": 1 if ordinal < 3 else 0, "prep": 1 if ordinal < 6 else 0, "undone": false, "spent_by": "", "ordinal": ordinal + 1}
		data.events.append(event)
	else:
		# Reactivating an undo restores its original reward, never opens a new slot.
		event.undone = false
	data.xp = int(data.xp) + int(event.xp)
	data.resources = int(data.resources) + int(event.resources)
	var unlocked: Array = []
	if not data.inventory.has("ash_hook"):
		data.inventory.append("ash_hook")
		data.equipped = "ash_hook"
		unlocked.append("ash_hook")
	return _commit(before, {"event": event.duplicate(true), "reward": {"xp": event.xp, "resources": event.resources, "branch": event.branch, "prep": event.prep, "minimum": event.minimum}, "unlocked": unlocked})

func undo_completion(id: String, day: String = "") -> Dictionary:
	if day == "":
		day = today()
	var event: Dictionary = _completion(id, day)
	if event.is_empty():
		return _fail("Активная отметка не найдена.")
	if str(event.spent_by) != "":
		return _fail("Эта отметка уже использована в охоте. Отмена изменила бы сохранённый исход боя.")
	# A battle also depends on permanent XP/equipment, even when this particular
	# preparation charge was not selected. Preserve those causal dependencies.
	for battle: Dictionary in data.battles:
		if battle.get("source_events", []).has(str(event.id)):
			return _fail("Опыт этой отметки уже повлиял на охоту. Сохранённый бой нельзя пересчитать отменой.")
	var before: Dictionary = data.duplicate(true)
	event.undone = true
	data.xp = int(data.xp) - int(event.xp)
	data.resources = int(data.resources) - int(event.resources)
	if _completion_count() == 0:
		data.inventory.erase("ash_hook")
		if str(data.equipped) == "ash_hook":
			data.equipped = "worn_blade"
	return _commit(before)

func plan_rest(day: String = "") -> Dictionary:
	if day == "":
		day = today()
	if not _valid_day(day):
		return _fail("Неверная дата отдыха.")
	var before: Dictionary = data.duplicate(true)
	if data.rest_days.has(day):
		data.rest_days.erase(day)
	else:
		data.rest_days.append(day)
	return _commit(before, {"rest": data.rest_days.has(day)})

func set_boundary(hour: int) -> Dictionary:
	if hour < 0 or hour > 23:
		return _fail("Граница дня — час от 0 до 23.")
	var before: Dictionary = data.duplicate(true)
	today()
	data.settings.boundary_hour = hour
	today()
	return _commit(before)

func set_tactic(tactic: String) -> Dictionary:
	if not TACTICS.has(tactic):
		return _fail("Неизвестная тактика.")
	var before: Dictionary = data.duplicate(true)
	data.settings.tactic = tactic
	return _commit(before)

func set_settings(patch: Dictionary) -> Dictionary:
	var before: Dictionary = data.duplicate(true)
	for key: String in ["economy", "reduced_motion", "high_quality", "auto_timezone", "sound_enabled"]:
		if patch.has(key):
			if not patch[key] is bool:
				data = before
				return _fail("Неверный формат настройки.")
			data.settings[key] = patch[key]
	if patch.has("sound_volume"):
		if not (patch.sound_volume is float or patch.sound_volume is int) or not is_finite(float(patch.sound_volume)) or float(patch.sound_volume) < 0.0 or float(patch.sound_volume) > 1.0:
			data = before
			return _fail("Громкость — от 0 до 100%.")
		data.settings.sound_volume = float(patch.sound_volume)
	if patch.has("text_scale"):
		if not (patch.text_scale is float or patch.text_scale is int) or float(patch.text_scale) < 1.0 or float(patch.text_scale) > 1.5:
			data = before
			return _fail("Масштаб текста — от 1 до 1,5.")
		data.settings.text_scale = float(patch.text_scale)
	return _commit(before)

func equip(item_id: String) -> Dictionary:
	if not ITEMS.has(item_id) or not data.inventory.has(item_id):
		return _fail("Предмет ещё не открыт.")
	var before: Dictionary = data.duplicate(true)
	data.equipped = item_id
	return _commit(before)

func level_info() -> Dictionary:
	var remaining: int = int(data.xp)
	var level: int = 1
	var threshold: int = 60
	while remaining >= threshold:
		remaining -= threshold
		level += 1
		threshold = 60 + 20 * (level - 1)
	return {"level": level, "xp_in_level": remaining, "xp_to_next": threshold, "total_xp": data.xp}

func _completion_count() -> int:
	var count: int = 0
	for event: Dictionary in data.events:
		if str(event.kind) == "completion" and not bool(event.undone):
			count += 1
	return count

func stats() -> Dictionary:
	var level: int = int(level_info().level)
	var item: Dictionary = ITEMS[str(data.equipped)]
	var abilities: Array = []
	for id: String in ["resonance", "ceramic_guard", "steady_breath"]:
		if level >= int(ABILITIES[id].level):
			abilities.append(ABILITIES[id].duplicate(true))
	var prep: Dictionary = {"force": 0, "insight": 0, "craft": 0}
	for event: Dictionary in data.events:
		if str(event.kind) == "completion" and not bool(event.undone) and str(event.spent_by) == "":
			prep[str(event.branch)] = int(prep[str(event.branch)]) + int(event.prep)
	var stage: int = 0
	if data.inventory.has("ash_hook"):
		stage = 1
	if data.inventory.has("oath_mantle"):
		stage = 2
	if data.inventory.has("ember_lantern"):
		stage = 3
	return {"level": level, "hp": 84 + 8 * (level - 1) + int(item.hp) + (8 if level >= 8 else 0), "attack": 12 + 3 * (level - 1) + int(item.attack), "defense": 3 + int(floor(float(level - 1) / 2.0)) + int(item.defense), "prep": prep, "completions": _completion_count(), "visual_stage": stage, "abilities": abilities}

func available_hunts() -> Array:
	var result: Array = []
	for id: String in ["husk", "bellkeeper", "root_heart"]:
		var enemy: Dictionary = ENEMIES[id].duplicate(true)
		enemy.completed = data.completed_contracts.has(id)
		enemy.locked = _completion_count() == 0 or (str(enemy.requires) != "" and not data.completed_contracts.has(str(enemy.requires)))
		result.append(enemy)
	return result

func start_hunt(enemy_id: String, tactic: String = "balanced") -> Dictionary:
	if not ENEMIES.has(enemy_id) or not TACTICS.has(tactic):
		return _fail("Неизвестная цель или тактика.")
	# Replaying returns the exact saved sequence, with an explicit zero reward.
	if data.completed_contracts.has(enemy_id):
		for old: Dictionary in data.battles:
			if str(old.enemy_id) == enemy_id and bool(old.victory):
				var replay: Dictionary = old.duplicate(true)
				replay.replay = true
				replay.xp = 0
				replay.resources = 0
				return _ok({"battle": replay})
	var enemy: Dictionary = ENEMIES[enemy_id]
	if _completion_count() == 0 or (str(enemy.requires) != "" and not data.completed_contracts.has(str(enemy.requires))):
		return _fail("Выполните действие и предыдущий контракт, чтобы открыть эту охоту.")
	var preparation: Dictionary = stats().prep
	if int(preparation.force) + int(preparation.insight) + int(preparation.craft) < 1:
		return _fail("Для новой охоты нужно хотя бы одно действие с подготовкой. Повторы побед доступны без неё.")
	var before: Dictionary = data.duplicate(true)
	var snapshot: Dictionary = stats().duplicate(true)
	snapshot.equipped = data.equipped
	var used: Dictionary = {"force": 0, "insight": 0, "craft": 0}
	var battle_id: String = _new_id("b")
	var sources: Array = []
	for event: Dictionary in data.events:
		if str(event.kind) != "completion" or bool(event.undone):
			continue
		sources.append(str(event.id))
		var branch: String = str(event.branch)
		if str(event.spent_by) == "" and int(event.prep) > 0 and int(used[branch]) < 3:
			used[branch] = int(used[branch]) + 1
			event.spent_by = battle_id
	snapshot.prep_used = used.duplicate(true)
	var hero_hp: int = int(snapshot.hp) + int(used.craft) * 6
	var enemy_hp: int = int(enemy.hp)
	var attack_delta: int = 4 if tactic == "aggressive" else (-2 if tactic == "guarded" else 0)
	var defense_delta: int = -3 if tactic == "aggressive" else (4 if tactic == "guarded" else 0)
	var resonance_damage: int = 2 if int(snapshot.level) >= 3 else 0
	var guard_reduction: int = 2 if int(snapshot.level) >= 5 else 0
	var turns: Array = []
	for turn: int in range(1, 81):
		var hero_damage: int = maxi(1, int(snapshot.attack) + int(used.force) * 2 + attack_delta - int(enemy.defense) + (int(used.insight) + resonance_damage if turn % 3 == 0 else 0))
		enemy_hp = maxi(0, enemy_hp - hero_damage)
		var enemy_damage: int = 0
		if enemy_hp > 0:
			enemy_damage = maxi(1, int(enemy.attack) + (5 if turn % 3 == 0 else 0) - int(snapshot.defense) - int(used.insight) * 2 - defense_delta - guard_reduction)
			hero_hp = maxi(0, hero_hp - enemy_damage)
		turns.append({"turn": turn, "hero_hp": hero_hp, "enemy_hp": enemy_hp, "hero_damage": hero_damage, "enemy_damage": enemy_damage, "text": "Удар охотника: %d. Ответ: %d." % [hero_damage, enemy_damage]})
		if hero_hp == 0 or enemy_hp == 0:
			break
	var victory: bool = enemy_hp == 0 and hero_hp > 0
	var battle: Dictionary = {"id": battle_id, "enemy_id": enemy_id, "enemy_name": enemy.name, "victory": victory, "turns": turns, "xp": int(enemy.xp) if victory else 0, "resources": int(enemy.resources) if victory else 0, "tactic": tactic, "hero_snapshot": snapshot, "replay": false, "day": today(), "timestamp": _now(), "source_events": sources}
	data.battles.append(battle)
	if victory:
		data.completed_contracts.append(enemy_id)
		data.xp = int(data.xp) + int(battle.xp)
		data.resources = int(data.resources) + int(battle.resources)
		if str(enemy.item) != "" and not data.inventory.has(str(enemy.item)):
			data.inventory.append(str(enemy.item))
	data.events.append({"id": _new_id("e"), "kind": "battle", "battle_id": battle_id, "day": battle.day, "timestamp": battle.timestamp, "title": enemy.name, "victory": victory, "xp": battle.xp, "resources": battle.resources})
	return _commit(before, {"battle": battle.duplicate(true)})

func export_json() -> String:
	return JSON.stringify(data, "\t")

func _parse_json(content: String) -> Variant:
	var parser: JSON = JSON.new()
	if parser.parse(content) != OK:
		return null
	return parser.data

func import_json(content: String) -> Dictionary:
	if content.length() > 16 * 1024 * 1024:
		return _fail("Файл слишком большой (максимум 16 МБ).")
	var parsed: Variant = _parse_json(content)
	var problem: String = _validate(parsed)
	if problem != "":
		return _fail(problem)
	var before: Dictionary = data.duplicate(true)
	var old_offset: int = _clock_offset
	var old_path: String = _path
	data = parsed.duplicate(true)
	_clock_offset = int(data.settings.timezone_offset)
	# Explicit validated import can repair a failed load, and must persist to the
	# original destination rather than silently create a memory-only session.
	if _path == "" and _recovery_path != "":
		_path = _recovery_path
	var result: Dictionary = _commit(before)
	if not bool(result.ok):
		_clock_offset = old_offset
		_path = old_path
	else:
		_recovery_path = ""
	return result

func load_game(path: String = "user://ashen_oath.json") -> Dictionary:
	_path = path
	_recovery_path = ""
	recovered_backup = false
	if not FileAccess.file_exists(path):
		# A process can stop after main->backup, before temp->main.
		if FileAccess.file_exists(path + ".bak"):
			return _recover(path)
		return _ok({"new_game": true})
	var content: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = _parse_json(content)
	var problem: String = _validate(parsed)
	if problem != "":
		if FileAccess.file_exists(path + ".bak"):
			return _recover(path)
		_path = "" # Do not overwrite a damaged only copy with an empty game.
		_recovery_path = path
		return _fail("Сохранение повреждено. Оригинал сохранён; импортируйте исправную копию. " + problem)
	data = parsed
	_clock_offset = int(data.settings.timezone_offset)
	return _ok()

func _recover(path: String) -> Dictionary:
	var parsed: Variant = _parse_json(FileAccess.get_file_as_string(path + ".bak"))
	if _validate(parsed) != "":
		_path = ""
		_recovery_path = path
		return _fail("Основное сохранение и резервная копия повреждены. Файлы оставлены для восстановления.")
	data = parsed
	_clock_offset = int(data.settings.timezone_offset)
	recovered_backup = true
	# Keep the valid backup; quarantine corrupt main before future autosaves.
	if FileAccess.file_exists(path):
		var code: int = DirAccess.rename_absolute(path, path + ".damaged")
		if code != OK:
			_path = ""
			_recovery_path = path
			return _fail("Резервная копия прочитана, но повреждённый файл не удалось переместить. Автосохранение отключено.")
	return _ok({"recovered_backup": true})

func save_game(path: String = "") -> Dictionary:
	var target: String = path if path != "" else _path
	if target == "":
		return _fail("Путь сохранения не выбран.")
	var result: Dictionary = _write_atomic(target, data)
	if bool(result.ok):
		_path = target
		_recovery_path = ""
		last_error = ""
	else:
		last_error = str(result.error)
	return result

func _write_atomic(path: String, value: Dictionary) -> Dictionary:
	var temp: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Не удалось записать сохранение. Проверьте свободное место и доступ к папке."}
	file.store_string(JSON.stringify(value))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		return {"ok": false, "error": "Запись прервана. Награда не выдана; можно повторить действие."}
	if _validate(_parse_json(FileAccess.get_file_as_string(temp))) != "":
		return {"ok": false, "error": "Проверка записанного сохранения не пройдена."}
	var backup: String = path + ".bak"
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup):
			if DirAccess.remove_absolute(backup) != OK:
				return {"ok": false, "error": "Не удалось обновить резервную копию."}
		if DirAccess.rename_absolute(path, backup) != OK:
			return {"ok": false, "error": "Не удалось заменить сохранение. Действие отменено."}
	if DirAccess.rename_absolute(temp, path) != OK:
		if FileAccess.file_exists(backup) and not FileAccess.file_exists(path):
			DirAccess.copy_absolute(backup, path)
		return {"ok": false, "error": "Не удалось завершить сохранение. Действие отменено."}
	return {"ok": true}

func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value))

func _valid_id(value: Variant, prefix: String) -> bool:
	if not value is String or not str(value).begins_with(prefix):
		return false
	var suffix: String = str(value).substr(prefix.length())
	return suffix.is_valid_int() and int(suffix) > 0 and str(int(suffix)) == suffix

func _valid_day(day: String) -> bool:
	if day.length() != 10 or day.substr(4, 1) != "-" or day.substr(7, 1) != "-":
		return false
	var parts: PackedStringArray = day.split("-")
	if parts.size() != 3 or not parts[0].is_valid_int() or not parts[1].is_valid_int() or not parts[2].is_valid_int():
		return false
	if int(parts[0]) < 1970 or int(parts[0]) > 9999 or int(parts[1]) < 1 or int(parts[1]) > 12 or int(parts[2]) < 1 or int(parts[2]) > 31:
		return false
	var epoch: int = Time.get_unix_time_from_datetime_string(day + "T12:00:00")
	return Time.get_date_string_from_unix_time(epoch) == day

func _validate(value: Variant) -> String:
	if not value is Dictionary:
		return "Ожидался JSON-объект."
	var required: Array[String] = ["schema", "xp", "resources", "habits", "events", "battles", "inventory", "equipped", "settings", "completed_contracts", "rest_days", "next_id", "clock"]
	for key: String in required:
		if not value.has(key):
			return "Отсутствует поле: " + key
	if not _integer(value.schema) or int(value.schema) != SCHEMA:
		return "Версия сохранения не поддерживается."
	for key: String in ["xp", "resources", "next_id"]:
		if not _integer(value[key]) or int(value[key]) < 0 or int(value[key]) > 100000000:
			return "Неверное число: " + key
	for key: String in ["habits", "events", "battles", "inventory", "completed_contracts", "rest_days"]:
		if not value[key] is Array or value[key].size() > 100000:
			return "Неверный список: " + key
	if value.habits.size() > 100 or not value.settings is Dictionary or not value.clock is Dictionary:
		return "Неверные настройки сохранения."
	var settings: Dictionary = value.settings
	# Audio preferences are optional so all previous schema-1 saves still load.
	if settings.has("sound_enabled") and not settings.sound_enabled is bool:
		return "Неверная настройка звука."
	if settings.has("sound_volume") and (not (settings.sound_volume is float or settings.sound_volume is int) or not is_finite(float(settings.sound_volume)) or float(settings.sound_volume) < 0.0 or float(settings.sound_volume) > 1.0):
		return "Неверная громкость звука."
	for key: String in ["boundary_hour", "timezone_offset", "tactic", "economy", "reduced_motion", "text_scale", "high_quality", "auto_timezone"]:
		if not settings.has(key):
			return "Отсутствует настройка: " + key
	if not _integer(settings.boundary_hour) or int(settings.boundary_hour) < 0 or int(settings.boundary_hour) > 23 or not _integer(settings.timezone_offset) or abs(int(settings.timezone_offset)) > 840 or not TACTICS.has(str(settings.tactic)):
		return "Неверные параметры дня или тактики."
	for key: String in ["economy", "reduced_motion", "high_quality", "auto_timezone"]:
		if not settings[key] is bool:
			return "Неверный флаг настройки."
	if not (settings.text_scale is float or settings.text_scale is int) or not is_finite(float(settings.text_scale)) or float(settings.text_scale) < 1.0 or float(settings.text_scale) > 1.5:
		return "Неверный масштаб текста."
	for key: String in ["day", "last_epoch", "offset", "boundary", "guard_until"]:
		if not value.clock.has(key):
			return "Неверные данные часов."
	if not value.clock.day is String or (value.clock.day != "" and not _valid_day(value.clock.day)):
		return "Неверный день часов."
	for key: String in ["last_epoch", "offset", "boundary", "guard_until"]:
		if not _integer(value.clock[key]):
			return "Неверное значение часов."
	if not value.equipped is String or not ITEMS.has(value.equipped) or not value.inventory.has(value.equipped) or not value.inventory.has("worn_blade"):
		return "Неизвестная экипировка."
	var item_ids: Array = []
	for item: Variant in value.inventory:
		if not item is String or not ITEMS.has(item) or item_ids.has(item):
			return "Неверный инвентарь."
		item_ids.append(item)
	for day: Variant in value.rest_days:
		if not day is String or not _valid_day(day):
			return "Неверная дата отдыха."
	var habit_ids: Array = []
	var largest_id: int = 0
	for habit: Variant in value.habits:
		if not habit is Dictionary:
			return "Неверная привычка."
		for key: String in ["id", "title", "branch", "minimum", "schedule", "paused", "created_day"]:
			if not habit.has(key):
				return "Неполная привычка."
		if not _valid_id(habit.id, "h") or habit_ids.has(habit.id) or not habit.title is String or str(habit.title).is_empty() or str(habit.title).length() > 120 or not habit.minimum is String or str(habit.minimum).length() > 160 or not BRANCHES.has(str(habit.branch)) or not habit.schedule is Dictionary or not _valid_schedule(habit.schedule) or not habit.paused is bool or not _valid_day(str(habit.created_day)):
			return "Неверные поля привычки."
		habit_ids.append(habit.id)
		largest_id = maxi(largest_id, int(str(habit.id).substr(1)))
	var event_ids: Array = []
	var completion_keys: Array = []
	var xp_sum: int = 0
	var resource_sum: int = 0
	for event: Variant in value.events:
		if not event is Dictionary:
			return "Неверная запись журнала."
		for key: String in ["id", "kind", "day", "timestamp", "title", "xp", "resources"]:
			if not event.has(key):
				return "Неполная запись журнала."
		if not _valid_id(event.id, "e") or event_ids.has(event.id) or not _valid_day(str(event.day)) or not _integer(event.timestamp) or not event.title is String or not _integer(event.xp) or int(event.xp) < 0 or not _integer(event.resources) or int(event.resources) < 0:
			return "Повреждена запись журнала."
		event_ids.append(event.id)
		largest_id = maxi(largest_id, int(str(event.id).substr(1)))
		if str(event.kind) == "completion":
			for key: String in ["habit_id", "branch", "minimum", "prep", "undone", "spent_by", "ordinal"]:
				if not event.has(key):
					return "Неполная отметка."
			var composite: String = str(event.habit_id) + "/" + str(event.day)
			if not habit_ids.has(event.habit_id) or completion_keys.has(composite) or not BRANCHES.has(str(event.branch)) or not event.minimum is bool or not event.undone is bool or not event.spent_by is String or not _integer(event.prep) or int(event.prep) < 0 or int(event.prep) > 1 or not _integer(event.ordinal) or int(event.ordinal) < 1 or int(event.xp) > 20 or int(event.resources) > 1:
				return "Неверная или повторная отметка."
			completion_keys.append(composite)
			if not bool(event.undone):
				xp_sum += int(event.xp)
				resource_sum += int(event.resources)
		elif str(event.kind) == "battle":
			if not event.has("battle_id") or not event.has("victory") or not event.victory is bool:
				return "Неполная запись боя."
			xp_sum += int(event.xp)
			resource_sum += int(event.resources)
		else:
			return "Неизвестный тип записи."
	if xp_sum != int(value.xp) or resource_sum != int(value.resources):
		return "Награды не совпадают с журналом."
	var battle_ids: Array = []
	var won: Array = []
	for battle: Variant in value.battles:
		if not battle is Dictionary:
			return "Неверный бой."
		for key: String in ["id", "enemy_id", "enemy_name", "victory", "turns", "xp", "resources", "tactic", "hero_snapshot", "replay", "day", "timestamp", "source_events"]:
			if not battle.has(key):
				return "Неполный бой."
		if not _valid_id(battle.id, "b") or battle_ids.has(battle.id) or not ENEMIES.has(str(battle.enemy_id)) or not battle.victory is bool or not battle.enemy_name is String or not battle.replay is bool or bool(battle.replay) or not battle.turns is Array or battle.turns.size() < 1 or battle.turns.size() > 80 or not battle.hero_snapshot is Dictionary or not TACTICS.has(str(battle.tactic)) or not battle.source_events is Array or not _valid_day(str(battle.day)) or not _integer(battle.timestamp):
			return "Неверные поля боя."
		battle_ids.append(battle.id)
		largest_id = maxi(largest_id, int(str(battle.id).substr(1)))
		var snapshot: Dictionary = battle.hero_snapshot
		# Abilities were added as derived stats; old schema-1 replay snapshots may
		# omit them and must keep their original recorded damage unchanged.
		if snapshot.has("abilities"):
			if not snapshot.abilities is Array or snapshot.abilities.size() > ABILITIES.size():
				return "Неверный список способностей."
			var ability_ids: Array = []
			for ability: Variant in snapshot.abilities:
				if not ability is Dictionary or not ability.has("id") or not ABILITIES.has(str(ability.id)) or ability_ids.has(ability.id):
					return "Неизвестная способность."
				ability_ids.append(ability.id)
				for key: String in ["name", "description"]:
					if not ability.has(key) or not ability[key] is String:
						return "Неполное описание способности."
		for key: String in ["level", "hp", "attack", "defense", "completions", "visual_stage"]:
			if not snapshot.has(key) or not _integer(snapshot[key]) or int(snapshot[key]) < 0:
				return "Повреждён снимок героя."
		if not snapshot.has("equipped") or not ITEMS.has(str(snapshot.equipped)):
			return "Неизвестный предмет в снимке героя."
		for key: String in ["prep", "prep_used"]:
			if not snapshot.has(key) or not snapshot[key] is Dictionary:
				return "Отсутствует подготовка снимка."
			for branch: String in BRANCHES:
				if not snapshot[key].has(branch) or not _integer(snapshot[key][branch]) or int(snapshot[key][branch]) < 0 or (key == "prep_used" and int(snapshot[key][branch]) > 3):
					return "Неверная подготовка снимка."
		var enemy: Dictionary = ENEMIES[str(battle.enemy_id)]
		if not _integer(battle.xp) or not _integer(battle.resources) or int(battle.xp) != (int(enemy.xp) if bool(battle.victory) else 0) or int(battle.resources) != (int(enemy.resources) if bool(battle.victory) else 0):
			return "Неверная награда боя."
		for turn: Variant in battle.turns:
			if not turn is Dictionary:
				return "Неверный ход."
			for key: String in ["turn", "hero_hp", "enemy_hp", "hero_damage", "enemy_damage"]:
				if not turn.has(key) or not _integer(turn[key]) or int(turn[key]) < 0:
					return "Повреждён ход боя."
			if not turn.has("text") or not turn.text is String:
				return "Отсутствует описание хода."
		for event_id: Variant in battle.source_events:
			if not event_ids.has(event_id):
				return "Отсутствует источник подготовки."
		if bool(battle.victory):
			if won.has(battle.enemy_id):
				return "Повторная награда контракта."
			won.append(battle.enemy_id)
	if won.size() != value.completed_contracts.size():
		return "Неверный список контрактов."
	for id: Variant in value.completed_contracts:
		if not won.has(id):
			return "Контракт не подтверждён боем."
	var battle_events: Array = []
	for event: Dictionary in value.events:
		if str(event.kind) == "completion":
			if str(event.spent_by) != "" and (not battle_ids.has(event.spent_by) or bool(event.undone)):
				return "Неверное расходование подготовки."
		else:
			if not battle_ids.has(event.battle_id) or battle_events.has(event.battle_id):
				return "Неверная связь журнала и боя."
			battle_events.append(event.battle_id)
			for battle: Dictionary in value.battles:
				if battle.id == event.battle_id and (battle.xp != event.xp or battle.resources != event.resources or battle.victory != event.victory):
					return "Награда боя не совпадает с журналом."
	if battle_events.size() != battle_ids.size():
		return "Бой отсутствует в журнале."
	if int(value.next_id) <= largest_id:
		return "Счётчик событий создаст повторный идентификатор."
	return ""
