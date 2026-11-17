extends SceneTree

var game: Node2D
var allow_auto := true

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
	grid.region = Rect2i(0, 0, 48, 46)
	grid.cell_size = Vector2(16, 16)
	grid.offset = Vector2(8, 8)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y in range(46):
		for x in range(48):
			grid.set_point_solid(Vector2i(x, y), not game._walkable(game._center(Vector2i(x, y))))
	var path := grid.get_point_path(Vector2i((game.player / 16).floor()), tile)
	if not verify(not path.is_empty(), "route to " + str(tile)): return false
	for point in path:
		var budget := 480
		while game.player.distance_to(point) > 1.3:
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
	if not await walk_to(Vector2i(14,14)): return
	tap(KEY_E)
	await read_dialogue()
	if not verify(game.story.stage == game.story.Stage.RETURN,"child rescued"): return
	if not await walk_to(Vector2i(7,16)): return
	await frames(100)
	tap(KEY_E)
	await read_dialogue()
	if not verify(game.story.stage == game.story.Stage.DEFEND,"village defense started"): return
	if not await walk_to(Vector2i(10,17)): return
	if not await walk_to(Vector2i(11,15)): return
	await frames(2)
	await read_dialogue()
	if not verify(game.story.stage == game.story.Stage.KNIGHT,"village defended"): return
	if not await walk_to(Vector2i(6,17)): return
	tap(KEY_E)
	await read_dialogue()
	if not verify(game.story.stage == game.story.Stage.KEYS,"princess abduction and royal badge"): return
	await frames(100)
	if not await walk_to(Vector2i(6,14)): return
	await frames(100)
	if not await walk_to(Vector2i(6,11)): return
	if not await walk_to(Vector2i(4,11)): return
	await frames(50)
	if not await walk_to(Vector2i(7,11)): return
	if not await walk_to(Vector2i(7,14)): return
	await frames(100)
	print("PASS refined village, child rescue/escort, defense, knight and house passage")
	quit()
