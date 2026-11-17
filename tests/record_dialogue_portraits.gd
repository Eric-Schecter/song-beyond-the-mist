extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	await frames(30)
	game.story.speak([["Noah's Mother","小诺带着水壶去了村东，到现在还没回来。你能帮我找找他吗？"],["Hero","我会找到他，带他平安回来。"],["Noah","谢谢你！我们一起回家吧。"],["Roland","带上我的徽记，去泉岛找神官艾琳。"],["Erin","先救这里的人，再一起寻找公主。"]])
	while not game.story.pages.is_empty():
		await frames(140)
		var previous: int = game.story.page
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = Vector2(290,200)
		game._input(click)
		if not verify(game.story.pages.is_empty() or game.story.page == previous+1,"click advances dialogue"): return

	await frames(40)
	print("PASS widescreen dialogue portraits")
	quit()
