extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.KNIGHT;game.intro_time=0
	for kind in ["skeleton","bat","plant"]:
		game.exploration.enemies.clear();game.exploration.shots.clear()
		game.player=Vector2(280,248);game.health=game.max_health;game.hurt_time=0
		game.exploration._add(kind,Vector2i(19,15),Rect2(200,180,200,140))
		var enemy:Dictionary=game.exploration.enemies.back();enemy.pos=game.player+Vector2(22 if kind=="skeleton" else 48,0);enemy.time=.4
		await frames(160)
		print("REVIEW ",kind)
	game.queue_free();await process_frame;quit()
