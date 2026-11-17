extends SceneTree
func _initialize():
	var atlas=preload("res://scripts/refined_atlas.gd").new()
	atlas.open("res://assets/refined/village/cast.png",4,4)
	DirAccess.make_dir_recursive_absolute("res://assets/refined/hero/pixellab_walk")
	for index in [0,2]:
		var region:Rect2=atlas.cells[index]
		var sprite:Image=atlas.texture.get_image().get_region(Rect2i(region))
		var scale:float=104.0/region.size.y
		sprite.resize(roundi(region.size.x*scale),104,Image.INTERPOLATE_NEAREST)
		var canvas:=Image.create(128,128,false,Image.FORMAT_RGBA8)
		canvas.blit_rect(sprite,Rect2i(0,0,sprite.get_width(),104),Vector2i((128-sprite.get_width())/2,12))
		canvas.save_png("res://assets/refined/hero/pixellab_walk/reference_%s.png"%("south" if index==0 else "north"))
	quit()
