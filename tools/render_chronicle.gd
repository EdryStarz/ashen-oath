extends SceneTree
## Isolated example fixture; it does not read a user's save or claim real progress.
const Card = preload("res://scripts/chronicle_card.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	OS.low_processor_usage_mode = true
	var card := Card.new()
	root.add_child(card)
	var result: Image = await card.render_card(4, "ember_lantern", {"force": 2, "insight": 1}, 23, 3, "2026-10-08", null)
	if DisplayServer.get_name() == "headless":
		var valid: bool = result == null and card.get_child_count() == 0
		print("CHRONICLE_HEADLESS_GUARD=", valid)
		quit(0 if valid else 1)
		return
	if result == null:
		push_error("Chronicle card produced no image")
		quit(1)
		return
	var error := result.save_png("res://artifacts/chronicle-fixture.png")
	print("CHRONICLE_RENDER saved=", error, " size=", result.get_size(), " remaining_viewports=", card.get_child_count(), " low_processor_restored=", OS.low_processor_usage_mode)
	if not OS.low_processor_usage_mode or card.get_child_count() != 0:
		quit(2)
		return
	card.call_deferred("cancel_render")
	var cancelled: Image = await card.render_card(1, "worn_blade", {}, 0, 0, "2026-10-08", null)
	var cancel_ok: bool = cancelled == null and OS.low_processor_usage_mode and card.get_child_count() == 0
	print("CHRONICLE_CANCEL_RESTORE=", cancel_ok)
	quit(error if cancel_ok else 3)
