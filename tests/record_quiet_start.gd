extends "res://tests/record_chapter_one.gd"
func run():
	var opening=load("res://start.tscn").instantiate();root.add_child(opening);game=opening.game
	if not verify(not game.sounds.ember.playing,"no automatic startup effect"):return
	await frames(240)
	tap(KEY_ENTER)
	if not verify(game.sounds.confirm.playing,"start click sound preserved"):return
	await frames(180);tap(KEY_ENTER)
	if not verify(game.sounds.confirm.playing,"page turn sound preserved"):return
	await frames(120);opening.queue_free();await process_frame;quit()
