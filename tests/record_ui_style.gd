extends "res://tests/record_landscape_ground.gd"
var opening_shown := false

func read_dialogue() -> void:
	if not opening_shown:
		opening_shown = true
		await frames(180)
	await super.read_dialogue()

func walk_to(tile: Vector2i) -> bool:
	if tile == Vector2i(19,11):
		print("UI_SHOWCASE_START frame=",recorded_ticks)
		tap(KEY_M);tap(KEY_RIGHT)
		await frames(2)
		if not verify(game.map_open and game.controls.map_journal,"journal opened"): return false
		await frames(150)
		tap(KEY_M)
		tap(KEY_M)
		await frames(2)
		if not verify(game.map_open,"map opened"): return false
		await frames(150)
		tap(KEY_M)
		if not await super.walk_to(game.VILLAGE): return false
		tap(KEY_E)
		await frames(2)
		if not verify(game.controls.page.is_empty() and game.health==game.max_health,"direct camp rest"): return false
		await frames(120)
		tap(KEY_P)
		await frames(100)
		tap(KEY_ESCAPE)
	if tile == Vector2i(19,19):
		print("PASS styled dialogue, journal, map, direct camp rest, combat HUD and reward dialogue")
		await frames(90)
		quit()
		return false
	return await super.walk_to(tile)
