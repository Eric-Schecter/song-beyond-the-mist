extends "res://tests/record_full_chapter.gd"
func shot(path:String):
	await process_frame
	root.get_texture().get_image().save_png(path)
func run():
	var opening=load("res://start.tscn").instantiate();root.add_child(opening);opening.phase=5
	game=opening.game;game.remove_meta("opening_preview");game.set_physics_process(true);game.set_process_input(true)
	game.intro_time=0
	if DisplayServer.get_name()!="headless":DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	await frames(120)
	assert(game.story.chapter_card_active())
	await shot("res://recordings/chapter-card-opening.png")
	await read_dialogue()
	assert(game.story.stage==game.story.Stage.CHILD)
	await frames(120)
	assert(game.controls.lesson_cue(game)=="move")
	await shot("res://recordings/tutorial-movement.png")
	if not await walk_to(game.story.CLUES["wheel"]):return
	tap(KEY_E);await read_dialogue()
	assert(game.controls.interacted)
	if not await walk_to(Vector2i(15,14)):return
	if not await walk_to(game.story.CHILD):return
	await frames(120)
	assert(game.controls.completed[0]>=0)
	tap(KEY_Q);await frames(70)
	assert(game.controls.completed[2]>=0)
	# Closing layout preview, independent of chapter progression verification.
	game.story.pages.clear();game.story.advance(game.story.Stage.COMPLETE);game.fountain_awake=true
	await frames(150)
	await shot("res://recordings/chapter-card-ending.png")
	await frames(150);tap(KEY_E);await frames(60)
	assert(not game.story.complete_card)
	print("PASS chapter opening/closing presentation, movement, contextual interaction, light attack and dash guide")
	quit()
