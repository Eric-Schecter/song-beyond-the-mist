extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://combo_lab.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.player=Vector2(605,270);g.slime=Vector2(629,270);g.swing_direction=Vector2.RIGHT
	g.move_name="heavy";g.combat_stats.accuracy=1;g.combat_stats.critical=1;g.target_evasion=0
	g.strike()
	assert(is_equal_approx(g.slime_health,14.5) and g.results.back().damage==35)
	assert(g.damage_popups.back().critical and g.critical_flash>0)
	g.combat_stats.accuracy=0;g.strike()
	assert(is_equal_approx(g.slime_health,14.5) and g.results.back().type=="miss")
	g.combat_stats.accuracy=1;g.target_evasion=1;g.strike()
	assert(is_equal_approx(g.slime_health,14.5) and g.results.back().type=="evade")
	g.combat_stats.evasion=1;g.hurt_time=0;g.health=3;g.dodge_time=0
	assert(not g._hurt_player(Vector2.RIGHT) and g.health==3)
	g.combat_stats.evasion=0;g.hurt_time=0
	assert(g._hurt_player(Vector2.RIGHT) and g.health==2)
	print("PASS damage applied, critical feedback, zero damage on miss/evasion and player passive evasion")
	g.queue_free();await process_frame;quit()
