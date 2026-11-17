extends "res://tests/record_full_chapter.gd"

func run() -> void:
	game=load("res://main.tscn").instantiate();root.add_child(game)
	await frames(3)
	game.story.pages.clear();game.story.stage=game.story.Stage.CHILD
	game.player=game._center(game.VILLAGE)
	tap(KEY_F);await frames(2)
	assert(game.controls.page.is_empty())
	tap(KEY_E);await frames(2)
	assert(game.controls.page.is_empty())
	tap(KEY_P);await frames(2)
	assert(game.growth.opened)
	tap(KEY_ESCAPE);await frames(2)
	assert(game.controls.page.is_empty())
	await frames(2)
	assert(game.controls.page.is_empty())
	assert(not game.floor_tiles.has(Vector2i(12,27)))
	assert(not game.floor_tiles.has(Vector2i(12,37)))
	assert(game.exploration.enemies.size()==5)
	game.story.stage=game.story.Stage.COMPLETE
	game.player=game._center(game.CRACK);tap(KEY_E);await frames(2)
	assert(not game.cave_open and not game.relic_found)
	game.slime_health=0;game.growth.update(game)
	assert(game.growth.rewards.has("warden"))
	assert(not game.rockbreak)
	print("PASS direct camp rest, retired F key, no mine, boss XP without rockbreak")
	game.queue_free();await process_frame;quit()
