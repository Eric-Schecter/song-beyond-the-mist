extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.KEYS;game.intro_time=0
	game.exploration.enemies.clear();game.growth.points=1
	await frames(30);tap(KEY_P);await frames(60)
	var before:Vector2=game.player
	for code in [KEY_D,KEY_S,KEY_A,KEY_W]:
		var expected:int=posmod(game.growth.selected+(1 if code in [KEY_D,KEY_S] else -1),3)
		tap(code);await frames(45)
		if not verify(game.growth.selected==expected and game.player==before,"WASD selects without moving player"):return
	tap(KEY_D);tap(KEY_E);await frames(90)
	if not verify(game.growth.vitality==1 and game.growth.points==0,"E allocates selected attribute"):return
	tap(KEY_ESCAPE);await frames(60)
	if not verify(not game.growth.opened,"Escape closes panel"):return
	game.queue_free();await process_frame;quit()
