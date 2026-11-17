extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.KEYS;game.intro_time=0
	game.exploration.enemies.clear();game.player=Vector2(290,264);game.facing=Vector2.RIGHT
	game.exploration._add("plant",Vector2i(22,16),Rect2(220,200,200,120))
	var enemy:Dictionary=game.exploration.enemies.back();enemy.pos=Vector2(354,264);enemy.home=enemy.pos;enemy.time=.2
	var saw_projectile:=false
	var saw_burst:=false
	for i in range(660):
		if i>300 and i%26==0:tap(KEY_J)
		if not game.exploration.shots.is_empty():saw_projectile=true
		if not game.exploration.seed_art.bursts.is_empty():saw_burst=true
		await frames(1)
	if not verify(saw_projectile and saw_burst,"plant fired seeds and produced burst effects"):return
	game.queue_free();await process_frame;quit()
