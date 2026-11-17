extends RefCounted

var game: Node2D
var props = preload("res://scripts/refined_atlas.gd").new()
var guardian = preload("res://scripts/refined_atlas.gd").new()
var priest = preload("res://scripts/refined_atlas.gd").new()
var layers: Array[Dictionary] = []
var outline := PackedVector2Array()
const CENTER := Vector2(608,240)

func signed_edge(p: Vector2) -> float:
	var q := (p-CENTER).abs()-Vector2(88,124)
	return q.max(Vector2.ZERO).length()+minf(maxf(q.x,q.y),0)-24+sin(p.y*0.061)*2+sin(p.x*0.083)*1.8

func contains(tile: Vector2i) -> bool:
	return tile.x >= 32 and tile.x < 44 and tile.y >= 7 and tile.y < 23

func weight(layer: int,p: Vector2) -> float:
	var edge := signed_edge(p)
	var shore := smoothstep(-19,-3,edge)*0.85
	var noise: float = game.landscape_ground.noise_at(p)
	var plaza := 1.0-smoothstep(0.55,1.0,Vector2((p.x-610)/91,(p.y-252)/115).length()+noise*0.06)
	var approach := 1.0-smoothstep(10,24,game.landscape_ground.segment_distance(p,Vector2(510,232),Vector2(641,179))+noise*4)
	var opacity := 1.0-smoothstep(-1.0,2.0,edge)
	return [opacity,maxf(plaza,approach)*opacity*(1-shore*0.6),shore*opacity][layer]

func setup(owner: Node2D) -> void:
	game = owner
	props.open("res://assets/refined/island/props.png",3,2)
	guardian.open("res://assets/refined/island/warden.png",4,2)
	priest.open("res://assets/refined/island/priest.png",2,2)
	for i in range(96):
		var direction := Vector2.from_angle(i*TAU/96)
		var low := 0.0
		var high := 220.0
		for j in range(14):
			var middle := (low+high)*0.5
			if signed_edge(CENTER+direction*middle) > 0: high = middle
			else: low = middle
		outline.append(CENTER+direction*(low+high)*0.5)
	var definitions := [[game.village_art.terrain,0],[game.wild_art.terrain,2],[game.village_art.terrain,2]]
	for layer in range(3):
		var atlas = definitions[layer][0]
		if atlas.texture == null: continue
		var region: Rect2 = atlas.cells[definitions[layer][1]]
		var vertices := PackedVector3Array()
		var uvs := PackedVector2Array()
		var colors := PackedColorArray()
		for y in range(84,396,4):
			for x in range(488,728,4):
				var p := Vector2(x,y)
				if weight(layer,p+Vector2(2,2)) < 0.01: continue
				var uv_start := region.position+Vector2(posmod(x,64),posmod(y,64))*region.size/64
				for corner in [Vector2.ZERO,Vector2(4,0),Vector2(4,4),Vector2.ZERO,Vector2(4,4),Vector2(0,4)]:
					vertices.append(Vector3(p.x+corner.x,p.y+corner.y,0))
					uvs.append((uv_start+corner*region.size/64)/Vector2(atlas.texture.get_size()))
					colors.append(Color(0.91,0.96,0.86,weight(layer,p+corner)) if layer == 0 else Color(1,1,1,weight(layer,p+corner)))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_COLOR] = colors
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		layers.append({"mesh":mesh,"texture":atlas.texture})

func ground() -> void:
	if layers.is_empty(): return
	for band in range(3):
		var points := PackedVector2Array()
		for p in outline: points.append(CENTER+(p-CENTER)*(1.08-band*0.025)+Vector2(0,6-band*2))
		var dry_colors := [Color("#5c5d4b"),Color("#8b8869"),Color("#b5aa7c")]
		var wet_colors := [Color("#326c70"),Color("#60958a"),Color("#b5b68b")]
		game.draw_colored_polygon(points,dry_colors[band].lerp(wet_colors[band],game.water_at(CENTER)))
	for layer in layers: game.draw_mesh(layer.mesh,layer.texture)
	bridge()

func bridge() -> void:
	# A single continuous deck joins both banks and covers the old tile seams.
	game.draw_rect(Rect2(428,210,104,49),Color("#49382b"))
	for x in range(428,532,6):
		game.draw_rect(Rect2(x,210,5,44),Color("#a17a4c") if x%12 == 8 else Color("#ad8756"))
		game.draw_line(Vector2(x+1,212),Vector2(x+1,252),Color("#c9a66d"))
		game.draw_line(Vector2(x+3,218),Vector2(x+3,238),Color("#85613e"))
	for y in [208,255]:
		game.draw_line(Vector2(428,y),Vector2(532,y),Color("#4d3b2e"),3)
		game.draw_line(Vector2(428,y-1),Vector2(532,y-1),Color("#c5a36b"),1)
		for x in [432,464,496,528]:
			game.draw_rect(Rect2(x-2,y-5,4,10),Color("#604832"))
			game.draw_rect(Rect2(x-1,y-5,2,2),Color("#d0b47c"))

func decorations() -> void:
	if props.texture == null: return
	# Shore objects sit outside the playable rectangle; low boulders mark blocked cells.
	for i in range(0,outline.size(),5):
		var p: Vector2 = outline[i]
		if p.x < 530 and p.y > 194 and p.y < 270: continue
		var size := Vector2(20,14) if i%2 == 0 else Vector2(13,11)
		props.draw(game,4 if i%2 == 0 else 5,Rect2(p-Vector2(size.x/2,size.y-3),size))
	props.draw(game,2,Rect2(624,91,47,35))
	for p in [Vector2(568,160),Vector2(680,320)]:
		props.draw(game,3,Rect2(p-Vector2(8,20),Vector2(17,24)))
	for p in [Vector2(535,125),Vector2(690,132),Vector2(542,350),Vector2(689,357)]:
		props.draw(game,5,Rect2(p-Vector2(9,6),Vector2(18,12)))

func fountain() -> bool:
	if props.texture == null: return false
	var p: Vector2 = game._center(game.FOUNTAIN)
	props.draw(game,0,Rect2(p+Vector2(-24,-30),Vector2(48,39)))
	var wet: float = game.water_at(p)
	props.draw(game,1,Rect2(p+Vector2(-24,-30),Vector2(48,39)),Color(1,1,1,wet))
	if wet > 0:
		for i in range(3):
			game.draw_arc(p+Vector2(0,1),5+fposmod(game.clock*3+i*3,9),0,TAU,24,Color(0.7,0.9,0.83,0.5*wet),0.6)
	return true

func npc(p: Vector2) -> bool:
	if priest.texture == null: return false
	var state: Dictionary = game.village_art.motion.at(p)
	var facing: Vector2 = state.facing if not state.is_empty() and state.weight>.05 else game.player-p
	var index: int = game.village_art.direction_index(facing)
	var region: Rect2 = priest.cells[index]
	var unit: float = 23.0/priest.cells[0].size.y
	if game.village_art.motion.walking(game,priest,index,p,unit,Color.WHITE):return true
	var target := Rect2(p+Vector2((region.position.x-priest.feet[index].x)*unit,4-region.size.y*unit),region.size*unit)
	preload("res://scripts/contact_shadow.gd").draw_at(game,region,target,priest.soles[index])
	priest.draw(game,index,target)
	return true

func boss(dead: bool = false) -> bool:
	if guardian.texture == null: return false
	var index := 0
	if dead:
		index = 5 if game.boss_death > 0.55 else (6 if game.boss_death > 0.15 else 7)
	else:
		index = {game.Guard.WINDUP:1,game.Guard.CHARGE:2,game.Guard.STAGGER:3}.get(game.guard_state,0)
		if game.slime_hurt_time > 0: index = 4
	var p: Vector2 = game.slime
	if not dead: game.patterns.draw(game)
	if not dead:
		if game.guard_state==game.Guard.WINDUP:p-=game.charge_direction*(2 if game.patterns.kind==3 else 1)
		elif game.guard_state==game.Guard.CHARGE and game.patterns.kind==3:p+=game.charge_direction*4
		elif game.guard_state==game.Guard.RECOVERY:p+=game.charge_direction*minf(2,game.guard_time*4)
	var region: Rect2 = guardian.cells[index]
	var unit: float = 32.0/guardian.cells[0].size.y
	var target := Rect2(p+Vector2((region.position.x-guardian.feet[index].x)*unit,5-region.size.y*unit),region.size*unit)
	var facing: Vector2 = game.charge_direction if game.guard_state in [game.Guard.WINDUP,game.Guard.CHARGE] else game.player-p
	if facing.x < 0:
		target.position.x = p.x-(region.position.x-guardian.feet[index].x)*unit
		target.size.x *= -1
	var tint := Color.WHITE
	preload("res://scripts/contact_shadow.gd").draw_at(game,region,target,guardian.soles[index],8)
	guardian.draw(game,index,target,tint)
	if not dead:game.patterns.draw_melee(game)
	if game.slime_hurt_time>0:
		game.combat_signal.draw(game,guardian,index,target,Color("#fff7df"),clampf(game.slime_hurt_time/.055,0,1)*.92,true)
	elif not dead:
		var recovering:bool=game.guard_state==game.Guard.STAGGER
		var charging:bool=game.guard_state==game.Guard.WINDUP
		game.combat_signal.draw(game,guardian,index,target,Color("#9ce5cf") if recovering else Color("#edab62"),0.38 if recovering else (0.3 if charging else (0.35*game.patterns.phase_flash if game.patterns.phase_flash>0 else 0.0)))
	if not dead and game.guard_state == game.Guard.CHARGE and game.patterns.kind==0:
		for side in [-1,1]:
			var origin: Vector2 = p+game.charge_direction.orthogonal()*side*10
			game.draw_line(origin-game.charge_direction*22,origin-game.charge_direction*8,game.CREAM,1)
	return true

func gate() -> void:
	for y in [210,252]:
		game.draw_rect(Rect2(464,y-5,6,12),Color("#49392c"))
		game.draw_rect(Rect2(465,y-4,4,3),Color("#bc9d62"))
	for y in range(213,252,7):
		game.draw_line(Vector2(466,y),Vector2(471,y+5),Color("#79583b"),3)
		game.draw_line(Vector2(466,y-1),Vector2(471,y+4),Color("#c2a171"),1)
	game.draw_circle(Vector2(469,232),5,Color("#443e31"))
	game.draw_arc(Vector2(469,232),4,0,TAU,16,game.GOLD,1)
