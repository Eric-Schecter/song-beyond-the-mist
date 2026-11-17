extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.CHILD;game.intro_time=0
	game.controls.walked=2;game.controls.learned={"light1":true,"light3":true}
	await frames(120)
	if not verify(game.controls.lesson_cue(game)!="dodge","early swings do not prompt dodge before encounter"):return
	root.get_texture().get_image().save_png("res://recordings/tutorial-before-enemy.png")
	var enemy:Dictionary=game.exploration.enemies[game.story.child_enemy]
	game.player=enemy.pos+Vector2(-35,20);await frames(30)
	if not verify(game.controls.lesson_cue(game)=="dodge","encounter unlocks missing dodge lesson"):return
	await frames(90);tap(KEY_Q);await frames(40)
	if not verify(game.controls.basics_complete(),"dodge completes basics"):return
	game.queue_free();await process_frame;quit()
