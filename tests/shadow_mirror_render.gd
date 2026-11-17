extends SceneTree
var canvas: Node2D
var texture: ImageTexture
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var picture := Image.create(10,10,false,Image.FORMAT_RGBA8)
	picture.fill(Color.RED)
	texture = ImageTexture.create_from_image(picture)
	canvas = Node2D.new()
	root.add_child(canvas)
	canvas.draw.connect(func(): preload("res://scripts/contact_shadow.gd").draw_sprite(canvas,texture,Rect2(0,0,10,10),Rect2(40,20,-10,10)))
	canvas.queue_redraw()
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame
	var frame := root.get_texture().get_image()
	var low := 99999
	var high := -1
	for y in range(frame.get_height()):
		for x in range(frame.get_width()):
			var c := frame.get_pixel(x,y)
			if c.r > 0.9 and c.g < 0.1:
				low = mini(low,x)
				high = maxi(high,x)
	assert(low == 90 and high == 119)
	print("PASS rendered mirrored quad x=90..119: matches shadow contact geometry")
	quit()
