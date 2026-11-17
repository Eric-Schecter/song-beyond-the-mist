extends "res://tests/record_chapter_one.gd"
func run():
	var opening=load("res://start.tscn").instantiate();root.add_child(opening);opening.phase=5
	game=opening.game;game.remove_meta("opening_preview");game.set_physics_process(true);game.set_process_input(true)
	game.story.stage=game.story.Stage.CHILD;game.story.pages.clear();game.intro_time=0
	if DisplayServer.get_name()!="headless":DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	await frames(90)
	tap(KEY_J);await frames(45)
	key(KEY_K,true);await frames(45);key(KEY_K,false);await frames(70)
	tap(KEY_Q);await frames(160)
	key(KEY_TAB,true);await frames(180);assert(game.controls.page=="peek")
	key(KEY_TAB,false);await frames(60);assert(not game.controls.blocked())
	tap(KEY_ESCAPE);await frames(80);tap(KEY_DOWN);tap(KEY_ENTER);await frames(100)
	tap(KEY_ESCAPE);await frames(40);tap(KEY_ESCAPE)
	tap(KEY_M);await frames(90);tap(KEY_RIGHT);await frames(120);assert(game.controls.map_journal)
	tap(KEY_M);await hold(KEY_RIGHT,80);await frames(90)
	assert(not game.controls.blocked() and not game.map_open)
	print("PASS tutorial actions, held guide, pause menu guide, map journal and clean gameplay")
	quit()
