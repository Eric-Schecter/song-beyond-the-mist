extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.story.stage=g.story.Stage.CHILD;g.story.pages.clear();g.intro_time=0
	var b=g.growth
	g.player=g._center(g.VILLAGE);b.points=9;b.opened=true
	var base_hp:int=g.max_health
	for i in range(3):b.allocate(g,0)
	assert(g.max_health==base_hp+3 and b.max_armor()==1 and is_equal_approx(b.heavy_bonus(),1.36))
	assert(b.light_speed()==1 and b.max_mana()==100,"fortitude does not grant other paths")
	for i in range(3):b.allocate(g,1)
	assert(is_equal_approx(b.light_speed(),1.15) and b.critical()>.2 and b.evasion()>.1)
	g.move_name="light3";assert(g._weapon_reach()==40)
	for i in range(3):b.allocate(g,2)
	assert(b.max_mana()==130 and b.mana_regen()==16.5 and b.accuracy()>.95)
	assert(is_equal_approx(g.move_cost("thrust"),18.7) and g.move_cost("heavy")==24)
	assert(b.points==0);b.allocate(g,0);assert(b.power==3)
	g.stamina=0;g.stamina_delay=0;g.attack_time=0;g.holding_heavy=false;g.dodge_time=0
	g._recover_stamina(1);assert(g.stamina==16.5)
	g.rest_at_camp();assert(g.stamina==130)
	b.opened=false;g.story_enabled=false
	var durations:Array[int]=[]
	for rank in [0,3]:
		b.vitality=rank;g.cancel_combo();g.hit_stop=0;g.start_move("light1")
		var count:=0
		while g.attack_time>0 and count<60:g._physics_process(1.0/60);count+=1
		durations.append(count)
	assert(durations[1]<durations[0],"swift actually shortens light attack duration")
	b.vitality=3;b.opened=true;g.story_enabled=true
	var damage_values:Array[float]=[]
	for rank in [0,3]:
		b.power=rank;g.move_name="heavy";g.combat_stats.rng.seed=17
		damage_values.append(g.combat_hit(g.slime,0))
	assert(damage_values[1]>damage_values[0],"fortitude changes actual heavy damage")
	b.refund(g);assert(b.points==9 and g.max_health==base_hp and g.stamina==100)
	g.player=g._center(Vector2i(20,10));b.allocate(g,0);assert(b.points==8 and b.allocation_taught,"allocation available away from camp and completes guidance")
	b.refund(g)
	g.player=g._center(g.VILLAGE)
	var click:=InputEventMouseButton.new();click.pressed=true;click.button_index=MOUSE_BUTTON_LEFT;click.position=Vector2(64,147)
	g._input(click);assert(b.power==1 and b.points==8,"new plus hitbox")
	g._reset();assert(b.power==0 and b.vitality==0 and b.agility==0 and b.points==0)
	g.queue_free();await process_frame
	print("PASS mixed builds, distinct benefits, milestones, mana cost/regen/refill, refund, anywhere allocation, guidance, mouse hitbox and reset")
	quit()
