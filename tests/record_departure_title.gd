extends "res://tests/record_full_chapter.gd"
func run()->void:
	var opening=load("res://start.tscn").instantiate()
	root.add_child(opening);game=opening.game
	var locale=preload("res://scripts/game_locale.gd")
	var original:String=locale.language
	locale.language="en"
	await frames(150)
	if DisplayServer.get_name()!="headless":root.get_texture().get_image().save_png("res://recordings/title-departure-en.png")
	locale.language="zh"
	await frames(150)
	if DisplayServer.get_name()!="headless":root.get_texture().get_image().save_png("res://recordings/title-departure-zh.png")
	locale.language=original
	tap(KEY_ENTER);await frames(120)
	if not verify(opening.phase==1,"new cover enters story introduction"):return
	opening.queue_free();await process_frame;quit()
