extends RefCounted

var game: Node2D
var enemies: Array[Dictionary] = []
var encounter_id := 0
var actor := 0
var round_number := 1
var phase := "command"
var selection := 0
var action := 0
var target := 0
var timer := 0.0
var pending := ""
var enemy_queue: Array[int] = []
var log_text := ""
var effect_target := -1
var effect_time := 0.0


func begin(id: int, formation: Array[Dictionary]) -> void:
	encounter_id = id
	enemies = formation.duplicate(true)
	actor = 0
	round_number = 1
	phase = "command"
	selection = 0
	effect_time = 0
	enemy_queue.clear()
	for member in game.party:
		member.guard = false
		if member.hp > 0:
			actor = game.party.find(member)
			break
	log_text = "Choose an action. Watch the enemy's next move."


func update(delta: float) -> void:
	effect_time = maxf(0, effect_time - delta)
	if phase != "resolving":
		return
	timer -= delta
	if timer > 0:
		return
	if pending == "next_actor":
		_next_actor()
	elif pending == "enemy":
		_enemy_turn()


func input_key(code: Key) -> void:
	if phase == "victory":
		if code in [KEY_ENTER, KEY_E, KEY_SPACE]:
			game.finish_battle(encounter_id, true)
		return
	if phase == "defeat":
		if code in [KEY_ENTER, KEY_E, KEY_SPACE]:
			game.finish_battle(encounter_id, false)
		return
	if phase == "resolving":
		return
	if phase == "target":
		var choices := _targets()
		if code == KEY_ESCAPE:
			phase = "command"
			return
		if code in [KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D]:
			var step := -1 if code in [KEY_LEFT, KEY_A] else 1
			target = choices[posmod(choices.find(target) + step, choices.size())]
		if code in [KEY_ENTER, KEY_E, KEY_SPACE]:
			_execute()
		return
	if code in [KEY_LEFT, KEY_A]:
		selection = posmod(selection - 1, 4)
	elif code in [KEY_RIGHT, KEY_D]:
		selection = (selection + 1) % 4
	elif code in [KEY_UP, KEY_W, KEY_DOWN, KEY_S]:
		selection = (selection + 2) % 4
	if code in [KEY_1, KEY_2, KEY_3, KEY_4]:
		selection = int(code - KEY_1)
		choose(selection)
	elif code in [KEY_ENTER, KEY_E, KEY_SPACE]:
		choose(selection)


func choose(index: int) -> void:
	if phase != "command":
		return
	action = index
	if action == 1 and game.party[actor].mp < 3:
		log_text = "Not enough MP. Guard to restore 1 MP."
		return
	if action == 3 and game.potions <= 0:
		log_text = "No potions left. Rest in town to replenish them."
		return
	if action == 2:
		_execute()
		return
	phase = "target"
	var choices := _targets()
	target = choices[0]
	if _party_target():
		for i in choices:
			if game.party[i].hp < game.party[target].hp:
				target = i
	log_text = "Left / Right: Target   Enter: Confirm"


func _party_target() -> bool:
	return action == 3 or (action == 1 and game.party[actor].role == "healer")


func _targets() -> Array[int]:
	var result: Array[int] = []
	var source: Array = game.party if _party_target() else enemies
	for i in range(source.size()):
		if source[i].hp > 0 or action == 3:
			result.append(i)
	return result


func _execute() -> void:
	var member: Dictionary = game.party[actor]
	if action == 2:
		member.guard = true
		member.mp = mini(member.max_mp, member.mp + 1)
		log_text = member.name + " guards, reducing damage and restoring MP."
	elif _party_target():
		var ally: Dictionary = game.party[target]
		if ally.hp >= ally.max_hp:
			log_text = "That target is at full HP. Choose another."
			return
		var heal: int = 16 + game.level * 2
		if action == 3:
			heal = 22
			game.potions -= 1
		else:
			member.mp -= 3
		ally.hp = mini(ally.max_hp, ally.hp + heal)
		log_text = "%s recovers %d HP" % [ally.name, heal]
		game._play("confirm")
	else:
		var foe: Dictionary = enemies[target]
		var damage: int = member.attack
		if action == 1:
			member.mp -= 3
			damage += 8
		else:
			damage = maxi(1, damage - foe.armor)
		foe.hp = maxi(0, foe.hp - damage)
		effect_target = target
		effect_time = 0.5
		log_text = "%s hits %s for %d damage" % [member.name, foe.name, damage]
		game._play("attack")
	if _living(enemies).is_empty():
		phase = "victory"
		log_text = "Victory! The tower seal is broken." if encounter_id == 2 else "Victory! Experience and star seal gained."
		game._play("ember")
		return
	phase = "resolving"
	timer = 0.65
	pending = "next_actor"


func _living(units: Array) -> Array[int]:
	var result: Array[int] = []
	for i in range(units.size()):
		if units[i].hp > 0:
			result.append(i)
	return result


func _next_actor() -> void:
	for i in range(actor + 1, game.party.size()):
		if game.party[i].hp > 0:
			actor = i
			phase = "command"
			selection = 0
			log_text = game.party[actor].name + "'s turn"
			return
	enemy_queue = _living(enemies)
	pending = "enemy"
	timer = 0.55


func intent(index: int) -> String:
	var foe: Dictionary = enemies[index]
	var living := _living(game.party)
	if living.is_empty():
		return ""
	var victim := living[(round_number + index - 1) % living.size()]
	var heavy: bool = foe.heavy and round_number % 3 == 0
	return ("Heavy strike > " if heavy else "Attack > ") + game.party[victim].name


func _enemy_turn() -> void:
	if enemy_queue.is_empty():
		for member in game.party:
			member.guard = false
		round_number += 1
		actor = _living(game.party)[0]
		selection = 0
		phase = "command"
		log_text = game.party[actor].name + "'s turn"
		return
	var index: int = enemy_queue.pop_front()
	var foe: Dictionary = enemies[index]
	var living := _living(game.party)
	var victim := living[(round_number + index - 1) % living.size()]
	var member: Dictionary = game.party[victim]
	var damage: int = foe.attack
	if foe.heavy and round_number % 3 == 0:
		damage *= 2
	if member.guard:
		damage = maxi(1, int(ceil(damage * 0.3)))
	member.hp = maxi(0, member.hp - damage)
	log_text = "%s attacks %s for %d damage" % [foe.name, member.name, damage]
	game._play("hit")
	if _living(game.party).is_empty():
		phase = "defeat"
		log_text = "The party has fallen. Enter: Return to town"
		return
	timer = 0.8


func draw() -> void:
	game.draw_rect(Rect2(0, 0, 320, 224), Color("#23405a"))
	game.draw_rect(Rect2(0, 65, 320, 82), Color("#697d51"))
	for x in range(0, 320, 43):
		game.draw_colored_polygon(PackedVector2Array([Vector2(x - 30, 65), Vector2(x + 24, 30), Vector2(x + 64, 65)]), Color("#3e5d64"))
	for x in range(0, 320, 19):
		game.draw_line(Vector2(x, 115), Vector2(x + 7, 115), Color("#91a16d"))
	game.draw_rect(Rect2(0, 0, 320, 23), game.INK)
	game._label("Starbridge Highlands / Battle", Vector2(9, 16), 12, game.GOLD)
	game._label("Turn %d" % round_number, Vector2(263, 16), 10, game.LIGHT)
	for i in range(game.party.size()):
		var member: Dictionary = game.party[i]
		var point := Vector2(60 + i * 24, 60 + i * 48)
		if member.hp > 0:
			game.draw_actor("hero" if i == 0 else "healer", point, 2)
		else:
			game.draw_line(point, point + Vector2(19, 0), game.RED, 3)
		if phase in ["command", "target"] and actor == i:
			game.draw_colored_polygon(PackedVector2Array([point + Vector2(-14, -10), point + Vector2(-7, -6), point + Vector2(-14, -2)]), game.GOLD)
		if member.guard:
			game.draw_rect(Rect2(point + Vector2(-9, -19), Vector2(29, 28)), game.BLUE, false)
	for i in range(enemies.size()):
		var foe: Dictionary = enemies[i]
		if foe.hp <= 0:
			continue
		var point := Vector2(225 + i * 25, 66 + i * 39)
		var name_y := 34 + i * 39
		if enemies.size() == 1:
			point = Vector2(238, 89)
			name_y = 38
		game._label(foe.name, Vector2(point.x - 20, name_y), 11, game.LIGHT)
		game._label(intent(i), Vector2(point.x - 25, name_y + 12), 9, game.GOLD if round_number % 3 == 0 and foe.heavy else game.LIGHT)
		game.draw_actor(foe.kind, point, 3 if foe.kind == "boss" else 2, effect_time > 0 and effect_target == i)
		var bar_origin := point + Vector2(-19, 18)
		var bar_width := 53.0
		if enemies.size() > 1:
			bar_origin = point + Vector2(-43, 0)
			bar_width = 24.0
		game.draw_rect(Rect2(bar_origin, Vector2(bar_width, 3)), game.INK)
		game.draw_rect(Rect2(bar_origin + Vector2.ONE, Vector2((bar_width - 2) * foe.hp / foe.max_hp, 1)), game.RED)
		if phase == "target" and not _party_target() and target == i:
			if enemies.size() == 1:
				game.draw_rect(Rect2(point + Vector2(-26, -28), Vector2(65, 45)), game.GOLD, false)
			else:
				game.draw_colored_polygon(PackedVector2Array([point + Vector2(-17, -8), point + Vector2(-12, -4), point + Vector2(-17, 0)]), game.GOLD)
	game.draw_rect(Rect2(4, 128, 312, 21), game.INK)
	game._label(log_text, Vector2(10, 142), 10, game.LIGHT)
	game.draw_rect(Rect2(4, 152, 149, 68), game.INK)
	for i in range(game.party.size()):
		var member: Dictionary = game.party[i]
		var y := 166 + i * 30
		game._label("%s  HP %d/%d" % [member.name, member.hp, member.max_hp], Vector2(11, y), 10, game.LIGHT)
		game._label("MP %d/%d" % [member.mp, member.max_mp], Vector2(11, y + 12), 9, game.BLUE)
		if phase == "target" and _party_target() and target == i:
			game.draw_rect(Rect2(6, y - 12, 144, 28), game.GOLD, false)
	game.draw_rect(Rect2(157, 152, 159, 68), game.INK)
	if phase in ["victory", "defeat"]:
		game._label("Victory / +12 XP" if phase == "victory" else "Rest in town, then try again.", Vector2(165, 174), 11, game.GOLD)
		game._label("Enter: Continue", Vector2(165, 199), 12, game.LIGHT)
		return
	var labels := ["1 Attack", "2 Heal 3MP" if game.party[actor].role == "healer" else "2 Break 3MP", "3 Guard", "4 Potion x%d" % game.potions]
	for i in range(4):
		var pos := Vector2(165 + (i % 2) * 74, 169 + (i / 2) * 21)
		game._label(labels[i], pos, 10, game.GOLD if i == selection else game.LIGHT)
		if i == selection and phase == "command":
			game.draw_rect(Rect2(pos + Vector2(-3, -12), Vector2(72, 17)), game.GOLD, false)
	game._label("Left / Right: Target   Enter: Confirm" if phase == "target" else "Arrows: Select   Enter: Confirm", Vector2(165, 214), 9, game.BLUE)
