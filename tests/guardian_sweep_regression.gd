extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://main.tscn").instantiate()
	root.add_child(g);g.set_physics_process(false)
	g.story.stage=g.story.Stage.GUARD;g.story.pages.clear()
	for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		for sample in [Vector2(30,0),Vector2.from_angle(1.1)*30,Vector2(-20,0),Vector2(36,0)]:
			g.slime_health=18;g.health=3;g.hurt_time=0;g.dodge_time=0;g.growth.armor=0
			g.patterns.reset();g.patterns.skill_cooldown=10;g.patterns.select(g)
			g.charge_direction=direction;g.player=g.slime+sample.rotated(direction.angle())
			g.guard_state=g.Guard.WINDUP;g.guard_time=0;g.patterns.update(g,0)
			for tick in range(13):
				g.guard_time=.24-tick*.02;g.hurt_time=0
				g.patterns.update(g,.02)
			var expected:int=2 if sample.x>0 and sample.length()<=34 else 3
			assert(g.health==expected,"directional sweep, rear safety, reach and single hit")
	g.patterns.reset();g.patterns.skill_cooldown=10;g.patterns.select(g)
	g.guard_state=g.Guard.WINDUP;g.guard_time=.4;g.player=g.slime+Vector2.UP*30;g.charge_direction=Vector2.RIGHT
	g.patterns.update(g,0)
	assert(g.charge_direction.is_equal_approx(Vector2.UP),"early windup aims vertically")
	g.guard_time=.2;g.player=g.slime+Vector2.DOWN*30;g.patterns.update(g,0)
	assert(g.charge_direction.is_equal_approx(Vector2.UP),"final windup locks direction and permits dodging")
	print("PASS four directions, wide flanks, rear/range safety, single hit, early aim and final lock")
	quit()
