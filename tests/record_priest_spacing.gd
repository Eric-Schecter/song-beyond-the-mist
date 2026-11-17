extends "res://tests/record_full_chapter.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.stage=game.story.Stage.SPRING;game.story.pages.clear();game.story.beats.memory_done=true
	game.story.beats.purified=true;game.story.beats.priest_pos=game._center(game.FOUNTAIN)+Vector2(-22,10)
	game.player=game._center(game.FOUNTAIN)+Vector2(0,16);game.camera=Vector2(448,96)
	game.intro_time=0;game.slime_health=0;game.gate_open=true
	for enemy in game.exploration.enemies:enemy.hp=0
	var last:Array[Vector2]=[game.story.beats.priest_pos]
	var track:Callable=func():
		assert(game.story.beats.priest_pos.distance_to(last[0])<2.0,"no priest position jumps")
		last[0]=game.story.beats.priest_pos
	physics_frame.connect(track)
	await frames(90)
	tap(KEY_E);await read_dialogue()
	assert(game.story.stage==game.story.Stage.HOME and game.fountain_awake and game.rockbreak)
	if not await walk_to(game.story.MOTHER):return
	assert(game.story.beats.priest_pos.distance_to(game.player)<65,"priestess reaches village without teleport")
	tap(KEY_E);await read_dialogue()
	await frames(150)
	physics_frame.disconnect(track)
	print("PASS priestess remains at spring, faces dialogue, follows route and reaches village")
	quit()
