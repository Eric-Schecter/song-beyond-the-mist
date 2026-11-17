extends SceneTree
func _initialize():run.call_deferred()
func reset_targets(g):
	for e in g.exploration.enemies:
		e.hp=10;e.plated=false;e.exposed=0;e.windup=false;e.stun=0;e.push=Vector2.ZERO
	g.combat_stats.rng.seed=17
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.story.pages.clear();g.intro_time=0;g.player=Vector2(605,270);g.swing_direction=Vector2.RIGHT
	g.exploration.enemies.clear()
	for offset in [Vector2(20,0),Vector2(48,0),Vector2(0,32),Vector2(-30,0)]:
		g.exploration._add("skeleton",Vector2i(39,17),Rect2(500,180,180,160))
		g.exploration.enemies.back().pos=g.player+offset
	reset_targets(g);g.move_name="thrust";g.exploration.attack(g._weapon_reach(),12)
	assert(g.exploration.enemies[0].hp<10 and g.exploration.enemies[1].hp<10,"thrust penetrates aligned targets")
	assert(g.exploration.enemies[2].hp==10 and g.exploration.enemies[3].hp==10,"thrust excludes side and rear")
	reset_targets(g);g.move_name="spin";g.exploration.enemies[0].plated=true;g.exploration.attack(g._weapon_reach(),12)
	assert(g.exploration.enemies[0].hp==10 and g.exploration.enemies[0].exposed==0,"spin cannot break armor")
	assert(g.exploration.enemies[2].hp<10 and g.exploration.enemies[3].hp<10,"spin hits sides and rear")
	assert(g.exploration.enemies[3].push.x<0,"spin pushes outward")
	reset_targets(g);g.move_name="heavy";var e:Dictionary=g.exploration.enemies[0];e.plated=true;e.windup=true
	g.exploration.attack(g._weapon_reach(),12)
	assert(e.hp<10 and e.exposed>0 and e.stun>=.45 and not e.windup,"heavy breaks armor and interrupts normal enemy")
	reset_targets(g);g.move_name="light1";g.exploration.enemies[0].windup=true;g.exploration.attack(g._weapon_reach(),12)
	assert(g.exploration.enemies[0].windup and g.exploration.enemies[0].stun==0,"light does not stunlock windups")
	assert(g.exploration.enemies[3].hp==10,"light cannot hit rear")
	assert(not g._in_reach(g.player+Vector2(50,0),g._weapon_reach(),12),"light cannot reach thrust distance")
	print("PASS actual line penetration, side/rear exclusion, area attack, armor roles, radial push and interrupt rules")
	g.queue_free();await process_frame;quit()
