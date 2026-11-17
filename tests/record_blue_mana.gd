extends "res://tests/record_chapter_one.gd"
func run():
	var opening=load("res://start.tscn").instantiate();root.add_child(opening);opening.phase=5
	game=opening.game;game.remove_meta("opening_preview");game.set_physics_process(true);game.set_process_input(true)
	game.story.stage=game.story.Stage.CHILD;game.story.pages.clear();game.intro_time=0
	game.player=game._center(Vector2i(11,15));game.camera=Vector2(16,136)
	await frames(90)
	for i in range(2):tap(KEY_K);await frames(55)
	await hold(KEY_RIGHT,1);tap(KEY_Q);await frames(60)
	assert(game.stamina<80,"mana spending visible")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://recordings/blue-mana-hud.png")
	key(KEY_TAB,true);await frames(160)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://recordings/blue-mana-guide.png")
	key(KEY_TAB,false);await frames(200)
	print("PASS blue Mana HUD, consumption, MP guide and regeneration")
	quit()
