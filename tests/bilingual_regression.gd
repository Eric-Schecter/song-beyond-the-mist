extends SceneTree
const L=preload("res://scripts/game_locale.gd")
func _initialize():run.call_deferred()
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	L.language="zh"
	assert(L.text("New Journey")=="开始旅程")
	assert(L.text("Lv.3! Attribute point earned. Press P to allocate.")=="等级 3！获得属性点，按 P 分配。")
	assert(L.text("Heavy +12% / HP +10 / Armor 0 > 1")=="重击 +12% · 生命 +10 · 护甲 0→1")
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/localization/en_reference.json"))
	for chinese in catalog:
		var translated:String=L.text(catalog[chinese])
		assert(translated!=catalog[chinese] or chinese==catalog[chinese])
		for line in g.story.wrapped(translated,227):assert(g.font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x<=227.1)
	g.story.speak([["Hero", "Today, the riverbed is dry. A child who left to find water has not come home."]])
	assert(g.story.pages[0][0]=="Hero" and "河床" in g.story.pages[0][1])
	for stage in [g.story.Stage.INTRO,g.story.Stage.KNIGHT,g.story.Stage.PRIEST]:
		g.story.stage=stage;assert(g.story.quest_symbol()=="?")
	g.story.stage=g.story.Stage.KEYS;assert(g.story.quest_symbol()=="!")
	L.language="en";assert(L.text("New Journey")=="New Journey")
	print("PASS bilingual catalog, dynamic values, Chinese wrap, stable speaker IDs and quest symbols")
	g.queue_free();await process_frame;quit()
