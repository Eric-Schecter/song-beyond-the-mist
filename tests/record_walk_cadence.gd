extends "res://tests/record_full_chapter.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.KNIGHT;game.intro_time=0
	game.controls.walked=2;game.controls.interacted=true
	for id in game.controls.LESSONS:game.controls.learned[id]=true
	game.player=Vector2(312,264)
	await frames(90)
	for cycle in range(2):
		for direction in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]:
			var before:Vector2=game.player
			await hold(direction,55);await frames(35)
			if not verify(game.player.distance_to(before)>40,"direction moved "+str(direction)):return
	print("PASS four directions at matched approximately 10 animation frames per second")
	game.queue_free();await process_frame;quit()
