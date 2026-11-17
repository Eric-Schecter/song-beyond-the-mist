extends "res://tests/record_full_chapter.gd"

func run() -> void:
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	# Focused preview fixture, then use the normal interaction and dialogue input.
	game.story.pages.clear()
	game.story.stage=game.story.Stage.KNIGHT
	game.player=game._center(Vector2i(6,17))
	game.camera=Vector2(0,150)
	await frames(90)
	tap(KEY_E)
	if not verify(not game.story.pages.is_empty(),"Roland conversation opened"):return
	await read_dialogue()
	if not verify(game.story.stage==game.story.Stage.KEYS,"rescue motivation leads to river keys"):return
	await frames(150)
	game.queue_free()
	await process_frame
	quit()
