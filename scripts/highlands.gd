extends "res://scripts/action_base.gd"

const MAP_SIZE := Vector2i(48, 34)
const TOWN := Vector2i(8, 25)
const HEALER := Vector2i(10, 24)
const SUPPLIES := Vector2i(14, 27)
const SITES := [Vector2i(18, 15), Vector2i(34, 23), Vector2i(38, 8)]
const BLOCKS := [Vector2i(15, 18), Vector2i(16, 18), Vector2i(32, 13), Vector2i(33, 13), Vector2i(40, 17)]
const GOLD := Color("#efc77a")
const RED := Color("#cf6d63")
const BLUE := Color("#6db6d1")
const GROUND := Color("#759458")
const EnemyArt = preload("res://scripts/enemy_field.gd")

var carried_weapon := Weapon.SWORD
var carried_health := 3
var party: Array[Dictionary] = []
var defeated: Array[int] = []
var potions := 3
var level := 1
var experience := 0
var mode := "world"
var intro_time := 3.5
var supplies_taken := false
var terrain: Sprite2D
var map_texture: ImageTexture
var terrain_material: ShaderMaterial
var battle = preload("res://scripts/turn_battle.gd").new()


func _ready() -> void:
	INK = Color("#1d2c43")
	SHADE = Color("#5283a4")
	MOSS = Color("#93b27f")
	LIGHT = Color("#f2e6cb")
	font.allow_system_fallback = false
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	_add_sound("confirm", _tone([523.0, 659.0, 784.0], 0.09))
	_add_sound("attack", _tone([262.0, 196.0, 130.0], 0.05))
	_add_sound("hit", _tone([110.0, 82.0], 0.08))
	_add_sound("ember", _tone([523.0, 659.0, 784.0, 1047.0], 0.12))
	battle.game = self
	_build_map()
	_reset()


func _reset() -> void:
	player = _center(TOWN)
	weapon = carried_weapon
	level = 1
	experience = 0
	potions = 3
	party = [{
		"name": "Traveler", "role": "hero", "hp": 24 + carried_health * 4,
		"max_hp": 24 + carried_health * 4, "mp": 9, "max_mp": 9,
		"attack": 11 if weapon == Weapon.SWORD else 12, "guard": false,
	}]
	defeated.clear()
	supplies_taken = false
	mode = "world"
	cleared = false
	map_open = false
	intro_time = 3.5
	message_time = 0
	terrain.visible = true
	_play("ember")


func _build_map() -> void:
	var image := Image.create(MAP_SIZE.x * 16, MAP_SIZE.y * 16, false, Image.FORMAT_RGB8)
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var tile := Vector2i(x, y)
			var land := (x >= 3 and x <= 22 and y >= 10 and y <= 30) or (x >= 12 and x <= 22 and y >= 5 and y <= 12) or (x >= 27 and x <= 44 and y >= 4 and y <= 29)
			var bridge := x in range(23, 27) and y in range(17, 20)
			land = land or bridge
			if land and tile not in BLOCKS:
				floor_tiles[tile] = true
			var road := (y in range(24, 26) and x in range(8, 19)) or (x in range(17, 19) and y in range(15, 26)) or (y in range(17, 20) and x in range(18, 39)) or (x in range(37, 39) and y in range(8, 20)) or (x in range(33, 35) and y in range(19, 24))
			for py in range(16):
				for px in range(16):
					var color := Color("#326580")
					if land:
						color = Color("#b7a576") if road else GROUND
						if (x * 7 + y * 13 + px * 3 + py * 5) % 37 == 0:
							color = Color("#a5bb77")
						if y < 17 and x < 22 and px in range(5, 11) and py in range(3, 11):
							color = Color("#416850")
						if bridge:
							color = Color("#a97f58") if px % 8 != 0 else INK
						if tile in BLOCKS:
							color = Color("#657b80") if py > abs(px - 8) else GROUND
					elif (px + y * 3) % 13 < 5 and py % 8 == 0:
						color = Color("#4b89a2")
					image.set_pixel(x * 16 + px, y * 16 + py, color)
	map_texture = ImageTexture.create_from_image(image)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec2 player_world;
void fragment() {
	vec2 screen = UV * vec2(320.0, 224.0);
	vec4 water = vec4(0.196, 0.396, 0.502, 1.0);
	if (screen.y > 38.0 && screen.y < 181.0) {
		float depth = 21760.0 / (screen.y - 36.0);
		vec2 world = vec2(player_world.x + (screen.x - 160.0) * depth / 170.0,
			player_world.y + 220.0 - depth);
		vec2 map_uv = world / vec2(768.0, 544.0);
		COLOR = (map_uv.x >= 0.0 && map_uv.y >= 0.0 && map_uv.x < 1.0 && map_uv.y < 1.0)
			? texture(TEXTURE, map_uv) : water;
	} else {
		COLOR = water;
	}
}
"""
	terrain_material = ShaderMaterial.new()
	terrain_material.shader = shader
	terrain = Sprite2D.new()
	terrain.texture = map_texture
	terrain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	terrain.position = Vector2(160, 112)
	terrain.scale = Vector2(320.0 / 768.0, 224.0 / 544.0)
	terrain.material = terrain_material
	terrain.z_index = -1
	add_child(terrain)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var code: Key = event.physical_keycode
	if code == KEY_R and mode != "battle":
		_reset()
		return
	if mode == "battle":
		battle.input_key(code)
		return
	if code == KEY_M and mode == "world":
		map_open = not map_open
		return
	if map_open or mode != "world" or intro_time > 2.5:
		return
	if code in [KEY_E, KEY_ENTER]:
		_interact()


func _interact() -> void:
	if player.distance_to(_center(TOWN)) < 26:
		_restore_party()
		potions = 3
		_notice("Rested at the inn. HP, MP and potions restored.")
		_play("confirm")
	elif party.size() == 1 and player.distance_to(_center(HEALER)) < 26:
		party.append({"name": "Arlan", "role": "healer", "hp": 28, "max_hp": 28, "mp": 12, "max_mp": 12, "attack": 7, "guard": false})
		_notice("Arlan joined the party. Healing is now available.")
		_play("ember")
	elif player.distance_to(_center(SITES[2])) < 28:
		if 0 in defeated and 1 in defeated:
			_begin_battle(2)
		else:
			_notice("The tower requires the Forest and Citadel star seals.")


func _physics_process(delta: float) -> void:
	clock += delta
	if mode == "battle":
		battle.update(delta)
	elif mode == "world" and not map_open:
		intro_time = maxf(0, intro_time - delta)
		message_time = maxf(0, message_time - delta)
		if intro_time <= 2.5:
			_move_player(delta)
			if not supplies_taken and player.distance_to(_center(SUPPLIES)) < 13:
				supplies_taken = true
				potions += 2
				_notice("Travel supplies: +2 potions")
				_play("confirm")
			for i in range(2):
				if i not in defeated and player.distance_to(_center(SITES[i])) < 13:
					_begin_battle(i)
					break
	terrain_material.set_shader_parameter("player_world", player)
	queue_redraw()


func _foe(name_text: String, kind: String, hp: int, attack: int, armor: int, heavy: bool) -> Dictionary:
	return {"name": name_text, "kind": kind, "hp": hp, "max_hp": hp, "attack": attack, "armor": armor, "heavy": heavy}


func _begin_battle(id: int) -> void:
	if mode != "world" or id in defeated:
		return
	var formation: Array[Dictionary] = []
	match id:
		0:
			formation = [_foe("Forest Drake", "bat", 18, 4, 0, false), _foe("Venom Bloom", "plant", 24, 5, 0, false)]
		1:
			formation = [_foe("Citadel Sentry", "skeleton", 40, 7, 2, true)]
		2:
			formation = [_foe("Star Tower Colossus", "boss", 86, 9, 3, true)]
	mode = "battle"
	map_open = false
	terrain.visible = false
	battle.begin(id, formation)
	_play("hit")


func finish_battle(id: int, won: bool) -> void:
	terrain.visible = true
	mode = "world"
	if not won:
		player = _center(TOWN)
		_restore_party()
		potions = maxi(1, potions)
		_notice("Returned to the inn. Star seals kept.")
		return
	if id not in defeated:
		defeated.append(id)
		experience += 12
	if experience >= level * 12:
		level += 1
		for member in party:
			member.max_hp += 4
			member.attack += 2
			member.max_mp += 2
			member.hp = member.max_hp
			member.mp = member.max_mp
		_notice("Level %d! Party healed and strengthened." % level)
	if id == 2:
		message_time = 0
		mode = "complete"
		cleared = true
		_play("ember")


func _restore_party() -> void:
	for member in party:
		member.hp = member.max_hp
		member.mp = member.max_mp
		member.guard = false


func _project(world: Vector2) -> Vector3:
	var depth := 220.0 + player.y - world.y
	if depth <= 1:
		return Vector3(-1000, -1000, 0)
	var scale_factor := 170.0 / depth
	return Vector3(160 + (world.x - player.x) * scale_factor, 36 + 128 * scale_factor, scale_factor)


func draw_actor(kind: String, point: Vector2, size: float, flash: bool = false) -> void:
	var rows: Array = HERO
	var palette := [INK, BLUE, GOLD]
	match kind:
		"healer":
			rows = KEEPER_SPRITE
			palette = [INK, Color("#b5c698"), LIGHT]
		"bat":
			rows = EnemyArt.BAT
			palette = [INK, Color("#9b6d9e"), RED]
		"plant":
			rows = EnemyArt.PLANT
			palette = [INK, GROUND, RED]
		"skeleton":
			rows = EnemyArt.BONES
			palette = [INK, Color("#95a8ad"), LIGHT]
		"boss":
			rows = SLIME
			palette = [INK, Color("#8199b6"), GOLD]
	for y in range(rows.size()):
		var row: String = rows[y]
		for x in range(row.length()):
			var index := int(row[x])
			if index > 0:
				draw_rect(Rect2(point + Vector2(x - 5, y - 9) * size, Vector2.ONE * size), LIGHT if flash else palette[index - 1])


func _draw() -> void:
	if mode == "battle":
		battle.draw()
		return
	draw_rect(Rect2(0, 0, 320, 38), Color("#5f8fa6"))
	for x in range(-30, 350, 60):
		draw_colored_polygon(PackedVector2Array([Vector2(x, 38), Vector2(x + 30, 21), Vector2(x + 70, 38)]), Color("#456377"))
	var landmarks: Array[Dictionary] = [
		{"tile": TOWN, "kind": "town", "label": "Starbridge"},
		{"tile": HEALER, "kind": "healer", "label": "Healer"}]
	if not supplies_taken:
		landmarks.append({"tile": SUPPLIES, "kind": "chest", "label": "Supplies"})
	for i in range(SITES.size()):
		landmarks.append({"tile": SITES[i], "kind": "tower" if i == 2 else ("cleared" if i in defeated else "enemy"), "label": ["Forest", "Citadel", "Star Tower"][i]})
	landmarks.sort_custom(func(a, b): return a.tile.y < b.tile.y)
	for mark in landmarks:
		_draw_landmark(mark)
	if party.size() > 1:
		draw_actor("healer", Vector2(144, 140), 1.4)
	draw_actor("hero", Vector2(160, 139), 1.6)
	_draw_world_hud()
	if map_open:
		_draw_world_map()
	if intro_time > 0:
		draw_rect(Rect2(27, 66, 266, 65), INK)
		_label("PHASE 03 / A Wider World", Vector2(44, 89), 16, GOLD)
		_label("Starbridge Highlands: form a party and explore.", Vector2(44, 113), 11, LIGHT)
	if mode == "complete":
		draw_rect(Rect2(32, 57, 256, 100), INK)
		draw_rect(Rect2(34, 59, 252, 96), GOLD, false)
		_label("PHASE 03 / COMPLETE", Vector2(52, 79), 12, GOLD)
		_label("The road to the Star Tower is open.", Vector2(52, 106), 18, LIGHT)
		_label("Party level %d / Both star seals restored" % level, Vector2(52, 128), 11, MOSS)
		_label("R Restart Phase Three", Vector2(52, 145), 10, BLUE)


func _draw_landmark(mark: Dictionary) -> void:
	var projected := _project(_center(mark.tile))
	if projected.z <= 0 or projected.y < 39 or projected.y > 180 or projected.x < -30 or projected.x > 350:
		return
	var point := Vector2(projected.x, projected.y)
	var size := clampf(projected.z, 0.3, 1.4)
	if mark.kind == "healer":
		if party.size() == 1:
			draw_actor("healer", point, size * 1.5)
	elif mark.kind == "enemy":
		draw_actor("skeleton" if mark.tile == SITES[1] else "bat", point, size * 2)
	elif mark.kind == "town":
		draw_rect(Rect2(point + Vector2(-13, -20) * size, Vector2(26, 22) * size), LIGHT)
		draw_colored_polygon(PackedVector2Array([point + Vector2(-17, -19) * size, point + Vector2(0, -33) * size, point + Vector2(17, -19) * size]), RED)
		draw_rect(Rect2(point + Vector2(-4, -9) * size, Vector2(8, 11) * size), INK)
	elif mark.kind == "tower":
		draw_rect(Rect2(point + Vector2(-11, -42) * size, Vector2(22, 44) * size), Color("#8296aa"))
		for i in range(3):
			draw_rect(Rect2(point + Vector2(-13 + i * 9, -48) * size, Vector2(7, 10) * size), LIGHT)
		draw_rect(Rect2(point + Vector2(-4, -13) * size, Vector2(8, 15) * size), INK)
		draw_rect(Rect2(point + Vector2(-2, -32) * size, Vector2(4, 6) * size), GOLD)
	else:
		draw_rect(Rect2(point + Vector2(-6, -6) * size, Vector2(12, 8) * size), GOLD)
	if size > 0.55 and mark.kind != "healer":
		_label(mark.label, point + Vector2(-11, 13), 9, LIGHT)


func _draw_world_hud() -> void:
	draw_rect(Rect2(0, 0, 320, 24), INK)
	_label("Starbridge Highlands", Vector2(8, 17), 14, GOLD)
	_label("Lv.%d" % level, Vector2(83, 17), 10, LIGHT)
	_label("Seals %d/2" % mini(2, defeated.size()), Vector2(128, 17), 10, MOSS)
	_label("Potions %d" % potions, Vector2(206, 17), 10, BLUE)
	_label("Party %d" % party.size(), Vector2(264, 17), 10, LIGHT)
	draw_rect(Rect2(0, 182, 320, 42), INK)
	_label(_hint(), Vector2(9, 198), 11, LIGHT)
	_label("WASD Move / E Interact / M Map / R Restart", Vector2(9, 215), 10, BLUE)
	if message_time > 0:
		draw_rect(Rect2(9, 29, 302, 22), INK)
		_label(message, Vector2(16, 44), 10, GOLD)


func _hint() -> String:
	if mode == "complete":
		return "Phase Three Complete"
	if player.distance_to(_center(TOWN)) < 26:
		return "E Rest at the inn. Meet the healer to the east."
	if party.size() == 1 and player.distance_to(_center(HEALER)) < 26:
		return "E Invite Arlan"
	if player.distance_to(_center(SITES[2])) < 28:
		return "E Challenge the Colossus" if 0 in defeated and 1 in defeated else "Find both star seals in the Forest and Citadel."
	if not (0 in defeated and 1 in defeated):
		return "Defeat enemies in the Forest and Citadel for the seals."
	return "Head northeast to the tower. Guard against heavy attacks."


func _draw_world_map() -> void:
	draw_rect(Rect2(15, 29, 290, 150), INK)
	draw_texture_rect(map_texture, Rect2(55, 44, 210, 123), false)
	var factor := Vector2(210.0 / 768, 123.0 / 544)
	for i in range(SITES.size()):
		draw_rect(Rect2(Vector2(55, 44) + _center(SITES[i]) * factor - Vector2(2, 2), Vector2(4, 4)), GOLD if i in defeated else RED)
	draw_rect(Rect2(Vector2(55, 44) + player * factor - Vector2(2, 2), Vector2(4, 4)), LIGHT)
	_label("Starbridge", Vector2(63, 155), 9, LIGHT)
	_label("Forest", Vector2(120, 98), 9, LIGHT)
	_label("Citadel", Vector2(203, 146), 9, LIGHT)
	_label("Star Tower", Vector2(230, 62), 9, GOLD)
	_label("M Back / White: You / Red: Enemies", Vector2(24, 174), 9, BLUE)
