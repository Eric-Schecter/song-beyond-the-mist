extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.intro_time=0;await frames(60)
	game.story.advance(game.story.Stage.COMPLETE)
	for i in range(20):
		tap(KEY_ENTER);await frames(12)
		if not verify(game.story.complete_card,"early input ignored"):return
	await frames(100)
	if not verify(game.story.complete_card,"wait does not auto dismiss"):return
	root.get_texture().get_image().save_png("res://recordings/ending-hold.png")
	tap(KEY_ENTER);await frames(30)
	if not verify(not game.story.complete_card,"fresh input after minimum closes card"):return
	game.queue_free();await process_frame;quit()
