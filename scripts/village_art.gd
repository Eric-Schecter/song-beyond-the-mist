extends RefCounted

var motion = preload("res://scripts/actor_motion.gd").new()
var game: Node2D
var props = preload("res://scripts/refined_atlas.gd").new()
var terrain = preload("res://scripts/refined_atlas.gd").new()
var vertical_walk = preload("res://scripts/refined_atlas.gd").new()
var cast = preload("res://scripts/refined_atlas.gd").new()
var structures: Array[Dictionary] = []

func setup(owner: Node2D) -> void:
	game = owner
	props.open("res://assets/refined/village/props.png",3,2)
	terrain.open("res://assets/refined/village/terrain.png",2,2,false)
	vertical_walk.open("res://assets/refined/hero/vertical_walk.png",6,2)
	cast.open("res://assets/refined/village/cast.png",4,4)
	structures = [
		{"sprite":0,"rect":Rect2(43,161,58,64),"base":224.0},
		{"sprite":1,"rect":Rect2(123,161,58,64),"base":224.0},
		{"sprite":2,"rect":Rect2(-30,155,63,63),"base":218.0},
		{"sprite":2,"rect":Rect2(157,131,57,57),"base":188.0},
		{"sprite":2,"rect":Rect2(210,142,47,47),"base":189.0},
		{"sprite":2,"rect":Rect2(185,279,47,47),"base":326.0},
		{"sprite":2,"rect":Rect2(228,280,45,45),"base":325.0},
		{"sprite":2,"rect":Rect2(-10,280,45,45),"base":325.0},
	]

	structures.sort_custom(func(a: Dictionary, b: Dictionary): return a.base < b.base)

func ready() -> bool:
	return props.texture != null and terrain.texture != null and cast.texture != null

func contains(tile: Vector2i) -> bool:
	return tile.x >= 2 and tile.x <= 16 and tile.y >= 11 and tile.y <= 19

func floor_tile(tile: Vector2i) -> bool:
	if not ready() or not contains(tile): return false
	var p := Vector2(tile*16)
	var dirt: bool = (tile.x < 12 and tile.y in range(14,18)) or tile.x in [6,7] or (tile.x >= 12 and tile.y in [14,15])
	var variant := posmod(tile.x*7+tile.y*11,7)
	var material: int = 2 if dirt else (0 if variant > 1 else 1)
	var source: Rect2 = terrain.cells[material]
	var patch := source.size/4.0
	source.position += Vector2(posmod(tile.x,4),posmod(tile.y,4))*patch
	source.size = patch
	game.draw_texture_rect_region(terrain.texture,Rect2(p,Vector2(16,16)),source)
	# Raised banks keep the walkable footprint legible beside the dry river bed.
	for offset in [Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP]:
		if game.floor_tiles.has(tile+offset): continue
		if offset == Vector2i.DOWN:
			game.draw_rect(Rect2(p+Vector2(0,15),Vector2(16,4)),Color("#505b49"))
			game.draw_line(p+Vector2(0,15),p+Vector2(16,15),Color("#8a9b6b"),0.7)
		elif offset == Vector2i.UP:
			game.draw_line(p,p+Vector2(16,0),Color("#8a9b6b"),0.7)
		else:
			var x: float = 0 if offset.x < 0 else 15
			game.draw_line(p+Vector2(x,0),p+Vector2(x,16),Color("#596c4c"),1)
	return true

func ground_props() -> void:
	if not ready(): return
	for item in structures: props.draw(game,item.sprite,item.rect)
	props.draw(game,3,Rect2(84,237,14,13))
	props.draw(game,4,Rect2(48,217,11,9))
	props.draw(game,4,Rect2(163,217,12,9))
	for p in [Vector2(36,232),Vector2(177,235),Vector2(36,269),Vector2(177,274),Vector2(202,203),Vector2(233,205),Vector2(204,261),Vector2(245,261),Vector2(52,308),Vector2(155,308)]:
		props.draw(game,5,Rect2(p,Vector2(11,8)))
	# Flat stepping stones mark the eastward route without blocking it.
	for x in range(188,264,16):
		game.draw_colored_polygon(PackedVector2Array([Vector2(x,241),Vector2(x+5,239),Vector2(x+10,241),Vector2(x+8,244),Vector2(x+1,244)]),Color("#b7ac86"))
		game.draw_line(Vector2(x+1,241),Vector2(x+6,240),Color("#d8c89c"),0.5)

func foreground() -> void:
	if not ready(): return
	# Draw roofs/leaves over actors standing behind their base, not over those in front.
	for item in structures:
		var rect: Rect2 = item.rect
		if game.player.y < item.base and game.player.y > rect.position.y-24 and game.player.x > rect.position.x-10 and game.player.x < rect.end.x+10:
			props.draw(game,item.sprite,rect)

func direction_index(facing: Vector2) -> int:
	if absf(facing.x) > absf(facing.y): return 1 if facing.x > 0 else 3
	return 2 if facing.y < 0 else 0

func actor(row: int, position: Vector2, facing: Vector2, height: float, bob: float = 0, tint: Color = Color.WHITE) -> bool:
	if cast.texture == null: return false
	var state: Dictionary = motion.at(position) if row>0 else {}
	if not state.is_empty() and state.weight>.05: facing=state.facing
	var index := row*4+direction_index(facing)
	var region: Rect2 = cast.cells[index]
	var unit: float = height/cast.cells[row*4].size.y
	if row>0 and motion.walking(game,cast,index,position,unit,tint):return true
	var size: Vector2 = region.size*unit
	var target := Rect2(position+Vector2((region.position.x-cast.feet[index].x)*unit,4-size.y+bob),size)
	preload("res://scripts/contact_shadow.gd").draw_at(game,region,target,cast.soles[index],3.0 if row == 2 else 3.8)
	cast.draw(game,index,target,tint)
	return true

func draw_hero(rig: RefCounted) -> bool:
	if not ready(): return false
	var facing: Vector2 = game.swing_direction if game.attack_time > 0 else game.facing
	if absf(facing.x) > absf(facing.y):
		return rig.action_clips.draw(game,rig.stride,rig.locomotion)
	if game.attack_time>0:
		var index := direction_index(facing)
		preload("res://scripts/actor_motion.gd").vertical_attack(game,cast,index,23.0/cast.cells[0].size.y,Color(1.4,.65,.6) if game.hurt_time>.86 else Color.WHITE)
		return true
	var tint := Color(1.4,.65,.6) if game.hurt_time>.86 else Color.WHITE
	if vertical_walk.texture != null and game.moved and rig.locomotion>.15:
		var index:int=(6 if facing.y<0 else 0)+int(fposmod(rig.stride/TAU,1.0)*6)%6
		var region:Rect2=vertical_walk.cells[index]
		var unit:float=23.0/vertical_walk.cells[0].size.y
		var center_x:float=vertical_walk.origins[index].x+vertical_walk.grid_size.x*.5
		var target:=Rect2(game.player+Vector2((region.position.x-center_x)*unit,4-region.size.y*unit),region.size*unit)
		preload("res://scripts/contact_shadow.gd").draw_at(game,Rect2(0,0,1,1),Rect2(game.player+Vector2(0,4),Vector2.ONE),Vector2.ZERO)
		vertical_walk.draw(game,index,target,tint)
		return true
	return actor(0,game.player,facing,23,0,tint)

func npc(p: Vector2, coat: Color, small: bool) -> bool:
	if not ready(): return false
	var row := -1
	if small: row = 2
	elif coat.is_equal_approx(Color("#a36b87")): row = 1
	elif coat.is_equal_approx(Color("#849aaf")): row = 3
	elif coat.is_equal_approx(Color("#849756")): row = 3
	if row < 0: return false
	return actor(row,p,game.player-p,17 if small else 23,0,Color(0.78,1.0,0.68) if coat.is_equal_approx(Color("#849756")) else Color.WHITE)
