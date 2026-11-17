extends "res://tests/record_chapter_one.gd"

# Start from the chapter-one-complete checkpoint; all mine interactions below use real input.
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.story.stage = game.story.Stage.COMPLETE
	game.story.pages.clear()
	game.story.complete_card = false
	game.intro_time = 0
	game.rockbreak = true
	game.fountain_awake = true
	game.gate_open = true
	game.slime_health = 0
	game.player = game._center(Vector2i(16,25))
	game.camera = game.player-Vector2(160,110)
	if DisplayServer.get_name() != "headless": DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	await frames(80)
	if not await walk_to(Vector2i(15,25)): return
	tap(KEY_E)
	await frames(50)
	if not verify(game.cave_open,"cracked entrance opened"): return
	for tile in [Vector2i(12,25),Vector2i(10,24),Vector2i(12,27),game.RELIC]:
		if not await walk_to(tile): return
	tap(KEY_E)
	await frames(100)
	if not verify(game.relic_found,"echo core acquired"): return
	tap(KEY_E)
	if not await walk_to(Vector2i(10,30)): return
	tap(KEY_K)
	await frames(65)
	if not verify(game.mine.wall_open,"loose wall shattered"): return
	if not await walk_to(game.mine.JOURNAL): return
	tap(KEY_E)
	await frames(130)
	if not await walk_to(game.mine.CACHE): return
	tap(KEY_E)
	await frames(65)
	for tile in [Vector2i(7,35),Vector2i(11,33),Vector2i(15,33),game.mine.PRISM]:
		if not await walk_to(tile): return
	tap(KEY_E)
	await frames(100)
	if not verify(game.mine.prism_found,"crystal ledge reached"): return
	for tile in [Vector2i(14,34),Vector2i(13,36),Vector2i(12,37)]:
		if not await walk_to(tile): return
	while game.pulse_cooldown > 0 or game.attack_time > 0: await frames(1)
	tap(KEY_K)
	await frames(70)
	if not verify(game.mine.door_open,"paired rune stones activated"): return
	if not await walk_to(Vector2i(13,38)): return
	for i in range(180):
		if not await attack_nearby(): await frames(1)
	if not await walk_to(game.mine.TREASURE): return
	tap(KEY_E)
	await frames(90)
	if not verify(game.mine.treasure_found,"treasury explored"): return
	for tile in [Vector2i(10,44),Vector2i(15,44),game.mine.LIFT]:
		if not await walk_to(tile): return
		await frames(35)
	tap(KEY_E)
	await frames(90)
	if not verify(game.mine.lift_repaired,"lift repaired"): return
	tap(KEY_E)
	await frames(100)
	verify(game.player.distance_to(game._center(game.mine.LIFT_TOP))<2,"lift returns to upper mine")
	quit()
