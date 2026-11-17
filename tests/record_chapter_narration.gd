extends "res://tests/record_chapter_presentation.gd"
func run():
	var opening=load("res://start.tscn").instantiate();root.add_child(opening);opening.phase=5
	game=opening.game;game.remove_meta("opening_preview");game.set_physics_process(true);game.set_process_input(true);game.intro_time=0
	if DisplayServer.get_name()!="headless":DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	await frames(180)
	assert(game.story.chapter_card_active() and game.story.pages[game.story.page][1]=="")
	await shot("res://recordings/chapter-title-only.png")
	tap(KEY_E);await frames(120)
	assert(not game.story.chapter_card_active() and game.story.pages[game.story.page][0]=="Narrator")
	await shot("res://recordings/chapter-narrator.png")
	await frames(240);tap(KEY_E);await frames(120)
	assert(game.story.pages[game.story.page][0]=="Noah's Mother")
	await shot("res://recordings/chapter-dialogue.png")
	await read_dialogue()
	assert(game.story.stage==game.story.Stage.CHILD)
	await frames(90)
	print("PASS title-only card -> portrait-free narration -> NPC dialogue -> playable tutorial")
	quit()
