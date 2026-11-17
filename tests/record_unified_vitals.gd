extends "res://tests/record_chapter_one.gd"
func snapshot(id:String):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://recordings/unified-vitals-"+id+".png")
func run():
	var opening=load("res://start.tscn").instantiate();root.add_child(opening);opening.phase=5
	game=opening.game;game.remove_meta("opening_preview");game.set_physics_process(true);game.set_process_input(true)
	game.story.stage=game.story.Stage.CHILD;game.story.pages.clear();game.intro_time=0
	game.player=game._center(Vector2i(11,15));game.camera=Vector2(16,136)
	game.controls.walked=100;game.controls.interacted=true;game.controls.completed.assign([1.0,1.0,1.0])
	game.growth.award(game,"hud_preview",12)
	await frames(100);await snapshot("full")
	for i in range(2):tap(KEY_K);await frames(55)
	await hold(KEY_RIGHT,1);tap(KEY_Q);await frames(55)
	game.hurt_time=0;game._hurt_player(Vector2.LEFT)
	await frames(35);await snapshot("spent")
	await frames(100)
	game.growth.award(game,"hud_level_preview",30)
	await frames(25);await snapshot("level")
	await frames(110)
	tap(KEY_P);await frames(110);await snapshot("attributes");tap(KEY_P)
	await frames(70)
	print("PASS unified vitals capture: full, HP damage, MP cost/regen, XP award, level-up and attributes")
	quit()
