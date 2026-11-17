extends "res://tests/record_chapter_one.gd"
func setup_case(title:String):
	game.demo_title=title;game.player=Vector2(605,270);game.slime=Vector2(629,270)
	game.facing=Vector2.RIGHT;game.chain=0;game.link_time=0;game.dash_follow=0
	game.slime_health=18;game.stamina=100;game.attack_time=0;game.dodge_cooldown=0
	await frames(65)
func run():
	game=load("res://combo_lab.tscn").instantiate();root.add_child(game)
	game.combat_stats.rng.seed=17
	tap(KEY_P);await frames(150);tap(KEY_P)
	if DisplayServer.get_name()!="headless":DisplayServer.window_move_to_foreground()
	await setup_case("三连斩   J → J → J")
	tap(KEY_J);await frames(9);tap(KEY_J)
	if not await wait_move("light2"):return
	await frames(8);tap(KEY_J);await frames(75)
	await setup_case("突进刺   J → K")
	tap(KEY_J);await frames(10);tap(KEY_K);await frames(75)
	await setup_case("回旋重斩   J → J → K")
	tap(KEY_J);await frames(9);tap(KEY_J)
	if not await wait_move("light2"):return
	await frames(8);tap(KEY_K);await frames(90)
	await setup_case("重劈   K")
	tap(KEY_K);await frames(80)
	await setup_case("蓄力重劈   按住 K → 松开")
	key(KEY_K,true);await frames(48);key(KEY_K,false);await frames(90)
	await setup_case("追身斩   Q → J")
	game.player=Vector2(570,270)
	key(KEY_RIGHT,true);tap(KEY_Q);await frames(10);key(KEY_RIGHT,false);tap(KEY_J);await frames(100)
	for id in game.MOVES.keys():
		if not verify(id in game.executed,"move performed: "+id):return
	var critical_count:=0
	var evasion_count:=0
	for result in game.results:
		if result.type=="critical":critical_count+=1
		if result.type=="evade":evasion_count+=1
	assert(critical_count>0 and evasion_count>0,"recording covers critical and evasion outcomes")
	print("RESULTS ",game.results)
	quit()

func wait_move(id:String)->bool:
	for i in range(90):
		if game.move_name==id:return true
		await frames(1)
	return verify(false,"queued move starts: "+id)
