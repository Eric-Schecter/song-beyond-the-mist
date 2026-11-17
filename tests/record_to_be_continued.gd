extends "res://tests/record_chapter_one.gd"

func run() -> void:
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.story.beats.memory_done=true
	game.story.pages.clear()
	game.story.stage=game.story.Stage.COMPLETE
	game.player=game._center(game.VILLAGE)
	game.intro_time=0
	game.fountain_awake=true
	game.slime_health=0
	for enemy in game.exploration.enemies:enemy.hp=0
	await frames(60)
	game.story.advance(game.story.Stage.COMPLETE)
	await frames(240)
	assert(game.story.complete_card and game.story.modal())
	assert(game.story.objective().contains("待续"))
	if DisplayServer.get_name()!="headless":
		root.get_texture().get_image().save_png("res://recordings/chapter-one-to-be-continued.png")
	tap(KEY_E)
	await frames(15)
	assert(not game.story.complete_card and not game.story.modal())
	var before:Vector2=game.player
	await hold(KEY_RIGHT,30)
	assert(game.player.distance_to(before)>1,"Free exploration remains available")
	await frames(120)
	print("PASS chapter ending shows to be continued and returns to free exploration")
	quit()
