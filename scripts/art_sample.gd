extends "res://scripts/valley.gd"

var return_scene: Node2D
var sample_texture: Texture2D
var sample_zoom := 1.0
var sample_font: FontFile

func _ready() -> void:
	set_meta("art_sample",true)
	set_meta("motion_sample",true)
	set_meta("hero_art_scale",1.5)
	super._ready()
	sample_font = font.duplicate()
	sample_font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	if ResourceLoader.exists("res://assets/refined/mine_sample.png"):
		sample_texture = load("res://assets/refined/mine_sample.png")

func _reset() -> void:
	super._reset()
	player = Vector2(150,142)
	facing = Vector2.DOWN
	camera = Vector2.ZERO
	intro_time = 0
	message_time = 0
	relic_found = true
	gate_open = true
	cave_open = true
	slime_health = 0
	floor_tiles.clear()
	for y in range(4,12):
		for x in range(4,17): floor_tiles[Vector2i(x,y)] = true
	exploration.enemies.clear()
	exploration.shots.clear()
	exploration.greeted = true
	exploration.healing_taken = true
	exploration._add("skeleton",Vector2i(13,8),Rect2(64,64,208,128))
	var target: Dictionary = exploration.enemies[0]
	target.hp = 999
	target.stun = 999
	mine.prism_found = false

func _walkable(point: Vector2) -> bool:
	var normalized := (point-Vector2(160,144))/Vector2(108,48)
	return normalized.length_squared() < 1.0 or Rect2(148,182,24,20).has_point(point)

func _at_camp() -> bool:
	return true

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.physical_keycode in [KEY_ESCAPE,KEY_F6]:
			if is_instance_valid(return_scene):
				return_scene.process_mode = Node.PROCESS_MODE_INHERIT
				return_scene.show()
				return_scene.art_preview = null
				queue_free()
			else: get_tree().change_scene_to_file("res://main.tscn")
			return
		if event.physical_keycode == KEY_Z:
			sample_zoom = 1.5 if sample_zoom == 1 else 1.0
			return
		if event.physical_keycode in [KEY_E,KEY_F,KEY_M]: return
	super._input(event)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	camera = Vector2.ZERO
	if not exploration.enemies.is_empty():
		exploration.enemies[0].stun = 999
		exploration.enemies[0].push = Vector2.ZERO

func _sample_text(value: String,p: Vector2,size: int,color: Color) -> void:
	draw_string(sample_font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _draw() -> void:
	draw_rect(Rect2(0,0,320,224),Color("#101824"))
	draw_set_transform(Vector2(160,112)-Vector2(160,112)*sample_zoom,0,Vector2.ONE*sample_zoom)
	if sample_texture: draw_texture_rect(sample_texture,Rect2(0,0,320,224),false)
	if not exploration.enemies.is_empty():
		var e: Dictionary = exploration.enemies[0]
		var p: Vector2 = e.pos
		var straw := Color("#e2b66c") if e.flash <= 0 else CREAM
		draw_set_transform(Vector2(160,112)-Vector2(160,112)*sample_zoom,0,Vector2.ONE*sample_zoom)
		draw_circle(p+Vector2(0,4),6,Color(0,0,0,0.3))
		draw_line(p+Vector2(0,-16),p+Vector2(0,4),Color("#694431"),3)
		draw_line(p+Vector2(-7,-9),p+Vector2(7,-9),Color("#9d7250"),2)
		draw_circle(p+Vector2(0,-15),4,straw)
		draw_rect(Rect2(p+Vector2(-4,-10),Vector2(8,10)),straw)
		for i in range(3): draw_line(p+Vector2(-4,-8+i*3),p+Vector2(4,-8+i*3),Color("#8b5a37"),0.5)
		draw_arc(p+Vector2(0,-5),2,0,TAU,12,Color("#a45848"),0.7)
	_draw_hero()
	if pulse_time > 0:
		draw_arc(pulse_origin,6+(1-pulse_time/0.32)*(_pulse_radius()-6),0,TAU,48,GOLD,0.6)
	for effect in effects:
		draw_line(effect.pos-Vector2(1,0),effect.pos+Vector2(1,0),effect.color,0.7)
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(0,0,320,25),Color(0.035,0.055,0.08,0.85))
	_sample_text("Floating Sword / Slash & Uppercut Study",Vector2(9,16),9,CREAM)
	_sample_text("Z Zoom / Esc Back",Vector2(237,16),8,GOLD)
	draw_rect(Rect2(0,204,320,20),Color(0.035,0.055,0.08,0.9))
	_sample_text("Arrows Move / J Attack / K Quake / Q Dodge / 1-2 Weapons",Vector2(12,217),8,CREAM)
	if sample_zoom > 1:
		_sample_text("Detail View x1.5",Vector2(9,38),8,GOLD)
