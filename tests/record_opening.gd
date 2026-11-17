extends "res://tests/record_chapter_one.gd"
func run():
	var opening=load("res://start.tscn").instantiate()
	root.add_child(opening)
	if DisplayServer.get_name() != "headless":DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	await frames(180)
	tap(KEY_ENTER)
	for i in range(3):
		await frames(360)
		tap(KEY_ENTER)
	await frames(160)
	game=opening.game
	if not verify(opening.phase==5 and game.is_physics_processing(),"title, prologue and fade into village"):return
	if not verify(opening.music.playing,"adventure music playing"):return
	await read_dialogue()
	await hold(KEY_RIGHT,70)
	await frames(80)
	quit()
