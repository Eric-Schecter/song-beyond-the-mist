extends "res://tests/record_full_chapter.gd"
func run():
	# Isolated UI review checkpoint; actual controls open and close each menu.
	var opening=load("res://start.tscn").instantiate();root.add_child(opening)
	await frames(90)
	tap(KEY_ENTER);await frames(120)
	opening.phase=5;game=opening.game;game.remove_meta("opening_preview")
	game.set_physics_process(true);game.set_process_input(true)
	game.story.stage=game.story.Stage.KEYS;game.story.pages.clear();game.story.complete_card=false
	game.intro_time=0;game.player=game._center(game.VILLAGE);game.checkpoint=game.VILLAGE
	game.camera=Vector2(0,120);game.growth.award(game,"ui_review",100);game.message_time=0
	if DisplayServer.get_name()!="headless":DisplayServer.window_move_to_foreground()
	await frames(120)
	tap(KEY_P);await frames(120)
	assert(game.growth.opened)
	tap(KEY_1);tap(KEY_2);await frames(90);tap(KEY_P)
	assert(not game.growth.opened)
	tap(KEY_F);await frames(120);tap(KEY_F)
	tap(KEY_M);await frames(120);tap(KEY_M)
	game.story.speak([["Noah's Mother","谢谢你带小诺回来。村里的大家，终于能安心一些了。"]],game.story.Stage.KEYS)
	await frames(210);tap(KEY_ENTER);await frames(15);tap(KEY_ENTER)
	await frames(30)
	tap(KEY_M);tap(KEY_RIGHT);await frames(120);tap(KEY_M)
	await hold(KEY_RIGHT,45);await frames(90)
	print("PASS UI palette review: HUD, allocation, camp, map, portrait dialogue and journal")
	quit()
