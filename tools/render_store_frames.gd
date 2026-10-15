extends SceneTree
var canvas: Node2D
var current_image: Texture2D
var icon: Texture2D
var camp: Texture2D
var font: Font
var target_size := Vector2(1080,1920)
var headlines := [["Маленькие шаги.","Настоящий прогресс."],["Развивай", "свою героиню."],["Готовься к охоте.", "Выбирай тактику."],["Вся история —", "под твоим контролем."]]
var labels := ["ПРИВЫЧКИ И ПРИКЛЮЧЕНИЯ", "ОПЫТ · УРОВНИ · СНАРЯЖЕНИЕ", "ТРИ СУЩЕСТВА · ТВОЯ ТАКТИКА", "ХРОНИКА · ЭКСПОРТ · ВОССТАНОВЛЕНИЕ"]
var current := 0
var device := "phone"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	font = load("res://assets/fonts/NotoSans.ttf")
	icon = load("res://assets/store_icon.png")
	camp = load("res://assets/pixel/camp.png")
	canvas = Node2D.new()
	canvas.draw.connect(paint)
	root.add_child(canvas)
	for type in ["phone","tablet"]:
		device = type
		target_size = Vector2(1080,1920) if type == "phone" else Vector2(1200,1920)
		root.size = Vector2i(target_size)
		for index in range(4):
			current = index
			var image := Image.load_from_file("res://artifacts/store-art/%s/raw/%02d.png" % [type,index+1])
			current_image = ImageTexture.create_from_image(image)
			canvas.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var path := "res://artifacts/store-art/%s/%02d.png" % [type,index+1]
			var result := root.get_texture().get_image().save_png(path)
			print("STORE_FRAME ",type," ",index+1," result=",result)
	quit()
func paint() -> void:
	var w := target_size.x
	canvas.draw_rect(Rect2(Vector2.ZERO,target_size),Color("12152b"))
	canvas.draw_texture_rect(camp,Rect2(0,0,w,470),false,Color(0.42,0.4,0.64,1))
	canvas.draw_rect(Rect2(0,0,w,470),Color(0.06,0.07,0.17,0.66))
	for i in range(12):
		canvas.draw_rect(Rect2(15+(i%3)*23,550+i*93,8,8),Color("354467"))
		canvas.draw_rect(Rect2(w-38-(i%2)*18,470+i*111,8,8),Color("365165"))
	canvas.draw_texture_rect(icon,Rect2(70,42,78,78),false)
	canvas.draw_string(font,Vector2(175,94),"ПЕПЕЛЬНЫЙ ОБЕТ",HORIZONTAL_ALIGNMENT_LEFT,-1,38,Color("ffdb85"))
	canvas.draw_string(font,Vector2(70,198),headlines[current][0],HORIZONTAL_ALIGNMENT_LEFT,-1,62,Color("f1f4ff"))
	canvas.draw_string(font,Vector2(70,277),headlines[current][1],HORIZONTAL_ALIGNMENT_LEFT,-1,62,Color("f1f4ff"))
	canvas.draw_string(font,Vector2(72,321),labels[current],HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("78dfd1"))
	var available := Rect2(70,369,w-140,1478)
	var ratio := minf(available.size.x / current_image.get_width(),available.size.y/current_image.get_height())
	var size := current_image.get_size()*ratio
	var rect := Rect2(available.position+(available.size-size)*0.5,size)
	canvas.draw_rect(Rect2(rect.position+Vector2(-9,-9),rect.size+Vector2(18,18)),Color("6072a0"))
	canvas.draw_texture_rect(current_image,rect,false)
	canvas.draw_line(Vector2(70,1880),Vector2(w-70,1880),Color("38415f"),2)
	canvas.draw_string(font,Vector2(70,1910),"ОФЛАЙН  /  БЕЗ РЕКЛАМЫ И ПОКУПОК",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("a9b6d6"))
