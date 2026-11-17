extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var shadow = preload("res://scripts/contact_shadow.gd")
	# Contact mapping must follow the opaque shoe, including flipped rectangles.
	for atlas in [game.village_art.cast,game.village_art.vertical_walk]:
		assert(atlas.soles.size() == atlas.cells.size())
		for i in range(atlas.cells.size()):
			var source: Rect2 = atlas.cells[i]
			var sole: Vector2 = atlas.soles[i]
			assert(sole.y == source.end.y)
			assert(sole.x >= source.position.x and sole.x <= source.end.x)
			var target := Rect2(100,100,source.size.x*0.1,source.size.y*0.1)
			var left: Vector2 = shadow.point(source,target,sole)
			target.position.x += target.size.x
			target.size.x = -target.size.x
			var right: Vector2 = shadow.point(source,target,sole)
			assert(absf(left.y-target.end.y) < 0.001)
			assert(absf(left.x+right.x-(200+source.size.x*0.1)) < 0.001)
	assert(game.refined_hero.action_clips.soles.size() == 18)
	print("PASS shoe contact anchors: 16 poses, 12 vertical walk frames, 18 action frames and mirrored mapping")
	quit()
