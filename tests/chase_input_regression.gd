extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.KNIGHT;game.intro_time=0
	game.exploration.enemies.clear();game.player=Vector2(280,248)
	await frames(60)
	for delay in [0,8,20,35,60]:
		game.cancel_combo();game.stamina=100;game.dodge_cooldown=0;game.dodge_time=0
		game.executed.clear();tap(KEY_Q);await frames(delay);tap(KEY_J);await frames(45)
		if not verify(game.executed.has("chase"),"Q J delay %d"%delay):return
	game.cancel_combo();game.stamina=18;game.dodge_cooldown=0;game.dodge_time=0
	tap(KEY_Q);await frames(18);tap(KEY_J)
	if not verify(game.dash_follow>0,"insufficient MP does not consume followup"):return
	game.stamina=100;tap(KEY_J);await frames(30)
	if not verify(game.move_name=="chase","retry remains chase"):return
	game.cancel_combo();game.dodge_cooldown=0;game.stamina=100;game.hurt_time=0
	tap(KEY_Q);await frames(18);game._hurt_player(Vector2.RIGHT);tap(KEY_J);await frames(30)
	if not verify(game.move_name=="chase","surviving hit preserves chase window"):return
	game.queue_free();await process_frame;quit()
