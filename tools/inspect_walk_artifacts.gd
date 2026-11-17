extends SceneTree
func _initialize():
	var changes:Array=[]
	var colors:Dictionary={}
	for frame in range(16):
		var picture:=Image.load_from_file("res://assets/refined/hero/pixellab_walk/north_v2_%02d.png"%frame)
		var pixels:Array=[]
		for y in range(78,128):
			for x in range(128):
				var c:=picture.get_pixel(x,y)
				if c.a>.01 and c.r>.25 and maxf(c.r,maxf(c.g,c.b))-minf(c.r,minf(c.g,c.b))<.025:
					var hex:="#"+c.to_html(true)
					colors[hex]=int(colors.get(hex,0))+1
					pixels.append([x,y,hex,"#00000000"])
		if not pixels.is_empty():changes.append({"operation":"patch_pixels","layer":"image","frames":[frame+2],"pixels":pixels,"reason":"Remove isolated neutral-gray generated dust next to boots; preserve colored boots and cloak."})
	var file:=FileAccess.open("/tmp/t18-walk-cleanup.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(changes))
	print("GRAY_ARTIFACT_COLORS ",colors," frames=",changes.size())
	quit()
