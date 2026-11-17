extends "res://tests/record_chapter_one.gd"
func setup_case(title:String):
	game.demo_title=title;game.player=Vector2(605,270);game.slime=Vector2(625,270)
	game.facing=Vector2.RIGHT;game.chain=0;game.link_time=0;game.dash_follow=0
	game.slime_health=18;game.stamina=100;game.attack_time=0;game.dodge_cooldown=0
	await frames(65)
	game.facing=Vector2.RIGHT
	print("CASE ",title," ",game.player," target=",game.slime," facing=",game.facing)
func run():
	game=load("res://combo_lab.tscn").instantiate();root.add_child(game)
	game.combat_stats.accuracy=1;game.combat_stats.critical=0;game.target_evasion=0
	if DisplayServer.get_name()!="headless":DisplayServer.window_move_to_foreground()
	await setup_case("三连斩 · 快速贴身")
	tap(KEY_J);await frames(6);tap(KEY_J)
	if not await wait_move("light2"):return
	await frames(6);tap(KEY_J);await frames(75)
	await setup_case("突进刺 · 远距直线")
	game.slime=game.player+Vector2(48,0);await frames(45)
	tap(KEY_J);await frames(10);tap(KEY_K);await frames(75)
	await setup_case("回旋斩 · 四周清场")
	game.slime=game.player+Vector2(-32,0);await frames(45)
	tap(KEY_J);await frames(6);tap(KEY_J)
	if not await wait_move("light2"):return
	await frames(6)
	print("SPIN BUFFER before=",game.move_name," time=",game.attack_time," chain=",game.chain," focus=",DisplayServer.window_is_focused())
	tap(KEY_K)
	print("SPIN BUFFER queued=",game.queued," hold=",game.holding_heavy," stamina=",game.stamina)
	if not await wait_move("spin"):return
	await frames(90)
	await setup_case("重劈 · 近身破甲")
	tap(KEY_K);await frames(80)
	await setup_case("蓄力重劈 · 预判爆发")
	key(KEY_K,true);await frames(48);key(KEY_K,false);await frames(90)
	await setup_case("追身斩 · 快速接近")
	game.player=Vector2(570,270)
	key(KEY_RIGHT,true);tap(KEY_Q);await frames(10);key(KEY_RIGHT,false);tap(KEY_J);await frames(100)
	print("EXECUTED ",game.executed," HITS ",game.hits)
	for id in game.MOVES.keys():
		if not verify(id in game.executed and game.hits.get(id,0)>0,"move performed and hit: "+id):return
	print("HITS ",game.hits)
	quit()

func wait_move(id:String)->bool:
	for i in range(90):
		if game.move_name==id:return true
		await frames(1)
	return verify(false,"queued move starts: "+id)
