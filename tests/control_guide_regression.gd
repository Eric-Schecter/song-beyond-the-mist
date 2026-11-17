extends SceneTree
func _initialize():run.call_deferred()
func key(g,code:Key,pressed:bool=true):
	var e:=InputEventKey.new();e.physical_keycode=code;e.pressed=pressed;g._input(e)
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.story.stage=g.story.Stage.CHILD;g.story.pages.clear();g.intro_time=0
	g.holding_heavy=true;g.queued="light";g.stamina=20
	key(g,KEY_TAB);assert(g.controls.page=="peek" and not g.holding_heavy and g.queued.is_empty())
	var before:float=g.clock;g._physics_process(.5)
	assert(g.clock==before and g.stamina==20,"peek freezes combat and resource recovery")
	key(g,KEY_TAB,false);assert(not g.controls.blocked(),"release closes peek")
	key(g,KEY_ESCAPE);assert(g.controls.page=="pause")
	key(g,KEY_DOWN);key(g,KEY_ENTER);assert(g.controls.page=="guide")
	key(g,KEY_ESCAPE);assert(g.controls.page=="pause");key(g,KEY_ESCAPE);assert(not g.controls.blocked())
	key(g,KEY_M);assert(g.map_open);key(g,KEY_RIGHT);assert(g.controls.map_journal and not g.story.journal_open)
	key(g,KEY_TAB);key(g,KEY_TAB,false);assert(g.map_open and not g.controls.blocked(),"map tab does not open overlapping guide")
	key(g,KEY_ESCAPE);assert(not g.map_open)
	g.growth.opened=true;key(g,KEY_TAB);assert(not g.controls.blocked());g.growth.opened=false
	g.controls.tick(g,1);key(g,KEY_J);g.cancel_combo();g.stamina=100
	key(g,KEY_K);key(g,KEY_K,false);g.cancel_combo();g.dodge_cooldown=0;g.dodge_time=0;key(g,KEY_Q)
	assert(g.controls.completed[0]>=0 and g.controls.completed[1]>=0 and g.controls.completed[2]>=0,"tutorial tracks performed actions")
	key(g,KEY_TAB);g._notification(g.NOTIFICATION_APPLICATION_FOCUS_OUT);assert(g.controls.page!="peek","focus loss clears held peek")
	print("PASS hold/release guide, combat pause, cleared input buffer, pause menu, map journal, modal exclusion and tutorial progress")
	g.queue_free();await process_frame;quit()
