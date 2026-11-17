extends "res://tests/record_full_chapter.gd"
func snap(label:String):
	root.get_texture().get_image().save_png("res://recordings/gait-"+label+".png")
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.KNIGHT;game.intro_time=0
	game.controls.walked=2;game.controls.interacted=true
	for id in game.controls.LESSONS:game.controls.learned[id]=true
	game.player=Vector2(312,264);game.facing=Vector2.UP
	await frames(90)
	for cycle in range(3):
		var before:Vector2=game.player
		await hold(KEY_UP,55);await frames(40)
		if not verify(before.y-game.player.y>40,"north walking displacement"):return
		snap("north-idle")
		await hold(KEY_DOWN,55);await frames(40)
		if not verify(game.player.distance_to(before)<3,"south returns to start"):return
		snap("south-idle")
	# Short steps and reversals exercise the easing into a planted idle pose.
	for direction in [KEY_UP,KEY_DOWN,KEY_UP,KEY_DOWN]:
		await hold(direction,10);await frames(25)
	game.player=game._center(game.story.KNIGHT)-Vector2(38,0)
	await frames(100);snap("quest-far")
	await hold(KEY_RIGHT,19);await frames(100);snap("quest-near")
	if not verify(not preload("res://scripts/world_interaction.gd").target(game).is_empty(),"nearby interaction cue"):return
	tap(KEY_E);await frames(150);snap("dialogue")
	if not verify(game.story.modal(),"NPC interaction preserved"):return
	game.queue_free();await process_frame;quit()
