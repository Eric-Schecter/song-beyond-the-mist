extends RefCounted

var texture: Texture2D
var cells: Array[Rect2] = []
var origins: Array[Vector2] = []
var feet: Array[Vector2] = []
var soles: Array[Vector2] = []
var grid_size := Vector2.ZERO

func open(path: String, columns: int, rows: int, transparent: bool = true) -> void:
	if not ResourceLoader.exists(path): return
	texture = load(path)
	grid_size = Vector2(texture.get_size())/Vector2(columns,rows)
	var picture := texture.get_image()
	for y in range(rows):
		for x in range(columns):
			var start := Vector2i(Vector2(x,y)*grid_size)
			var end := Vector2i(Vector2(x+1,y+1)*grid_size)
			var bounds := Rect2i(start,end-start)
			origins.append(Vector2(start))
			cells.append(Rect2(_solid_bounds(picture,bounds)) if transparent else Rect2(bounds))
			feet.append(foot_anchor(picture,Rect2i(cells.back())) if transparent else Vector2.ZERO)
			soles.append(foot_anchor(picture,Rect2i(cells.back()),0.025) if transparent else Vector2.ZERO)

func _solid_bounds(picture: Image, rect: Rect2i) -> Rect2i:
	var low := rect.end
	var high := rect.position
	for y in range(rect.position.y,rect.end.y):
		var left := rect.end.x
		var right := -1
		var count := 0
		for x in range(rect.position.x,rect.end.x):
			if picture.get_pixel(x,y).a > 0.6:
				left = mini(left,x)
				right = maxi(right,x)
				count += 1
		if count < 4: continue
		low.x = mini(low.x,left)
		low.y = mini(low.y,y)
		high.x = maxi(high.x,right)
		high.y = maxi(high.y,y)
	return Rect2i(low,high-low+Vector2i.ONE)

func draw(g: Node2D, index: int, rect: Rect2, color: Color = Color.WHITE) -> void:
	if texture != null and index < cells.size():
		if rect.size.x < 0 or rect.size.y < 0:
			preload("res://scripts/contact_shadow.gd").draw_sprite(g,texture,cells[index],rect,color)
		else:
			g.draw_texture_rect_region(texture,rect,cells[index],color)

func foot_anchor(picture: Image, bounds: Rect2i, depth: float = 0.12) -> Vector2:
	var left := bounds.end.x
	var right := bounds.position.x
	for y in range(bounds.end.y-maxi(2,int(bounds.size.y*depth)),bounds.end.y):
		for x in range(bounds.position.x,bounds.end.x):
			if picture.get_pixel(x,y).a > 0.6:
				left = mini(left,x)
				right = maxi(right,x)
	return Vector2((left+right+1)*0.5,bounds.end.y)
