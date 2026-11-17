extends "res://tests/record_combo_showcase.gd"
func prepare(kind:String,title:String):
	game.cancel_combo();game.hit_stop=0;game.shake_time=0;game.stamina=100;game.health=game.max_health
	game.exploration.enemies.clear();game.exploration.shots.clear();game.effects.clear();game.damage_popups.clear()
	game.player=Vector2(605,270);game.facing=Vector2.RIGHT
	game.exploration._add(kind,Vector2i(39,17),Rect2(500,180,180,160))
	var e=game.exploration.enemies.back();e.pos=game.player+Vector2(20,0);e.hp=20;e.time=99
	game._notice(title);game.message_time=3
	game.combat_stats.rng.seed=17
	await frames(45)
func run():
	var opening=load("res://start.tscn").instantiate();root.add_child(opening);opening.phase=5
	game=opening.game;game.remove_meta("opening_preview");game.set_physics_process(true);game.set_process_input(true)
	game.story.stage=game.story.Stage.COMPLETE;game.story.pages.clear();game.story.complete_card=false;game.intro_time=0;game.slime_health=0;game.gate_open=true
	game.controls.walked=1;game.controls.interacted=true;game.controls.completed=[0.0,0.0,0.0]
	if DisplayServer.get_name()!="headless":DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	await prepare("skeleton","轻击三连 · 短促顿帧")
	tap(KEY_J);await frames(6);tap(KEY_J)
	if not await wait_move("light2"):return
	await frames(6);tap(KEY_J);await frames(90)
	await prepare("plant","重劈 · 低频冲击")
	tap(KEY_K);await frames(100)
	await prepare("bat","轻击 · 飞行目标受击")
	tap(KEY_J);await frames(85)
	await prepare("skeleton","蓄力暴击 · 更强命中反馈")
	game.sync_stats()
	for seed in range(1000):
		game.combat_stats.rng.seed=seed
		if game.combat_stats.resolve(38,.05).type=="critical":
			game.combat_stats.rng.seed=seed;break
	key(KEY_K,true);await frames(48);key(KEY_K,false);await frames(120)
	var critical:=false
	for result in game.results:
		if result.type=="critical":critical=true
	assert(critical and game.results.size()>=5)
	print("PASS main campaign feedback on skeleton, plant, bat, heavy and seeded critical; hits=",game.results.size())
	quit()
