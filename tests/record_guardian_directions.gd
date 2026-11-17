extends "res://tests/record_chapter_one.gd"
func run():
	# Isolated four-direction visual review. Each case resets positions and health.
	var opening=load("res://start.tscn").instantiate();root.add_child(opening)
	opening.phase=5;game=opening.game;game.remove_meta("opening_preview")
	game.set_physics_process(true);game.set_process_input(true)
	game.story.stage=game.story.Stage.GUARD;game.story.pages.clear();game.story.complete_card=false
	game.intro_time=0;game.gate_open=true;game.seals.assign([0,1])
	if DisplayServer.get_name()!="headless":DisplayServer.window_move_to_foreground()
	for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		game.slime=Vector2(608,256);game.player=game.slime+direction*30
		game.camera=game.slime-Vector2(160,110)
		game.health=3;game.hurt_time=0;game.dodge_time=0;game.slime_health=18
		game.patterns.reset();game.patterns.skill_cooldown=10
		game.guard_state=game.Guard.WATCH
		await frames(100)
		if not verify(game.health==2,"standing in melee range is hit from "+str(direction)):return
	await frames(30)
	quit()
