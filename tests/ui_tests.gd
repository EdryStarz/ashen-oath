extends SceneTree
## Exercise actual Godot forms/signals on an isolated save. No desktop input.
var app: Control
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("run")
	create_timer(25.0).timeout.connect(func():
		push_error("UI test watchdog expired")
		quit(2))

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS UI: ", label)
	else:
		failed += 1
		push_error("FAIL UI: " + label)

func descendants(node: Node, kind: String) -> Array:
	var found: Array = []
	for child in node.get_children():
		if child.is_class(kind): found.append(child)
		found.append_array(descendants(child, kind))
	return found

func press(parent: Node, text_value: String) -> bool:
	for b in descendants(parent, "Button"):
		if b.text == text_value and not b.disabled:
			b.pressed.emit()
			return true
	return false

func run() -> void:
	root.size = Vector2i(432, 900)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	check(app.game.data.habits.is_empty(), "clean isolated save")
	await process_frame
	app._sync_world()
	var normal_width: int = app.viewport.size.x
	app.game.set_settings({"high_quality": true})
	app._sync_world()
	check(app.viewport.size.x == normal_width and normal_width == 384, "quality setting preserves the pixel grid")
	check(app.scene_box.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "pixel scene uses sharp nearest filtering")
	app.game.set_settings({"high_quality": false})
	app._sync_world()

	app._edit_habit({})
	check(press(app.modal, "Сохранить привычку"), "create form has save action")
	check(app.game.data.habits.is_empty() and is_instance_valid(app.modal), "empty title rejected without closing form")
	var fields: Array = descendants(app.modal, "LineEdit")
	fields[0].text = "Тест: прогулка"
	fields[1].text = "Одна минута"
	press(app.modal, "Сохранить привычку")
	check(app.game.data.habits.size() == 1 and not is_instance_valid(app.modal), "valid form commits habit")
	var habit: Dictionary = app.game.data.habits[0]
	app._edit_habit(habit)
	fields = descendants(app.modal, "LineEdit")
	fields[0].text = "Прогулка у реки"
	var options: Array = descendants(app.modal, "OptionButton")
	options[0].select(1)
	options[1].select(2)
	options[1].item_selected.emit(2)
	var counts: Array = descendants(app.modal, "SpinBox")
	counts[0].value = 3
	press(app.modal, "Сохранить привычку")
	habit = app.game.data.habits[0]
	check(habit.title == "Прогулка у реки" and habit.branch == "insight", "edit title and remap branch")
	check(habit.schedule.type == "weekly" and int(habit.schedule.count) == 3, "weekly form maps count correctly")
	app._minimum_dialog(habit)
	press(app.modal, "Минимум выполнен")
	check(int(app.game.data.xp) == 10, "minimum UI awards 10 XP")
	app._complete(str(habit.id), true)
	check(int(app.game.data.xp) == 10, "repeat completion has no second reward")
	app._undo(str(habit.id))
	check(int(app.game.data.xp) == 0, "undo UI restores balance")
	app._complete(str(habit.id), false)
	check(int(app.game.data.xp) == 10, "redo preserves original minimum reward")
	app._navigate("hero")
	app._equip("ash_hook")
	check(app.game.data.equipped == "ash_hook", "equipment action commits")
	app._navigate("hunt")
	app._start_hunt()
	check(app.game.data.battles.size() == 1, "hunt UI resolves and commits")
	check(not app.last_battle.is_empty() and not app.busy, "economy/no-world completes presentation")
	var copy: String = app.game.export_json()
	app._import_dialog()
	var editors: Array = descendants(app.modal, "TextEdit")
	editors[0].text = "{ broken"
	press(app.modal, "Проверить и заменить сохранение")
	check(is_instance_valid(app.modal) and app.game.export_json() == copy, "invalid import preserves data and form")
	var imported: Dictionary = JSON.parse_string(copy)
	imported.settings.text_scale = 1.2
	imported.settings.economy = true
	editors[0].text = JSON.stringify(imported)
	press(app.modal, "Проверить и заменить сохранение")
	check(not is_instance_valid(app.modal), "valid import completes")
	check(app.last_battle.is_empty() and not app.busy and app.selected_enemy == 0, "import clears stale battle presentation")
	check(is_equal_approx(app.font_scale, 1.2) and app.game.data.settings.economy, "import applies text and rendering preferences")
	app._settings()
	var buttons: Array = descendants(app.modal, "CheckBox")
	buttons[0].button_pressed = true
	buttons[1].button_pressed = true
	buttons[4].button_pressed = false
	var volumes: Array = descendants(app.modal, "HSlider")
	volumes[0].value = 35
	options = descendants(app.modal, "OptionButton")
	options[0].select(2)
	press(app.modal, "Применить")
	check(app.game.data.settings.economy and app.game.data.settings.reduced_motion and is_equal_approx(float(app.font_scale), 1.4), "settings roundtrip economy motion text")
	check(not app.game.data.settings.sound_enabled and is_equal_approx(float(app.game.data.settings.sound_volume), 0.35) and not app.sound.enabled, "sound toggle and volume form persist and apply")
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(app.sound.paused and paused, "application pause reaches soundscape and scene tree")
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(not app.sound.paused and not paused, "application resume restores soundscape and scene tree")
	app._navigate("today")
	check(not app.shell.get_node("Stage").visible, "economy hides heavy viewport")
	app._rest_dialog()
	press(app.modal, "Запланировать отдых сегодня")
	check(app.game.today() in app.game.data.rest_days, "rest controls set day")
	app._rest_dialog()
	press(app.modal, "Вернуть сегодняшний план")
	check(not app.game.today() in app.game.data.rest_days, "rest controls restore plan")
	app._chronicle()
	var leaked: bool = false
	for label in descendants(app.modal, "Label"):
		if "Прогулка у реки" in label.text: leaked = true
	check(not leaked, "public chronicle hides habit titles")
	app._close_modal()
	app._navigate("journal")
	await process_frame
	print("UI TESTS: %d passed, %d failed" % [passed, failed])
	app.queue_free()
	await create_timer(0.1).timeout
	quit(0 if failed == 0 else 1)
