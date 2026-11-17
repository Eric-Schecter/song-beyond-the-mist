extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.KEYS;game.intro_time=0
	game.exploration.enemies.clear();game.player=game._center(game.VILLAGE)
	game.set_physics_process(false)
	for ratio in [1.0,.5,.05,0.0]:
		game.health=int(game.max_health*ratio);game.stamina=game.mana_max()*ratio
		game.queue_redraw();await frames(90)
		root.get_texture().get_image().save_png("res://recordings/status-edges-"+str(ratio)+".png")
	game.queue_free();await process_frame;quit()
