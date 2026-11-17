extends "res://scripts/enemy_field.gd"

const VALLEY_BLOCKS := [
	Vector2i(3, 12), Vector2i(4, 12), Vector2i(5, 12),
	Vector2i(3, 13), Vector2i(4, 13), Vector2i(5, 13),
	Vector2i(8, 12), Vector2i(9, 12), Vector2i(10, 12),
	Vector2i(8, 13), Vector2i(9, 13), Vector2i(10, 13),
	Vector2i(16, 3), Vector2i(18, 3), Vector2i(21, 6), Vector2i(25, 3),
	Vector2i(16, 24), Vector2i(17, 24), Vector2i(21, 28),
	Vector2i(35, 9), Vector2i(42, 19),
]
const HEALING_CHEST := Vector2i(16, 28)
var free_spawner=preload("res://scripts/free_roam_spawner.gd").new()
var greeted := false
var healing_taken := false


func reset() -> void:
	free_spawner.age=0
	enemies.clear()
	shots.clear()
	greeted = false
	healing_taken = false
	_add("bat", Vector2i(20, -5), Rect2(240, -128, 176, 128))
	_add("plant", Vector2i(24, -6), Rect2(240, -128, 176, 128))
	_add("skeleton", Vector2i(20, 25), Rect2(240, 352, 192, 128))
	_add("plant", Vector2i(25, 24), Rect2(240, 352, 192, 128))

	if game.story_enabled:return
	_add("skeleton", Vector2i(12, 27), Rect2(144, 368, 80, 112))
	_add("plant", Vector2i(10, 24), Rect2(144, 368, 80, 112))

	_add("skeleton", Vector2i(12, 37), Rect2(112,528,128,112))
	enemies.back()["plated"] = true
	_add("skeleton", Vector2i(13, 38), Rect2(112,528,128,112))
	enemies.back()["plated"] = true
	_add("plant", Vector2i(14, 36), Rect2(112,528,128,112))
	for i in range(6,9): enemies[i]["ambush"] = true


func update(delta: float) -> void:
	if not game.story_enabled and not greeted and game.player.distance_to(game._center(Vector2i(8, 16))) < 28:
		greeted = true
		game._notice("Villager: Two seals open the bridge. Cracked rock lies west of the quarry.")
		game._play("confirm")
	if not healing_taken and game.player.distance_to(game._center(HEALING_CHEST)) < 12:
		healing_taken = true
		game.growth.award(game,"quarry_supply",20)
		game.health = game.max_health
		game._notice("Found medicine. HP restored.")
		game._play("confirm")
	_update_enemies(delta)
	free_spawner.update(game,self,delta)


func area_name() -> String:
	if game.player.y > 640: return "Vault"
	if game.player.y > 480: return "Deep Mine"
	if game.player.x < 224 and game.player.y > 350: return "Mine"
	if game.player.x >= 512:
		return "Spring Isle"
	if game.player.y > 340:
		return "Quarry"
	if game.player.y < 140:
		return "Northwood"
	if game.player.x < 192:
		return "Village"
	return "Riverbank"


func hint() -> String:
	for enemy in enemies:
		if enemy.hp > 0 and enemy.pos.distance_to(game.player) < 60 and _visible(enemy.pos, game.player):
			match enemy.kind:
				"bat": return "Face the bat as it dives, then strike."
				"skeleton": return "Leave room to retreat when a skeleton raises its blade."
				"plant": return "Strike the bloom's spores to destroy them."
	return ""


func draw_world() -> void:
	for tile in [Vector2i(3, 12), Vector2i(8, 12)]:
		if game.village_art.ready(): continue
		var point: Vector2 = Vector2(tile * 16)
		game.draw_rect(Rect2(point, Vector2(48, 32)), game.EARTH)
		game.draw_rect(Rect2(point + Vector2(0, -7), Vector2(48, 15)), game.RED)
		game.draw_rect(Rect2(point + Vector2(4, -11), Vector2(40, 4)), game.RED)
		for x in range(4, 48, 8):
			game.draw_line(point + Vector2(x, -5), point + Vector2(x, 6), game.GOLD)
		game.draw_rect(Rect2(point + Vector2(18, 15), Vector2(12, 17)), game.INK)
		game.draw_rect(Rect2(point + Vector2(4, 13), Vector2(7, 7)), game.BLUE)
	for tile in VALLEY_BLOCKS:
		if game.island_art.props.texture != null and game.island_art.contains(tile): continue
		if game.wild_art.props.texture != null and game.wild_art.contains(tile): continue
		if tile.x < 12:
			continue
		var point: Vector2 = Vector2(tile * 16)
		if tile.y < 8:
			game.draw_rect(Rect2(point + Vector2(6, 5), Vector2(5, 12)), game.EARTH)
			game.draw_rect(Rect2(point + Vector2(-3, -6), Vector2(22, 15)), game.SHADE)
			game.draw_rect(Rect2(point + Vector2(1, -10), Vector2(15, 11)), game.GRASS)
			game.draw_rect(Rect2(point + Vector2(4, -7), Vector2(7, 2)), game.MOSS)
		else:
			game.draw_rect(Rect2(point + Vector2(1, 3), Vector2(14, 13)), game.SHADE)
			game.draw_rect(Rect2(point + Vector2(3, 0), Vector2(10, 7)), game.CREAM)
	var villager: Vector2 = game._center(Vector2i(8, 16))
	if not game.story_enabled: game._sprite(game.KEEPER_SPRITE, villager + Vector2(-5, -9), false)
	var chest: Vector2 = game._center(HEALING_CHEST)
	game.draw_rect(Rect2(chest + Vector2(-6, -4), Vector2(12, 10)), game.INK)
	game.draw_rect(Rect2(chest + Vector2(-5, -3), Vector2(10, 4)), game.SHADE if healing_taken else game.GOLD)
	_draw_enemies()


func draw_map() -> void:
	preload("res://scripts/ui_skin.gd").panel(game,Rect2(17,32,286,151),true)
	if game.has_method("heavy_cost"):
		game.controls.map_tabs(game)
		if game.controls.map_journal:
			game.controls.draw_journal(game);return
	else:game._label("Morningwind Valley / M Back",Vector2(29,48),12,Color("#897347"))
	var bounds:=Rect2(Vector2(game.floor_tiles.keys()[0]),Vector2.ONE)
	for tile in game.floor_tiles:bounds=bounds.expand(Vector2(tile)+Vector2.ONE);bounds=bounds.expand(Vector2(tile))
	var scale:float=minf(238.0/bounds.size.x,104.0/bounds.size.y)
	var origin:Vector2=Vector2(160,112)-bounds.get_center()*scale
	for tile in game.floor_tiles:
		var color:Color=game.EARTH if tile.x in range(26,33) else game.GRASS
		game.draw_rect(Rect2(origin+Vector2(tile)*scale,Vector2.ONE*scale),color)
	for i in range(game.SEALS.size()):
		game.draw_circle(origin+(Vector2(game.SEALS[i])+Vector2(.5,.5))*scale,2,Color("#897347") if i in game.seals else game.RED)
	game.draw_circle(origin+game.player/16*scale,2,Color("#343330"))
	for place in [["Village",Rect2(31,119,65,14)],["Northwood",Rect2(70,63,64,14)],["Quarry",Rect2(70,151,64,14)],["Spring",Rect2(227,111,63,14)]]:
		game.controls.center_label(game,place[0],place[1],9,Color("#343330"))
	game._label("Red: Seals / Dark: You", Vector2(28, 178), 9, Color("#68645b"))
	game._label("Journal ↔", Vector2(242,178),8,Color("#68645b"))
	if game.story_enabled:
		game.draw_circle(origin+(Vector2(game.story.target())+Vector2(.5,.5))*scale,3,Color("#897347"))

