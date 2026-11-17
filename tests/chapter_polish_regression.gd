extends "res://tests/chapter_one_regression.gd"
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	var s=g.story
	s.beats.memory_done=true;s.pages.clear();g.intro_time=0
	s.update(.1)
	assert(s.pages[0][0]=="Narrator" and not s.chapter_card_active(),"opening uses narration, no empty chapter page")
	dismiss(g)
	assert(g.exploration.enemies[s.child_enemy].hp==2)
	assert(g.exploration.enemies[2].hp==4 and g.exploration.enemies[3].hp==3)
	s.advance(s.Stage.DEFEND)
	for index in s.raid_indices:
		g.exploration.enemies[index].hp=0;g.exploration.enemies[index].death=.65
	s.update(.2);assert(s.pages.is_empty(),"village aftermath waits for death animation")
	g.exploration._update_enemies(.66);s.update(.1)
	assert(not s.pages.is_empty());dismiss(g)
	s.stage=s.Stage.GUARD;g.slime_health=0;g.boss_death=.8
	s.update(.1);assert(s.pages.is_empty(),"boss echo cannot freeze death animation")
	g.score._process(.5);assert(g.score.boss_active)
	g.boss_death=0;s.update(.1);assert(not s.pages.is_empty());dismiss(g)
	g.score._process(2.1);assert(not g.score.boss_active and g.score.battle_mix==0)
	g.fountain_awake=true;g.water_fill=0
	s.speak([["Erin","开闸了。"]])
	g._physics_process(.75)
	assert(g.water_fill>0 and g.water_fill<1 and s.modal(),"water advances during dialogue")
	assert(g.water_at(g._center(g.FOUNTAIN))>g.water_at(g._center(s.MOTHER)),"water reaches source before village")
	g._physics_process(4.5);assert(is_equal_approx(g.water_fill,1.0))
	g._reset();assert(g.water_fill==0 and g.village_art.motion.tracks.is_empty())
	g.queue_free();await process_frame
	print("PASS narration, stronger enemies, death gates, boss music lifecycle, downstream water transition during dialogue and reset")
	quit()
