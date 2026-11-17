extends RefCounted

const VOID := Color("#101521")
const DEEP := Color("#1b2235")
const ROCK := Color("#303e58")
const FACE := Color("#465873")
const EDGE := Color("#66738a")
const WOOD := Color("#78543e")
const GOLD := Color("#efb763")
const CYAN := Color("#62c9cd")
var game: Node2D
var atlas = preload("res://scripts/refined_atlas.gd").new()

func setup(owner: Node2D) -> void:
	game = owner
	atlas.open("res://assets/refined/mine/props.png",3,3)
	# The broad cliff occupies a wider first cell; keep its silhouette out of the rubble UV.
	if atlas.texture != null:
		var picture: Image = atlas.texture.get_image()
		var w := picture.get_width()
		var h := picture.get_height()/3
		atlas.cells[0] = Rect2(atlas._solid_bounds(picture,Rect2i(0,0,int(w*0.385),h)))
		atlas.cells[1] = Rect2(atlas._solid_bounds(picture,Rect2i(int(w*0.385),0,int(w*2.0/3)-int(w*0.385),h)))

func is_mine(tile: Vector2i) -> bool:
	return tile.y >= 23 and ((tile.y < 30 and tile.x < 15) or (tile.y >= 30 and tile.x < 20))

func visible(point: Vector2, padding: float = 24) -> bool:
	return Rect2(game.camera-Vector2.ONE*padding,Vector2(320,224)+Vector2.ONE*padding*2).has_point(point)

func background() -> void:
	# Extend solid rock beyond the camera bounds: no water/black rectangular cut at the map edge.
	rock_backdrop(Rect2i(-64,352,304,128))
	rock_backdrop(Rect2i(-64,480,864,352))
	for x in range(240,800,19):
		if visible(Vector2(x,480)):
			atlas.draw(game,0,Rect2(x-8,469,30,24),Color(0.65,0.70,0.74))
	game.draw_colored_polygon(PackedVector2Array([Vector2(175,493),Vector2(265,493),Vector2(272,501),Vector2(264,514),Vector2(181,512)]),VOID)
	for y in range(22,51):
		for x in range(-2,22):
			var tile := Vector2i(x,y)
			var p := Vector2(tile*16)
			if game.floor_tiles.has(tile) or not visible(p,40): continue
			if y < 30 and x >= 15: continue
			if y == 31 and x in range(11,17): continue
			var near := false
			for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				if game.floor_tiles.has(tile+offset): near = true
			if near:
				rock(p,posmod(x*7+y*3,7))
			else:
				var n := fposmod(sin(x*127.1+y*311.7)*43758.5453,1.0)
				if n > 0.76:
					var drift := Vector2(sin(x*9.7+y)*8,cos(y*5.3+x)*7)
					atlas.draw(game,0,Rect2(p+drift-Vector2(8,10),Vector2(28+n*16,18+n*14)),Color(0.23,0.28,0.32))

func rock(p: Vector2, variation: int) -> void:
	# Overlapping irregular silhouettes hide the collision grid. Floors render over their bases.
	var tint := Color(0.65,0.70,0.76).lightened(variation*0.017)
	var destination := Rect2(p+Vector2(-7,-9-variation%3),Vector2(30+variation%3,27))
	if variation%2 == 1:
		destination.position.x += destination.size.x
		destination.size.x *= -1
	atlas.draw(game,0,destination,tint)
	if variation in [1,4]: atlas.draw(game,1,Rect2(p+Vector2(-3,8),Vector2(22,10)),tint)

func material(atlas_source, index: int, area: Rect2, tint: Color) -> void:
	if atlas_source.texture == null: return
	var source: Rect2 = atlas_source.cells[index]
	var uv := Rect2(source.position+Vector2(fposmod(area.position.x,64),fposmod(area.position.y,64))*source.size/64,area.size*source.size/64)
	game.draw_texture_rect_region(atlas_source.texture,area,uv,tint)

func floor_tile(tile: Vector2i) -> void:
	var p := Vector2(tile*16)
	if not visible(p): return
	for dy in range(0,16,4):
		for dx in range(0,16,4):
			var q := p+Vector2(dx,dy)
			var grain := sin(q.x*0.13+q.y*0.09)*0.5+sin(q.y*0.21-q.x*0.17)*0.3
			var entry := smoothstep(199,244,q.x+grain*6)*(1-smoothstep(15,30,absf(q.y-408)))
			var area := Rect2(q,Vector2(4,4))
			material(game.wild_art.terrain,2,area,Color(0.58,0.64,0.70).lerp(Color.WHITE,entry))
			var dust := (0.15+0.2*(grain+0.8))*(1-entry)
			material(game.village_art.terrain,2,area,Color(0.54,0.51,0.48,dust))
	# Soft contact shade and loose scree join floor and walls, without bright tile outlines.
	for d in [Vector2i.UP,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.DOWN]:
		if game.floor_tiles.has(tile+d): continue
		for band in range(3):
			var a := p+Vector2(0,band) if d == Vector2i.UP else p+Vector2(0,15-band)
			var b := a+Vector2(16,0)
			if d == Vector2i.LEFT or d == Vector2i.RIGHT:
				a = p+Vector2(band if d == Vector2i.LEFT else 15-band,0)
				b = a+Vector2(0,16)
			game.draw_line(a,b,Color(0.09,0.12,0.16,0.24-band*0.065))
		if posmod(tile.x*3+tile.y,3) == 0:
			var foot := p+Vector2(8,8)+Vector2(d)*7
			atlas.draw(game,1,Rect2(foot-Vector2(5,2),Vector2(10,5)),Color(0.6,0.65,0.7))

func glow(p: Vector2, radius: float, color: Color) -> void:
	if not visible(p,radius): return
	for i in range(4,0,-1):
		game.draw_circle(p,roundf(radius*i/4.0),Color(color,0.035))

func support(p: Vector2) -> void:
	atlas.draw(game,2,Rect2(p+Vector2(-16,-22),Vector2(32,28)))

func props() -> void:
	for tile in [Vector2i(10,24),Vector2i(10,33),Vector2i(7,35),Vector2i(17,33),Vector2i(12,41)]:
		var p: Vector2 = game._center(tile)
		if not visible(p): continue
		support(p+Vector2(0,-6))
		glow(p,27,GOLD)
	var camp := Vector2(65,549)
	if visible(camp,50):
		atlas.draw(game,3,Rect2(camp+Vector2(-19,-15),Vector2(36,29)))
		var fire := camp+Vector2(20,19)
		glow(fire,27,GOLD)
		game.village_art.props.draw(game,3,Rect2(fire-Vector2(7,9),Vector2(14,15)))
	for y in range(33,40):
		var p := Vector2(11*16,y*16)
		if not visible(p): continue
		for offset in [3,11]:
			game.draw_line(p+Vector2(offset,0),p+Vector2(offset,16),Color("#7b8290"))
		for offset in [2,10]:
			game.draw_line(p+Vector2(1,offset),p+Vector2(13,offset),WOOD,2)
	var cart := Vector2(180,544)
	if visible(cart): atlas.draw(game,4,Rect2(cart-Vector2(10,13),Vector2(20,20)))
	if not game.mine.prism_found:
		var prism: Vector2 = game._center(game.mine.PRISM)
		glow(prism,32,CYAN)
		atlas.draw(game,5,Rect2(prism-Vector2(10,21),Vector2(20,25)))

func mechanism(index: int, p: Vector2, size: Vector2, opened: bool = false) -> void:
	atlas.draw(game,index,Rect2(p-Vector2(size.x/2,size.y-5),size),Color(0.55,0.6,0.65) if opened else Color.WHITE)
	if opened and index == 8:
		game.draw_line(p+Vector2(-5,-3),p+Vector2(5,-3),DEEP,3)

func rock_backdrop(area: Rect2i) -> void:
	if not "wild_art" in game or game.wild_art.terrain.texture == null:
		game.draw_rect(Rect2(area),VOID)
		return
	var atlas = game.wild_art.terrain
	var source: Rect2 = atlas.cells[3]
	for y in range(area.position.y,area.end.y,16):
		for x in range(area.position.x,area.end.x,16):
			if not visible(Vector2(x,y)): continue
			var uv := Rect2(source.position+Vector2(posmod(x,64),posmod(y,64))*source.size/64,source.size/4)
			game.draw_texture_rect_region(atlas.texture,Rect2(x,y,16,16),uv,Color(0.26,0.31,0.38))
