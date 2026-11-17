extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.story.pages.clear();g.intro_time=0;g.combat_stats.evasion=0;g.health=3;g.growth.armor=0
	assert(g._hurt_player(Vector2.RIGHT))
	assert(g.health==2 and g.sounds.hurt.playing)
	assert(g.sounds.hurt.stream.resource_path.begins_with("res://assets/audio/cc0_combat/"))
	var count:int=g.material_counts.hurt
	assert(not g._hurt_player(Vector2.RIGHT) and g.material_counts.hurt==count)
	g.hurt_time=0;g.dodge_time=.2
	assert(not g._hurt_player(Vector2.RIGHT) and g.material_counts.hurt==count)
	g.dodge_time=0;g.growth.armor=1
	assert(not g._hurt_player(Vector2.RIGHT) and g.health==2 and g.sounds.armor.playing and g.material_counts.hurt==count)
	print("PASS recorded player hurt, invulnerability/dash silence, distinct armor sound")
	g.queue_free();await process_frame;quit()
