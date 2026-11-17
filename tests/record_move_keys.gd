extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.CHILD;game.intro_time=0
	game.story.tutorial_shown=true;game.player=Vector2(312,264)
	await frames(120)
	root.get_texture().get_image().save_png("res://recordings/movement-keys.png")
	await hold(KEY_A,45)
	if not verify(game.controls.walked>=.65,"WASD completes movement tutorial"):return
	await frames(60);game.queue_free();await process_frame;quit()
