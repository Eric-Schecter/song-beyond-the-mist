extends "res://tests/record_chapter_one.gd"
func run():
	var opening=load("res://start.tscn").instantiate();root.add_child(opening);game=opening.game
	await frames(120)
	# Mouse path: title confirmation and each narration page must play feedback.
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	click.position=opening.menu_rect(0).get_center();opening._input(click)
	if not verify(game.sounds.confirm.playing,"mouse start confirmation sound"):return
	for i in range(3):
		await frames(150);opening._input(click)
		if not verify(game.sounds.confirm.playing,"narration click sound"):return
	await frames(100)
	game.story.pages.clear();game.story.stage=game.story.Stage.CHILD;game.intro_time=0
	game.exploration.enemies[game.story.child_enemy].hp=0;game.exploration.enemies[game.story.child_enemy].death=0;game.story.tutorial_shown=true
	game.controls.reset();game.controls.walked=1;game.controls.lesson_age=1
	game.player=game._center(game.story.CHILD)
	game.story.interact()
	if not verify(not game.story.modal() and game.story.stage==game.story.Stage.CHILD,"rescue cannot bypass missing basics"):return
	game.exploration.enemies.clear();game.story.stage=game.story.Stage.DEFEND;game.story.raid_indices.clear();game.player=Vector2(312,264)
	await frames(120)
	if not verify(game.story.stage==game.story.Stage.DEFEND and not game.story.modal(),"empty battle does not skip training"):return
	# Actual input: rejected attacks must not count as completed lessons.
	game.stamina=0;tap(KEY_K);await frames(1)
	if not verify(not game.controls.learned.has("heavy"),"insufficient mana does not satisfy lesson"):return
	game.stamina=game.mana_max()
	tap(KEY_J);await frames(85)
	for i in range(3):tap(KEY_J);await frames(16)
	await frames(90);tap(KEY_Q);await frames(95)
	if not verify(game.controls.basics_complete(),"basic attacks and dodge learned through inputs"):return
	for id in ["thrust","spin"]:
		game.cancel_combo();await frames(60)
		for i in range(1 if id=="thrust" else 2):tap(KEY_J);await frames(16)
		tap(KEY_K);await frames(110)
		if not verify(game.controls.learned.has(id),id+" recorded"):return
	tap(KEY_K);await frames(110)
	key(KEY_K,true);await frames(120);key(KEY_K,false);await frames(110)
	tap(KEY_Q);await frames(8);tap(KEY_J);await frames(100)
	if not verify(game.controls.combat_complete() and game.story.modal(),"all actions unlock post-battle story"):return
	game.story.pages.clear();game.story.stage=game.story.Stage.KEYS
	game.controls.learned.clear()
	if not verify(game.controls.lesson_cue(game)=="","later chapter states suppress stale tutorial prompts"):return
	await frames(90);opening.queue_free();await process_frame;quit()
