extends SceneTree
func _initialize(): run.call_deferred()
func dismiss(g):
	var e := InputEventKey.new()
	e.physical_keycode = KEY_E
	e.pressed = true
	while not g.story.pages.is_empty():
		g.story.dialogue_age = 1
		g._input(e)
func interact_at(g,tile):
	g.player = g._center(tile)
	g._interact()
func run():
	var g = load("res://main.tscn").instantiate()
	root.add_child(g)
	g.set_physics_process(false)
	var s = g.story
	g.intro_time = 0
	s.update(0.1)
	assert(s.modal())
	var saved = g.player
	var attack = g.attack_time
	g._physics_process(0.1)
	assert(g.player == saved and g.attack_time == attack)
	dismiss(g)
	assert(not s.beats.memory_active(),"new hero has no princess flashback")
	assert(s.stage == s.Stage.CHILD and g.weapon == g.Weapon.SWORD)
	interact_at(g,g.SEALS[0])
	assert(g.seals.is_empty())
	interact_at(g,s.CHILD)
	assert(s.pages.is_empty())
	g.exploration.enemies[s.child_enemy].hp = 0
	interact_at(g,s.CHILD)
	dismiss(g)
	assert(s.stage == s.Stage.RETURN)
	interact_at(g,s.MOTHER)
	assert(s.pages.is_empty(),"must escort child, not only return alone")
	s.child_position = g._center(s.MOTHER)
	interact_at(g,s.MOTHER)
	dismiss(g)
	assert(s.stage == s.Stage.DEFEND and s.raid_indices.size() == 2)
	for index in s.raid_indices: g.exploration.enemies[index].hp = 0
	s.update(0.1)
	dismiss(g)
	interact_at(g,s.KNIGHT)
	dismiss(g)
	assert(s.stage == s.Stage.KEYS)
	interact_at(g,g.SEALS[0])
	assert(g.seals.is_empty(),"keys require clearing guards")
	for i in range(4): g.exploration.enemies[i].hp = 0
	for tile in g.journey.SWITCHES:
		interact_at(g,tile)
	assert(g.journey.restored.size()==2)
	for tile in g.SEALS:
		interact_at(g,tile)
		dismiss(g)
	assert(g.gate_open and s.stage == s.Stage.PRIEST)
	interact_at(g,s.PRIEST);dismiss(g)
	assert(s.stage==s.Stage.PRIEST)
	for tile in [s.beats.WATER,s.beats.REFUGEES]:
		interact_at(g,tile);dismiss(g)
	interact_at(g,s.PRIEST)
	dismiss(g)
	assert(s.stage == s.Stage.GUARD)
	g.slime_health = 0
	g.rockbreak = true
	s.update(0.1)
	dismiss(g)
	assert(s.stage == s.Stage.SPRING)
	interact_at(g,g.CRACK)
	assert(not g.cave_open,"chapter one closure precedes mine entry")
	interact_at(g,g.FOUNTAIN);dismiss(g)
	assert(s.beats.purifying and not g.fountain_awake)
	s.update(4.0)
	assert(not s.beats.purified,"living threats prevent purification")
	for index in s.beats.threats:g.exploration.enemies[index].hp=0
	s.update(2.1);dismiss(g)
	interact_at(g,g.FOUNTAIN)
	dismiss(g)
	assert(g.fountain_awake and not g.cleared and s.stage == s.Stage.HOME)
	g.player=g._center(Vector2i(24,17));s.update(.1);dismiss(g)
	assert(s.beats.bridge_talk and s.beats.following)
	g.player=g._center(Vector2i(12,17));s.update(.1)
	assert(s.beats.home_seen and s.modal())
	s.update(3.0);dismiss(g)
	assert(not s.beats.revealing())
	g.health = 1
	g.hurt_time = 0
	g._hurt_player(Vector2.RIGHT)
	assert(s.stage == s.Stage.HOME and g.fountain_awake,"death preserves story progress")
	interact_at(g,s.MOTHER)
	dismiss(g)
	assert(s.stage == s.Stage.COMPLETE and s.complete_card)
	s.complete_card = false
	interact_at(g,g.CRACK)
	assert(not g.cave_open,"chapter one has no playable mine")
	g._reset()
	assert(s.stage == s.Stage.INTRO and not g.fountain_awake and not g.cave_open and g.exploration.enemies.size() == 5)
	assert(s.beats.memory_done and s.beats.island_seen.is_empty() and not s.beats.following)
	print("PASS dialogue pause, escort, defense, keys, priest, spring, death persistence, chapter closure, chapter-only boundary and reset")
	quit()
