extends RefCounted

var game: Node2D
var props = preload("res://scripts/refined_atlas.gd").new()
var terrain = preload("res://scripts/refined_atlas.gd").new()
var creatures = preload("res://scripts/refined_atlas.gd").new()
var structures: Array[Dictionary] = []

func setup(owner: Node2D) -> void:
	game = owner
	props.open("res://assets/refined/wild/props.png",3,2)
	terrain.open("res://assets/refined/wild/terrain.png",2,2,false)
	creatures.open("res://assets/refined/wild/enemies.png",4,3)
	# Roots/rocks occupy existing blocked cells. Border trees stay off the paths.
	for tile in [Vector2i(16,3),Vector2i(18,3),Vector2i(21,6),Vector2i(25,3)]:
		add_prop(0,Vector2(tile*16)+Vector2(8,16),Vector2(38,45))
	for p in [Vector2(228,53),Vector2(270,23),Vector2(325,20),Vector2(384,22),Vector2(430,63),Vector2(232,118),Vector2(416,131)]:
		add_prop(0,p,Vector2(43,50))
	for tile in [Vector2i(16,24),Vector2i(17,24),Vector2i(21,28)]:
		add_prop(2,Vector2(tile*16)+Vector2(8,16),Vector2(19,21))
	for p in [Vector2(254,351),Vector2(291,350),Vector2(380,351),Vector2(425,380),Vector2(431,456),Vector2(260,489),Vector2(338,490)]:
		add_prop(3,p,Vector2(30,24))
	add_prop(4,Vector2(401,354),Vector2(42,43))
	structures.sort_custom(func(a: Dictionary,b: Dictionary): return a.base < b.base)

func add_prop(index: int, foot: Vector2, size: Vector2) -> void:
	structures.append({"sprite":index,"rect":Rect2(foot-Vector2(size.x/2,size.y),size),"base":foot.y})

func contains(tile: Vector2i) -> bool:
	return (tile.x >= 15 and tile.x <= 26 and tile.y >= 2 and tile.y <= 10) or (tile.x >= 15 and tile.x <= 26 and tile.y >= 20 and tile.y <= 29)

func floor_tile(tile: Vector2i) -> bool:
	if terrain.texture == null or not contains(tile): return false
	var north := tile.y < 11
	var index := 0 if north else 2
	if north and (tile.x in [19,20] or tile.y == 4): index = 1
	var source: Rect2 = terrain.cells[index]
	var patch := source.size/4
	source.position += Vector2(posmod(tile.x,4),posmod(tile.y,4))*patch
	source.size = patch
	var p := Vector2(tile*16)
	game.draw_texture_rect_region(terrain.texture,Rect2(p,Vector2(16,16)),source)
	if not game.floor_tiles.has(tile+Vector2i.DOWN):
		game.draw_rect(Rect2(p+Vector2(0,15),Vector2(16,5)),Color("#4d5849") if north else Color("#595b59"))
		game.draw_line(p+Vector2(0,15),p+Vector2(16,15),Color("#a2a777") if north else Color("#beb59a"),1)
	return true

func ground_props() -> void:
	if props.texture == null: return
	for item in structures: props.draw(game,item.sprite,item.rect)
	for p in [Vector2(250,103),Vector2(285,111),Vector2(392,117),Vector2(354,38),Vector2(410,84),Vector2(292,140),Vector2(325,151)]:
		props.draw(game,1,Rect2(p-Vector2(8,7),Vector2(16,12)))
	for p in [Vector2(255,370),Vector2(414,423),Vector2(291,467)]:
		props.draw(game,3,Rect2(p-Vector2(8,8),Vector2(16,13)))

func foreground() -> void:
	if props.texture == null: return
	for item in structures:
		var rect: Rect2 = item.rect
		if game.player.y < item.base-3 and rect.grow(5).has_point(game.player):
			# Translucency keeps the hero readable under forest canopies.
			props.draw(game,item.sprite,rect,Color(1,1,1,0.62))

func pedestal(point: Vector2) -> bool:
	if props.texture == null: return false
	props.draw(game,5,Rect2(point+Vector2(-10,-5),Vector2(20,12)))
	return true

func enemy(enemy: Dictionary, point: Vector2) -> bool:
	if creatures.texture == null: return false
	var row: int = {"bat":0,"plant":1,"skeleton":2}.get(enemy.kind,0)
	var frame := int(game.clock*(12 if row == 0 else 4))% (3 if row == 0 else 2)
	if enemy.windup: frame = 2
	if enemy.dash > 0 or enemy.get("attack_fx",0.0)>0: frame = 3
	if enemy.hp <= 0: frame = 3
	var bounds: Rect2 = creatures.cells[row*4+frame]
	var maximum := Vector2.ZERO
	for i in range(4): maximum = maximum.max(creatures.cells[row*4+i].size)
	var unit: float = 27.0/maximum.x if row == 0 else (21.0 if row == 1 else 23.0)/maximum.y
	var size: Vector2 = bounds.size*unit
	var bob: float = sin(game.clock*12)*1.3 if row == 0 else 0.0
	var tint := Color.WHITE
	if enemy.hp <= 0:
		var remaining: float = clampf(enemy.death/preload("res://scripts/enemy_field.gd").DEATH_DURATION,0,1)
		size.y *= maxf(0.15,remaining)
		tint.a = remaining
	var rect := Rect2(point+Vector2(-size.x/2,4-size.y+bob),size)
	# Flip texture without moving the foot anchor or changing the hitbox.
	if game.player.x < point.x:
		rect.position.x += size.x
		rect.size.x = -size.x
	creatures.draw(game,row*4+frame,rect,tint)
	if enemy.flash>0:
		game.combat_signal.draw(game,creatures,row*4+frame,rect,Color("#fff7df"),clampf(enemy.flash/.055,0,1)*.92,true)
	elif enemy.hp>0:
		var exposed:bool=enemy.counter>0 or enemy.get("exposed",0.0)>0
		var warning:bool=enemy.windup and enemy.kind!="skeleton"
		var plated:bool=enemy.get("plated",false) and not exposed
		var attack_color:Color={"bat":Color("#c19aee"),"plant":Color("#b6d867"),"skeleton":Color("#edab62")}[enemy.kind]
		var color:=Color("#9ce5cf") if exposed else (attack_color if warning else Color("#a5c5df"))
		var duration:float=float(enemy.get("windup_duration",.4 if enemy.kind=="bat" else (.65 if enemy.kind=="plant" else .58)))
		game.combat_signal.draw(game,creatures,row*4+frame,rect,color,0.38 if exposed else (0.48 if warning else (0.18 if plated else 0.0)),false,clampf(1-enemy.time/duration,0,1) if warning else 0)
	return true
