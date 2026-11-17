extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.KEYS;game.intro_time=0
	game.exploration.enemies.clear()
	for tile in [game.journey.SWITCHES[0],game.exploration.HEALING_CHEST,game.SEALS[1]]:
		var center:Vector2=game._center(tile)
		game.player=center+Vector2(24,0);game.camera=game.player-Vector2(160,110)
		await frames(45);await hold(KEY_LEFT,50)
		if not verify(game.player.x>center.x+7,"body blocks direct approach"):return
		if tile==game.journey.SWITCHES[0]:
			tap(KEY_E);await frames(10)
			if not verify(0 in game.journey.restored,"sluice still interactable from collision edge"):return
		elif tile==game.exploration.HEALING_CHEST:
			tap(KEY_E);await frames(10)
			if not verify(game.exploration.healing_taken,"chest still reachable"):return
		await hold(KEY_DOWN,25);await hold(KEY_LEFT,35);await frames(30)
		if not verify(game.player.x<center.x,"can walk around object"):return
	game.queue_free();await process_frame;quit()
