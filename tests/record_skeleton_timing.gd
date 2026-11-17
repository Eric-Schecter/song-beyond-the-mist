extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.KNIGHT;game.intro_time=0
	for tutorial in [false,true]:
		game.exploration.enemies.clear();game.player=Vector2(280,248);game.health=game.max_health;game.hurt_time=0
		game.exploration._add("skeleton",Vector2i(19,15),Rect2(200,180,200,140))
		var e:Dictionary=game.exploration.enemies.back();e.pos=game.player+Vector2(22,0);e.time=.4
		if tutorial:e.windup_duration=.4;e.recovery_duration=2.3
		var windup_frames:=0
		var saw_attack:=false
		for i in range(240):
			await frames(1)
			if e.windup and not saw_attack:windup_frames+=1
			if e.get("attack_fx",0.0)>0:saw_attack=true
		if not verify(saw_attack and windup_frames<=26,"short windup, teaching="+str(tutorial)):return
	game.queue_free();await process_frame;quit()
