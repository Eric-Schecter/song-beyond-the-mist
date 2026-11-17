extends "res://tests/chapter_one_regression.gd"
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	var s=g.story
	s.speak([["Narrator","水车停转了。村民们等着河水回家。"],["Noah's Mother","小诺去了村东，拜托你找找他。"]],s.Stage.CHILD)
	assert(s.visible_characters()==0)
	s.dialogue_age=.2;assert(s.visible_characters()>0 and s.visible_characters()<18)
	var e:=InputEventKey.new();e.pressed=true;e.physical_keycode=KEY_E
	s.input(e);assert(s.page==0 and s.reveal_all)
	s.input(e);assert(s.page==0,"same frame cannot skip")
	s.dialogue_age=.2;s.input(e);assert(s.page==1 and not s.reveal_all and s.visible_characters()==0)
	s.dialogue_age=.5;e.echo=true;s.input(e);assert(not s.reveal_all);e.echo=false
	s.dialogue_age=10;assert(s.visible_characters()==str(s.pages[1][1]).length())
	s.input(e);assert(s.pages.is_empty() and s.stage==s.Stage.CHILD)
	print("PASS progressive reveal, reveal-first/advance-second, debounce, held-key suppression, reset and completion")
	g.queue_free();await process_frame;quit()
