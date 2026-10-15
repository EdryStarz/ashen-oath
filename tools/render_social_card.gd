extends SceneTree
var canvas: Node2D
var font: Font
var camp: Texture2D
var icon: Texture2D
func _initialize() -> void: call_deferred("run")
func run() -> void:
 root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 root.content_scale_size = Vector2i.ZERO
 root.size = Vector2i(1200,630)
 font = load("res://assets/fonts/NotoSans.ttf")
 camp = load("res://assets/pixel/camp.png")
 icon = load("res://assets/store_icon.png")
 canvas = Node2D.new()
 canvas.draw.connect(paint)
 root.add_child(canvas)
 await process_frame
 await RenderingServer.frame_post_draw
 var error := root.get_texture().get_image().save_png("res://docs/site-assets/social-card.png")
 quit(error)
func paint() -> void:
 canvas.draw_texture_rect(camp,Rect2(0,0,1200,630),false)
 canvas.draw_rect(Rect2(0,0,1200,630),Color(.035,.055,.11,.88))
 canvas.draw_string(font,Vector2(58,79),"ASHEN OATH / ПЕПЕЛЬНЫЙ ОБЕТ",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("7de1cd"))
 canvas.draw_string(font,Vector2(55,215),"Your to-do list",HORIZONTAL_ALIGNMENT_LEFT,-1,65,Color("f8f0df"))
 canvas.draw_string(font,Vector2(55,302),"has a boss fight.",HORIZONTAL_ALIGNMENT_LEFT,-1,65,Color("ffd677"))
 canvas.draw_string(font,Vector2(59,377),"Реальные дела. Пиксельные победы.",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("b5bdd1"))
 canvas.draw_rect(Rect2(58,443,427,58),Color("ffd677"))
 canvas.draw_string(font,Vector2(83,482),"ANDROID  /  FREE  /  OFFLINE",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("111626"))
 canvas.draw_texture_rect(icon,Rect2(756,119,382,382),false)
 canvas.draw_line(Vector2(58,554),Vector2(1138,554),Color("34415b"),1)
 canvas.draw_string(font,Vector2(58,596),"EMBERTRAIL STUDIO",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("b5bdd1"))
 canvas.draw_string(font,Vector2(737,596),"edrystarz.github.io/ashen-oath",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("b5bdd1"))
