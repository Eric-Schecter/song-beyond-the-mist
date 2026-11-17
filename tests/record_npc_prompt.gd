extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.story.stage=game.story.Stage.COMPLETE
	game.story.pages.clear()
	game.story.complete_card=false
	game.intro_time=0
	if DisplayServer.get_name() != "headless":DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	await frames(60)
	for tile in [Vector2i(7,16),Vector2i(6,17),Vector2i(10,17)]:
		if not await walk_to(tile):return
		await frames(100)
		if not verify(game.story.talk_position()!=Vector2.INF,"NPC overhead interaction available"):return
		if not verify(game.hud.interaction().is_empty(),"no dialogue text strip"):return
		tap(KEY_E)
		await read_dialogue()
	if not await walk_to(Vector2i(11,15)):return
	await frames(80)
	verify(game.story.talk_position()==Vector2.INF,"prompt disappears outside range")
	quit()
