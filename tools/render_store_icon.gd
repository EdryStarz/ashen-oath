extends SceneTree
func _initialize() -> void:
 var image := Image.load_from_file("res://assets/pixel/store-icon-grid.png")
 image.resize(512,512,Image.INTERPOLATE_NEAREST)
 image.save_png("res://assets/store_icon.png")
 image.save_png("res://artifacts/rustore/icon-512.png")
 image.save_png("res://artifacts/store-art/icon-512.png")
 quit()
