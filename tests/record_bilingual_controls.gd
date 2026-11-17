extends "res://tests/record_full_chapter.gd"
const L=preload("res://scripts/game_locale.gd")
func snap(label:String):
	if DisplayServer.get_name()!="headless":root.get_texture().get_image().save_png("res://recordings/update-"+label+".png")
func run():
	var opening=load("res://start.tscn").instantiate();root.add_child(opening);game=opening.game
	# The title toggle is exercised twice, preserving the saved preference.
	await frames(150);snap("title-a")
	tap(KEY_DOWN);tap(KEY_ENTER);await frames(150);snap("title-b")
	tap(KEY_ENTER);await frames(90)
	L.language="zh"
	tap(KEY_UP);tap(KEY_ENTER)
	for i in range(3):
		await frames(240);snap("prologue-"+str(i));tap(KEY_ENTER)
	await frames(120)
	await read_dialogue()
	# Focused review setup: later chapter state, all actions still use real inputs.
	game.story.stage=game.story.Stage.KNIGHT;game.story.pages.clear();game.player=Vector2(183,256);game.controls.reset()
	await frames(90);snap("quest-accept")
	game.story.beats.child_confided=true
	game.story.stage=game.story.Stage.RETURN
	await frames(90);snap("quest-progress")
	game.story.stage=game.story.Stage.KEYS;game.story.pages.clear()
	game.player=Vector2(202,242)
	for direction in [KEY_RIGHT,KEY_LEFT,KEY_UP,KEY_DOWN]:
		await hold(direction,35);await frames(30)
	game.player=Vector2(202,242);game.facing=Vector2.RIGHT
	await frames(90);snap("light-cue")
	tap(KEY_J);await frames(85)
	if not verify(game.controls.learned.has("light1"),"first attack taught by input"):return
	snap("combo-cue")
	for i in range(3):tap(KEY_J);await frames(16)
	await frames(90)
	if not verify(game.controls.learned.has("light3"),"three-hit chain taught"):return
	tap(KEY_Q);await frames(95)
	for id in ["thrust","spin"]:
		game.cancel_combo();await frames(60)
		var count:=1 if id=="thrust" else 2
		for i in range(count):tap(KEY_J);await frames(16)
		tap(KEY_K);await frames(110)
		if not verify(game.controls.learned.has(id),id+" lesson completed"):return
	tap(KEY_K);await frames(110)
	if not verify(game.controls.learned.has("heavy"),"tap heavy taught"):return
	var mana_before:float=game.stamina
	key(KEY_K,true);await frames(120);snap("charge-regeneration")
	if not verify(game.holding_heavy and game.stamina>mana_before,"mana regenerates during held charge"):return
	key(KEY_K,false);await frames(110)
	if not verify(game.controls.learned.has("charged"),"charged release taught"):return
	tap(KEY_Q);await frames(8);tap(KEY_J);await frames(100)
	if not verify(game.controls.learned.has("chase"),"dash follow-up taught"):return
	key(KEY_TAB,true);await frames(180);snap("moves-zh");key(KEY_TAB,false)
	game.growth.points=1;tap(KEY_P);await frames(120);snap("stats-zh")
	tap(KEY_3);await frames(80);tap(KEY_ESCAPE)
	game.player=game._center(game.VILLAGE);game.health=2;game.stamina=25;await frames(90)
	tap(KEY_E);await frames(130);snap("rest")
	if not verify(game.controls.page.is_empty() and game.health==game.max_health,"one-press camp rest without menu"):return
	L.language="en";key(KEY_TAB,true);await frames(150);snap("moves-en");key(KEY_TAB,false)
	print("PASS bilingual title/prologue, directional walking, every tutorial branch, camp and charge regen")
	opening.queue_free();await process_frame;quit()
