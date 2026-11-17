extends "res://tests/record_chapter_one.gd"
func run() -> void:
	game=load("res://main.tscn").instantiate();root.add_child(game)
	await frames(100)
	assert(game.intro_time==0,"story mode has no legacy intro card or input timer")
	assert(not game.story.pages.is_empty(),"narration remains")
	await read_dialogue()
	await frames(60)
	await hold(KEY_LEFT,24)
	await frames(90)
	if DisplayServer.get_name()!="headless":root.get_texture().get_image().save_png("res://recordings/clean-chapter-opening.png")
	assert(game.story.pages.is_empty() and not game.story.chapter_card_active())
	print("PASS narration remains; free movement after dialogue without legacy chapter overlay")
	game.queue_free();await process_frame;quit()
