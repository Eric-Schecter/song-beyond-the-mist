extends "res://tests/record_full_chapter.gd"
func run() -> void:
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.beats.memory_done=true;game.story.pages.clear();game.story.stage=game.story.Stage.GUARD
	game.intro_time=0;game.gate_open=true;game.player=Vector2(567,257);game.slime=Vector2(606,267)
	game.growth.power=3;game.growth.level=4;game.max_health=8;game.health=8;game.growth.armor=1
	game.combat_stats.rng.seed=17;use_combo_branches=true
	if not await fight_warden():return
	await frames(65)
	assert(not game.story.pages.is_empty(),"victory still reaches story after death animation")
	print("PASS complete guardian battle and story handoff with solid bodies")
	game.queue_free();await process_frame;quit()
