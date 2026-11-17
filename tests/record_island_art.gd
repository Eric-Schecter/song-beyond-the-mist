extends "res://tests/record_chapter_one.gd"
var recorded_ticks := 0

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		recorded_ticks += 1

func read_dialogue() -> void:
	await frames(2)
	while not game.story.pages.is_empty():
		var line: String = str(game.story.pages[game.story.page][1])
		await frames(18 if game.story.stage < game.story.Stage.PRIEST else maxi(125,int(line.length()*4.8)))
		tap(KEY_E)
		await frames(2)

func walk_to(tile: Vector2i) -> bool:
	if tile == game.BRIDGE_CAMP:
		print("ISLAND_SHOWCASE_START frame=",recorded_ticks)
	if tile == game.story.CHILD: return await super.walk_to(Vector2i(14,14))
	if tile == game.story.KNIGHT: return await super.walk_to(Vector2i(6,17))
	if tile == game.story.PRIEST: return await super.walk_to(Vector2i(32,14))
	if tile == game.FOUNTAIN: return await super.walk_to(game.FOUNTAIN+Vector2i.DOWN)
	if tile == game.story.MOTHER:
		if game.story.stage < game.story.Stage.HOME: return await super.walk_to(Vector2i(7,16))
		for stop in [Vector2i(42,10),Vector2i(43,14),Vector2i(43,21),Vector2i(38,22),Vector2i(34,18)]:
			if not await super.walk_to(stop): return false
			await frames(35)
		print("PASS restored spring, east/south shoreline and bridge landing")
		await frames(120)
		quit()
		return false
	return await super.walk_to(tile)
