extends "res://tests/record_vertical_gait.gd"
func snap(label:String):
	root.get_texture().get_image().save_png("res://recordings/pixel-walk-"+label+".png")
func run():
	var clips=preload("res://scripts/pixel_walk.gd").new()
	if not clips.clips.has("north") or not clips.clips.has("south"):
		printerr("FAIL both PixelLab walk directions must be present");quit(1);return
	print("PIXELLAB_CLIPS north=",clips.clips.north.size()," south=",clips.clips.south.size())
	await super.run()
