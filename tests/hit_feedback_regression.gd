extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://combo_lab.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.combat_stats.accuracy=1;g.combat_stats.critical=0;g.target_evasion=0
	g.player=Vector2(605,270);g.slime=Vector2(625,270);g.facing=Vector2.RIGHT
	g.start_move("light1");g.strike()
	var light:float=g.hit_stop
	assert(light>=.045 and g.shake_time>0)
	var popup_age:float=g.damage_popups[0].age
	var attack:float=g.attack_time;var clock_before:float=g.clock;var link:float=g.link_time
	g._physics_process(.01)
	assert(g.attack_time==attack and g.clock==clock_before and g.link_time==link and g.damage_popups[0].age==popup_age,"hitstop freezes action, combo window and numbers")
	assert(g.hit_stop<light and g._camera_kick().length()<=3.1)
	g.hit_stop=0;g.cancel_combo();g.start_move("charged");g.strike()
	assert(g.hit_stop>light and g.hit_stop<=.13)
	g.hit_stop=0;g.shake_time=0;g.cancel_combo();g.start_move("heavy");g.slime=Vector2(700,270);g.strike()
	assert(g.hit_stop==0 and g.shake_time==0,"whiff has no hit feedback")
	g.slime=Vector2(625,270);g.combat_stats.accuracy=0;g.strike()
	assert(g.hit_stop==0 and g.shake_time==0,"miss has no hit feedback")
	g.combat_stats.accuracy=1;g.combat_stats.critical=1;g.strike()
	assert(g.critical_flash>0 and g.hit_stop>.09 and g.sounds.combo_critical.playing)
	g._reset();assert(g.hit_stop==0 and g.shake_time==0)
	print("PASS landed/whiff/miss/critical feedback, real hitstop, strength limits and reset")
	g.queue_free();await process_frame;quit()
