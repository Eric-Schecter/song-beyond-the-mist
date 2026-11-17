extends "res://tests/record_full_chapter.gd"
func run() -> void:
	# Focused review starts from a chapter checkpoint; no state changes during combat.
	var opening=load("res://start.tscn").instantiate()
	root.add_child(opening)
	opening.phase=5
	game=opening.game
	game.remove_meta("opening_preview")
	game.set_physics_process(true);game.set_process_input(true)
	game.story.stage=game.story.Stage.GUARD
	game.story.pages.clear();game.story.complete_card=false
	game.intro_time=0;game.gate_open=true
	game.seals.assign([0,1])
	game.player=game._center(game.BRIDGE_CAMP)
	game.checkpoint=game.BRIDGE_CAMP
	game.camera=game.player-Vector2(160,110)
	game.growth.award(game,"checkpoint_progress",140)
	if DisplayServer.get_name()!="headless":DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	await frames(90)
	tap(KEY_P)
	await frames(150)
	tap(KEY_1);tap(KEY_2)
	await frames(150)
	if not verify(game.growth.power==1 and game.growth.vitality==1,"strength and vitality allocated at camp"):return
	tap(KEY_P)
	if not await walk_to(Vector2i(32,14)):return
	if not await fight_warden():return
	await read_dialogue()
	await frames(150)
	quit()
