extends "res://tests/record_landscape_ground.gd"

func walk_to(tile: Vector2i) -> bool:
	if tile == Vector2i(19,11):
		for stop in [Vector2i(7,15),Vector2i(7,18),Vector2i(10,18),Vector2i(7,18),Vector2i(7,15)]:
			if not await super.walk_to(stop): return false
			await frames(25)
		print("PASS four-direction walk and idle shadow tour")
	if tile == Vector2i(19,19):
		for stop in [Vector2i(25,4),Vector2i(25,7),Vector2i(23,7)]:
			if not await super.walk_to(stop): return false
	if tile == Vector2i(24,27):
		for stop in [Vector2i(25,28),Vector2i(25,29),Vector2i(22,29),Vector2i(22,27)]:
			if not await super.walk_to(stop): return false
		print("PASS north riverbank and quarry south perimeter")
	return await super.walk_to(tile)
