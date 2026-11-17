extends "res://tests/record_full_chapter.gd"

func run() -> void:
	game=load("res://main.tscn").instantiate();root.add_child(game)
	await frames(3)
	game.story.pages.clear();game.story.stage=game.story.Stage.CHILD
	game.player=game._center(game.VILLAGE);game.camera=Vector2(0,150)
	await frames(80)
	tap(KEY_E);await frames(180)
	tap(KEY_P);await frames(160)
	if not verify(game.growth.opened,"attributes accessible directly"):return
	tap(KEY_ESCAPE);await frames(60)
	await frames(70)
	if not verify(game.controls.page.is_empty(),"no camp menu"):return
	tap(KEY_M);await frames(180);tap(KEY_M)
	key(KEY_TAB,true);await frames(180);key(KEY_TAB,false)
	if not await walk_to(Vector2i(15,14)):return
	if not await walk_to(game.story.CHILD):return
	tap(KEY_E);await read_dialogue()
	if not verify(game.story.stage==game.story.Stage.RETURN,"single sword combat and rescue retained"):return
	await frames(90)
	game.queue_free();await process_frame;quit()
