extends "res://tests/record_material_audio.gd"
func run():
	var opening=load("res://start.tscn").instantiate();root.add_child(opening);opening.phase=5
	game=opening.game;game.remove_meta("opening_preview");game.set_physics_process(true);game.set_process_input(true)
	game.story.stage=game.story.Stage.COMPLETE;game.story.pages.clear();game.story.complete_card=false;game.intro_time=0;game.slime_health=0;game.gate_open=true
	game.controls.walked=1;game.controls.interacted=true;game.controls.completed=[0.0,0.0,0.0]
	if DisplayServer.get_name()!="headless":DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	await prepare("skeleton","受击录音 · 护甲格挡")
	game.growth.armor=1;game.exploration.enemies[0].time=.1
	for i in range(300):
		await frames(1)
		if game.growth.armor==0:break
	assert(game.growth.armor==0)
	await frames(90)
	await prepare("skeleton","受击录音 · 身体受伤")
	game.growth.armor=0;game.hurt_time=0;game.exploration.enemies[0].time=.1
	var hp:float=game.health
	for i in range(300):
		await frames(1)
		if game.health<hp:break
	assert(game.health<hp and game.material_counts.get("hurt",-1)>=0)
	await frames(75)
	await prepare("skeleton","反击 · 敌人受击")
	tap(KEY_K);await frames(100)
	assert(not game.results.is_empty())
	print("PASS real enemy armor/body hits and retaliation with recorded audio")
	quit()
