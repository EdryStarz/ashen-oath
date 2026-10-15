class_name ChronicleCard
extends Node
## Renders a private-by-default snapshot; never accesses or changes GameState.
## The caller supplies actual current values and decides whether to save/share.

const WorldScript = preload("res://scripts/world.gd")
const EQUIPMENT_NAMES := {
	"worn_blade": "Дорожный клинок",
	"ash_hook": "Пепельный крюк",
	"oath_mantle": "Мантия обета",
	"ember_lantern": "Жаровой фонарь"
}
const INK := Color("eee7d8")
const MUTED := Color("b5bdb9")
const GOLD := Color("d1b480")
var rendering := false
var _cancelled := false
var _deadline_msec := 0
var _holds_capture_lease := false
var _viewports: Array[SubViewport] = []
# Closing and reopening the modal can overlap two short captures. The last
# owner restores the original preference rather than overwriting it per card.
static var _active_captures := 0
static var _saved_low_processor_mode := false


func render_card(level: int, equipment: String, prep: Dictionary, completions: int,
		contracts: int, day: String, theme: Theme) -> Image:
	# Dummy/headless rendering has no image to read; do not create any viewports.
	if DisplayServer.get_name() == "headless" or not is_inside_tree() or rendering:
		return null
	rendering = true
	_cancelled = false
	_deadline_msec = Time.get_ticks_msec() + 12000
	if _active_captures == 0:
		_saved_low_processor_mode = OS.low_processor_usage_mode
	_active_captures += 1
	_holds_capture_lease = true
	OS.low_processor_usage_mode = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var stage := SubViewport.new()
	stage.name = "Chronicle3D"
	stage.size = Vector2i(432, 400)
	stage.own_world_3d = true
	stage.transparent_bg = false
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	stage.msaa_3d = Viewport.MSAA_2X
	add_child(stage)
	_viewports.append(stage)
	var world := WorldScript.new()
	stage.add_child(world)
	world.set_hero(level, equipment, prep.duplicate(true))
	world.set_mode("hero")
	world.set_reduced_motion(true)
	world.set_quality(false)
	world.set_process(false)
	# A static Android journal may never emit frame_post_draw with low processor
	# usage enabled. Use explicit, bounded draw passes, never an unbounded signal.
	if not await _render_passes(stage, 3):
		_finish_capture()
		return null
	var hero_image := stage.get_texture().get_image()
	_dispose_viewport(stage)
	if hero_image == null or hero_image.is_empty():
		_finish_capture()
		return null
	var hero_texture := ImageTexture.create_from_image(hero_image)
	var canvas := SubViewport.new()
	canvas.name = "Chronicle2D"
	canvas.size = Vector2i(432, 768)
	canvas.disable_3d = true
	canvas.transparent_bg = false
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(canvas)
	_viewports.append(canvas)
	var page := Control.new()
	page.size = Vector2(432, 768)
	if theme:
		page.theme = theme
	canvas.add_child(page)
	var body_font: Font = load("res://assets/fonts/NotoSans.ttf") if ResourceLoader.exists("res://assets/fonts/NotoSans.ttf") else null
	var title_font: Font = load("res://assets/fonts/Cormorant.ttf") if ResourceLoader.exists("res://assets/fonts/Cormorant.ttf") else body_font
	_rect(page, Rect2(0, 0, 432, 768), Color("101719"))
	_rect(page, Rect2(26, 22, 34, 2), GOLD)
	_label(page, "ПЕПЕЛЬНЫЙ ОБЕТ", Rect2(74, 10, 330, 28), 13, GOLD, body_font)
	_label(page, "Моя хроника", Rect2(26, 42, 380, 46), 38, INK, title_font)
	_label(page, "ТЕКУЩИЙ ГЕРОЙ", Rect2(28, 89, 376, 24), 11, MUTED, body_font)
	var portrait := TextureRect.new()
	portrait.position = Vector2(0, 122)
	portrait.size = Vector2(432, 400)
	portrait.texture = hero_texture
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	page.add_child(portrait)
	# Two small solid strips frame the image without covering the actual model.
	_rect(page, Rect2(0, 500, 432, 22), Color("101719"))
	_label(page, "Иара · уровень %d" % level, Rect2(26, 511, 380, 42), 30, INK, title_font)
	_label(page, str(EQUIPMENT_NAMES.get(equipment, equipment)), Rect2(27, 553, 378, 26), 15, GOLD, body_font)
	_rect(page, Rect2(27, 590, 378, 1), Color("4a5652"))
	_label(page, str(completions), Rect2(26, 603, 174, 39), 31, INK, body_font)
	_label(page, "отмеченных действий", Rect2(27, 645, 182, 28), 12, MUTED, body_font)
	_label(page, str(contracts), Rect2(235, 603, 170, 39), 31, INK, body_font)
	_label(page, "контрактов завершено", Rect2(236, 645, 170, 28), 12, MUTED, body_font)
	_label(page, "Герой растёт благодаря реальным делам.", Rect2(27, 694, 380, 30), 13, GOLD, body_font)
	var safe_day := day.replace("\n", " ").replace("\r", " ").substr(0, 24)
	_label(page, safe_day + "  ·  Личные привычки скрыты", Rect2(27, 737, 380, 21), 10, MUTED, body_font)
	if not await _render_passes(canvas, 2):
		_finish_capture()
		return null
	var result := canvas.get_texture().get_image()
	_finish_capture()
	if result == null or result.is_empty():
		return null
	return result


func _render_passes(viewport: SubViewport, count: int) -> bool:
	for _frame in range(count):
		if not _can_capture():
			return false
		# This timer runs while SceneTree is paused and ignores Engine.time_scale;
		# cancellation therefore resolves without a draw signal after app suspend.
		await get_tree().create_timer(0.04, true, false, true).timeout
		if not _can_capture() or not is_instance_valid(viewport):
			return false
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		RenderingServer.force_draw(false, 0.0)
	if not _can_capture():
		return false
	RenderingServer.force_sync()
	return true


func _can_capture() -> bool:
	return not _cancelled and is_inside_tree() and not get_tree().paused and Time.get_ticks_msec() <= _deadline_msec


func cancel_render() -> void:
	_cancelled = true
	for viewport in _viewports:
		if is_instance_valid(viewport):
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_release_capture_lease()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and rendering:
		cancel_render()


func _exit_tree() -> void:
	# If the owning UI is removed during a capture, child nodes are freed by
	# Godot and the global idle preference must still be restored immediately.
	cancel_render()


func _dispose_viewport(viewport: SubViewport) -> void:
	_viewports.erase(viewport)
	if is_instance_valid(viewport):
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		if viewport.get_parent() == self:
			remove_child(viewport)
		viewport.queue_free()


func _release_capture_lease() -> void:
	if not _holds_capture_lease:
		return
	_holds_capture_lease = false
	_active_captures = maxi(0, _active_captures - 1)
	if _active_captures == 0:
		OS.low_processor_usage_mode = _saved_low_processor_mode


func _finish_capture() -> void:
	for viewport in _viewports.duplicate():
		_dispose_viewport(viewport)
	_release_capture_lease()
	rendering = false


func _rect(parent: Control, rect: Rect2, color: Color) -> void:
	var block := ColorRect.new()
	block.position = rect.position
	block.size = rect.size
	block.color = color
	parent.add_child(block)


func _label(parent: Control, text: String, rect: Rect2, font_size: int,
		color: Color, font: Font) -> void:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	if font:
		label.add_theme_font_override("font", font)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(label)
