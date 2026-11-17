extends SceneTree

var game: Node2D
var allow_auto := true
var use_combo_branches:=false
var melee_inputs:=0

func _initialize() -> void:
	process_frame.connect(force_render)
	run.call_deferred()

func force_render() -> void:
	RenderingServer.force_draw(false)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func hold(code: Key, count: int) -> void:
	for frame in range(count):
		key(code, true)
		await frames(1)
	key(code, false)

func tap(code: Key) -> void:
	key(code, true)
	key(code, false)

func verify(value: bool, label: String) -> bool:
	if value:
		print("PASS ", label, " ", game.player)
	else:
		printerr("FAIL ", label, " ", game.player, " scene=", game.name)
		quit(1)
	return value

func walk_to(tile: Vector2i) -> bool:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, -10, 48, 56)
	grid.cell_size = Vector2(16, 16)
	grid.offset = Vector2(8, 8)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y in range(-10,46):
		for x in range(48):
			grid.set_point_solid(Vector2i(x, y), not game._walkable(game._center(Vector2i(x, y))) or not preload("res://scripts/story_space.gd").body_free(game.story,game._center(Vector2i(x,y))))
	var start:=Vector2i((game.player/16).floor())
	grid.set_point_solid(start,false)
	if grid.is_point_solid(tile):
		var original:=tile
		var best:=INF
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var candidate:Vector2i=original+offset
			if not grid.is_point_solid(candidate):
				var distance:float=game.player.distance_squared_to(game._center(candidate))
				if distance<best:best=distance;tile=candidate
	var path := grid.get_point_path(Vector2i((game.player / 16).floor()), tile)
	if not verify(not path.is_empty(), "route to " + str(tile)): return false
	for point in path:
		var budget := 480
		while game.player.distance_to(point) > 3.5:
			if not game.story.pages.is_empty(): await read_dialogue()
			if game.cleared: return true
			budget -= 1
			if budget <= 0:
				verify(false, "navigation stalled")
				return false
			if allow_auto and await attack_nearby():
				continue
			var offset: Vector2 = point - game.player
			var code := KEY_RIGHT if offset.x > 0 else KEY_LEFT
			if absf(offset.y) > absf(offset.x):
				code = KEY_DOWN if offset.y > 0 else KEY_UP
			await hold(code, 1)
	return true

func attack_nearby() -> bool:
	for enemy in game.exploration.enemies:
		if enemy.hp <= 0: continue
		var offset: Vector2 = enemy.pos - game.player
		if offset.length() > 23 or not game.exploration._visible(game.player, enemy.pos):
			continue
		if game.story.training.active:
			if game.attack_time>0 or game.dodge_time>0:await frames(1);return true
			game.facing=offset.normalized()
			match game.story.training.lesson():
				"light3":
					for i in range(3):tap(KEY_J);await frames(16)
				"thrust","spin":
					for i in range(1 if game.story.training.lesson()=="thrust" else 2):tap(KEY_J);await frames(16)
					tap(KEY_K)
				"heavy":tap(KEY_K)
				"charged":key(KEY_K,true);await frames(48);key(KEY_K,false)
				"chase":tap(KEY_Q);await frames(8);tap(KEY_J)
			await frames(65)
			return true
		if enemy.get("plated", false) and enemy.get("exposed", 0.0) <= 0:
			if game.pulse_cooldown <= 0 and game.attack_time <= 0: tap(KEY_K)
			await frames(1)
			return true
		if game.attack_time > 0:
			await frames(1)
			return true
		var code := KEY_RIGHT if offset.x > 0 else KEY_LEFT
		if absf(offset.y) > absf(offset.x):
			code = KEY_DOWN if offset.y > 0 else KEY_UP
		await hold(code, 1)
		tap(KEY_J)
		await frames(1)
		return true
	return false

func read_dialogue() -> void:
	await frames(2)
	while not game.story.pages.is_empty():
		var line: String = str(game.story.pages[game.story.page][1])
		await frames(2 if DisplayServer.get_name() == "headless" else maxi(125,int(line.length()*4.8)))
		game.story.dialogue_age = maxf(game.story.dialogue_age,0.2) if DisplayServer.get_name() == "headless" else game.story.dialogue_age
		tap(KEY_E)
		await frames(2)

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	if DisplayServer.get_name() != "headless": DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(), RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	await frames(100)
	await read_dialogue()
	if not verify(game.story.stage == game.story.Stage.CHILD,"chapter opening"): return
	if not await walk_to(Vector2i(15,14)): return
	if not await walk_to(game.story.CHILD): return
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
	await frames(2)
	await read_dialogue()
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
	if not await walk_to(game.SEALS[0]): return
	tap(KEY_E)
	await read_dialogue()
	if not verify(game.seals.size() == 1,"north sluice key"): return
	if not await walk_to(Vector2i(19,19)): return
	if not await walk_to(Vector2i(20,25)): return
	if not await walk_to(Vector2i(25,24)): return
	if not await walk_to(game.SEALS[1]): return
	tap(KEY_E)
	await read_dialogue()
	if not verify(game.gate_open and game.story.stage == game.story.Stage.PRIEST,"both keys open bridge"): return
	if not await walk_to(game.BRIDGE_CAMP): return
	tap(KEY_E)
	await frames(70)
	if not await walk_to(game.story.PRIEST): return
	tap(KEY_E)
	await read_dialogue()
	if not verify(game.story.stage == game.story.Stage.GUARD,"meet priestess"): return
	if not await fight_warden(): return
	await frames(2)
	await read_dialogue()
	if not await walk_to(game.FOUNTAIN): return
	tap(KEY_E)
	await read_dialogue()
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
	var previous_health:int=game.health
	var previous_state := -1
	var dodge_code := KEY_UP
	for frame in range(4200):
		if game.health!=previous_health:
			print("HIT health=",game.health," boss=",game.slime_health," kind=",game.patterns.kind," distance=",game.slime.distance_to(game.player))
			previous_health=game.health
		if game.slime_health <= 0:
			return verify(true, "warden defeated with normal attacks and recovery windows")
		if game.player.distance_to(game._center(game.checkpoint)) < 20:
			return verify(false, "warden fight caused respawn")
		var offset: Vector2 = game.slime - game.player
		if game.guard_state == 1 and previous_state != 1:
			var side: Vector2 = game.charge_direction.orthogonal()
			if game.player.y < 155: side = Vector2.DOWN
			if game.player.y > 320: side = Vector2.UP
			dodge_code = KEY_RIGHT if side.x > 0 else KEY_LEFT
			if absf(side.y) > absf(side.x):
				dodge_code = KEY_DOWN if side.y > 0 else KEY_UP
		if game.player.x < 550 and dodge_code == KEY_LEFT:
			dodge_code = KEY_RIGHT
		if game.player.x > 675 and dodge_code == KEY_RIGHT:
			dodge_code = KEY_LEFT
		if game.player.y < 145 and dodge_code == KEY_UP:
			dodge_code = KEY_DOWN
		if game.player.y > 330 and dodge_code == KEY_DOWN:
			dodge_code = KEY_UP
		previous_state = game.guard_state
		var danger:bool=game.guard_state in [1,2]
		if danger and game.patterns.kind in [1,3]:
			danger=(-offset.normalized()).dot(game.charge_direction)>(.3 if game.patterns.kind==3 else .5)
		if danger and game.patterns.kind==2:
			danger=false
			for mark in game.patterns.marks:
				if game.player.distance_to(mark)<22:danger=true
		if danger:
			if game.patterns.kind==3 and game.guard_state==1 and game.guard_time>.43 and offset.length()<24 and game.attack_time<=0:
				var aim:=KEY_RIGHT if offset.x>0 else KEY_LEFT
				if absf(offset.y)>absf(offset.x):aim=KEY_DOWN if offset.y>0 else KEY_UP
				await hold(aim,1);tap(KEY_J)
			if game.patterns.kind==3 and offset.length()>39:
				await frames(1)
				continue
			if game.patterns.kind==3:
				# A solid guardian cannot be crossed to escape its tracking swing.
				# Retreat outside the sweep, then punish the recovery.
				var away:Vector2=game.slime.direction_to(game.player)
				dodge_code=KEY_RIGHT if away.x>0 else KEY_LEFT
				if absf(away.y)>absf(away.x):dodge_code=KEY_DOWN if away.y>0 else KEY_UP
			elif game.patterns.kind==1:
				var flank:Vector2=game.slime+game.charge_direction.orthogonal()*19
				if not game._walkable(flank):flank=game.slime-game.charge_direction.orthogonal()*19
				var toward:Vector2=flank-game.player
				dodge_code=KEY_RIGHT if toward.x>0 else KEY_LEFT
				if absf(toward.y)>absf(toward.x):dodge_code=KEY_DOWN if toward.y>0 else KEY_UP
			if game.guard_state==1 and game.guard_time<.15 and game.dodge_cooldown<=0 and game.patterns.kind==0:
				await hold(dodge_code,1)
				tap(KEY_Q)
			await hold(dodge_code, 1)
		elif offset.length() < 20:
			if game.attack_time <= 0:
				var code := KEY_RIGHT if offset.x > 0 else KEY_LEFT
				if absf(offset.y) > absf(offset.x): code = KEY_DOWN if offset.y > 0 else KEY_UP
				await hold(code, 1)
				melee_inputs+=1
				var heavy:bool=use_combo_branches and game.chain>0 and game.stamina>=55 and (melee_inputs%3==0 or melee_inputs%5==0)
				tap(KEY_K if heavy else KEY_J)
			await frames(1)
		else:
			var code := KEY_RIGHT if offset.x > 0 else KEY_LEFT
			if absf(offset.y) > absf(offset.x): code = KEY_DOWN if offset.y > 0 else KEY_UP
			await hold(code, 1)
	return verify(false, "warden timeout")
