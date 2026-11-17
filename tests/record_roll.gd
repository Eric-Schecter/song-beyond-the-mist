extends "res://tests/record_chapter_one.gd"

func perform_roll(code: Key, label: String, blocked: bool = false) -> bool:
	while game.dodge_cooldown > 0: await frames(1)
	key(code,true)
	await frames(1)
	var start: Vector2 = game.player
	tap(KEY_Q)
	key(code,false)
	if not verify(game.dodge_time > 0,"roll started: "+label): return false
	await frames(1)
	tap(KEY_Q)
	if not verify(game.dodge_cooldown < 1,"cooldown prevents repeated roll"): return false
	while game.refined_hero.roll.elapsed < game.refined_hero.roll.DURATION: await frames(1)
	var distance: float = start.distance_to(game.player)
	if not verify(distance < 12 if blocked else distance > 25 and distance < 38,"roll distance/collision: "+label): return false
	if not verify(game._walkable(game.player),"roll remains on walkable ground"): return false
	await frames(30)
	return true

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.story.stage = game.story.Stage.COMPLETE
	game.story.pages.clear()
	game.story.complete_card = false
	game.intro_time = 0
	game.player = game._center(game.VILLAGE)
	game.camera = Vector2(0,138)
	if DisplayServer.get_name() != "headless": DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_update_mode(root.get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	await frames(60)
	tap(KEY_1)
	if not verify(game.weapon == game.Weapon.SWORD,"equip floating sword"): return
	for pass_index in range(2):
		Engine.time_scale = 1.0 if pass_index == 0 else 0.35
		game._notice("四向残影疾步 · 正常速度" if pass_index == 0 else "四向残影疾步 · 慢动作检查")
		for code in [KEY_RIGHT,KEY_DOWN,KEY_LEFT,KEY_UP]:
			if not await perform_roll(code,str(code)): return
	Engine.time_scale = 1
	if not await walk_to(game.VILLAGE): return
	tap(KEY_2)
	if not verify(game.weapon == game.Weapon.SPEAR,"equip floating spear"): return
	if not await perform_roll(KEY_RIGHT,"spear right"): return
	if not await perform_roll(KEY_LEFT,"spear left"): return
	tap(KEY_1)
	while game.dodge_cooldown > 0: await frames(1)
	tap(KEY_Q)
	while game.dodge_time > 0: await frames(1)
	tap(KEY_J)
	await frames(1)
	if not verify(game.attack_time > 0 and game.refined_hero.roll.elapsed >= 0.30,"attack interrupts visual recovery"): return
	await frames(50)
	if not await walk_to(Vector2i(2,15)): return
	if not await perform_roll(KEY_LEFT,"wall",true): return
	await frames(60)
	print("PASS four directions, mirrored left, floating sword/spear, cooldown, recovery and wall collision")
	quit()
