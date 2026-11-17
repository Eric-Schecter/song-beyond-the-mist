extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.KNIGHT;game.intro_time=0;game.exploration.enemies.clear();game.player=Vector2(280,248)
	await frames(60)
	tap(KEY_ESCAPE);await frames(90)
	root.get_texture().get_image().save_png("res://recordings/pause-aligned.png")
	tap(KEY_ESCAPE);tap(KEY_M);await frames(90)
	root.get_texture().get_image().save_png("res://recordings/map-aligned.png")
	tap(KEY_M)
	for id in game.MOVES:
		for direction in [Vector2.RIGHT,Vector2.UP,Vector2(1,1).normalized()]:
			game.stamina=100;game.start_move(id);game.swing_direction=direction
			if not verify(game.enemy_in_reach(game.player+direction*20,6),id+" front hit"):return
			if not verify(not game.enemy_in_reach(game.player+direction*150,6),id+" far miss"):return
			if id=="spin" and not verify(game.enemy_in_reach(game.player-direction*30,6),"spin rear hit"):return
	game.cancel_combo();game.stamina=100
	game.exploration._add("skeleton",Vector2i(18,15),Rect2(0,0,800,800))
	var enemy:Dictionary=game.exploration.enemies.back();enemy.pos=game.player+Vector2(-24,0);enemy.hp=20;enemy.max_hp=20;enemy.time=999
	tap(KEY_J);await frames(16);tap(KEY_J);await frames(16);tap(KEY_K);await frames(65)
	if not verify(game.move_name=="spin" and enemy.hp<20,"JJ K hits rear target"):return
	if not verify(game.struck_enemies.size()==1,"one attempt per target per spin"):return
	await frames(90);game.queue_free();await process_frame;quit()
