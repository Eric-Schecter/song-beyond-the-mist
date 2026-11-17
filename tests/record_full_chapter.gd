extends "res://tests/record_chapter_one.gd"

func finish_lessons(advanced:bool)->void:
	for id in game.controls.LESSONS:
		if game.controls.learned.has(id):continue
		if not advanced and id not in ["light1","light3","dodge"]:continue
		game.cancel_combo();await frames(90)
		while game.stamina<40:await frames(30)
		match id:
			"light1":tap(KEY_J)
			"light3":
				for i in range(3):tap(KEY_J);await frames(16)
			"dodge":tap(KEY_Q)
			"thrust","spin":
				for i in range(1 if id=="thrust" else 2):tap(KEY_J);await frames(16)
				tap(KEY_K)
			"heavy":tap(KEY_K)
			"charged":key(KEY_K,true);await frames(120);key(KEY_K,false)
			"chase":tap(KEY_Q);await frames(8);tap(KEY_J)
		await frames(100)

func read_dialogue() -> void:
	await frames(2)
	while not game.story.pages.is_empty():
		var line: String=str(game.story.pages[game.story.page][1])
		await frames(maxi(150,int(line.length()*2.8)+60) if DisplayServer.get_name() != "headless" else 10)
		tap(KEY_E)
		await frames(2)

func walk_to(tile: Vector2i) -> bool:
	var destination := tile
	if tile==game.story.CHILD:destination=tile+Vector2i.LEFT
	elif tile==game.story.MOTHER:destination=Vector2i(7,16)
	elif tile==game.story.KNIGHT:destination=Vector2i(6,17)
	elif tile==game.story.PRIEST:destination=Vector2i(32,14)
	elif tile==game.FOUNTAIN:destination=tile+Vector2i.DOWN
	if not await super.walk_to(destination):return false
	# Adjacent NPC cells are safe, but the route tolerance can stop just outside E range.
	for i in range(16):
		var offset:Vector2=game._center(tile)-game.player
		if offset.length()<=17.5:break
		var code:=KEY_RIGHT if offset.x>0 else KEY_LEFT
		if absf(offset.y)>absf(offset.x):code=KEY_DOWN if offset.y>0 else KEY_UP
		await hold(code,1)
	return true

func run() -> void:
	var opening=load("res://start.tscn").instantiate()
	root.add_child(opening)
	game=opening.game
	if use_combo_branches:game.combat_stats.rng.seed=17
	if DisplayServer.get_name() != "headless": DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(), RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	await frames(180)
	tap(KEY_ENTER)
	for i in range(3):
		await frames(420)
		tap(KEY_ENTER)
	await frames(180)
	if not verify(opening.phase==5 and opening.music.playing,"title and prologue complete with music"):return
	await read_dialogue()
	if game.story.beats.memory_active():
		for tile in [game.story.beats.GEAR,game.story.CLUES.wheel,game.story.beats.LIA]:
			if not await walk_to(tile):return
			tap(KEY_E);await read_dialogue()
		await frames(3);await read_dialogue()
	if not verify(game.story.stage == game.story.Stage.CHILD,"chapter opening"): return
	if not await walk_to(game.story.CLUES["wheel"]):return
	tap(KEY_E);await read_dialogue()
	if not await walk_to(Vector2i(15,14)): return
	if not await walk_to(game.story.CHILD): return
	await finish_lessons(false)
	tap(KEY_E)
	await read_dialogue()
	if not verify(game.story.stage == game.story.Stage.RETURN,"child rescued"): return
	if not await walk_to(game.story.MOTHER): return
	await frames(100)
	tap(KEY_E)
	await read_dialogue()
	if not verify(game.story.stage == game.story.Stage.DEFEND,"village defense started"): return
	if not await walk_to(Vector2i(10,17)): return
	if not await walk_to(Vector2i(11,15)): return
	await finish_lessons(true)
	await frames(2)
	await read_dialogue()
	for frame in range(1800):
		if not game.story.pages.is_empty():await read_dialogue()
		if game.story.stage==game.story.Stage.KNIGHT:break
		await attack_nearby();await frames(1)
	if not verify(game.story.stage == game.story.Stage.KNIGHT,"village defended"): return
	if not await walk_to(game.story.KNIGHT): return
	tap(KEY_E)
	await read_dialogue()
	if not verify(game.story.stage == game.story.Stage.KEYS,"princess abduction and royal badge"): return
	tap(KEY_M);tap(KEY_RIGHT)
	await frames(150 if DisplayServer.get_name() != "headless" else 2)
	tap(KEY_M)
	if not await walk_to(Vector2i(19,11)): return
	if not await walk_to(Vector2i(20,5)): return
	if not await walk_to(Vector2i(24,6)): return
	tap(KEY_E);await read_dialogue()
	for tile in game.journey.SWITCHES:
		if not await walk_to(tile):return
		tap(KEY_E)
		await frames(100)
	if not await walk_to(game.SEALS[0]): return
	tap(KEY_E)
	await read_dialogue()
	if not verify(game.seals.size() == 1,"north sluice key"): return
	if not await walk_to(game.VILLAGE):return
	tap(KEY_E)
	tap(KEY_P)
	await frames(120)
	while game.growth.points>0:
		tap(KEY_1);await frames(15)
	await frames(120)
	tap(KEY_P)
	if not await walk_to(Vector2i(19,19)): return
	if not await walk_to(Vector2i(20,25)): return
	if not await walk_to(game.story.CLUES["manifest"]):return
	tap(KEY_E);await read_dialogue()
	if not await walk_to(Vector2i(25,24)): return
	if not await walk_to(game.SEALS[1]): return
	tap(KEY_E)
	await read_dialogue()
	if not verify(game.gate_open and game.story.stage == game.story.Stage.PRIEST,"both keys open bridge"): return
	if not await walk_to(game.BRIDGE_CAMP): return
	tap(KEY_E)
	tap(KEY_P);await frames(70)
	while game.growth.points>0:
		tap(KEY_1);await frames(15)
	await frames(70);tap(KEY_P)
	tap(KEY_E)
	print("EARNED BUILD fortitude=",game.growth.power," level=",game.growth.level," HP=",game.max_health," armor=",game.growth.armor)
	await frames(70)
	if not await walk_to(game.story.PRIEST): return
	tap(KEY_E)
	await read_dialogue()
	for tile in [game.story.beats.WATER,game.story.beats.REFUGEES]:
		if not await walk_to(tile):return
		tap(KEY_E);await read_dialogue()
	if not await walk_to(game.story.PRIEST):return
	tap(KEY_E);await read_dialogue()
	if not verify(game.story.stage == game.story.Stage.GUARD,"meet priestess"): return
	if not await fight_warden(): return
	await frames(65)
	await read_dialogue()
	if not await walk_to(game.story.PRIEST):return
	tap(KEY_E);await read_dialogue()
	if not await walk_to(game.FOUNTAIN): return
	tap(KEY_E)
	await read_dialogue()
	for tile in [Vector2i(38,11),Vector2i(42,11),Vector2i(40,11)]:
		if not await walk_to(tile):return
	for frame in range(1800):
		if not game.story.pages.is_empty():await read_dialogue()
		if game.story.beats.purified:break
		await attack_nearby();await frames(1)
	if not verify(game.story.beats.purified,"purification defended"):return
	await read_dialogue()
	if not await walk_to(game.FOUNTAIN):return
	tap(KEY_E);await read_dialogue()
	if not verify(game.fountain_awake and game.story.stage == game.story.Stage.HOME,"spring restored"): return
	if not await walk_to(game.story.MOTHER): return
	tap(KEY_E)
	await read_dialogue()
	if not verify(game.story.stage == game.story.Stage.COMPLETE and game.story.complete_card,"chapter one complete"): return
	await frames(240 if DisplayServer.get_name() != "headless" else 3)
	tap(KEY_E)
	await frames(120 if DisplayServer.get_name() != "headless" else 3)
	quit()

func fight_warden() -> bool:
	var kinds:Dictionary={}
	var phase_checks:Dictionary={}
	var tracking:Callable=func():
		kinds[game.patterns.kind]=true
		if game.patterns.enraged:phase_checks["enraged"]=true
		if game.patterns.enraged and game.patterns.kind==3 and game.patterns.followups>0:phase_checks["combo"]=true
	physics_frame.connect(tracking)
	var result:=await super.fight_warden()
	physics_frame.disconnect(tracking)
	if result:print("PHASE REVIEW ",phase_checks)
	return result and verify(kinds.has(3) and kinds.size()>=3,"basic attacks and varied guardian skills encountered")
