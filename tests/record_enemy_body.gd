extends "res://tests/record_chapter_one.gd"
var watching := false
var contacts := 0
func check_body() -> void:
	if not watching:return
	for enemy in game.exploration.enemies:
		if enemy.hp<=0:continue
		var gap:float=game.exploration.body_gap(enemy)
		assert(game.player.distance_to(enemy.pos)>=gap-.02,"no player/enemy penetration")
		if game.player.distance_to(enemy.pos)<gap+.15:contacts+=1
func snap(id:String) -> void:
	if DisplayServer.get_name()!="headless":root.get_texture().get_image().save_png("res://recordings/enemy-body-"+id+".png")
func run() -> void:
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.beats.memory_done=true;game.story.pages.clear();game.story.stage=game.story.Stage.KEYS
	game.intro_time=0;game.gate_open=true;game.slime_health=0;game.slime=Vector2(800,800)
	game.controls.walked=200;game.controls.interacted=true
	game.combat_stats.rng.seed=17
	process_frame.connect(check_body)
	for kind in ["skeleton","plant","bat"]:
		watching=false;game.exploration.enemies.clear();game.exploration.shots.clear()
		game.cancel_combo();game.hurt_time=0;game.dodge_time=0;game.dodge_cooldown=0;game.health=game.max_health;game.stamina=100
		game.player=Vector2(610,275);game.camera=Vector2(448,165)
		game.exploration._add(kind,Vector2i(40,17),Rect2(520,150,180,200))
		var enemy:Dictionary=game.exploration.enemies[0];enemy.pos=Vector2(642,275)
		# Brief neutral setup to clearly demonstrate body blocking before live combat.
		enemy.time=99
		watching=true;await frames(45)
		await hold(KEY_RIGHT,50);snap(kind+"-contact")
		tap(KEY_Q);await hold(KEY_RIGHT,40)
		assert(game.player.x<enemy.pos.x,"dash cannot cross "+kind)
		await hold(KEY_UP,25);await hold(KEY_RIGHT,35);await hold(KEY_DOWN,25);await hold(KEY_LEFT,32)
		assert(game.player.x>enemy.pos.x,"can circle around "+kind)
		snap(kind+"-flank")
		enemy.time=0
		for frame in range(900):
			if enemy.hp<=0:break
			var offset:Vector2=enemy.pos-game.player
			if game.attack_time<=0:
				var code:=KEY_RIGHT if offset.x>0 else KEY_LEFT
				if absf(offset.y)>absf(offset.x):code=KEY_DOWN if offset.y>0 else KEY_UP
				await hold(code,1)
				if offset.length()<23:tap(KEY_J)
			await frames(1)
		assert(enemy.hp<=0 and game.health>0,"normal basic attacks beat "+kind)
		await frames(55);snap(kind+"-defeated")
		print("PASS ",kind," walk/dash blockage, circling and normal-input melee victory")
	watching=false;process_frame.disconnect(check_body)
	assert(contacts>100)
	print("PASS contact-frame checks: ",contacts)
	await frames(40);game.queue_free();await process_frame;quit()
