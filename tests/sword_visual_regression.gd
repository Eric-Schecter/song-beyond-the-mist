extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var g = load("res://scenes/art_sample.tscn").instantiate()
	root.add_child(g)
	g.set_physics_process(false)
	g.player = g.exploration.enemies[0].pos-Vector2(19,0)
	g.facing = Vector2.RIGHT
	g._attack()
	g._physics_process(0.1)
	assert(g.exploration.enemies[0].hp == 999,"anticipation must not hit")
	g._physics_process(0.045)
	assert(g.exploration.enemies[0].hp == 998,"contact frame must hit once")
	assert(not g.sword_presentation.trail.is_empty())
	assert(not g.sword_presentation.impacts.is_empty())
	var held: float = g.attack_time
	g._physics_process(0.02)
	assert(g.attack_time == held,"hit stop must hold the attack pose")
	g._physics_process(0.1)
	g._physics_process(0.4)
	g._physics_process(0.4)
	assert(g.sword_presentation.trail.is_empty(),"trail must disappear after recovery")
	g.sword_presentation.reset()
	g.player = Vector2(130,145)
	g._attack()
	g._physics_process(0.15)
	assert(g.sword_presentation.impacts.is_empty(),"whiffs must not generate contact bursts")
	var clips = g.refined_hero.action_clips
	assert(clips.regions.size() == 18)
	for region in clips.regions:
		assert(region.size.x > 80 and region.size.y > 180 and region.size.y < 260)
	g._reset()
	assert(g.sword_presentation.trail.is_empty() and g.sword_presentation.impacts.is_empty())
	print("PASS 18 aligned frames, contact timing, hit stop, trail lifetime, whiff and reset")
	quit()
