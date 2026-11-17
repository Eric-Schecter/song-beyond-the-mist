extends "res://tests/record_full_chapter.gd"
func run():
	var opening=load("res://start.tscn").instantiate();root.add_child(opening);game=opening.game
	var locale=preload("res://scripts/game_locale.gd")
	locale.language="en"
	await frames(180)
	root.get_texture().get_image().save_png("res://recordings/title-mist-en.png")
	locale.language="zh"
	await frames(180)
	root.get_texture().get_image().save_png("res://recordings/title-mist-zh.png")
	opening.queue_free();await process_frame;quit()
