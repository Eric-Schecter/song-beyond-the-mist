extends RefCounted

const ROOMS := [Rect2i(10, 30, 1, 3), Rect2i(7, 33, 8, 7), Rect2i(3, 34, 3, 4), Rect2i(6, 35, 1, 1), Rect2i(12, 40, 1, 1), Rect2i(10, 41, 6, 4), Rect2i(15,33,1,1), Rect2i(16,32,3,3)]
const WALL := Vector2i(10, 31)
const DOOR := Vector2i(12, 40)
const PLATES := [Vector2i(10, 37), Vector2i(13, 37)]
const CACHE := Vector2i(4, 36)
const TREASURE := Vector2i(13, 43)
const PRISM := Vector2i(17,32)
const JOURNAL := Vector2i(4,35)
const LIFT := Vector2i(14,42)
const LIFT_TOP := Vector2i(12,29)
const BUDS := [Vector2i(13,36),Vector2i(12,38),Vector2i(14,38)]
var prism_found := false
var journal_read := false
var lift_repaired := false
var vista_seen := false
var spent_buds: Array[int] = []
var echoes: Array[Dictionary] = []
var game: Node2D
var wall_open := false
var door_open := false
var cache_found := false
var treasure_found := false
var resonance := 0.0

func reset() -> void:
	prism_found = false
	journal_read = false
	lift_repaired = false
	vista_seen = false
	spent_buds.clear()
	echoes.clear()
	wall_open = false
	door_open = false
	cache_found = false
	treasure_found = false
	resonance = 0

func blocked(tile: Vector2i) -> bool:
	return (tile == WALL and not wall_open) or (tile == DOOR and not door_open)

func pulse() -> void:
	if not wall_open and game.player.distance_to(game._center(WALL)) <= game._pulse_radius():
		wall_open = true
		game._stone_burst(game._center(WALL), 18, 0.6)
		game._play("stone_die")
		game._notice("Loose rock shattered. The deep mine is open.")
	var both := true
	for tile in PLATES:
		both = both and game.player.distance_to(game._center(tile)) <= game._pulse_radius() and game.exploration._visible(game.player, game._center(tile))
	if both and wall_open and not door_open:
		door_open = true
		resonance = 1.2
		game._play("ember")
		game._notice("Both pillars resonate. The vault is open.")

func interact() -> bool:
	if game.player.distance_to(game._center(JOURNAL)) < 12:
		journal_read = true
		game._notice("Miner's notes: cross the eastern bridge; use the prism to burst spores.")
		game.message_time = 6
		game._play("confirm")
		return true
	if game.player.distance_to(game._center(PRISM)) < 22 and not prism_found:
		prism_found = true
		game._play("ember")
		game._notice("Resonance prism: K bursts spores and shatters armor.")
		game.message_time = 6
		game.pulse_cooldown = 0
		return true
	if game.player.distance_to(game._center(LIFT)) < 22:
		if not treasure_found:
			game._notice("The lift needs power from the vault core.")
		elif not lift_repaired:
			lift_repaired = true
			game._play("ember")
			game._notice("Lift repaired. E returns to camp.")
			game.message_time = 5
		else: travel(true)
		return true
	if lift_repaired and game.player.distance_to(game._center(LIFT_TOP)) < 20:
		travel(false)
		return true
	if game.player.distance_to(game._center(CACHE)) < 22 and not cache_found:
		cache_found = true
		game.health = game.max_health
		game._play("confirm")
		game._notice("Supplies found. HP and quake cooldown restored.")
		game.pulse_cooldown = 0
		return true
	if game.player.distance_to(game._center(TREASURE)) < 22 and not treasure_found and door_open:
		for enemy in game.exploration.enemies:
			if enemy.get("plated", false) and enemy.hp > 0:
				game._notice("Defeat the Echo Warden before taking the mine heart.")
				return true
		treasure_found = true
		game.max_health += 1
		game.health = game.max_health
		game._play("ember")
		game._notice("Mine Heart: +10 HP")
		game.message_time = 5
		return true
	return false

func hint() -> String:
	if game.player.y < 470: return ""
	if not wall_open: return "Loose rock: approach and press K to shatter it."
	if game.player.distance_to(game._center(CACHE)) < 22 and not cache_found: return "E Open supply chest"
	if game.player.distance_to(game._center(TREASURE)) < 22 and not treasure_found: return "E Take the Mine Heart"
	if treasure_found: return "Mine explored. Return to the spring."
	if not door_open: return "Stand between both pillars; press K to activate them."
	return "Echo Warden: K breaks armor. Strike while it is stunned."

func draw() -> void:
	draw_adventure()
	for tile in [WALL, DOOR]:
		var opened := wall_open if tile == WALL else door_open
		var p: Vector2 = game._center(tile)
		game.mine_art.mechanism(1 if opened else 6,p,Vector2(17,7) if opened else Vector2(20,22))
	for tile in PLATES:
		var p: Vector2 = game._center(tile)
		game.mine_art.mechanism(7,p,Vector2(12,18))
		if door_open: game.mine_art.glow(p,15,game.GOLD)
	if door_open:
		game.draw_line(game._center(PLATES[0]),game._center(PLATES[1]),Color(game.GOLD,0.6))
	for tile in [CACHE,TREASURE]:
		var found := cache_found if tile == CACHE else treasure_found
		game.mine_art.mechanism(8,game._center(tile),Vector2(17,13),found)


func update(delta: float) -> void:
	for echo in echoes: echo.life -= delta
	echoes = echoes.filter(func(e): return e.life > 0)
	if game.relic_found and not vista_seen and game.player.distance_to(game._center(Vector2i(10,30))) < 24:
		vista_seen = true
		game._notice("A crystal glows across the bridge. Search the western camp for notes.")
		game.message_time = 5

func travel(up: bool) -> void:
	game.player = game._center(LIFT_TOP if up else LIFT)
	game.camera = (game.player - Vector2(160,110)).clamp(Vector2(0,-16),Vector2(400,544))
	game._clear_weapon_action()
	game.attack_time = 0
	game.swing_pending = false
	game.hurt_time = 1
	game._play("confirm")
	game._notice("Shortcut open. Travel between camp and vault.")

func chain_pulse() -> void:
	if not prism_found: return
	var origins: Array[Vector2] = []
	for i in range(BUDS.size()):
		var p: Vector2 = game._center(BUDS[i])
		if i not in spent_buds and p.distance_to(game.player) <= game._pulse_radius() and game.exploration._visible(game.player,p):
			spent_buds.append(i)
			origins.append(p)
	for i in range(game.exploration.shots.size()-1,-1,-1):
		var p: Vector2 = game.exploration.shots[i].pos
		if p.distance_to(game.player) <= game._pulse_radius() and game.exploration._visible(game.player,p):
			origins.append(p)
			game.exploration.shots.remove_at(i)
	var cursor := 0
	while cursor < origins.size() and cursor < 32:
		var center := origins[cursor]
		cursor += 1
		echoes.append({"pos":center,"life":0.45})
		game._enemy_effect(center,"seed_pop",true)
		for i in range(BUDS.size()):
			var p: Vector2 = game._center(BUDS[i])
			if i not in spent_buds and p.distance_to(center) <= 40 and game.exploration._visible(center,p):
				spent_buds.append(i)
				origins.append(p)
		for enemy in game.exploration.enemies:
			if enemy.hp <= 0 or enemy.pos.distance_to(center) > 40 or not game.exploration._visible(center,enemy.pos): continue
			enemy.hp -= 1
			enemy.flash = 0.08
			enemy.stun = 1.2
			enemy["exposed"] = 2.0
			enemy.windup = false
			enemy.dash = 0
			if enemy.hp <= 0:
				enemy.death = 0.22
				if enemy.kind == "skeleton": game._impact(enemy.pos,"break")
				else: game._enemy_effect(enemy.pos,enemy.kind+"_die",true)
	if not origins.is_empty():
		game._notice("Chain resonance: spores burst and armor shatters.")

func objective() -> String:
	if not game.relic_found: return ""
	if not wall_open: return "A distant crystal. Break through and find another path."
	if not journal_read: return "Search the old western camp for clues"
	if not prism_found: return "Follow the eastern tunnel to the prism"
	if not door_open: return "Burst spores; activate both pillars"
	if not treasure_found: return "Recover the lift's power from the vault"
	if not lift_repaired: return "Repair the vault lift to open a shortcut"
	return "Shortcut open. Return to the spring."

func interaction_hint() -> String:
	if game.player.distance_to(game._center(JOURNAL)) < 12: return "E Read the miner's notes"
	if not prism_found and game.player.distance_to(game._center(PRISM)) < 22: return "E Take the resonance prism"
	if game.player.distance_to(game._center(LIFT)) < 22: return "E Return to camp" if lift_repaired else "E Repair the lift"
	if lift_repaired and game.player.distance_to(game._center(LIFT_TOP)) < 20: return "E Ride the lift to the vault"
	return ""

func draw_adventure() -> void:
	var prism: Vector2 = game._center(PRISM)
	# Broken bridge ends leave a visible gap; the eastern path reaches the ledge.
	for x in [11,12,15,16]:
		var p := Vector2(x*16,31*16)
		game.draw_rect(Rect2(p,Vector2(13,7)),Color("#78543e"))
		for dx in [1,5,9]: game.draw_line(p+Vector2(dx,0),p+Vector2(dx,6),game.GOLD.darkened(0.25))
		game.draw_line(p+Vector2(0,8),p+Vector2(12,8),game.SHADE)
		game.draw_rect(Rect2(p+Vector2(0,-3),Vector2(2,5)),game.EARTH)
		game.draw_line(p+Vector2(0,-3),p+Vector2(12,-3),game.EARTH)
	var note: Vector2 = game._center(JOURNAL)
	game.draw_rect(Rect2(note-Vector2(5,4),Vector2(10,8)),game.CREAM)
	game.draw_line(note-Vector2(3,1),note+Vector2(3,1),game.INK)
	for i in range(BUDS.size()):
		var p: Vector2 = game._center(BUDS[i])
		if i in spent_buds:
			game.draw_line(p-Vector2(3,0),p+Vector2(3,0),game.SHADE)
			continue
		game.draw_rect(Rect2(p+Vector2(-1,-2),Vector2(2,6)),game.MOSS)
		game.draw_circle(p+Vector2(0,-3),4,game.RED)
		game.draw_rect(Rect2(p+Vector2(-2,-5),Vector2(2,2)),game.GOLD)
	for echo in echoes:
		game.draw_arc(echo.pos,3+(1-echo.life/0.45)*37,0,TAU,20,game.GOLD,2)
	for tile in [LIFT,LIFT_TOP]:
		var p: Vector2 = game._center(tile)
		game.wild_art.props.draw(game,4,Rect2(p+Vector2(-12,-22),Vector2(24,28)))
		for plank in range(5):
			game.draw_rect(Rect2(p+Vector2(-7,-2+plank*2),Vector2(14,2)),Color("#8c6d4e") if plank%2 == 0 else Color("#70543e"))
		game.draw_circle(p+Vector2(8,-8),1.5,game.GOLD if lift_repaired else game.SHADE)
	if lift_repaired:
		var p: Vector2 = game._center(Vector2i(15,44))
		game.draw_arc(p,4+sin(game.clock*2)*2,PI,TAU,12,game.BLUE)
		game._label("An echo lingers below...",p+Vector2(-66,-10),9,game.MOSS)
