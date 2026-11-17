extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.story.pages.clear();g.intro_time=0;g.stamina=100;g.dodge_cooldown=0
	g._start_dodge();assert(g.stamina==82 and g.dodge_time>0,"dodge consumes 18")
	g._start_dodge();assert(g.stamina==82,"cooldown does not consume twice")
	g.dodge_time=0;g.dodge_cooldown=0;g.stamina=17;g._start_dodge()
	assert(g.dodge_time==0 and g.stamina==17 and g.stamina_warning>0,"insufficient stamina rejects dodge")
	g.cancel_combo();g.stamina=11;g.start_move("chase");assert(g.attack_time==0,"chase needs 12")
	g.stamina=0;g.start_move("light1");assert(g.attack_time>0 and g.stamina==0,"basic light remains free at zero")
	g.cancel_combo();g.stamina=100
	for id in ["thrust","spin","heavy","charged","chase"]:
		g.stamina=100;g.start_move(id);assert(g.stamina==100-g.MOVES[id][5]);g.cancel_combo()
	g.stamina=0;g.stamina_delay=.8;g._recover_stamina(.5);assert(g.stamina==0,"recovery delay")
	g._recover_stamina(.8);assert(is_equal_approx(g.stamina,6),"12 per second after delay")
	g.stamina=99;g._recover_stamina(1);assert(g.stamina==100,"cap")
	g.stamina=0;g.holding_heavy=true;g._recover_stamina(1);assert(g.stamina==12,"regen continues while charging");g.stamina=0
	g.holding_heavy=false;g.start_move("light1");g._recover_stamina(1);assert(g.stamina==12,"free light attacks allow recovery")
	print("PASS all paid moves, free light chain, dodge cost and cooldown, denial, delay, gradual recovery and cap")
	g.queue_free();await process_frame;quit()
