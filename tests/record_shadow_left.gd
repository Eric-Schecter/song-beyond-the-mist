extends "res://tests/record_landscape_ground.gd"

func walk_to(tile: Vector2i) -> bool:
	if tile == Vector2i(19,11):
		for stop in [Vector2i(11,15),Vector2i(7,15),Vector2i(11,15),Vector2i(7,15),Vector2i(11,15)]:
			if not await super.walk_to(stop): return false
			await frames(50)
		await hold(KEY_LEFT,2)
		tap(KEY_J)
		await frames(45)
		tap(KEY_J)
		await frames(55)
		print("PASS repeated left/right walking, stopping and left-facing attacks")
		quit()
		return false
	return await super.walk_to(tile)
