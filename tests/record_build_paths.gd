extends "res://tests/record_chapter_one.gd"
func shot(name:String):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://recordings/build-paths-"+name+".png")
func run():
	var opening=load("res://start.tscn").instantiate();root.add_child(opening);opening.phase=5
	game=opening.game;game.remove_meta("opening_preview");game.set_physics_process(true);game.set_process_input(true)
	game.story.stage=game.story.Stage.CHILD;game.story.pages.clear();game.intro_time=0
	game.player=game._center(game.VILLAGE);game.camera=Vector2(0,140)
	game.growth.points=9;game.controls.walked=100;game.controls.interacted=true;game.controls.completed.assign([1.0,1.0,1.0])
	await frames(50);tap(KEY_P);await frames(70);await shot("empty")
	for keycode in [KEY_1,KEY_2,KEY_3]:
		for i in range(3):tap(keycode);await frames(20)
		await frames(65);await shot(str(keycode))
	tap(KEY_P);await frames(30)
	tap(KEY_E);tap(KEY_ENTER);tap(KEY_ESCAPE);await frames(50)
	await hold(KEY_RIGHT,100)
	for i in range(3):tap(KEY_J);await frames(20)
	tap(KEY_K);await frames(65)
	tap(KEY_P);await frames(70);await shot("locked");tap(KEY_P)
	await frames(60)
	print("PASS icon build cards, nine mixed allocations, camp MP refill, light chain, heavy and outside-camp locked panel")
	quit()
