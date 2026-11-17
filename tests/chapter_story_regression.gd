extends "res://tests/chapter_one_regression.gd"
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	var s=g.story
	s.stage=s.Stage.CHILD;s.pages.clear()
	assert(not s.clue_available("marks"))
	for id in s.CLUES:
		s.stage=s.Stage.KEYS
		assert(g._walkable(g._center(s.CLUES[id])),"clue reachable: "+id)
		var count=s.logbook.size()
		interact_at(g,s.CLUES[id])
		assert(s.discoveries.has(id) and not s.pages.is_empty())
		for page in s.pages:assert(s.wrapped(page[1],227).size()<=3)
		dismiss(g)
		interact_at(g,s.CLUES[id]);dismiss(g)
		assert(s.logbook.size()==count+1,"unique investigation journal")
	var long_line="河水恢复以后，我们还要沿着莉娅留下的足迹，继续寻找穿过黑雾的道路。".repeat(8)
	s.speak([["Hero",long_line]],s.Stage.PRIEST)
	var joined=""
	assert(s.pages.size()>1)
	for page in s.pages:
		joined+=page[1]
		assert(s.wrapped(page[1],227).size()<=3)
	assert(joined==long_line)
	dismiss(g);assert(s.stage==s.Stage.PRIEST)
	s.reset();assert(s.discoveries.is_empty())
	g.queue_free();await process_frame
	print("PASS reachable optional clues, unique journal, lossless dialogue pagination and transition/reset")
	quit()
