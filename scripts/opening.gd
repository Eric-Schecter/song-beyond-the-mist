extends Node2D
var game: Node2D
var age := 0.0
var phase := 0
var music: AudioStreamPlayer
var title_font := SystemFont.new()
var title_ink: Node2D
var title_cjk: FontFile
var overlay: Node2D
var backgrounds: Texture2D
var title_background: Texture2D
var selection:=0
var web_cover_waiting := false
const LINES := [
["Once, the river connected every village. ","Princess Lia built canals along its banks, bringing life back to barren fields."],
["Then black mist crossed the northern border, and the capital fell silent. ","The Demon King took the princess. Even the spring's guardian turned against the valley."],
["You grew up in Morningwind, and have only just learned to wield a sword. ","Today, the riverbed is dry. A child who left to find water has not come home."]]
func _ready():
	web_cover_waiting = OS.has_feature("web") and "--web-cover" in OS.get_cmdline_user_args()
	preload("res://scripts/game_locale.gd").restore()
	title_font.font_names = PackedStringArray(["Georgia","Noto Serif","Songti SC"])
	title_font.font_weight = 600
	title_font.multichannel_signed_distance_field = true
	title_font.msdf_size = 96
	title_cjk = load("res://assets/fonts/NotoSansCJKsc-Regular.otf").duplicate()
	title_cjk.multichannel_signed_distance_field = true
	title_cjk.msdf_size = 96
	backgrounds=load("res://assets/refined/opening.png")
	title_background=load("res://assets/refined/title_departure.png")
	game=load("res://main.tscn").instantiate()
	game.set_meta("opening_preview",true)
	game.set_meta("music_context","title")
	game.set_meta("defer_title_music",web_cover_waiting)
	add_child(game)
	title_font.fallbacks = [title_cjk]
	game.set_physics_process(false)
	game.set_process_input(false)
	game.set_meta("opening_preview",true)
	var layer := CanvasLayer.new()
	add_child(layer)
	overlay=Node2D.new()
	layer.add_child(overlay)
	overlay.draw.connect(paint)
	# Smooth scalable lettering on its own canvas; keep the pixel artwork untouched.
	title_ink = Node2D.new()
	title_ink.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	layer.add_child(title_ink)
	title_ink.draw.connect(paint_title)
	music=game.score.music
	if web_cover_waiting:
		announce_web_ready()
func announce_web_ready():
	# Two rendered frames include title font rasterization and texture upload.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	JavaScriptBridge.eval("window.songGameReady && window.songGameReady()")
func _process(delta):
	if web_cover_waiting:
		if not JavaScriptBridge.eval("window.songCoverEntered === true"):
			return
		web_cover_waiting = false
		age = 0.0
		music.play()
	age+=delta
	if phase==4 and age>=1.5:
		phase=5
		game.remove_meta("opening_preview")
		game.set_physics_process(true)
		game.set_process_input(true)
		game.queue_redraw()
	overlay.queue_redraw()
	title_ink.queue_redraw()
func advance():
	if phase>=4 or age<.35:return
	game._play("confirm")
	phase+=1
	if phase==1:
		game.set_meta("music_context","history")
		game.score.set_context("history")
	elif phase==4:
		game.set_meta("music_context","adventure")
		game.score.set_context("adventure")
	age=0
func _input(event):
	if web_cover_waiting or phase>=4:return
	if phase==0:
		if event is InputEventMouseMotion:
			for i in range(3):
				if menu_rect(i).has_point(event.position):selection=i
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			for i in range(3):
				if menu_rect(i).has_point(event.position):selection=i;choose_title();break
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode in [KEY_UP,KEY_W]:selection=posmod(selection-1,3)
			elif event.physical_keycode in [KEY_DOWN,KEY_S]:selection=posmod(selection+1,3)
			elif event.physical_keycode in [KEY_ENTER,KEY_SPACE,KEY_E]:choose_title()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ENTER,KEY_SPACE,KEY_E]:advance()
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:advance()
func menu_rect(index:int)->Rect2:return Rect2(143,123+index*24,155,22)
func choose_title():
	if age<.35:return
	match selection:
		0:advance()
		1:preload("res://scripts/game_locale.gd").toggle()
		2:get_tree().quit()
func label(value:String,p:Vector2,size:int,color:Color):
	value=preload("res://scripts/game_locale.gd").text(value)
	overlay.draw_string(title_font if size>=20 else game.font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func paint_title():
	if phase != 0:return
	var color := Color("#ede2c7")
	if preload("res://scripts/game_locale.gd").language == "zh":
		title_ink.draw_string(title_cjk,Vector2(143,91),preload("res://scripts/game_locale.gd").text("Song Beyond the Mist"),HORIZONTAL_ALIGNMENT_LEFT,-1,27,color)
	else:
		title_ink.draw_string(title_font,Vector2(141,72),"Song Beyond",HORIZONTAL_ALIGNMENT_LEFT,-1,21,color)
		title_ink.draw_string(title_font,Vector2(142,100),"the Mist",HORIZONTAL_ALIGNMENT_LEFT,-1,25,color)
func paint():
	if phase==5:return
	var skin=preload("res://scripts/ui_skin.gd")
	if phase<4 and backgrounds != null:
		var cell := Vector2(backgrounds.get_size())/Vector2(1,3)
		overlay.draw_texture_rect_region(backgrounds,Rect2(0,0,320,224),Rect2(Vector2(0,maxi(0,phase-1)*cell.y),cell))
	if phase==0:
		if title_background!=null:overlay.draw_texture_rect(title_background,Rect2(0,0,320,224),false,Color.WHITE)
		# Keep the departure illustration bright; shade only the menu area.
		for x in range(320):
			var shade:float=lerpf(0.0,.38,smoothstep(105,300,x))
			overlay.draw_rect(Rect2(x,0,1,224),Color(.07,.085,.10,shade))
		overlay.draw_line(Vector2(143,111),Vector2(285,111),Color(skin.GOLD,.42),.6,true)
		var labels:=["New Journey","Language: English","Quit"]
		for i in range(3):
			var rect:=menu_rect(i)
			var selected:bool=i==selection
			if selected:
				var p:=rect.position+Vector2(4,11)
				overlay.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-2),p+Vector2(2,0),p+Vector2(0,2),p+Vector2(-2,0)]),skin.GOLD)
				overlay.draw_line(rect.position+Vector2(15,21),rect.position+Vector2(120,21),Color(skin.GOLD,.55),.6,true)
			label(labels[i],rect.position+Vector2(15,15),11,skin.TEXT if selected else Color("#a7aaa5"))
	elif phase<4:
		skin.panel(overlay,Rect2(8,137,304,80),true)
		var heading:String=["The Valley Before","The Mist Arrives","Morning in the Village"][phase-1]
		heading=preload("res://scripts/game_locale.gd").text(heading)
		var heading_width:float=game.font.get_string_size(heading,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
		skin.panel(overlay,Rect2(15,126,heading_width+16,23))
		label(heading,Vector2(23,142),11,skin.TEXT)
		var lines=game.story.wrapped(preload("res://scripts/game_locale.gd").text(LINES[phase-1][0])+preload("res://scripts/game_locale.gd").text(LINES[phase-1][1]),278)
		for j in range(lines.size()):label(lines[j],Vector2(21,164+j*14),10,skin.INK)
		var p:=Vector2(297,204+roundf(sin(age*5)*1.5))
		overlay.draw_colored_polygon(PackedVector2Array([p+Vector2(-3,-2),p+Vector2(3,-2),p+Vector2(0,2)]),skin.INK)
	else:
		overlay.draw_rect(Rect2(0,0,320,224),Color(.09,.14,.12,1-clampf(age/1.5,0,1)))
