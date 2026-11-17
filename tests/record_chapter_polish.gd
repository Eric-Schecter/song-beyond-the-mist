extends "res://tests/record_full_chapter.gd"

func quick_dismiss() -> void:
	while not game.story.pages.is_empty():
		game.story.dialogue_age=10;tap(KEY_E);await frames(2)

func snap(label: String) -> void:
	if DisplayServer.get_name()!="headless":root.get_texture().get_image().save_png("res://recordings/polish-"+label+".png")

func run() -> void:
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.beats.memory_done=true;game.intro_time=0
	game.combat_stats.rng.seed=17
	await frames(200)
	assert(game.story.pages[0][0]=="Narrator")
	snap("opening")
	await quick_dismiss()
	# Focused animation demonstration in the real scene with normal attack input.
	game.story.stage=game.story.Stage.COMPLETE
	game.player=Vector2(202,242);game.camera=Vector2(42,132)
	await frames(60)
	for direction in [KEY_UP,KEY_DOWN]:
		await hold(direction,2)
		for strike in range(3):
			tap(KEY_J);await frames(9)
			snap("attack-"+str(direction)+"-"+str(strike))
			await frames(20)
		await frames(60)
		tap(KEY_K);await frames(24);snap("heavy-"+str(direction));await frames(75)
	# Actual breadcrumb escort movement, including the newly animated feet.
	game.story.stage=game.story.Stage.RETURN;game.story.beats.child_confided=true
	game.story.child_position=game.player-Vector2(23,0);game.story.footsteps.clear()
	await hold(KEY_RIGHT,65);snap("child-walk");await hold(KEY_LEFT,35);await frames(40)
	# Ordinary level-1 combat against the stronger quarry skeleton.
	game.story.stage=game.story.Stage.KEYS;game.player=Vector2(304,408);game.camera=Vector2(144,296)
	game.health=game.max_health;game.stamina=game.mana_max()
	var enemy:Dictionary=game.exploration.enemies[2]
	assert(enemy.hp==4.0)
	await frames(35)
	for frame in range(900):
		if enemy.hp<=0:break
		var offset:Vector2=enemy.pos-game.player
		var code:=KEY_RIGHT if offset.x>0 else KEY_LEFT
		if absf(offset.y)>absf(offset.x):code=KEY_DOWN if offset.y>0 else KEY_UP
		if game.attack_time<=0:
			await hold(code,1)
			if offset.length()<24:tap(KEY_K if game.stamina>=24 and game.chain==0 else KEY_J)
		await frames(1)
	assert(enemy.hp<=0 and game.health>0)
	await frames(18);snap("skeleton-falling");await frames(65)
	print("PASS level-one combat against 40 HP skeleton and complete death animation")
	game.combat_stats.rng.seed=17
	# Start at the usual pre-boss state. Attribute allocation mirrors the earned level-4 build.
	game.story.stage=game.story.Stage.GUARD;game.story.beats.memory_done=true
	game.player=Vector2(567,257);game.slime=Vector2(606,267);game.camera=Vector2(448,146)
	game.gate_open=true;game.growth.power=3;game.growth.level=4;game.sync_stats();game.max_health=8;game.health=8;game.growth.armor=1
	game.stamina=game.mana_max();game.guard_state=game.Guard.WATCH
	use_combo_branches=true
	await frames(30);snap("boss-music")
	if not await fight_warden():return
	assert(game.story.pages.is_empty(),"death is not interrupted by dialogue")
	await frames(22);snap("boss-falling")
	await frames(55)
	assert(not game.story.pages.is_empty())
	await frames(120);await quick_dismiss()
	# The purification encounter is covered by full-route regression; show the sluice opening.
	game.story.beats.purified=true;game.story.beats.priest_pos=game._center(game.FOUNTAIN)+Vector2(-22,10)
	game.player=game._center(game.FOUNTAIN)+Vector2(0,16);game.camera=Vector2(448,96)
	await frames(90);snap("water-dry")
	tap(KEY_E)
	await frames(50);snap("water-rising")
	await frames(230);snap("water-restored")
	await quick_dismiss()
	assert(game.story.stage==game.story.Stage.HOME)
	# Follow the same physical route home as normal play.
	if not await walk_to(Vector2i(35,14)):return
	snap("priest-walk")
	if not await walk_to(game.story.MOTHER):return
	tap(KEY_E);await quick_dismiss();await frames(180)
	assert(game.story.complete_card);snap("ending")
	print("PASS polish capture: narration, vertical attacks, escorts, boss score/death, water restoration and to be continued")
	game.queue_free();await process_frame;quit()
