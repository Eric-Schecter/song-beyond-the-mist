extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.intro_time=0;game.player=Vector2(280,248)
	game.exploration.enemies.clear();game.story.advance(game.story.Stage.DEFEND)
	var t=game.story.training
	var enemy=game.exploration.enemies[game.story.raid_indices[0]]
	t.hit(game.story,enemy,"heavy")
	if not verify(not t.demonstrated,"wrong move does not clear lesson"):return
	t.hit(game.story,enemy,"light3");enemy.hp=0;enemy.death=.5
	t.update(game.story,1)
	if not verify(t.wave==0,"wait for death animation"):return
	enemy.death=0;t.update(game.story,1)
	if not verify(t.wave==1,"advance after correct hit and death"):return
	for index in game.story.raid_indices:
		game.exploration.enemies[index].hp=0;game.exploration.enemies[index].death=0
	t.update(game.story,1)
	if not verify(t.wave==1 and game.exploration.enemies[game.story.raid_indices[0]].hp>0,"wrong-move clear repeats current wave"):return
	var prior:Array=game.story.raid_indices.duplicate()
	t.retry(game.story)
	if not verify(t.wave==1 and not t.demonstrated and game.exploration.enemies[prior[0]].hp==0,"retry replaces current wave"):return
	var first=game.exploration.enemies[game.story.raid_indices[0]]
	var second=game.exploration.enemies[game.story.raid_indices[1]]
	first.windup=true
	if not verify(not game.exploration._can_begin_attack(second),"teaching enemies attack one at a time"):return
	first.windup=false
	if not verify(game.exploration._can_begin_attack(second),"next enemy can attack after windup"):return
	game.health=game.max_health-1;t.recovery_age=0;t.update(game.story,5)
	if not verify(game.health==game.max_health,"teaching health recovery"):return
	game.queue_free();await process_frame;quit()
