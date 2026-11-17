extends SceneTree
func _initialize():run.call_deferred()
func run():
	var opening=load("res://start.tscn").instantiate();root.add_child(opening)
	var g=opening.game
	for size in [Vector2i(960,600),Vector2i(800,600),Vector2i(1260,540)]:
		root.size=size
		for i in range(5):await process_frame
		await RenderingServer.frame_post_draw
		var shot=root.get_texture().get_image()
		shot.save_png("/tmp/window-title-%dx%d.png"%[size.x,size.y])
	opening.phase=5;g.remove_meta("opening_preview")
	g.story.stage=g.story.Stage.CHILD;g.story.pages.clear();g.player=g._center(Vector2i(7,16));g.camera=Vector2(0,144)
	g.story.speak([["Noah's Mother","小诺带着水壶去了村东。请你把他平安带回来。"]])
	g.story.reveal_all=true;g.queue_redraw()
	for size in [Vector2i(960,600),Vector2i(800,600),Vector2i(1260,540)]:
		root.size=size
		for i in range(5):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/window-dialogue-%dx%d.png"%[size.x,size.y])
	print("PASS native title and dialogue captured at 16:10, 4:3, 21:9")
	quit()
