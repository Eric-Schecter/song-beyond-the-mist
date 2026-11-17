extends RefCounted

# Cached texture meshes separate visible land from collision cells. Materials share
# world-space UVs, and dissolve along irregular edges rather than tile borders.
var game: Node2D
var layers: Array[Dictionary] = []
var borders: Array[Vector2] = []
var distant_props:Array[Dictionary]=[]

func contains(tile: Vector2i) -> bool:
	return tile.x < 28 and tile.y < 31 and (tile.y < 22 or tile.x >= 15)

func noise_at(p: Vector2) -> float:
	return sin(p.x*0.123+p.y*0.071)*0.48+sin(p.x*0.047-p.y*0.151)*0.32+sin(p.x*0.31+p.y*0.27)*0.2

func segment_distance(p: Vector2,a: Vector2,b: Vector2) -> float:
	return p.distance_to(a+(b-a)*clampf((p-a).dot(b-a)/(b-a).length_squared(),0,1))

func path_distance(p: Vector2) -> float:
	var points := [Vector2(68,247),Vector2(166,247),Vector2(219,235),Vector2(312,239),Vector2(314,146),Vector2(320,79),Vector2(380,73)]
	var distance := 10000.0
	for i in range(points.size()-1): distance = minf(distance,segment_distance(p,points[i],points[i+1]))
	distance = minf(distance,segment_distance(p,Vector2(312,239),Vector2(312,372)))
	distance = minf(distance,segment_distance(p,Vector2(312,239),Vector2(440,232)))
	return distance

func material_weight(layer: int, p: Vector2) -> float:
	var n := noise_at(p)
	var forest := (1.0-smoothstep(126,207,p.y+n*10))*smoothstep(166,226,p.x)
	var quarry := smoothstep(334,382,p.y+n*13)*smoothstep(225,252,p.x)
	var path := 1.0-smoothstep(10,24,path_distance(p)+n*5)
	var clearing := 1.0-smoothstep(0.65,1.0,Vector2((p.x-108)/82,(p.y-251)/36).length()+n*0.05)
	path = maxf(path,clearing)
	var rim:float=1-smoothstep(334,360,p.y+n*8)*(1-smoothstep(232,260,p.x+n*8))
	rim*=1-smoothstep(464,492,p.y+n*8)*(1-smoothstep(342,372,p.x+n*8))
	return [1.0,forest*0.68,path*(1.0-quarry),quarry][layer]*rim

func setup(owner: Node2D) -> void:
	game = owner
	layers.clear();borders.clear();distant_props.clear()
	if game.village_art.terrain.texture == null or game.wild_art.terrain.texture == null: return
	var definitions := [
		[game.village_art.terrain,0], [game.wild_art.terrain,0],
		[game.village_art.terrain,2], [game.wild_art.terrain,2]]
	for layer in range(4):
		var vertices := PackedVector3Array()
		var uvs := PackedVector2Array()
		var colors := PackedColorArray()
		var atlas = definitions[layer][0]
		var source: Rect2 = atlas.cells[definitions[layer][1]]
		for y in range(-240,816,4):
			for x in range(-64,468,4):
				var p := Vector2(x,y)
				if x >= coast_x(y)+4: continue
				if (y >= 352 and y < 480 and x < 240) or (y >= 480 and x < 352): continue
				var alpha := material_weight(layer,p+Vector2(2,2))
				if alpha < 0.015: continue
				var tint := Color(0.91,0.96,0.83,alpha) if layer == 0 else Color(1,1,1,alpha)
				# 64 world pixels per material tile, same scale as village texture.
				var uv_start := source.position+Vector2(posmod(x,64),posmod(y,64))*source.size/64.0
				for corner in [Vector2.ZERO,Vector2(4,0),Vector2(4,4),Vector2.ZERO,Vector2(4,4),Vector2(0,4)]:
					vertices.append(Vector3(minf(p.x+corner.x,coast_x(p.y+corner.y)),p.y+corner.y,0))
					uvs.append((uv_start+corner*source.size/64.0)/Vector2(atlas.texture.get_size()))
					tint.a = material_weight(layer,p+corner)
					colors.append(tint)
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_COLOR] = colors
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		layers.append({"mesh":mesh,"texture":atlas.texture})
	# Dense vegetation follows non-walkable outer edges, explaining the collision
	# without portraying every room as a rectangular island in a river.
	for tile in game.floor_tiles:
		if not contains(tile): continue
		for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var other: Vector2i = tile+d
			if game.floor_tiles.has(other) or other in game.exploration.VALLEY_BLOCKS: continue
			if other.x >= 27 or other.y >= 30 or (other.y >= 22 and other.x < 15): continue
			var foot := Vector2(other*16)+Vector2(8,12)
			if not borders.has(foot): borders.append(foot)
	# Deterministic scenery in inaccessible land, with a full tile of clearance
	# around routes. It has no collision and never changes the playable layout.
	for y in range(-224,800,23):
		for x in range(-48,440,27):
			var p:=Vector2(x+sin(y*.37+x)*9,y+cos(x*.23-y)*7)
			if p.x>coast_x(p.y)-18:continue
			var tile:=Vector2i((p/16).floor())
			var clear:=true
			for dy in range(-1,2):
				for dx in range(-1,2):
					if game.floor_tiles.has(tile+Vector2i(dx,dy)):clear=false
			if not clear:continue
			var rocky:bool=p.y>340
			var variant:int=posmod(int(x*17+y*31),5)
			if variant==4:continue
			var size:Vector2=(Vector2(30,24) if rocky else (Vector2(42,54) if variant<2 else Vector2(24,17)))*(.75+float(variant)*.14)
			distant_props.append({"pos":p,"index":(3 if variant==2 else 2) if rocky else (0 if variant<2 else 1),"size":size,"tint":Color(.76,.80,.73) if rocky else Color(.68,.79,.64)})
	distant_props.sort_custom(func(a,b):return a.pos.y<b.pos.y)

func draw() -> void:
	outer_ground()
	bank_faces()
	for layer in layers: game.draw_mesh(layer.mesh,layer.texture)
	var visible:=Rect2(game.camera-Vector2(60,60),Vector2(440,344))
	for item in distant_props:
		if visible.has_point(item.pos):
			game.wild_art.props.draw(game,item.index,Rect2(item.pos-Vector2(item.size.x/2,item.size.y),item.size),item.tint)

func outer_ground()->void:
	if layers.is_empty():return
	var start:=Vector2i((game.camera/32).floor())*32
	for y in range(start.y-32,start.y+256,32):
		for x in range(start.x-32,start.x+352,32):
			if x+32>coast_x(y)-4:continue
			var atlas=game.village_art.terrain
			var source:Rect2=atlas.cells[0]
			var uv:=Rect2(source.position+Vector2(posmod(x,64),posmod(y,64))*source.size/64,source.size*.5)
			game.draw_texture_rect_region(atlas.texture,Rect2(x,y,32,32),uv,Color(.85,.91,.78))
			if y<304:continue
			atlas=game.wild_art.terrain;source=atlas.cells[2]
			for dy in range(0,32,8):
				for dx in range(0,32,8):
					var p:=Vector2(x+dx,y+dy)
					var alpha:float=smoothstep(312,372,p.y+noise_at(p)*18)
					uv=Rect2(source.position+Vector2(posmod(x+dx,64),posmod(y+dy,64))*source.size/64,source.size*.125)
					game.draw_texture_rect_region(atlas.texture,Rect2(p,Vector2(8,8)),uv,Color(.83,.86,.79,alpha))

func edge_props() -> void:
	if layers.is_empty(): return
	for base in borders:
		var p: Vector2 = base+Vector2(sin(base.y*0.7+base.x)*2.5,cos(base.x*0.3)*2.5)
		if p.y > 350:
			game.wild_art.props.draw(game,3,Rect2(p-Vector2(9,8),Vector2(18,13)),Color(0.9,0.92,0.88))
		else:
			game.village_art.props.draw(game,5,Rect2(p-Vector2(10,9),Vector2(19+sin(p.x)*2,13+sin(p.y)*2)),Color(0.78,0.9,0.72))

func coast_x(y: float) -> float:
	return 444+sin(y*0.021)*6+sin(y*0.057)*3

func riverbed(dry: bool) -> void:
	if not dry or layers.is_empty(): return
	var atlas = game.wild_art.terrain
	var source: Rect2 = atlas.cells[3]
	var start := Vector2i((game.camera/32).floor())*32
	var step := 8 if game.water_fill>0 and game.water_fill<1 else 32
	for y in range(start.y,start.y+256,step):
		for x in range(start.x,start.x+352,step):
			var uv := Rect2(source.position+Vector2(posmod(x,64),posmod(y,64))*source.size/64,source.size*step/64)
			game.draw_texture_rect_region(atlas.texture,Rect2(x,y,step,step),uv,Color(0.64,0.63,0.55,1.0-game.water_at(Vector2(x+step*.5,y+step*.5))))
			game.draw_rect(Rect2(x,y,step,step),Color(game.WATER,game.water_at(Vector2(x+step*.5,y+step*.5))))

func bank_faces() -> void:
	if layers.is_empty(): return
	for band in range(3):
		var polygon := PackedVector2Array()
		for y in range(-240,816,4): polygon.append(Vector2(coast_x(y),y))
		for y in range(812,-244,-4): polygon.append(Vector2(coast_x(y)+12-band*4,y+5-band))
		game.draw_colored_polygon(polygon,[Color("#535548"),Color("#767660"),Color("#aba780")][band])

func bank_props() -> void:
	if layers.is_empty(): return
	# Irregular rocks reinforce the bank and conceal the former flat cutoff.
	for y in range(12,650,27):
		if y in range(194,266): continue # bridge landing
		var p := Vector2(coast_x(y)-3,y)
		if not Rect2(game.camera-Vector2(30,30),Vector2(380,284)).has_point(p): continue
		game.wild_art.props.draw(game,2,Rect2(p-Vector2(9,7),Vector2(17,12)),Color(0.85,0.87,0.75))
	# A rocky south rim reads as the end of the quarry, with land continuing below.
	for x in range(360,432,19):
		var p := Vector2(x,493+sin(x)*3)
		game.wild_art.props.draw(game,3,Rect2(p-Vector2(12,10),Vector2(24,17)))

func mine_rim() -> void:
	if layers.is_empty(): return
	# The underground backdrop meets the surface under a rock ridge, not a black rectangle.
	for x in range(-12,240,17):
		var p := Vector2(x,353+sin(x*0.15)*3)
		game.wild_art.props.draw(game,2,Rect2(p-Vector2(11,9),Vector2(25,20)),Color(0.72,0.77,0.76))
	for y in range(366,480,17):
		if y in range(393,426): continue # existing cracked-rock entrance
		var p := Vector2(239+sin(y)*2,y)
		game.wild_art.props.draw(game,2,Rect2(p-Vector2(10,9),Vector2(22,18)),Color(0.72,0.77,0.76))
	for x in range(252,352,17):
		game.wild_art.props.draw(game,2,Rect2(x-10,475,23,19),Color(0.72,0.77,0.76))
