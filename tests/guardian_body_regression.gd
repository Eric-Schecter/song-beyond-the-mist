extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.story.beats.memory_done=true;g.story.pages.clear();g.story.stage=g.story.Stage.GUARD;g.intro_time=0
	var center:=Vector2(610,265)
	for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		g.slime=center;g.player=center+direction*35
		g.player=g._move(g.player,-direction*90)
		assert(g.player.distance_to(g.slime)>=14.99 and (g.player-g.slime).dot(direction)>0,"player cannot tunnel through guardian")
		g.player=center;g.slime=center+direction*35
		g.slime=g._move(g.slime,-direction*90,true)
		assert(g.player.distance_to(g.slime)>=14.99 and (g.slime-g.player).dot(direction)>0,"guardian cannot tunnel through player")
	g.slime=center;g.player=center+Vector2(-15.1,0)
	var original:Vector2=g.player
	g.player=g._move(g.player,Vector2(10,-12))
	assert(g.player.y<original.y-5 and g.player.distance_to(g.slime)>=14.99,"tangential movement slides around body")
	g.slime=center;g.player=center+Vector2(-15.01,0);g.swing_direction=Vector2.RIGHT;g.facing=Vector2.RIGHT
	g.move_name="light1";g.combat_stats.rng.seed=17;g.campaign_strike()
	assert(g.slime_health<18,"basic sword reaches guardian from contact distance")
	g.slime=center;g.player=center+Vector2(25,0);g.health=3;g.hurt_time=0;g.dodge_time=0;g.combat_stats.evasion=0
	g.patterns.reset();g.guard_state=g.Guard.CHARGE;g.guard_time=.32;g.charges_left=0;g.charge_hit=false;g.charge_direction=Vector2.RIGHT
	g._move_slime(.15)
	assert(g.charge_hit and g.health==2,"charge deals damage at physical contact")
	assert(g.guard_state==g.Guard.RECOVERY and g.slime.x<g.player.x,"contact ends charge without crossing")
	g.slime=center;g.slime_health=0;g.player=center+Vector2(-30,0)
	g.player=g._move(g.player,Vector2(60,0))
	assert(g.player.x>center.x,"dead guardian no longer blocks exploration")
	g.queue_free();await process_frame
	print("PASS bilateral swept body collision, sliding, sword reach, charge contact damage/recovery and corpse release")
	quit()
