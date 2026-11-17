extends SceneTree
func _initialize():
	const DIR="res://assets/refined/hero/pixellab_walk/"
	var sheet:=Image.load_from_file(DIR+"north_clean_sheet.png")
	assert(sheet.get_size()==Vector2i(640,512))
	var manifest:Dictionary={"south":[],"north":[]}
	for index in range(16):
		# PixelLab's first cell is the unchanged reference, not a gait frame.
		var cell:int=index+1
		var frame:=sheet.get_region(Rect2i((cell%5)*128,(cell/5)*128,128,128))
		var name:="north_clean_%02d.png"%index
		assert(frame.save_png(DIR+name)==OK)
		manifest.north.append(name)
		manifest.south.append("south_v2_%02d.png"%index)
	var file:=FileAccess.open(DIR+"clips.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"  "))
	print("IMPORTED 16 south / 16 clean north frames")
	quit()
