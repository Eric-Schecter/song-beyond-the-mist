extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	g.set_physics_process(false)
	g.story.pages.clear();g.story.stage=g.story.Stage.COMPLETE
	g.growth.award(g,"test",100)
	assert(g.growth.level==3 and g.growth.points==2)
	g.growth.award(g,"test",100)
	assert(g.growth.level==3 and g.growth.points==2,"no repeated XP for same reward")
	g.growth.opened=true
	g.player=g._center(g.VILLAGE)
	var e:=InputEventKey.new();e.pressed=true;e.physical_keycode=KEY_1
	g.growth.input(g,e)
	assert(g.growth.power==1 and g.growth.heavy_bonus()>1)
	g.player=g._center(Vector2i(20,10))
	e.physical_keycode=KEY_2;g.growth.input(g,e)
	assert(g.growth.points==1,"allocation requires camp")
	g.player=g._center(g.VILLAGE);g.growth.input(g,e)
	assert(g.growth.vitality==1 and g.max_health==5)
	g.growth.power=2;g.growth.armor=1;g.hurt_time=0
	g.combat_stats.evasion=0
	var health=g.health
	g._hurt_player(Vector2.ZERO)
	assert(g.health==health and g.growth.armor==0,"armor absorbs a hit")
	g.growth.agility=2
	assert(g.growth.max_mana()>100)
	g.growth.opened=true;g.growth.points=1
	var click:=InputEventMouseButton.new();click.pressed=true;click.button_index=MOUSE_BUTTON_LEFT;click.position=Vector2(64,147)
	var previous_power:int=g.growth.power
	g._input(click)
	assert(g.growth.power==previous_power+1 and g.growth.points==0,"mouse plus allocates once")
	g._input(click)
	assert(g.growth.power==previous_power+1,"disabled plus does not spend below zero")
	click.position=Vector2(292,28);g._input(click)
	assert(not g.growth.opened,"mouse close returns to game")
	print("PASS mouse allocation, empty points and panel close")
	print("PASS XP deduplication, leveling, camp allocation, damage, vitality, armor and agility")
	quit()
