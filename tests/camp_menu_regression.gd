extends SceneTree
func _initialize():run.call_deferred()
func key(g,code:Key):
	var e:=InputEventKey.new();e.physical_keycode=code;e.pressed=true;g._input(e)
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.story.stage=g.story.Stage.GUARD;g.story.pages.clear();g.intro_time=0;g.player=g._center(g.BRIDGE_CAMP)
	g.health=1;g.stamina=2
	assert(preload("res://scripts/world_interaction.gd").target(g).key=="E")
	key(g,KEY_E)
	assert(g.controls.page.is_empty() and g.health==g.max_health and g.stamina==g.mana_max() and g.checkpoint==g.BRIDGE_CAMP)
	g.player=g._center(Vector2i(20,13));g.growth.points=1
	assert(not g._at_camp())
	key(g,KEY_P);assert(g.growth.opened)
	g.growth.allocate(g,0);assert(g.growth.power==1 and g.growth.points==0)
	g.growth.refund(g);assert(g.growth.power==0 and g.growth.points==1)
	print("PASS direct camp rest/checkpoint and allocate/refund outside camp")
	g.queue_free();await process_frame;quit()
