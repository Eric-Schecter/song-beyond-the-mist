extends "res://tests/record_chapter_one.gd"
var heading:=""
var detail:=""
var banner:Node2D
var totals:Array=[]
var video_frame:=0
func paint():
	var skin=preload("res://scripts/ui_skin.gd")
	skin.panel(banner,Rect2(78,180,235,38))
	banner.draw_string(game.font,Vector2(87,195),heading,HORIZONTAL_ALIGNMENT_LEFT,-1,10,skin.TEXT)
	banner.draw_string(game.font,Vector2(87,209),detail,HORIZONTAL_ALIGNMENT_LEFT,-1,8,skin.PAPER)
func wait_done():
	for i in range(180):
		if game.attack_time<=0 and game.queued.is_empty():return
		await frames(1)
func chain():
	tap(KEY_J);await frames(5);tap(KEY_J)
	for i in range(60):
		if game.move_name=="light2":break
		await frames(1)
	await frames(4);tap(KEY_J)
	await wait_done()
func case(path:int,rank:int):
	print("CASE_START ",path," ",rank," FRAME ",video_frame)
	game._reset();game.story.stage=game.story.Stage.COMPLETE;game.story.pages.clear();game.story.complete_card=false
	game.intro_time=0;game.gate_open=true;game.slime_health=0;game.rockbreak=false
	game.controls.walked=100;game.controls.interacted=true;game.controls.completed.assign([1.0,1.0,1.0])
	game.player=game._center(game.VILLAGE);game.growth.points=rank
	for i in range(rank):game.growth.allocate(game,path)
	game.player=Vector2(560,280);game.camera=Vector2(400,170);game.facing=Vector2.RIGHT
	game.stamina=game.mana_max();game.combat_stats.rng.seed=1
	game.exploration.enemies.clear();game.exploration.shots.clear()
	var offsets:Array=[Vector2(22,0),Vector2(44,0),Vector2(58,0)]
	if path==1:offsets=[Vector2(20,0),Vector2(30,22),Vector2(40,-24)]
	if path==2:offsets=[Vector2(60,0),Vector2(80,0),Vector2(103,0)]
	for off in offsets:
		game.exploration._add("skeleton",Vector2i.ZERO,Rect2(512,224,192,112))
		var e:Dictionary=game.exploration.enemies.back();e.pos=game.player+off;e.home=e.pos;e.hp=12;e.time=3.5
		if path==0:e["plated"]=true
	heading=["刚毅 · 地裂重劈","疾锋 · 三连宽弧","灵巧 · 贯穿剑气"][path]+"  /  %d点"%rank
	detail="对照训练 · 每组相同阵型 / 120HP / 正常AI"
	banner.queue_redraw();await frames(55)
	var mana_before:float=game.stamina
	if path==0:key(KEY_K,true);await frames(48);key(KEY_K,false);await wait_done()
	elif path==1:await chain()
	else:
		tap(KEY_J);await frames(5);tap(KEY_K);await wait_done()
	var targets:=0
	var damage:=0.0
	for e in game.exploration.enemies:
		if e.hp<12:targets+=1
		damage+=12-e.hp
	totals.append([path,rank,targets,snappedf(damage*10,.1)])
	detail="命中目标 %d / 3 · 本轮伤害 %.0f · MP %.0f / %.0f"%[targets,damage*10,game.stamina,game.mana_max()]
	banner.queue_redraw();await frames(50)
	# Keep the enemies' normal AI active for the follow-up exchange.
	if path==0:tap(KEY_K);await wait_done()
	elif path==1:await chain()
	else:
		tap(KEY_J);await frames(5);tap(KEY_K);await wait_done()
	await frames(65)
func run():
	physics_frame.connect(func():video_frame+=1)
	game=load("res://main.tscn").instantiate();root.add_child(game)
	var layer:=CanvasLayer.new();root.add_child(layer);banner=Node2D.new();layer.add_child(banner);banner.draw.connect(paint)
	for path in range(3):
		for rank in [0,3,6]:await case(path,rank)
	print("BUILD COMBAT RESULTS ",totals)
	for path in range(3):
		assert(totals[path*3+2][2]>totals[path*3][2],"high-rank opening reaches additional real enemies")
	quit()
