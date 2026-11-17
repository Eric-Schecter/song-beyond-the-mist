extends "res://tests/record_chapter_one.gd"
func run():
	var opening=load("res://start.tscn").instantiate()
	root.add_child(opening);game=opening.game
	await frames(960)
	if not verify(game.score.context=="title" and game.score.music.playing,"title music"):return
	if not verify(game.score.music.stream.data==game.score.loop_stream("res://assets/music/mist_title_theme.wav").data and not game.score.outgoing.playing,"menu actual title audio only after 16 seconds"):return
	tap(KEY_ENTER);await frames(420)
	if not verify(game.score.context=="history" and game.score.music.playing and not game.score.outgoing.playing,"history crossfade finished"):return
	if not verify(game.score.music.stream.data==game.score.loop_stream("res://assets/music/mist_history_story.wav").data,"history actual audio asset"):return
	tap(KEY_ENTER);await frames(360)
	tap(KEY_ENTER);await frames(360)
	tap(KEY_ENTER);await frames(480)
	if not verify(opening.phase==5 and game.score.context=="adventure" and game.score.music.playing,"village adventure music"):return
	print("PASS three distinct music contexts")
	opening.queue_free();await process_frame;quit()
