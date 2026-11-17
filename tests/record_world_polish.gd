extends "res://tests/record_chapter_one.gd"
func snap(id:String):
	root.get_texture().get_image().save_png("res://recordings/polish-"+id+".png")
func run():
	preload("res://scripts/game_locale.gd").language="zh"
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.KEYS;game.intro_time=0
	game.exploration.enemies.clear();game.player=Vector2(312,264)
	game.growth.award(game,"test_first_level",35)
	await frames(150);snap("point-prompt")
	if not verify(game.growth.points==1 and not game.growth.allocation_taught,"first level has persistent allocation guidance"):return
	tap(KEY_P);await frames(100);snap("fortitude")
	tap(KEY_RIGHT);await frames(100);snap("swiftblade")
	tap(KEY_RIGHT);await frames(100);snap("finesse")
	tap(KEY_ENTER);await frames(90)
	if not verify(game.growth.allocation_taught and game.growth.agility==1 and game.growth.points==0,"allocation input completes guide"):return
	tap(KEY_ESCAPE)
	for kind in ["skeleton","bat","plant"]:
		game.exploration.enemies.clear();game.exploration.shots.clear()
		game.player=Vector2(312,264);game.health=game.max_health
		game.exploration._add(kind,Vector2i(20,16),Rect2(220,200,200,120))
		var e:Dictionary=game.exploration.enemies.back()
		e.pos=game.player+Vector2(21 if kind=="skeleton" else 40,0);e.home=e.pos;e.time=.5
		await frames(42);snap(kind+"-charge")
		await frames(220)
		if not verify(game.defeat_age<0,kind+" attack demonstration remains alive"):return
	game.exploration.enemies.clear();game.exploration.shots.clear()
	for point in [Vector2(104,248),Vector2(270,60),Vector2(304,440)]:
		game.player=point;await frames(130);snap("edge-"+str(int(point.y)))
	if not verify(game.landscape_ground.distant_props.size()>0,"cached outside scenery populated"):return
	game.queue_free();await process_frame;quit()
