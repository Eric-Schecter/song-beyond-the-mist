extends RefCounted

# Derive the contact point from the same source region and signed destination
# rectangle as the sprite. This also handles mirrored frames without offsets.
static func point(source: Rect2, destination: Rect2, sole: Vector2) -> Vector2:
	return destination.position+(sole-source.position)/source.size*destination.size

static func draw_at(g: Node2D, source: Rect2, destination: Rect2, sole: Vector2, width: float = 3.8) -> void:
	var contact := point(source,destination,sole)
	# The inner shadow overlaps the last opaque shoe row; no daylight gap.
	contact.y -= 0.25
	for band in range(2):
		var radius := Vector2(width,1.0) if band == 0 else Vector2(width*0.64,0.62)
		var polygon := PackedVector2Array()
		for i in range(24): polygon.append(contact+Vector2(cos(i*TAU/24),sin(i*TAU/24))*radius)
		g.draw_colored_polygon(polygon,Color(0.04,0.055,0.045,0.12 if band == 0 else 0.14))

# draw_texture_rect_region treats negative width as flip-only at the supplied
# origin. Use an explicit positive quad so its geometry matches point() exactly.
static func draw_sprite(g: Node2D, texture: Texture2D, source: Rect2, destination: Rect2, color: Color = Color.WHITE) -> void:
	var bounds := destination.abs()
	var positions := PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])
	var uvs := PackedVector2Array()
	for p in positions:
		var fraction := (p-destination.position)/destination.size
		uvs.append((source.position+fraction*source.size)/Vector2(texture.get_size()))
	g.draw_polygon(positions,PackedColorArray([color]),uvs,texture)
