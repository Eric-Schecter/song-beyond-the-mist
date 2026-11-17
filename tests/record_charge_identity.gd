extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.KNIGHT;game.intro_time=0
	game.exploration.enemies.clear();game.player=Vector2(280,248)
	await frames(60)
	for direction in [Vector2.RIGHT,Vector2.UP]:
		game.player=Vector2(280,248);game.facing=direction;game.stamina=100
		game.exploration.enemies.clear();game.exploration._add("skeleton",Vector2i(20,15),Rect2(0,0,800,800))
		var enemy:Dictionary=game.exploration.enemies.back()
		enemy.pos=game.player+direction*43;enemy.time=999;enemy.hp=20;enemy.max_hp=20
		await frames(45);tap(KEY_K);await frames(80)
		if not verify(enemy.hp==20,"ordinary heavy cannot reach distant target"):return
		key(KEY_K,true);await frames(65);key(KEY_K,false);await frames(22)
		if DisplayServer.get_name()!="headless":root.get_texture().get_image().save_png("res://recordings/charge-impact-%d.png"%int(direction.y))
		if not verify(game.move_name=="charged" and enemy.hp<20,"charged shockwave reaches target"):return
		await frames(100)
	game.queue_free();await process_frame;quit()
