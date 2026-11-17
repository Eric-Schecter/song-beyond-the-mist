extends "res://tests/record_chapter_one.gd"
func run():
	var opening=load("res://start.tscn").instantiate();root.add_child(opening);opening.phase=5
	game=opening.game;game.remove_meta("opening_preview");game.set_physics_process(true);game.set_process_input(true)
	game.story.stage=game.story.Stage.GUARD;game.story.pages.clear();game.intro_time=0
	game.controls.lesson_age=20;game.seals.assign([0]);game.growth.award(game,"review",40)
	game.player=game._center(game.VILLAGE);game.health=2;game.stamina=38
	if DisplayServer.get_name()!="headless":DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	await frames(90)
	key(KEY_TAB,true);await frames(180);key(KEY_TAB,false);await frames(30)
	tap(KEY_E);await frames(90);assert(game.controls.page.is_empty() and game.health==game.max_health)
	tap(KEY_P);await frames(120);assert(game.growth.opened)
	tap(KEY_ESCAPE);await frames(120);assert(not game.controls.blocked())
	print("PASS move guide, direct E rest, P attributes and return")
	quit()
