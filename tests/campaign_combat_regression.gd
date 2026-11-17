extends SceneTree
func _initialize():run.call_deferred()
func key(g,code:Key,pressed:bool=true):
	var e:=InputEventKey.new();e.physical_keycode=code;e.pressed=pressed;g._input(e)
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.story.stage=g.story.Stage.GUARD;g.story.pages.clear();g.intro_time=0
	assert(g.campaign_mode and g.weapon==g.Weapon.SWORD)
	g.player=g._center(g.VILLAGE);key(g,KEY_2)
	assert(g.weapon==g.Weapon.SWORD,"weapon swapping removed")
	key(g,KEY_J);assert(g.move_name=="light1")
	key(g,KEY_K);assert(g.queued=="heavy")
	g.attack_time=0;g._physics_process(.01);assert(g.move_name=="thrust","J K branch")
	g.cancel_combo();g.chain=2;g.link_time=.4;key(g,KEY_K);key(g,KEY_K,false)
	assert(g.move_name=="spin","J J K branch")
	g.cancel_combo();key(g,KEY_K);g.charge_age=.7;key(g,KEY_K,false)
	assert(g.move_name=="charged","K charge release")
	g.cancel_combo();key(g,KEY_K);key(g,KEY_P)
	assert(g.growth.opened and not g.holding_heavy and g.queued.is_empty(),"modal clears buffered charge")
	key(g,KEY_K,false);key(g,KEY_P);assert(g.attack_time==0)
	g.cancel_combo();g.stamina=0;key(g,KEY_K);key(g,KEY_K,false);assert(g.attack_time==0,"heavy needs stamina")
	g.stamina=100
	g.growth.agility=4;g.growth.vitality=4;g.sync_stats();assert(g.combat_stats.accuracy>.95 and g.combat_stats.evasion>.1 and g.combat_stats.critical>.2)
	g.combat_stats.rng.seed=17;g.move_name="heavy"
	var damage:float=g.combat_hit(g.slime,0)
	assert(damage>0 and not g.damage_popups.is_empty(),"campaign damage and floating number")
	g.move_name="light3";g.growth.vitality=3
	assert(g._weapon_reach()==40,"attribute path changes combo reach")
	assert(g.charge_limit()==.65,"single charge threshold")
	g.cancel_combo();g._reset();assert(g.chain==0 and g.queued.is_empty() and g.stamina==100 and g.weapon==g.Weapon.SWORD)
	print("PASS campaign controls, branches, modal safety, stamina, growth stats, damage, attribute combo path and reset")
	g.queue_free();await process_frame;quit()
