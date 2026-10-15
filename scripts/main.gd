extends Control
## All progression lives in GameState. This script only presents committed results.
const StateScript = preload("res://scripts/game_state.gd")
const WorldScript = preload("res://scripts/pixel_world.gd")
const ChronicleScript = preload("res://scripts/chronicle_card.gd")
const SoundScript = preload("res://scripts/soundscape.gd")
const BG = Color("121527")
const SURFACE = Color("24243e")
const INK = Color("eee7d8")
const MUTED = Color("b5bdb9")
const GOLD = Color("ffd679")
const GREEN = Color("68dccb")
const EDGE = Color("647199")
const BRANCHES = ["force", "insight", "craft"]
const BRANCH_NAMES = ["Сила", "Знание", "Ремесло"]
const TACTICS = ["balanced", "aggressive", "guarded"]
const TACTIC_NAMES = ["Равновесие", "Натиск", "Защита"]
const ENEMY_IDS = ["husk", "bellkeeper", "root_heart"]
var game = StateScript.new()
var world: Node2D
var viewport: SubViewport
var scene_box: TextureRect
var page: String = "today"
var content: VBoxContainer
var shell: VBoxContainer
var scene_overlay: Control
var modal: Control
var notice: Label
var header_label: Label
var nav: HBoxContainer
var selected_enemy: int = 0
var busy: bool = false
var last_battle: Dictionary = {}
var combat_label: Label
var body_font: Font
var title_font: Font
var font_scale: float = 1.0
var clock_timer: Timer
var last_day: String = ""
var qa: bool = false
var ui_testing: bool = false
var app_paused: bool = false
var modal_notice: PanelContainer
var sound: Node

func _ready() -> void:
	qa = "--qa" in OS.get_cmdline_user_args()
	ui_testing = "--ui-tests" in OS.get_cmdline_user_args()
	OS.low_processor_usage_mode = true
	if ResourceLoader.exists("res://assets/fonts/NotoSans.ttf"):
		body_font = load("res://assets/fonts/NotoSans.ttf")
	if ResourceLoader.exists("res://assets/fonts/Cormorant.ttf"):
		title_font = body_font
	var save_path: String = "user://qa-ui.json" if qa else "user://ashen_oath.json"
	if ui_testing: save_path = "user://ui-tests-%d.json" % Time.get_ticks_usec()
	if "--store-capture" in OS.get_cmdline_user_args(): save_path = "user://store-preview-%d.json" % Time.get_ticks_usec()
	var loaded: Dictionary = game.load_game(save_path)
	_update_clock()
	font_scale = float(game.data.settings.get("text_scale", 1.0))
	sound = SoundScript.new()
	add_child(sound)
	_setup_theme()
	_build_shell()
	_render_page()
	if not loaded.get("ok", false):
		_toast(str(loaded.get("error", "Ошибка чтения сохранения")))
	clock_timer = Timer.new()
	clock_timer.wait_time = 20.0
	clock_timer.timeout.connect(_day_check)
	add_child(clock_timer)
	clock_timer.start()
	if not ui_testing: call_deferred("_load_world")
	if qa:
		call_deferred("_qa_run")

func _update_clock() -> void:
	if game.data.settings.get("auto_timezone", true):
		game.configure_clock(-1, int(Time.get_time_zone_from_system().get("bias", 0)))
	last_day = game.today()

func _day_check() -> void:
	var before: String = last_day
	_update_clock()
	if before != last_day and is_instance_valid(content):
		_render_page()
		_toast("Новый день. Накопленный прогресс сохранён.")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		app_paused = true
		if is_instance_valid(sound): sound.set_paused(true)
		if is_instance_valid(viewport):
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		get_tree().paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		app_paused = false
		if is_instance_valid(sound): sound.set_paused(false)
		get_tree().paused = false
		if is_instance_valid(content):
			_day_check()
			_sync_world()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(modal):
			_close_modal()
		elif page != "today":
			_navigate("today")

func _setup_theme() -> void:
	var t := Theme.new()
	t.default_font_size = int(18 * font_scale)
	if body_font:
		t.default_font = body_font
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", MUTED)
	for type_name in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type_name, _style(SURFACE, EDGE))
		t.set_stylebox("hover", type_name, _style(Color("2c3839"), GOLD))
		t.set_stylebox("pressed", type_name, _style(Color("3a443c"), GOLD))
		t.set_stylebox("focus", type_name, _style(Color(0,0,0,0), GOLD, 2))
		t.set_stylebox("disabled", type_name, _style(Color("182021"), Color("46504b")))
	for type_name in ["LineEdit", "TextEdit", "SpinBox"]:
		t.set_stylebox("normal", type_name, _style(Color("101719"), EDGE))
		t.set_stylebox("focus", type_name, _style(Color("101719"), GOLD, 2))
		t.set_color("font_color", type_name, INK)
		t.set_color("caret_color", type_name, GOLD)
	t.set_constant("separation", "VBoxContainer", 12)
	t.set_constant("separation", "HBoxContainer", 8)
	theme = t

func _style(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(0)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func _label(text_value: String, size_value: int = 18, color: Color = INK, serif: bool = false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", int(size_value * font_scale))
	label.add_theme_color_override("font_color", color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if serif and title_font:
		label.add_theme_font_override("font", title_font)
	return label

func _button(text_value: String, action: Callable, accent: bool = false) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size.y = 58
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(action)
	b.add_theme_font_size_override("font_size", int(16 * font_scale))
	if accent:
		b.add_theme_stylebox_override("normal", _style(GOLD, GOLD))
		b.add_theme_color_override("font_color", BG)
		b.add_theme_color_override("font_hover_color", BG)
		b.add_theme_color_override("font_pressed_color", BG)
		b.add_theme_stylebox_override("hover", _style(Color("e1c797"), GOLD))
		b.add_theme_stylebox_override("pressed", _style(Color("bca071"), GOLD))
	return b

func _margin(child: Control, amount: int = 20) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", amount)
	m.add_theme_constant_override("margin_right", amount)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	m.add_child(child)
	return m

func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	shell = VBoxContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("separation", 0)
	add_child(shell)
	var header := HBoxContainer.new()
	header_label = _label("ПЕПЕЛЬНЫЙ ОБЕТ", 17, GOLD)
	header.add_child(header_label)
	var settings := _button("Настройки", _settings)
	settings.size_flags_horizontal = Control.SIZE_SHRINK_END
	settings.add_theme_font_size_override("font_size", 13)
	header.add_child(settings)
	shell.add_child(_margin(header))
	var stage := Control.new()
	stage.name = "Stage"
	stage.custom_minimum_size.y = 280
	shell.add_child(stage)
	scene_box = TextureRect.new()
	scene_box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene_box.stretch_mode = TextureRect.STRETCH_SCALE
	scene_box.mouse_filter = Control.MOUSE_FILTER_STOP
	scene_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(scene_box)
	viewport = SubViewport.new()
	viewport.disable_3d = true
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.size = Vector2i(432, 280)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	scene_box.add_child(viewport)
	scene_box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene_box.texture = viewport.get_texture()
	scene_box.resized.connect(_resize_scene)
	scene_overlay = Control.new()
	scene_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(scene_overlay)
	scene_box.gui_input.connect(_scene_input)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shell.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inset := _margin(content)
	inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(inset)
	notice = _label("Офлайн • только твои действия дают опыт", 13, MUTED)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shell.add_child(_margin(notice, 12))
	nav = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 0)
	shell.add_child(nav)
	var names := ["Лагерь", "Привычки", "Герой", "Охота", "Журнал"]
	var ids := ["today", "habits", "hero", "hunt", "journal"]
	for i in range(5):
		var b := _button(names[i], _navigate.bind(ids[i]))
		b.add_theme_font_size_override("font_size", 12)
		b.custom_minimum_size.y = 64
		b.add_theme_stylebox_override("normal", _style(BG, Color("32413e")))
		nav.add_child(b)
	var bottom := Control.new()
	bottom.custom_minimum_size.y = 12
	shell.add_child(bottom)

func _load_world() -> void:
	if game.data.settings.get("economy", false):
		return
	world = WorldScript.new()
	viewport.add_child(world)
	if world.has_signal("battle_finished"):
		world.battle_finished.connect(_battle_finished)
	if world.has_signal("battle_turn"):
		world.battle_turn.connect(_battle_turn)
	world.combat_cue.connect(sound.play_cue)
	_sync_world()

func _sync_world() -> void:
	if is_instance_valid(sound): sound.configure(game.data.settings, page)
	var economy: bool = game.data.settings.get("economy", false)
	var stage: Control = shell.get_node("Stage")
	stage.visible = page in ["today", "hero", "hunt"] and not economy
	stage.custom_minimum_size.y = 320 if page == "hero" else 280
	_resize_scene()
	if not is_instance_valid(world):
		return
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if stage.visible and not app_paused else SubViewport.UPDATE_DISABLED
	world.set_process(stage.visible and not app_paused)
	world.set_scene_active(stage.visible and not app_paused)
	var stats: Dictionary = game.stats()
	if busy and not last_battle.is_empty():
		var snapshot: Dictionary = last_battle.get("hero_snapshot", stats)
		world.set_hero(int(snapshot.level), str(snapshot.get("equipped", game.data.equipped)), snapshot.get("prep", stats.prep))
	else:
		world.set_hero(int(stats.level), str(game.data.equipped), stats.prep)
	world.set_reduced_motion(bool(game.data.settings.get("reduced_motion", false)))
	world.set_quality(bool(game.data.settings.get("high_quality", false)))
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	if not busy:
		world.set_mode("battle" if page == "hunt" else ("hero" if page == "hero" else "camp"), selected_enemy)
	Engine.max_fps = 30
	for child in scene_overlay.get_children():
		child.queue_free()
	var tag := _label("ИАРА  /  УРОВЕНЬ %d" % stats.level, 13, GOLD)
	tag.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tag.offset_left = 22
	tag.offset_right = -22
	tag.offset_top = 8
	tag.offset_bottom = 32
	scene_overlay.add_child(tag)
	var caption := _label("Сторожевая межа" if page != "hunt" else str(StateScript.ENEMIES[ENEMY_IDS[selected_enemy]].name), 25, INK, true)
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_left = 22
	caption.offset_right = -22
	caption.offset_top = -42
	caption.offset_bottom = -8
	scene_overlay.add_child(caption)
	if page == "hunt":
		combat_label = _label("Выбери подготовку и тактику", 13, GOLD)
		combat_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		combat_label.offset_left = 22
		combat_label.offset_right = -22
		combat_label.offset_top = 33
		combat_label.offset_bottom = 58
		scene_overlay.add_child(combat_label)

func _resize_scene() -> void:
	if not is_instance_valid(viewport) or not is_instance_valid(scene_box): return
	var logical_size := scene_box.size
	if logical_size.x < 1 or logical_size.y < 1: return
	# Fixed pixel grid; nearest filtering keeps sprite edges sharp on Android.
	var requested := Vector2i(384, maxi(1, int(round(384 * logical_size.y / logical_size.x))))
	if viewport.size != requested: viewport.size = requested


func _scene_input(event: InputEvent) -> void:
	if is_instance_valid(world) and not busy:
		if event is InputEventScreenDrag:
			world.rotate_hero(event.relative.x * 0.01)
		elif event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			world.rotate_hero(event.relative.x * 0.01)

func _navigate(next: String) -> void:
	busy = false
	if is_instance_valid(world) and world.has_method("stop_battle"):
		world.stop_battle()
	page = next
	_render_page()

func _clear_content() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func _render_page() -> void:
	_clear_content()
	_sync_world()
	var ids := ["today", "habits", "hero", "hunt", "journal"]
	for i in range(5):
		var b: Button = nav.get_child(i)
		b.add_theme_color_override("font_color", GOLD if ids[i] == page else MUTED)
		b.add_theme_stylebox_override("normal", _style(SURFACE if ids[i] == page else BG, EDGE if ids[i] == page else Color("32413e")))
	match page:
		"today": _today_page()
		"habits": _habits_page()
		"hero": _hero_page()
		"hunt": _hunt_page()
		"journal": _journal_page()

func _heading(kicker: String, title: String, description: String = "") -> void:
	content.add_child(_label(kicker.to_upper(), 12, GOLD))
	content.add_child(_label(title, 31, INK, true))
	if not description.is_empty():
		content.add_child(_label(description, 16, MUTED))

func _divider(parent: Control) -> void:
	var line := HSeparator.new()
	parent.add_child(line)

func _today_page() -> void:
	var info: Dictionary = game.level_info()
	_heading(game.today(), "Дела укрепляют обет", "Небольшой шаг в жизни — подготовка к следующей охоте.")
	var meter := ProgressBar.new()
	meter.max_value = max(1, int(info.xp_to_next))
	meter.value = info.xp_in_level
	meter.show_percentage = false
	meter.custom_minimum_size.y = 5
	meter.add_theme_stylebox_override("background", _style(SURFACE, SURFACE, 0))
	meter.add_theme_stylebox_override("fill", _style(GOLD, GOLD, 0))
	content.add_child(meter)
	content.add_child(_label("Уровень %d  ·  %d / %d опыта" % [info.level, info.xp_in_level, info.xp_to_next], 13, MUTED))
	var habits: Array = game.habits_today()
	var due_count := 0
	for habit in habits:
		if habit.get("due", false) or habit.get("done", false):
			due_count += 1
			_habit_row(habit, false)
	if habits.is_empty():
		content.add_child(_label("Начни с одного реального дела. Герой уже ждёт в лагере.", 18))
		content.add_child(_button("Создать привычку", _edit_habit.bind({}), true))
		content.add_child(_button("Взять пример из трёх привычек", _starter_plan))
	elif due_count == 0:
		content.add_child(_label("Сегодня нет запланированных действий. Можно отдохнуть — всё, что заработано, остаётся с тобой.", 18))
	var row := HBoxContainer.new()
	row.add_child(_button("+ Привычка", _edit_habit.bind({})))
	row.add_child(_button("Отдых включён" if game.today() in game.data.rest_days else "День отдыха", _rest_dialog))
	content.add_child(row)
	var st: Dictionary = game.stats()
	content.add_child(_label("Подготовка: сила %d · знание %d · ремесло %d" % [st.prep.force, st.prep.insight, st.prep.craft], 14, GREEN))
	content.add_child(_button("К контрактам", _navigate.bind("hunt"), true))

func _starter_plan() -> void:
	if not game.data.habits.is_empty():
		return
	for item in [["Пройтись 10 минут", "force", "Выйти на 2 минуты"], ["Прочитать 5 страниц", "insight", "Прочитать абзац"], ["Навести порядок", "craft", "Убрать одну вещь"]]:
		var result: Dictionary = game.add_habit(item[0], item[1], item[2], {"type":"daily"})
		if not result.get("ok", false):
			_render_page()
			_toast(str(result.get("error")))
			return
	_render_page()
	_toast("Пример плана готов. Измени его под свою жизнь.")

func _branch_name(branch: String) -> String:
	var index: int = BRANCHES.find(branch)
	return BRANCH_NAMES[max(0, index)]

func _schedule_name(habit: Dictionary) -> String:
	var s: Dictionary = habit.get("schedule", {})
	match s.get("type", "daily"):
		"weekly": return "%d раз в неделю" % int(s.get("count", 3))
		"weekdays": return "В выбранные дни"
	return "Каждый день"

func _habit_row(habit: Dictionary, editing: bool) -> void:
	_divider(content)
	content.add_child(_label(str(habit.title), 19))
	var completed: bool = habit.get("done", false)
	var paused: bool = habit.get("paused", false)
	var sub: String = "%s  ·  %s" % [_branch_name(str(habit.branch)), _schedule_name(habit)]
	if paused: sub += "  ·  Пауза"
	elif completed: sub += "  ·  Выполнено"
	content.add_child(_label(sub, 13, GREEN if completed else MUTED))
	var row := HBoxContainer.new()
	if editing:
		row.add_child(_button("Изменить", _edit_habit.bind(habit)))
		row.add_child(_button("Возобновить" if paused else "Пауза", _pause.bind(str(habit.id), not paused)))
	elif completed:
		row.add_child(_button("Отменить отметку", _undo.bind(str(habit.id))))
	else:
		row.add_child(_button("Выполнено", _complete.bind(str(habit.id), false), true))
		row.add_child(_button("Минимум", _minimum_dialog.bind(habit)))
	content.add_child(row)

func _habits_page() -> void:
	_heading("Мой план", "Привычки", "Ветку развития можно выбрать свободно. Полезные дела не обязаны соответствовать одному билду.")
	content.add_child(_button("+ Новая привычка", _edit_habit.bind({}), true))
	for habit in game.habits_today():
		_habit_row(habit, true)
	if game.data.habits.is_empty():
		content.add_child(_label("Пока здесь пусто. Один посильный шаг — хорошее начало.", 18, MUTED))

func _complete(id: String, minimum: bool) -> void:
	var result: Dictionary = game.complete_habit(id, minimum)
	if not result.get("ok", false):
		_toast(str(result.get("error", "Не удалось сохранить отметку")))
		return
	_render_page()
	var reward: Dictionary = result.get("reward", {})
	var xp: int = int(reward.get("xp", result.get("xp", 0)))
	var text_value: String = "+%d опыта. Отметка сохранена." % xp
	if xp > 0: sound.play_cue("reward")
	if not result.get("unlocked", []).is_empty():
		text_value += " Открыто новое снаряжение — загляни к герою."
	_toast(text_value)

func _undo(id: String) -> void:
	var result: Dictionary = game.undo_completion(id)
	_render_page()
	_toast("Отметка и её награда отменены." if result.get("ok", false) else str(result.get("error")))

func _pause(id: String, value: bool) -> void:
	var result: Dictionary = game.pause_habit(id, value)
	_render_page()
	_toast(("Пауза. Достижения остаются." if value else "Привычка возвращена в план.") if result.get("ok", false) else str(result.get("error")))

func _minimum_dialog(habit: Dictionary) -> void:
	var box := _modal_box("Достаточно малого")
	box.add_child(_label(str(habit.get("minimum", "Сделать маленький шаг")), 22, INK, true))
	box.add_child(_label("Отметь, если сделал минимальную версию. Она даёт половину опыта и подготовку, без штрафа за сокращение.", 16, MUTED))
	box.add_child(_label("Повтор отменённой отметки восстанавливает её исходную награду.", 14, MUTED))
	box.add_child(_button("Минимум выполнен", func():
		_close_modal()
		_complete(str(habit.id), true), true))
	box.add_child(_button("Назад", _close_modal))

func _rest_dialog() -> void:
	var box := _modal_box("Отдых у огня")
	box.add_child(_label("Сегодняшний план можно отложить. Отдых не приносит опыт и не отнимает достижения. Уже выполненные дела останутся в истории.", 18))
	var resting: bool = game.today() in game.data.rest_days
	box.add_child(_button("Вернуть сегодняшний план" if resting else "Запланировать отдых сегодня", func():
		var result: Dictionary = game.plan_rest()
		_close_modal()
		_render_page()
		_toast(("Сегодня — день восстановления." if result.get("rest", false) else "Сегодняшний план снова доступен.") if result.get("ok", false) else str(result.get("error"))), true))
	var future := _field(box, "Другой день отдыха (ГГГГ-ММ-ДД)", "")
	var feedback := _label("", 14, MUTED)
	box.add_child(feedback)
	box.add_child(_button("Переключить отдых в эту дату", func():
		var result: Dictionary = game.plan_rest(future.text.strip_edges()) if not future.text.strip_edges().is_empty() else {"ok":false,"error":"Укажи дату."}
		feedback.text = ("Отдых запланирован." if result.get("rest", false) else "Отдых снят.") if result.get("ok", false) else str(result.get("error"))))
	box.add_child(_button("Вернуться", _close_modal))

func _hero_page() -> void:
	var st: Dictionary = game.stats()
	_heading("Хранительница межи", "Иара")
	content.add_child(_label("УРОВЕНЬ %d   /   АТАКА %d   /   ЗАЩИТА %d" % [st.level, st.attack, st.defense], 14, GOLD))
	content.add_child(_label("Здоровье %d · выполнено действий: %d" % [st.hp, st.completions], 15, MUTED))
	content.add_child(_label("Снаряжение", 26, INK, true))
	for id in StateScript.ITEMS:
		var item: Dictionary = StateScript.ITEMS[id]
		var owned: bool = id in game.data.inventory
		var chosen: bool = game.data.equipped == id
		_divider(content)
		content.add_child(_label(str(item.name), 19, GOLD if chosen else INK))
		content.add_child(_label("Атака +%d · защита +%d · здоровье +%d" % [item.get("attack", 0), item.get("defense", 0), item.get("hp", 0)], 14, MUTED))
		if owned:
			var b := _button("Надето" if chosen else "Надеть", _equip.bind(str(id)), not chosen)
			b.disabled = chosen
			content.add_child(b)
		else:
			content.add_child(_label("Откроется с выполненными делами и контрактами.", 14, MUTED))
	content.add_child(_label("Проведи по герою, чтобы рассмотреть снаряжение. Осмотри лицо, керамический протез и фактуру экипировки.", 13, MUTED))
	content.add_child(_label("Приёмы обета", 26, INK, true))
	for ability in st.get("abilities", []):
		content.add_child(_label(str(ability.name), 18, GOLD))
		content.add_child(_label(str(ability.description), 15, MUTED))
	if st.get("abilities", []).is_empty():
		content.add_child(_label("На 3-м уровне откроется Резонанс — усиление каждого третьего удара.", 15, MUTED))
	content.add_child(_label("Бывшая настройщица погребальных колоколов. Керамическая рука слышит отголоски чудовищ.", 16, MUTED))

func _equip(id: String) -> void:
	var result: Dictionary = game.equip(id)
	_render_page()
	_toast("Снаряжение изменено и сохранено." if result.get("ok", false) else str(result.get("error")))

func _hunt_page() -> void:
	_heading("Глава I · Глухая межа", "Охота")
	if not last_battle.is_empty():
		_show_battle_summary()
	if busy:
		content.add_child(_label("Каждый удар показан из сохранённого расчёта. Можно перейти к результату или вернуться к своим делам.", 16, MUTED))
		return
	var hunts: Array = game.available_hunts()
	var contracts := OptionButton.new()
	contracts.custom_minimum_size.y = 58
	for i in range(hunts.size()):
		var hunt: Dictionary = hunts[i]
		var prefix: String = "Пройден · " if hunt.get("completed", false) else ("Закрыт · " if hunt.get("locked", false) else "")
		contracts.add_item(prefix + str(hunt.name))
		contracts.set_item_disabled(i, bool(hunt.get("locked", false)))
	contracts.select(selected_enemy)
	contracts.item_selected.connect(_select_enemy)
	content.add_child(contracts)
	var enemy: Dictionary = StateScript.ENEMIES[ENEMY_IDS[selected_enemy]]
	content.add_child(_label(str(enemy.get("description", "Изучи подготовку и выбери, как встретить противника.")), 16, MUTED))
	var st: Dictionary = game.stats()
	content.add_child(_label("Сила %d · знание %d · ремесло %d" % [st.prep.force, st.prep.insight, st.prep.craft], 14, GREEN))
	var options := OptionButton.new()
	options.custom_minimum_size.y = 58
	for name_value in TACTIC_NAMES: options.add_item(name_value)
	options.select(max(0, TACTICS.find(str(game.data.settings.get("tactic", "balanced")))))
	options.item_selected.connect(func(index: int):
		var result: Dictionary = game.set_tactic(TACTICS[index])
		if not result.get("ok", false):
			options.select(max(0, TACTICS.find(str(game.data.settings.tactic))))
			_toast(str(result.get("error"))))
	content.add_child(options)
	var completed: bool = str(enemy.id) in game.data.completed_contracts
	var start := _button("Смотреть победу снова" if completed else "Начать охоту", _start_hunt, true)
	start.disabled = busy
	content.add_child(start)
	content.add_child(_label("Натиск: +4 атаки, −3 защиты. Защита: −2 атаки, +4 защиты. Подготовка расходуется; опыт и вещи остаются.", 14, MUTED))

func _select_enemy(index: int) -> void:
	selected_enemy = index
	last_battle = {}
	_render_page()

func _start_hunt() -> void:
	if busy: return
	var enemy: Dictionary = StateScript.ENEMIES[ENEMY_IDS[selected_enemy]]
	var result: Dictionary = game.start_hunt(str(enemy.id), str(game.data.settings.get("tactic", "balanced")))
	if not result.get("ok", false):
		_toast(str(result.get("error", "Не удалось начать охоту")))
		return
	last_battle = result.battle
	busy = true
	_render_page()
	_toast("Исход сохранён. Идёт бой…")
	if is_instance_valid(world) and not game.data.settings.get("economy", false):
		world.play_battle(last_battle.get("turns", []), bool(last_battle.get("victory", false)))
	else:
		_battle_finished()

func _battle_finished() -> void:
	var was_busy := busy
	busy = false
	if was_busy and page == "hunt" and last_battle.get("victory", false): sound.play_cue("victory")
	if page == "hunt": _render_page()
	if not last_battle.is_empty():
		_toast("Победа сохранена. Путь дальше открыт." if last_battle.get("victory", false) else "Отступление. Постоянный прогресс сохранён; подготовься и попробуй снова.")

func _battle_turn(index: int, hero_hp: int, enemy_hp: int) -> void:
	if is_instance_valid(combat_label):
		combat_label.text = "ХОД %d  ·  ИАРА %d  /  ВРАГ %d" % [index, hero_hp, enemy_hp]

func _show_battle_summary() -> void:
	_divider(content)
	content.add_child(_label("Идёт охота" if busy else ("Победа" if last_battle.get("victory", false) else "Отступление"), 28, GOLD, true))
	var replay: bool = last_battle.get("replay", false)
	var reward_text: String = "Повторный просмотр. Новых наград нет." if replay else "+%d опыта · +%d осколков" % [last_battle.get("xp", 0), last_battle.get("resources", 0)]
	if busy and not replay: reward_text = "Прогресс сохранён на случай прерывания."
	content.add_child(_label(reward_text, 15, GREEN))
	if busy:
		content.add_child(_button("Перейти к результату", func():
			if is_instance_valid(world) and world.has_method("stop_battle"): world.stop_battle()
			_battle_finished()))
	else:
		content.add_child(_button("Как прошёл бой", _battle_details))

func _battle_details() -> void:
	var box := _modal_box("Журнал охоты")
	var snapshot: Dictionary = last_battle.get("hero_snapshot", {})
	box.add_child(_label("Сохранённый снимок: уровень %s, атака %s, защита %s." % [snapshot.get("level", "?"), snapshot.get("attack", "?"), snapshot.get("defense", "?")], 16, MUTED))
	for turn_data in last_battle.get("turns", []):
		box.add_child(_label("Ход %d · %s\nЗдоровье: Иара %d / враг %d" % [turn_data.get("turn", 1), turn_data.get("text", ""), turn_data.get("hero_hp", 0), turn_data.get("enemy_hp", 0)], 16))
	box.add_child(_button("Назад", _close_modal))

func _journal_page() -> void:
	_heading("Хроника", "След реальных дел", "Самоотчёт, а не проверка поведения. Здесь видны начисления, отмены и результаты охоты.")
	content.add_child(_button("Экспорт сохранения", _export_dialog))
	content.add_child(_button("Восстановить из JSON", _import_dialog))
	content.add_child(_button("Создать хронику героя", _chronicle))
	var events: Array = game.data.get("events", []).duplicate()
	events.reverse()
	if events.is_empty(): content.add_child(_label("Первое выполненное дело начнёт хронику.", 18, MUTED))
	for event in events.slice(0, 80):
		_divider(content)
		content.add_child(_label(str(event.get("day", "")), 12, GOLD))
		var title_value: String = str(event.get("title", event.get("habit_title", event.get("kind", "Событие"))))
		content.add_child(_label(title_value, 17))
		content.add_child(_label("Опыт: %s · %s" % [event.get("xp", event.get("reward", {}).get("xp", 0)), "отменено" if event.get("undone", event.get("reversed", false)) else "сохранено"], 13, MUTED))
	for battle in game.data.get("battles", []):
		_divider(content)
		content.add_child(_label("Охота · " + str(battle.get("enemy_name", battle.get("enemy_id", ""))), 18, GOLD))
		content.add_child(_label("Победа" if battle.get("victory", false) else "Отступление", 14, MUTED))

func _modal_box(title_value: String) -> VBoxContainer:
	_close_modal()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.022, 0.025, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]: margin.add_theme_constant_override("margin_" + side, 24)
	for side in ["top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 28)
	modal.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	box.add_child(_label(title_value, 32, GOLD, true))
	return box

func _close_modal() -> void:
	if is_instance_valid(modal_notice):
		modal_notice.queue_free()
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()
	modal = null

func _field(box: VBoxContainer, title_value: String, value: String) -> LineEdit:
	box.add_child(_label(title_value, 15, MUTED))
	var field := LineEdit.new()
	field.text = value
	field.max_length = 120
	field.custom_minimum_size.y = 58
	box.add_child(field)
	return field

func _edit_habit(habit: Dictionary) -> void:
	var box := _modal_box("Новое дело" if habit.is_empty() else "Изменить привычку")
	var title_input := _field(box, "Что ты хочешь делать?", str(habit.get("title", "")))
	title_input.placeholder_text = "Например: гулять 10 минут"
	var min_input := _field(box, "Минимум на трудный день", str(habit.get("minimum", "Сделать 2 минуты")))
	box.add_child(_label("Какую ветку развивает?", 15, MUTED))
	var branch := OptionButton.new()
	branch.custom_minimum_size.y = 58
	for branch_name in BRANCH_NAMES: branch.add_item(branch_name)
	branch.select(max(0, BRANCHES.find(habit.get("branch", "force"))))
	box.add_child(branch)
	box.add_child(_label("Расписание", 15, MUTED))
	var schedule := OptionButton.new()
	schedule.custom_minimum_size.y = 58
	for name_value in ["Каждый день", "Выбранные дни", "N раз в неделю"]: schedule.add_item(name_value)
	box.add_child(schedule)
	var spec: Dictionary = habit.get("schedule", {"type":"daily"})
	schedule.select(max(0, ["daily", "weekdays", "weekly"].find(spec.get("type", "daily"))))
	var weekdays := GridContainer.new()
	weekdays.columns = 4
	box.add_child(weekdays)
	var checks: Array[CheckBox] = []
	var day_names := ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
	for i in range(7):
		var check := CheckBox.new()
		check.text = day_names[i]
		check.custom_minimum_size = Vector2(76, 58)
		check.button_pressed = (i + 1) in spec.get("days", [1, 3, 5])
		weekdays.add_child(check)
		checks.append(check)
	var target := SpinBox.new()
	target.min_value = 1
	target.max_value = 7
	target.value = spec.get("count", 3)
	target.custom_minimum_size.y = 58
	box.add_child(target)
	weekdays.visible = schedule.selected == 1
	target.visible = schedule.selected == 2
	schedule.item_selected.connect(func(index: int):
		weekdays.visible = index == 1
		target.visible = index == 2)
	box.add_child(_label("Награда зависит от выполненных дел за день: первые 3 — по 20 опыта; следующие 3 — по 5. Минимум даёт половину. Дальше остаётся запись без опыта.", 14, MUTED))
	var error_label := _label("", 15, Color("f0bba5"))
	box.add_child(error_label)
	box.add_child(_button("Сохранить привычку", func():
		var chosen_schedule: Dictionary = {"type": ["daily", "weekdays", "weekly"][schedule.selected]}
		if schedule.selected == 1:
			var days: Array = []
			for i in range(7):
				if checks[i].button_pressed: days.append(i + 1)
			chosen_schedule["days"] = days
		elif schedule.selected == 2: chosen_schedule["count"] = int(target.value)
		var result: Dictionary
		if habit.is_empty():
			result = game.add_habit(title_input.text, BRANCHES[branch.selected], min_input.text, chosen_schedule)
		else:
			result = game.edit_habit(str(habit.id), {"title":title_input.text,"branch":BRANCHES[branch.selected],"minimum":min_input.text,"schedule":chosen_schedule})
		if result.get("ok", false):
			_close_modal()
			_render_page()
			_toast("План сохранён. Прошлые награды не изменились.")
		else: error_label.text = str(result.get("error", "Проверь поля")), true))
	box.add_child(_button("Отмена", _close_modal))
	title_input.grab_focus()

func _settings() -> void:
	var box := _modal_box("У костра")
	box.add_child(_label("Всё основное работает офлайн. Регистрация и уведомления не нужны.", 16, MUTED))
	var flags: Dictionary = {}
	for pair in [["economy", "Экономичный режим: без сцены"], ["reduced_motion", "Уменьшить анимации"], ["high_quality", "Дополнительные эффекты окружения"], ["auto_timezone", "Часовой пояс устройства"], ["sound_enabled", "Звуки лагеря и охоты"]]:
		var check := CheckBox.new()
		check.text = pair[1]
		check.custom_minimum_size.y = 60
		check.add_theme_font_size_override("font_size", 15)
		check.button_pressed = game.data.settings.get(pair[0], pair[0] in ["auto_timezone", "sound_enabled"])
		box.add_child(check)
		flags[pair[0]] = check
	box.add_child(_label("Громкость звука", 15, MUTED))
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 5
	volume.value = float(game.data.settings.get("sound_volume", 0.6)) * 100
	volume.custom_minimum_size.y = 58
	box.add_child(volume)
	box.add_child(_label("Размер текста", 15, MUTED))
	var text_size := OptionButton.new()
	text_size.custom_minimum_size.y = 58
	for item in ["Обычный", "Крупный (+20%)", "Очень крупный (+40%)"]: text_size.add_item(item)
	text_size.select(clampi(roundi((font_scale - 1.0) / 0.2), 0, 2))
	box.add_child(text_size)
	box.add_child(_label("Новый день начинается в час", 15, MUTED))
	var boundary := SpinBox.new()
	boundary.min_value = 0
	boundary.max_value = 23
	boundary.value = game.data.settings.get("boundary_hour", 4)
	boundary.custom_minimum_size.y = 58
	box.add_child(boundary)
	box.add_child(_label("Тряска камеры отсутствует. Напоминания пока не реализованы; никаких уведомлений или аналитики приложение не отправляет.", 14, MUTED))
	box.add_child(_button("Применить", func():
		var patch: Dictionary = {"text_scale": 1.0 + 0.2 * text_size.selected, "sound_volume": volume.value / 100.0}
		for key in flags: patch[key] = flags[key].button_pressed
		var result: Dictionary = game.set_settings(patch)
		if result.get("ok", false): result = game.set_boundary(int(boundary.value))
		if not result.get("ok", false):
			_toast(str(result.get("error")))
			return
		font_scale = patch.text_scale
		_setup_theme()
		_close_modal()
		_update_clock()
		if not is_instance_valid(world) and not patch.economy: _load_world()
		_render_page()
		_toast("Настройки сохранены."), true))
	box.add_child(_button("Конфиденциальность и поддержка", _privacy))
	box.add_child(_button("Лицензии и версия", _credits))
	box.add_child(_button("Назад", _close_modal))

func _privacy() -> void:
	var box := _modal_box("Конфиденциальность")
	box.add_child(_label(FileAccess.get_file_as_string("res://assets/legal/privacy_ru.txt"), 15, INK))
	box.add_child(_button("Назад", _close_modal))

func _credits() -> void:
	var box := _modal_box("Пепельный обет · " + str(ProjectSettings.get_setting("application/config/version", "0.2.0")))
	box.add_child(_label("Оригинальная RPG привычек с пиксельной 2D-сценой и отдельными боевыми спрайтами.", 17))
	box.add_child(_label("Новые фон и спрайты созданы с помощью imagegen для Пепельного обета. Персонажи и мир оригинальные; ресурсы Scott Pilgrim не используются. Godot — MIT. Noto Sans — SIL Open Font License. Архивные 3D-ресурсы описаны в THIRD_PARTY_NOTICES.md.", 15, MUTED))
	box.add_child(_label("Godot: godotengine.org/license\nUniversal Modder: github.com/rehan-remade/universal-modder\nUI UX Pro Max: github.com/nextlevelbuilder/ui-ux-pro-max-skill", 14, MUTED))
	box.add_child(_button("Назад", _close_modal))

func _export_dialog() -> void:
	var raw: String = game.export_json()
	var box := _modal_box("Копия твоего пути")
	box.add_child(_label("Экспорт содержит личные названия привычек. Сохрани его в своё безопасное место. Хроника для друзей их не содержит.", 16, MUTED))
	var text_edit := TextEdit.new()
	text_edit.text = raw
	text_edit.editable = false
	text_edit.custom_minimum_size.y = 260
	box.add_child(text_edit)
	box.add_child(_button("Скопировать JSON", func():
		DisplayServer.clipboard_set(raw)
		_toast("Сохранение скопировано в буфер обмена."), true))
	box.add_child(_button("Сохранить файл…", _save_export.bind(raw)))
	box.add_child(_button("Назад", _close_modal))

func _save_export(raw: String) -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.current_file = "ashen-oath-" + game.today() + ".json"
	dialog.add_filter("*.json", "JSON")
	add_child(dialog)
	dialog.file_selected.connect(func(path_value: String):
		var file := FileAccess.open(path_value, FileAccess.WRITE)
		if file:
			file.store_string(raw)
			file.flush()
			var write_error: Error = file.get_error()
			file.close()
			_toast("Копия сохранена: " + path_value if write_error == OK else "Ошибка записи. Копия может быть неполной; выбери другое место.")
		else: _toast("Не удалось записать файл. Используй копирование JSON.")
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered_ratio(0.9)

func _import_dialog() -> void:
	var box := _modal_box("Восстановить путь")
	box.add_child(_label("Вставь JSON из своей резервной копии. Кнопка ниже заменит текущий план и прогресс после проверки файла.", 17, MUTED))
	var input := TextEdit.new()
	input.custom_minimum_size.y = 280
	box.add_child(input)
	var error_label := _label("", 15, Color("f0bba5"))
	box.add_child(error_label)
	box.add_child(_button("Вставить из буфера", func(): input.text = DisplayServer.clipboard_get()))
	box.add_child(_button("Проверить и заменить сохранение", func():
		var result: Dictionary = game.import_json(input.text)
		if result.get("ok", false):
			_close_modal()
			_after_import()
			_toast("Копия восстановлена.")
		else: error_label.text = str(result.get("error", "Некорректный JSON")), true))
	box.add_child(_button("Отмена", _close_modal))

func _after_import() -> void:
	busy = false
	last_battle = {}
	selected_enemy = 0
	if is_instance_valid(world) and world.has_method("stop_battle"): world.stop_battle()
	font_scale = float(game.data.settings.get("text_scale", 1.0))
	_setup_theme()
	_update_clock()
	if not is_instance_valid(world) and not game.data.settings.get("economy", false) and not ui_testing: _load_world()
	_render_page()

func _chronicle() -> void:
	var st: Dictionary = game.stats()
	var raw: String = "ПЕПЕЛЬНЫЙ ОБЕТ\nМой герой на %s\nУровень %d · %d реальных действий\nКонтрактов: %d\nСнаряжение: %s\nТвой герой развивается благодаря реальной жизни." % [game.today(), st.level, st.completions, game.data.completed_contracts.size(), StateScript.ITEMS[game.data.equipped].name]
	var box := _modal_box("Моя хроника")
	var current_modal: Control = modal
	var status := _label("Собираем снимок настоящего героя…", 16, MUTED)
	box.add_child(status)
	box.add_child(_label("Названия привычек скрыты. Эта карточка показывает текущее состояние; месячная видеохроника ещё не реализована.", 15, MUTED))
	box.add_child(_button("Скопировать для публикации", func():
		DisplayServer.clipboard_set(raw)
		_toast("Хроника скопирована. Ты выбираешь, где ей поделиться."), true))
	box.add_child(_button("Назад", _close_modal))
	var maker := ChronicleScript.new()
	add_child(maker)
	var card_image: Image = await maker.render_card(int(st.level), str(game.data.equipped), st.prep, int(st.completions), game.data.completed_contracts.size(), game.today(), theme)
	maker.queue_free()
	if not is_instance_valid(current_modal) or modal != current_modal: return
	if card_image:
		status.text = "Снимок готов. Данные остаются на устройстве."
		var preview := TextureRect.new()
		preview.texture = ImageTexture.create_from_image(card_image)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.custom_minimum_size = Vector2(0, 480)
		box.add_child(preview)
		box.move_child(preview, 2)
		var save := _button("Сохранить карточку PNG…", _save_card.bind(card_image), true)
		box.add_child(save)
		box.move_child(save, 3)
	else:
		status.text = raw

func _save_card(card_image: Image) -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.current_file = "ashen-chronicle-" + game.today() + ".png"
	dialog.add_filter("*.png", "PNG image")
	add_child(dialog)
	dialog.file_selected.connect(func(path_value: String):
		var err: Error = card_image.save_png(path_value)
		_toast("Карточка сохранена." if err == OK else "Не удалось записать PNG. Выбери доступную папку.")
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered_ratio(0.9)

func _toast(value: String) -> void:
	if is_instance_valid(notice):
		notice.text = value
		notice.add_theme_color_override("font_color", GOLD)
	if is_instance_valid(modal):
		if is_instance_valid(modal_notice): modal_notice.queue_free()
		modal_notice = PanelContainer.new()
		modal_notice.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		modal_notice.offset_left = 16
		modal_notice.offset_right = -16
		modal_notice.offset_top = -145
		modal_notice.offset_bottom = -24
		modal_notice.add_theme_stylebox_override("panel", _style(SURFACE, GOLD))
		modal_notice.z_index = 100
		modal_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
		modal_notice.add_child(_label(value, 16, GOLD))
		add_child(modal_notice)
		var shown: PanelContainer = modal_notice
		get_tree().create_timer(4.0, false).timeout.connect(func():
			if is_instance_valid(shown): shown.queue_free())

func _qa_run() -> void:
	# Isolated real-render smoke fixture; never uses the user's save.
	await get_tree().create_timer(2.0).timeout
	if game.data.habits.is_empty(): _starter_plan()
	for habit in game.habits_today():
		if not habit.get("done", false): game.complete_habit(str(habit.id))
	if "ash_hook" in game.data.inventory: game.equip("ash_hook")
	_render_page()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/01-camp.png")
	_navigate("hero")
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/02-hero.png")
	_navigate("hunt")
	_start_hunt()
	await get_tree().create_timer(4.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/03-hunt.png")
	await get_tree().create_timer(6.0).timeout
	_navigate("journal")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/04-journal.png")
	print("UI_QA_COMPLETED ", game.stats())
	get_tree().quit()
