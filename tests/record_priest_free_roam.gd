extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.intro_time=0;game.story.stage=game.story.Stage.PRIEST
	game.story.beats.island_confronted=true
	if not verify(game.story.quest_marker_position()==game._center(game.story.beats.WATER) and game.story.quest_symbol()=="!","water investigation marker"):return
	game.story.beats.island_seen.water=true
	if not verify(game.story.quest_marker_position()==game._center(game.story.beats.REFUGEES),"refugee marker"):return
	game.story.beats.island_seen.refugees=true
	if not verify(game.story.quest_marker_position()==game._center(game.story.PRIEST),"return to priest marker"):return
	game.player=game._center(game.story.PRIEST)+Vector2(0,26);await frames(100)
	game.slime_health=0;game.boss_death=0;game.story.stage=game.story.Stage.SPRING;game.story.beats.purified=true
	game.story.beats.priest_pos=game._center(game.FOUNTAIN)+Vector2(-22,10)
	game.player=game._center(game.FOUNTAIN)+Vector2(0,43);game.fountain_awake=true
	await frames(300)
	game.message_time=0;await frames(2)
	root.get_texture().get_image().save_png("res://recordings/priest-layer-fixed.png")
	game.story.stage=game.story.Stage.COMPLETE;game.story.pages.clear();game.player=Vector2(280,248)
	game.exploration.enemies.clear();await frames(40)
	for i in range(12):game.exploration.free_spawner.update(game,game.exploration,8)
	if not verify(game.exploration.enemies.size()==8,"free roam population cap"):return
	for e in game.exploration.enemies:
		if not verify(game.exploration.free_spawner.eligible(game,e.pos),"spawn outside view and safe area"):return
	var victim:Dictionary=game.exploration.enemies[0];victim.hp=0;victim.death=0
	game.exploration.free_spawner.update(game,game.exploration,8)
	if not verify(game.exploration.enemies.size()==8 and game.exploration.enemies[0].hp>0,"reuse dead roaming slot"):return
	game.player=game.exploration.enemies[0].pos+Vector2(0,35)
	await frames(120)
	root.get_texture().get_image().save_png("res://recordings/free-roam-enemies.png")
	game.queue_free();await process_frame;quit()
