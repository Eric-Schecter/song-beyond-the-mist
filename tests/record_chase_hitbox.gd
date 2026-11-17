extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.KNIGHT;game.intro_time=0
	game.player=game._center(game.story.KNIGHT)+Vector2(-17,0)
	await frames(90)
	if DisplayServer.get_name()!="headless":root.get_texture().get_image().save_png("res://recordings/quest-e-centered.png")
	game.exploration.enemies.clear();game.player=Vector2(280,248)
	game.controls.walked=2;game.controls.learned={"light1":true,"dodge":true}
	game.story.advance(game.story.Stage.DEFEND)
	for index in game.story.raid_indices:game.exploration.enemies[index].hp=0
	game.story.training.spawn(game.story,5)
	var seen:Dictionary={}
	for attempt in range(600):
		if not game.story.training.active:break
		var wave:int=game.story.training.wave
		seen[wave]=true
		var target:Dictionary={}
		for index in game.story.raid_indices:
			var enemy:Dictionary=game.exploration.enemies[index]
			if enemy.hp>0 and (target.is_empty() or enemy.pos.distance_to(game.player)<target.pos.distance_to(game.player)):target=enemy
		if target.is_empty():await frames(45);continue
		if not target.get("arrival",[]).is_empty():await frames(20);continue
		var offset:Vector2=target.pos-game.player
		var desired_distance:float=40 if wave==5 and not game.story.training.demonstrated else 19
		if offset.length()>desired_distance:
			var keycode:Key=KEY_RIGHT if offset.x>0 else KEY_LEFT
			if absf(offset.y)>absf(offset.x):keycode=KEY_DOWN if offset.y>0 else KEY_UP
			await hold(keycode,6);continue
		if wave==5 and minf(absf(offset.x),absf(offset.y))>3:
			var align_key:Key=(KEY_DOWN if offset.y>0 else KEY_UP) if absf(offset.x)>absf(offset.y) else (KEY_RIGHT if offset.x>0 else KEY_LEFT)
			await hold(align_key,2);continue
		game.facing=offset.normalized()
		if game.attack_time>0 or game.dodge_time>0:await frames(10);continue
		if game.stamina<35:await frames(45);continue
		var lesson:String=game.story.training.lesson()
		if game.story.training.demonstrated and wave not in [3,4]:lesson="finish"
		match lesson:
			"finish":tap(KEY_J)
			"light3":
				for i in range(3):tap(KEY_J);await frames(16)
			"thrust","spin":
				for i in range(1 if lesson=="thrust" else 2):tap(KEY_J);await frames(16)
				tap(KEY_K)
			"heavy":tap(KEY_K)
			"charged":key(KEY_K,true);await frames(48);key(KEY_K,false)
			"chase":tap(KEY_Q);await frames(8);tap(KEY_J)
		await frames(65)
		print("WAVE ",wave," demonstrated=",game.story.training.demonstrated," hp=",target.hp," player=",game.player," enemy=",target.pos)
	if not verify(not game.story.training.active and seen.size()==1,"chase hit through actual input"):return
	await frames(100);game.queue_free();await process_frame;quit()
