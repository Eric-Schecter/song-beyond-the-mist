extends "res://tests/record_growth_guardian.gd"
func run():
	use_combo_branches=true
	var opening=load("res://start.tscn").instantiate();root.add_child(opening);opening.phase=5
	game=opening.game;game.remove_meta("opening_preview")
	game.set_physics_process(true);game.set_process_input(true)
	game.story.stage=game.story.Stage.GUARD;game.story.pages.clear();game.story.complete_card=false
	game.intro_time=0;game.gate_open=true;game.seals.assign([0,1])
	game.player=game._center(game.BRIDGE_CAMP);game.checkpoint=game.BRIDGE_CAMP
	game.camera=game.player-Vector2(160,110);game.growth.award(game,"checkpoint_progress",140)
	game.combat_stats.rng.seed=17
	if DisplayServer.get_name()!="headless":DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	await frames(90)
	tap(KEY_P);await frames(80);tap(KEY_1);tap(KEY_2);await frames(80);tap(KEY_P)
	for i in range(4):
		tap(KEY_K);await frames(2)
		while game.attack_time>0:await frames(1)
	var low:float=game.stamina
	tap(KEY_Q);assert(game.dodge_time==0 and game.stamina<18,"exhausted dodge rejected")
	tap(KEY_K);assert(game.attack_time==0,"exhausted heavy rejected")
	tap(KEY_J);assert(game.attack_time>0,"basic light available while exhausted")
	await frames(240)
	assert(game.stamina>low+20 and game.stamina<100,"slow regeneration visible")
	tap(KEY_E);tap(KEY_ENTER);tap(KEY_ESCAPE);await frames(60);assert(game.stamina==100,"camp restores stamina")
	print("PASS exhaustion blocks dodge/heavy, free basic attack, recovery and camp refill")
	if not await walk_to(Vector2i(32,14)):return
	if not await demonstrate_combat():return
	await frames(30);quit()

func demonstrate_combat()->bool:
	for frame in range(1500):
		if game.health<=2:return verify(true,"real attacks show numerical health loss and low-health bar")
		var offset:Vector2=game.slime-game.player
		var direction:Vector2=offset
		if game.guard_state in [game.Guard.WINDUP,game.Guard.CHARGE]:
			direction=game.charge_direction.orthogonal()
			if game.player.y<150:direction=Vector2.DOWN
			if game.player.y>325:direction=Vector2.UP
		else:
			if offset.length()<22 and game.attack_time<=0:
				game.facing=offset.normalized()
				tap(KEY_K if game.chain>0 and game.stamina>45 else KEY_J)
		var code:Key=KEY_RIGHT if direction.x>0 else KEY_LEFT
		if absf(direction.y)>absf(direction.x):code=KEY_DOWN if direction.y>0 else KEY_UP
		await hold(code,1)
		if game.guard_state==game.Guard.WINDUP and game.guard_time<.12 and game.stamina>=18:tap(KEY_Q)
		if game.slime_health<=0:return verify(true,"combat finished with vitals visible")
	return verify(game.health<game.max_health,"combat damage visible")
