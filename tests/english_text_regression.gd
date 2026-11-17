extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g)
	g.set_physics_process(false)
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/localization/en_reference.json"))
	for value in catalog.values():
		var wrapped:Array[String]=g.story.wrapped(value,227)
		assert("".join(wrapped)==value.strip_edges(),"Word wrapping preserves words and spaces")
		for line in wrapped:
			assert(g.font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x<=227.1)
	g.story.speak([["Hero","I will find the northern road. Together, we can search for a way to rescue the princess without rushing into the castle alone."]])
	for page in g.story.pages:assert(g.story.wrapped(page[1],227).size()<=3)
	assert(preload("res://scripts/story_space.gd").actors(g.story)[0].name=="Noah's Mother")
	print("PASS English catalog wrap widths, word preservation, dialogue pagination and actor names")
	g.queue_free();await process_frame;quit()
