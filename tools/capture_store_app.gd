extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 root.size = Vector2i(1280,2048) if "--tablet" in OS.get_cmdline_user_args() else Vector2i(1080,1920)
 await process_frame
 print("STORE_CAPTURE_SIZE ",root.size)
 var app: Node = load("res://main.tscn").instantiate()
 root.add_child(app)

