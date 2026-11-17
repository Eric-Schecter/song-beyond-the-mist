extends "res://tests/record_landscape_ground.gd"

func walk_to(tile: Vector2i) -> bool:
	if tile == Vector2i(19,11):
		for stop in [Vector2i(10,15),Vector2i(10,18),Vector2i(11,18),Vector2i(11,15),Vector2i(10,15)]:
			if not await super.walk_to(stop): return false
			await frames(45)
		for code in [KEY_DOWN,KEY_UP,KEY_LEFT,KEY_RIGHT]:
			await hold(code,2)
			tap(KEY_J)
			await frames(45)
		print("PASS sole-contact shadows: four directions, idle and sword attacks")
		await frames(90)
		quit()
		return false
	return await super.walk_to(tile)
