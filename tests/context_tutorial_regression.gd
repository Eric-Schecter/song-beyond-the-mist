extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.story.stage=g.story.Stage.CHILD;g.story.pages.clear();g.intro_time=0
	var c=g.controls
	assert(c.lesson_cue(g)=="move")
	c.tick(g,30);assert(c.lesson_cue(g)=="move","no timer dismissal")
	g.moved=true;c.tick(g,.7);g.moved=false
	g.player=g._center(g.story.CLUES["wheel"])
	assert(c.lesson_cue(g)=="E")
	g._interact();assert(c.interacted)
	g.story.pages.clear()
	g.player=g.exploration.enemies[g.story.child_enemy].pos
	assert(c.lesson_cue(g)=="light1")
	c.performed("light1");assert(c.lesson_cue(g)=="light3")
	c.performed("light2");assert(c.lesson_cue(g)=="light3")
	c.performed("light3");assert(c.lesson_cue(g)=="dodge")
	c.performed("dodge");assert(c.lesson_cue(g)=="")
	g.story.stage=g.story.Stage.DEFEND
	for id in ["thrust","spin","heavy","charged","chase"]:
		assert(c.lesson_cue(g)==id);c.performed(id)
	assert(c.lesson_cue(g)=="")
	g.story.complete_card=true;g.story.dialogue_age=1
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=Vector2(160,200)
	g._input(click);assert(not g.story.complete_card,"chapter card click continues")
	c.reset();assert(not c.interacted and c.walked==0 and c.completed[0]<0)
	print("PASS action-driven tutorial ordering, contextual interaction/combat, no timeout and reset")
	g.queue_free();await process_frame;quit()
