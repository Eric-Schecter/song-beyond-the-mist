extends "res://tests/record_full_chapter.gd"
func run() -> void:
	game=load("res://main.tscn").instantiate();root.add_child(game)
	await frames(20)
	assert(not game.story.beats.memory_active() and not game.fountain_awake)
	assert(game.story.pages[0][0]=="Narrator")
	await read_dialogue()
	assert(game.story.stage==game.story.Stage.CHILD)
	await frames(70)
	# Focused dialogue preview: visit the revised knight conversation.
	game.story.stage=game.story.Stage.KNIGHT
	game.player=game._center(Vector2i(6,17));game.camera=Vector2(0,150)
	await frames(50);tap(KEY_E)
	assert(not game.story.pages.is_empty())
	await read_dialogue()
	assert(game.story.stage==game.story.Stage.KEYS)
	# Show the revised chapter conclusion using the normal mother interaction.
	game.story.stage=game.story.Stage.HOME;game.fountain_awake=true;game.water_fill=1
	game.story.beats.bridge_talk=true;game.story.beats.home_seen=true;game.story.beats.home_age=3
	game.player=game._center(Vector2i(7,16));game.camera=Vector2(0,150)
	await frames(50);tap(KEY_E);await read_dialogue()
	assert(game.story.complete_card)
	await frames(140)
	print("PASS present-day opening, stranger-to-princess rescue mission and northbound chapter conclusion")
	game.queue_free();await process_frame;quit()
