extends "res://tests/record_full_chapter.gd"

func run() -> void:
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	# Dialogue-only preview fixtures; each conversation uses normal E interaction.
	game.story.pages.clear()
	game.story.stage=game.story.Stage.KNIGHT
	game.player=game._center(Vector2i(6,17));game.camera=Vector2(0,150)
	await frames(60);tap(KEY_E);await read_dialogue()
	if not verify(game.story.stage==game.story.Stage.KEYS,"Roland handoff"):return
	game.story.stage=game.story.Stage.PRIEST
	game.gate_open=true
	game.story.beats.island_seen={"water":true,"refugees":true}
	game.player=game._center(Vector2i(32,14));game.camera=Vector2(440,100)
	await frames(50);tap(KEY_E);await read_dialogue()
	if not verify(game.story.stage==game.story.Stage.GUARD,"Erin cautious plan"):return
	game.story.stage=game.story.Stage.SPRING
	game.slime_health=0
	game.story.beats.purified=true
	game.player=game._center(game.FOUNTAIN)+Vector2(0,17)
	await frames(50);tap(KEY_E);await read_dialogue()
	if not verify(game.story.stage==game.story.Stage.HOME,"spring and mine plan"):return
	game.story.beats.bridge_talk=true;game.story.beats.home_seen=true;game.story.beats.home_age=3
	game.water_fill=1
	game.player=game._center(Vector2i(7,16));game.camera=Vector2(0,150)
	game.story.beats.priest_pos=game._center(Vector2i(9,17))
	game.story.beats.priest_trail.clear()
	await frames(50);tap(KEY_E);await read_dialogue()
	if not verify(game.story.complete_card,"uncertain but shared next step and chapter end"):return
	await frames(180)
	game.queue_free();await process_frame;quit()
