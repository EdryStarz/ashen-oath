extends SceneTree
var canvas: Node2D
var images: Array[Texture2D] = []
var font: Font
func _initialize() -> void: call_deferred("run")
func run() -> void:
 root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 root.content_scale_size = Vector2i.ZERO
 root.size = Vector2i(1440,1320)
 font = load("res://assets/fonts/NotoSans.ttf")
 for device in ["phone","tablet"]:
  for i in range(4):
   images.append(ImageTexture.create_from_image(Image.load_from_file("res://artifacts/store-art/%s/%02d.png" % [device,i+1])))
 canvas = Node2D.new()
 canvas.draw.connect(paint)
 root.add_child(canvas)
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/store-art/preview.png")
 quit()
func paint() -> void:
 canvas.draw_rect(Rect2(0,0,1440,1320),Color("12152b"))
 for row in range(2):
  canvas.draw_string(font,Vector2(20,28+row*660),"ТЕЛЕФОН" if row==0 else "ПЛАНШЕТ",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("ffdb85"))
  for column in range(4):
   var texture := images[row*4+column]
   var ratio := minf(330.0/texture.get_width(),610.0/texture.get_height())
   var size := texture.get_size()*ratio
   canvas.draw_texture_rect(texture,Rect2(Vector2(column*360+15+(330-size.x)*.5,row*660+41),size),false)
