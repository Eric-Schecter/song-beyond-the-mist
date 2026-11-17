extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.KEYS;game.intro_time=0
	game.player=Vector2(312,264);game.checkpoint=game.VILLAGE
	game.exploration.enemies.clear();game.growth.armor=0;game.combat_stats.evasion=0
	await frames(90)
	game.health=1;game.hurt_time=0;game.combat_stats.evasion=0
	game._hurt_player()
	var fallen:Vector2=game.player
	if not verify(game.defeat_age>=0 and game.health==0,"lethal damage starts defeat transition"):return
	await hold(KEY_RIGHT,90)
	if not verify(game.player==fallen and not game.defeat_relocated,"input locked before fade reaches black"):return
	await frames(55)
	if not verify(game.defeat_relocated and game.player==game._center(game.checkpoint),"relocation under full black"):return
	await frames(95)
	if not verify(game.defeat_age<0 and game.health==game.max_health,"fade in completes with restored health"):return
	var camp:Vector2=game.player
	await hold(KEY_RIGHT,25)
	if not verify(game.player!=camp,"controls restored"):return
	await frames(75);game.queue_free();await process_frame;quit()
