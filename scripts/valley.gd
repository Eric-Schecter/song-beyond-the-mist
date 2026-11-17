extends "res://scripts/action_base.gd"

@export var story_enabled := false
var combat_signal = preload("res://scripts/combat_signal.gd").new()
var story = preload("res://scripts/chapter_one.gd").new()
var defeat_age := -1.0
var defeat_relocated := false

const VALLEY_ROOMS := [
	Rect2i(15, -8, 11, 10), Rect2i(2, 11, 10, 9), Rect2i(12, 12, 5, 5), Rect2i(16, 9, 10, 11),
	Rect2i(18, 7, 3, 3), Rect2i(15, 2, 11, 6),
	Rect2i(18, 20, 3, 3), Rect2i(15, 22, 12, 8),
	Rect2i(9, 23, 5, 7), Rect2i(14, 25, 1, 1),
	Rect2i(26, 13, 7, 3), Rect2i(32, 7, 12, 16),
]
const VILLAGE := Vector2i(6, 15)
const BRIDGE_CAMP := Vector2i(24, 17)
const FOUNTAIN := Vector2i(40, 10)
const SEALS := [Vector2i(24, -7), Vector2i(24, 27)]
const BLUE := Color("#438bbb")
const WATER := Color("#235774")
const GRASS := Color("#67854b")
const EARTH := Color("#b6a06b")
const GOLD := Color("#e8bc66")
const RED := Color("#bd6257")
const CREAM := Color("#eee1bb")

var carried_weapon := Weapon.SWORD
var carried_health := 3
var seals: Array[int] = []
var checkpoint := VILLAGE
var intro_time := 3.5
var journey = preload("res://scripts/forest_journey.gd").new()
var growth = preload("res://scripts/character_growth.gd").new()
var patterns = preload("res://scripts/warden_patterns.gd").new()
var charges_left := 0
var swing_direction := Vector2.RIGHT
var swing_pending := false
var hit_stop := 0.0
var shake_time := 0.0
var shake_strength:=2.0
var shake_direction:=Vector2.RIGHT
var shake_duration:=.15
var effects: Array[Dictionary] = []
var sound_serial := 0
var boss_death := 0.0
var boss_dust := 0.0
var boss_ring := 0.0
const CRACK := Vector2i(14, 25)
const RELIC := Vector2i(10, 28)
var combo_step := 0
var combo_window := 0.0
var combo_queued := false
var spear_charging := false
var spear_charge := 0.0
var spear_power := false
var dodge_time := 0.0
var dodge_cooldown := 0.0
var dodge_direction := Vector2.RIGHT
var boss_counter := 0.0
var boss_landed := false
var sword_presentation = preload("res://scripts/sword_presentation.gd").new()
var refined_hero = preload("res://scripts/refined_hero.gd").new()
var art_preview: Node2D
var landscape_ground = preload("res://scripts/landscape_ground.gd").new()
var island_art = preload("res://scripts/island_art.gd").new()
var wild_art = preload("res://scripts/wild_art.gd").new()
var village_art = preload("res://scripts/village_art.gd").new()
var mine_art = preload("res://scripts/mine_art.gd").new()
var hud = preload("res://scripts/valley_hud.gd").new()
var mine = preload("res://scripts/mine.gd").new()
var rockbreak := false
var cave_open := false
var relic_found := false
var score: Node
var fountain_awake := false
var water_fill := 0.0

func water_at(point: Vector2) -> float:
	if not story_enabled: return 1.0
	var delay := clampf(point.distance_to(_center(FOUNTAIN))/900.0,0,0.65)
	return smoothstep(delay,delay+0.35,water_fill)

var pulse_cooldown := 0.0
var pulse_time := 0.0
var pulse_origin := Vector2.ZERO


func _ready() -> void:
	INK = Color("#1c2937")
	SHADE = Color("#3e5860")
	MOSS = Color("#92b479")
	LIGHT = CREAM
	font.allow_system_fallback = false
	font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	font.multichannel_signed_distance_field = true
	mine_art.setup(self)
	village_art.setup(self)
	wild_art.setup(self)
	hud.game = self
	mine.game = self
	story.game = self
	for room: Rect2i in VALLEY_ROOMS + ([] if story_enabled else mine.ROOMS):
		for y in range(room.position.y, room.end.y):
			for x in range(room.position.x, room.end.x):
				if not story_enabled or x>=15 or y<23:
					floor_tiles[Vector2i(x, y)] = true
	_add_sound("confirm", _tone([523.0, 659.0, 784.0], 0.09))
	_add_sound("attack", _tone([196.0, 125.0], 0.045))
	_add_sound("hit", _tone([123.0, 83.0], 0.07))
	_add_sound("ember", _tone([523.0, 659.0, 784.0, 1047.0], 0.12))
	exploration = preload("res://scripts/valley_exploration.gd").new()
	exploration.game = self
	add_child(exploration)
	for tile in exploration.VALLEY_BLOCKS:
		floor_tiles.erase(tile)
	for x in range(15,24): floor_tiles.erase(Vector2i(x,-4))
	for x in range(17,26): floor_tiles.erase(Vector2i(x,-1))
	landscape_ground.setup(self)
	island_art.setup(self)
	for id in ["swing", "bone_hit", "armor", "hurt", "break", "warning", "thrust", "pierce", "bat_dash", "bat_hit", "bat_die", "plant_charge", "plant_spit", "plant_hit", "plant_die", "seed_pop", "stone_charge", "stone_dash", "stone_stop", "stone_hit", "stone_die"]:
		_add_sound(id, _combat_sound(id))
	_reset()
	if story_enabled:
		score=preload("res://scripts/adventure_score.gd").new()
		score.game=self
		add_child(score)


func _reset() -> void:
	defeat_age=-1;defeat_relocated=false
	growth.reset()
	journey.reset()
	refined_hero.reset()
	village_art.motion.reset()
	sword_presentation.reset()
	player = _center(VILLAGE)
	facing = Vector2.RIGHT
	camera = player - Vector2(110, 110)
	weapon = carried_weapon
	if weapon == Weapon.NONE:
		weapon = Weapon.SWORD
	max_health = carried_health
	health = max_health
	checkpoint = VILLAGE
	mine.reset()
	rockbreak = false
	cave_open = false
	relic_found = false
	fountain_awake = false
	water_fill = 0.0
	pulse_cooldown = 0
	pulse_time = 0
	seals.clear()
	gate_open = false
	cleared = false
	map_open = false
	_clear_weapon_action()
	dodge_time = 0
	dodge_cooldown = 0
	boss_counter = 0
	boss_landed = false
	attack_time = 0
	swing_pending = false
	hit_stop = 0
	shake_time = 0
	effects.clear()
	hurt_time = 0
	message_time = 0
	intro_time = 0.0 if story_enabled else 3.5
	moved = false
	_reset_guard()
	exploration.reset()
	story.reset()
	for sound in sounds.values():
		sound.stop()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if growth.opened and (event is InputEventMouseButton or event is InputEventMouseMotion):
		growth.mouse(self,event);queue_redraw();return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and (not story.pages.is_empty() or story.complete_card):
		if story.chapter_card_active() or Rect2(8,126,304,91).has_point(event.position):
			var advance := InputEventKey.new()
			advance.physical_keycode = KEY_ENTER
			advance.pressed = true
			story.input(advance)
			queue_redraw()
		return
	if not event is InputEventKey or event.echo: return
	var code: Key = event.physical_keycode
	if event.pressed and code == KEY_F6 and not story_enabled and not has_meta("art_sample"):
		art_preview = load("res://scenes/art_sample.tscn").instantiate()
		art_preview.return_scene = self
		get_tree().root.add_child(art_preview)
		hide()
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	if not story.modal() and growth.input(self,event):
		queue_redraw()
		return
	if story.input(event):
		queue_redraw()
		return
	if not event.pressed:
		if code in [KEY_J, KEY_SPACE] and spear_charging:
			if not map_open and not cleared and dodge_time <= 0:
				_release_spear()
			else: _clear_weapon_action()
		return
	if code == KEY_R:
		_reset()
		return
	if code == KEY_M:
		spear_charging = false
		spear_charge = 0
		combo_queued = false
		combo_window = 0
		map_open = not map_open
		return
	if cleared and code == KEY_C:
		cleared = false
		return
	if cleared and code in [KEY_ENTER, KEY_KP_ENTER, KEY_E]:
		var next_scene: Node2D = load("res://scenes/highlands.tscn").instantiate()
		next_scene.carried_weapon = weapon
		next_scene.carried_health = max_health
		get_tree().root.add_child(next_scene)
		get_tree().current_scene = next_scene
		queue_free()
		return
	if map_open or cleared or intro_time > 2.5:
		return
	if code == KEY_Q:
		_start_dodge()
		return
	if dodge_time > 0: return
	if code in [KEY_1, KEY_2] and attack_time <= 0 and _at_camp():
		_clear_weapon_action()
		weapon = Weapon.SWORD if code == KEY_1 else Weapon.SPEAR
		carried_weapon = weapon
		_notice("Equipped: " + WEAPONS[weapon]["name"])
		_play("confirm")
	elif code == KEY_K and relic_found and pulse_cooldown <= 0 and attack_time <= 0 and not spear_charging:
		_ground_pulse()
	elif code == KEY_E:
		_interact()
	elif code in [KEY_J, KEY_SPACE]:
		if weapon == Weapon.SPEAR:
			if attack_time <= 0 and not spear_charging:
				spear_charging = true
				spear_charge = 0
		elif combo_step == 1 and combo_window > 0 and attack_time > 0:
			combo_queued = true
		elif attack_time <= 0:
			_attack()


func _interact() -> void:
	if journey.interact(self): return
	if story.interact(): return
	if not story_enabled and mine.interact(): return
	if _at_camp(): growth.armor=growth.max_armor()
	if relic_found and player.distance_to(_center(RELIC)) < 23:
		checkpoint = RELIC
		health = max_health
		_notice("Core camp saved. HP restored.")
		_play("confirm")
		return
	if not story_enabled and player.distance_to(_center(CRACK)) < 27 and not cave_open:
		if not rockbreak:
			_notice("Cracked rock blocks the way. The guardian's core may help.")
		else:
			cave_open = true
			_stone_burst(_center(CRACK), 20, 0.6)
			_play("stone_die")
			shake_time = 0.2
			_notice("Rockbreak: Echo Mine is open.")
		return
	if cave_open and player.distance_to(_center(RELIC)) < 23 and not relic_found:
		for enemy in exploration.enemies:
			if enemy.home.x < 224 and enemy.home.y < 480 and enemy.hp > 0:
				_notice("Clear the mine guards before opening the relic chest.")
				return
		relic_found = true
		health = max_health
		_play("ember")
		_notice("Echo Core: heavy strikes trigger a quake.")
		message_time = 5
		return
	for camp: Vector2i in [VILLAGE, BRIDGE_CAMP]:
		if player.distance_to(_center(camp)) < 25:
			checkpoint = camp
			health = max_health
			_notice("Camp saved. HP restored.")
			_play("confirm")
			return
	for i in range(SEALS.size()):
		if i not in seals and player.distance_to(_center(SEALS[i])) < 23:
			seals.append(i)
			gate_open = seals.size() == 2
			_notice("Both seals found. The bridge is open." if gate_open else "One seal found. Keep searching.")
			if seals.size() == 1:
				_notice("River seal found. Find its counterpart.")
				message_time = 4
			_play("ember")
			return
	if player.distance_to(_center(FOUNTAIN)) < 25:
		if slime_health <= 0:
			cleared = true
			fountain_awake = true
			_play("ember")
		else:
			_notice("Defeat the guardian to unseal the spring.")


func _physics_process(delta: float) -> void:
	if defeat_age>=0:
		_tick_defeat(delta)
		return
	if hit_stop<=0:clock += delta
	water_fill = move_toward(water_fill,1.0 if fountain_awake else 0.0,delta/4.5)
	if growth.opened:
		queue_redraw()
		return
	growth.update(self)
	if story_enabled:
		story.update(delta)
		# Followers move in story.update; animation must sample their final positions.
		village_art.motion.update(self,delta)
		if story.modal():
			queue_redraw()
			return
	if not map_open and not cleared:
		pulse_cooldown = maxf(0, pulse_cooldown - delta)
		pulse_time = maxf(0, pulse_time - delta)
		intro_time = maxf(0.0, intro_time - delta)
		shake_time = maxf(0.0, shake_time - delta)
		if hit_stop > 0:
			hit_stop = maxf(0.0, hit_stop - delta)
			queue_redraw()
			return
		combo_window = maxf(0, combo_window - delta)
		if spear_charging:
			var previous_charge := spear_charge
			spear_charge = minf(_charge_duration(), spear_charge + delta)
			if previous_charge < _charge_duration() and spear_charge >= _charge_duration(): _play("warning")
		dodge_cooldown = maxf(0, dodge_cooldown - delta)
		dodge_time = maxf(0, dodge_time - delta)
		boss_counter = maxf(0, boss_counter - delta)
		boss_death = maxf(0, boss_death - delta)
		boss_ring = maxf(0, boss_ring - delta)
		for effect in effects:
			effect.life -= delta
			effect.pos += effect.velocity * delta
		effects = effects.filter(func(e): return e.life > 0)
		attack_time = maxf(0.0, attack_time - delta)
		if combo_queued and attack_time <= 0.1 and combo_step == 1:
			_attack()
		if swing_pending and attack_time <= (0.30 if weapon == Weapon.SPEAR else 0.18):
			swing_pending = false
			_resolve_attack()

		hurt_time = maxf(0.0, hurt_time - delta)
		slime_hurt_time = maxf(0.0, slime_hurt_time - delta)
		message_time = maxf(0.0, message_time - delta)
		if intro_time <= 2.5:
			if dodge_time > 0:
				for i in range(4): player = _move(player, dodge_direction * 160 * delta / 4)
				moved = true
			else:
				_move_player(delta * (0.4 if spear_charging else 1.0))
			if not story_enabled:mine.update(delta)
			exploration.update(delta)
			_move_slime(delta)
		var target := (player - Vector2(160, 110)).clamp(Vector2(0, -200), Vector2(448, 544))
		camera = camera.lerp(target, 1.0 - exp(-7.0 * delta))
		refined_hero.update(self, delta)
		sword_presentation.update(self, delta)
	queue_redraw()


func _walkable(point: Vector2) -> bool:
	var tile := Vector2i((point / 16).floor())
	if not floor_tiles.has(tile):
		return false
	if preload("res://scripts/quest_object_bodies.gd").blocked(self,point):return false
	if mine.blocked(tile): return false
	if tile == CRACK and not cave_open: return false
	return gate_open or tile.x != 29


func _attack() -> void:
	swing_direction = facing
	if weapon == Weapon.SWORD:
		sword_presentation.begin()
		combo_step = 2 if combo_step == 1 and combo_window > 0 else 1
		combo_window = 0.65 if combo_step == 1 else 0.0
		combo_queued = false
		if combo_step == 2:
			for i in range(3): player = _move(player, facing * 2)
		attack_time = 0.32
		swing_pending = true
	else:
		attack_time = WEAPONS[weapon].cooldown
		swing_pending = true


func _at_camp() -> bool:
	return player.distance_to(_center(VILLAGE)) < 25 or player.distance_to(_center(BRIDGE_CAMP)) < 25 or (relic_found and player.distance_to(_center(RELIC)) < 23)

func _charge_duration() -> float:
	return 0.6

func _spear_stun() -> float:
	return 0.9

func _weapon_reach() -> float:
	if weapon == Weapon.SPEAR: return 48.0 if spear_power else 40.0
	return 25.0

func _sword_arc() -> float:
	return 0.8

func _pulse_radius() -> float:
	return 42.0

func _pulse_cooldown() -> float:
	return 4.0


func _clear_weapon_action() -> void:
	combo_step = 0
	combo_window = 0
	combo_queued = false
	spear_charging = false
	spear_charge = 0
	spear_power = false


func _release_spear() -> void:
	spear_power = spear_charge >= _charge_duration()
	spear_charging = false
	spear_charge = 0
	_attack()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		spear_charging = false
		spear_charge = 0
		combo_queued = false


func _in_reach(target: Vector2, depth: float, width: float) -> bool:
	if weapon == Weapon.SPEAR:
		var spear_offset := target - player
		return spear_offset.dot(swing_direction) >= 0 and spear_offset.dot(swing_direction) <= depth and absf(spear_offset.cross(swing_direction)) <= width
	var offset := target - player
	return offset.length() <= depth and (offset.length() < 6 or offset.normalized().dot(swing_direction) >= cos(_sword_arc()))


func _resolve_attack() -> void:
	var equipped: Dictionary = WEAPONS[weapon].duplicate()
	equipped.reach = _weapon_reach()
	_play("thrust" if weapon == Weapon.SPEAR else "swing")
	exploration.attack(equipped.reach, equipped.width)
	if slime_health <= 0 or not _in_reach(slime, equipped.reach, equipped.width):
		return
	if weapon == Weapon.SPEAR and spear_power and guard_state == Guard.WINDUP:
		guard_state = Guard.STAGGER
		guard_time = 0.85
	# Ordinary hits deal damage without resetting the boss attack or recovery timer.
	var multiplier:=1.0 if guard_state in [Guard.RECOVERY,Guard.STAGGER] else 0.65
	slime_health = maxf(0,slime_health-growth.damage()*multiplier)
	slime_hurt_time = 0.07
	_stone_burst(slime, 9, 0.35)
	_play("stone_die" if slime_health == 0 else "stone_hit")
	hit_stop = 0.08 if slime_health == 0 else 0.05
	if slime_health == 0:
		rockbreak = true
		boss_death = 0.8
		boss_ring = 0.5
		shake_time = 0.35
		_stone_burst(slime, 26, 0.8)
		if not story_enabled:
			_notice("Rockbreak gained. Return west of the quarry.")
			message_time = 5


func _start_dodge() -> void:
	if dodge_cooldown > 0 or dodge_time > 0 or attack_time > 0.1: return
	var move_input := Vector2(int(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), int(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - int(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	_clear_weapon_action()
	dodge_direction = move_input.normalized() if move_input != Vector2.ZERO else facing
	refined_hero.roll.start(dodge_direction)
	facing = Vector2(signf(dodge_direction.x),0) if absf(dodge_direction.x) >= absf(dodge_direction.y) else Vector2(0,signf(dodge_direction.y))
	dodge_time = 0.22
	dodge_cooldown = growth.dodge_cooldown()
	attack_time = 0
	swing_pending = false
	_play("swing")


func _ground_pulse() -> void:
	if story_enabled:return
	mine.pulse()
	mine.chain_pulse()
	pulse_cooldown = _pulse_cooldown()
	pulse_time = 0.32
	pulse_origin = player
	_play("stone_stop")
	shake_time = 0.1
	for enemy in exploration.enemies:
		if enemy.hp <= 0 or enemy.pos.distance_to(player) > _pulse_radius() or not exploration._visible(player, enemy.pos): continue
		enemy.stun = 1.6 if enemy.get("plated", false) else 0.55
		if enemy.get("plated", false): enemy.exposed = 1.6
		enemy.windup = false
		enemy.dash = 0
		enemy.time = 0.6
		enemy.push = player.direction_to(enemy.pos) * 160
		_stone_burst(enemy.pos, 5, 0.25)


func _draw_exploration_rewards() -> void:
	if story_enabled:return
	mine_art.mechanism(1 if cave_open else 6,_center(CRACK),Vector2(19,7) if cave_open else Vector2(23,24))
	mine_art.mechanism(8,_center(RELIC),Vector2(17,13),relic_found)
	if pulse_time > 0:
		draw_arc(pulse_origin, 6 + (1 - pulse_time / 0.32) * (_pulse_radius() - 6), 0, TAU, 24, GOLD, 2)


func _impact(point: Vector2, kind: String, audible:bool=true) -> void:
	if weapon == Weapon.SWORD and (not has_method("impact_feedback") or kind=="armor"):
		sword_presentation.impact(point,swing_direction,combo_step == 2,kind == "armor")
	var piercing := weapon == Weapon.SPEAR and kind != "armor"
	if audible:_play("pierce" if piercing and kind == "bone_hit" else kind)
	if piercing:
		for i in range(5):
			var direction := swing_direction.rotated((i - 2) * 0.2)
			effects.append({"pos": point, "velocity": direction * (65 + i * 9), "life": 0.22, "color": CREAM if i % 2 == 0 else GOLD, "bone": false, "streak": direction})
	hit_stop = maxf(hit_stop, 0.055 if kind == "break" else 0.04)
	var color := BLUE if kind == "armor" else CREAM
	for i in range(10 if kind == "break" else 6):
		var direction := Vector2.from_angle(i * 2.399)
		effects.append({"pos": point, "velocity": direction * (36 + i * 3), "life": 0.4 if kind == "break" else 0.18, "color": color, "bone": kind == "break"})


func _enemy_effect(point: Vector2, kind: String, death: bool = false) -> void:
	_play(kind)
	var color := Color("#ad83bf") if kind.begins_with("bat") else MOSS
	if kind == "plant_spit" or kind == "seed_pop": color = GOLD
	for i in range(12 if death else 5):
		var direction := Vector2.from_angle(i * 2.399)
		effects.append({"pos": point, "velocity": direction * (18 + i * 4), "life": 0.48 if death else 0.20, "color": color if i % 3 else CREAM, "bone": true})


func _play(id: String) -> void:
	if id in ["swing", "bone_hit", "armor", "hurt", "break", "warning", "thrust", "pierce", "bat_dash", "bat_hit", "bat_die", "plant_charge", "plant_spit", "plant_hit", "plant_die", "seed_pop", "stone_charge", "stone_dash", "stone_stop", "stone_hit", "stone_die"]:
		sound_serial += 1
		sounds[id].pitch_scale = [0.96, 1.0, 1.04][sound_serial % 3]
	super._play(id)


func _combat_sound(kind: String) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	var duration: float = {"swing": 0.12, "bone_hit": 0.15, "armor": 0.22, "hurt": 0.25, "break": 0.32, "warning": 0.10, "thrust": 0.10, "pierce": 0.16, "bat_dash": 0.16, "bat_hit": 0.1, "bat_die": 0.3, "plant_charge": 0.24, "plant_spit": 0.12, "plant_hit": 0.14, "plant_die": 0.32, "seed_pop": 0.09, "stone_charge": 0.42, "stone_dash": 0.28, "stone_stop": 0.28, "stone_hit": 0.18, "stone_die": 0.8}[kind]
	var data := PackedByteArray()
	var count := int(duration * stream.mix_rate)
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 187
	for i in range(count):
		var t := float(i) / stream.mix_rate
		var progress := t / duration
		var noise := rng.randf_range(-1, 1)
		var wave := noise
		match kind:
			"stone_charge": wave = sin(TAU * (65 * t + 75 * t * t)) * 0.6 + noise * 0.25
			"stone_dash": wave = noise * 0.65 + sin(TAU * 65 * t) * 0.4
			"stone_stop": wave = noise * exp(-12 * t) * 0.8 + sin(TAU * 55 * t) * 0.6
			"stone_hit": wave = noise * 0.65 + sin(TAU * 280 * t) * exp(-25 * t) * 0.5
			"stone_die": wave = noise * (0.5 + 0.3 * sin(t * 85)) + sin(TAU * (70 * t - 25 * t * t)) * 0.4
			"bat_dash": wave = noise * 0.4 + sin(TAU * (950 * t - 1900 * t * t)) * 0.4
			"bat_hit": wave = noise * 0.5 + sin(TAU * 700 * t) * 0.4
			"bat_die": wave = sin(TAU * (1300 * t - 1600 * t * t)) * 0.5 + noise * 0.25
			"plant_charge": wave = sin(TAU * (180 * t + 700 * t * t)) * 0.5
			"plant_spit": wave = sin(TAU * (500 * t - 1600 * t * t)) * 0.65 + noise * 0.25
			"plant_hit": wave = noise * 0.7 + sin(TAU * 110 * t) * 0.35
			"plant_die": wave = noise * (0.5 + sin(t * 95) * 0.3) + sin(TAU * 75 * t) * 0.25
			"seed_pop": wave = noise * 0.6 + sin(TAU * 340 * t) * 0.3
			"thrust": wave = noise * 0.45 + sin(TAU * (1300 * t - 4200 * t * t)) * 0.35
			"pierce": wave = noise * exp(-45 * t) * 0.7 + sin(TAU * (480 * t - 1000 * t * t)) * 0.6
			"swing": wave = noise * 0.6 + sin(TAU * (700 * t - 1800 * t * t)) * 0.2
			"bone_hit": wave = noise * exp(-35 * t) + sin(TAU * 185 * t) * 0.5
			"armor": wave = (sin(TAU * 1700 * t) + sin(TAU * 2713 * t)) * 0.4
			"hurt": wave = signf(sin(TAU * (210 * t - 220 * t * t))) * 0.6
			"break": wave = noise * (0.4 + 0.4 * sin(t * 130)) + sin(TAU * 90 * t) * 0.3
			"warning": wave = sin(TAU * 1100 * t) * 0.35
		var envelope := minf(t / 0.003, 1) * pow(1 - progress, 2)
		data.encode_s16(i * 2, int(clampf(wave * envelope, -1, 1) * 6500))
	stream.data = data
	return stream


func _floating_weapon_origin() -> Vector2:
	# Keep a visible shoulder offset when facing vertically, behind the body.
	return refined_hero.weapon_origin(self)


func _draw_floating_weapon() -> void:
	if weapon == Weapon.SWORD:
		sword_presentation.draw_idle(self)
		return
	var grip := _floating_weapon_origin().round()
	var direction := Vector2(0.35, -1).normalized()
	var length := 14.0 if weapon == Weapon.SPEAR else 13.0
	var tip := grip + direction * length
	draw_line(grip - direction * 4, tip, INK, 4)
	draw_line(grip, tip, CREAM, 2)
	draw_line(grip - direction * 4, grip, GOLD, 2)
	if weapon == Weapon.SWORD:
		draw_line(grip - direction.orthogonal() * 3, grip + direction.orthogonal() * 3, GOLD, 2)
	else:
		draw_colored_polygon(PackedVector2Array([tip + direction * 2, tip - direction * 3 + direction.orthogonal() * 2, tip - direction * 3 - direction.orthogonal() * 2]), CREAM)


func _draw_hero() -> void:
	sword_presentation.draw_trails(self)
	_draw_hero_body()
	sword_presentation.draw_impacts(self)

func _draw_hero_body() -> void:
	if attack_time <= 0:
		_draw_floating_weapon()
		if spear_charging:
			var grip := _floating_weapon_origin()
			draw_arc(grip, 8, -PI/2, -PI/2 + TAU * maxf(0.01, spear_charge / _charge_duration()), 20, GOLD if spear_charge >= _charge_duration() else BLUE, 1)
			if spear_charge >= _charge_duration():
				draw_line(grip - Vector2(4,0), grip + Vector2(4,0), CREAM)
				draw_line(grip - Vector2(0,4), grip + Vector2(0,4), CREAM)
	var point := player.round()
	if hurt_time > 0.86 or hurt_time <= 0 or int(hurt_time * 14) % 2 == 0:
		_sprite(HERO, point + Vector2(-5, -9), facing == Vector2.LEFT)
	if attack_time <= 0:
		return
	if weapon == Weapon.SPEAR:
		_draw_spear_attack()
		return
	sword_presentation.draw_weapon(self)


func _draw_spear_attack() -> void:
	var elapsed := WEAPONS[Weapon.SPEAR].cooldown - attack_time
	var float_direction := Vector2(0.35, -1).normalized()
	var grip := _floating_weapon_origin()
	var direction := swing_direction
	if elapsed < 0.10:
		var t := smoothstep(0.0, 0.10, elapsed)
		grip = grip.lerp(player - swing_direction * 9, t)
		direction = Vector2.from_angle(lerp_angle(float_direction.angle(), swing_direction.angle(), t))
	elif elapsed < 0.16:
		grip = player + swing_direction * lerpf(-9, 32 if spear_power else 24, smoothstep(0.10, 0.16, elapsed))
	elif elapsed < 0.22:
		grip = player + swing_direction * (32 if spear_power else 24)
	else:
		var t := smoothstep(0.22, 0.46, elapsed)
		grip = (player + swing_direction * (32 if spear_power else 24)).lerp(grip, t)
		direction = Vector2.from_angle(lerp_angle(swing_direction.angle(), float_direction.angle(), t))
	var tip := grip + direction * 16
	if elapsed >= 0.10 and elapsed < 0.22:
		var side := swing_direction.orthogonal()
		for i in [-1, 1]:
			draw_line(player + swing_direction * 9 + side * i * 4, tip - swing_direction * 4 + side * i * 4, GOLD)
		draw_line(player + swing_direction * 10, tip, CREAM, 2)
	draw_line(grip - direction * 4, tip - direction * 4, INK, 4)
	draw_line(grip - direction * 4, tip - direction * 4, GOLD, 2)
	draw_colored_polygon(PackedVector2Array([tip, tip - direction * 5 + direction.orthogonal() * 2, tip - direction * 5 - direction.orthogonal() * 2]), CREAM)


func _reset_guard() -> void:
	patterns.reset()
	boss_death = 0
	boss_ring = 0
	boss_dust = 0
	slime = _center(Vector2i(37, 16))
	slime_health = 18.0
	guard_state = Guard.WATCH
	guard_time = 0
	charges_left = 0
	slime_hurt_time = 0
	charge_hit = false
	boss_landed = false
	boss_counter = 0


func _move_slime(delta: float) -> void:
	if story_enabled and story.stage < story.Stage.GUARD: return
	if slime_health <= 0 or player.x < 32 * TILE:
		return
	guard_time -= delta
	patterns.skill_cooldown=maxf(0,patterns.skill_cooldown-delta)
	if patterns.update(self,delta): return
	match guard_state:
		Guard.WATCH:
			if slime.distance_to(player) < (32 if patterns.skill_cooldown>0 else 70):
				charge_direction = slime.direction_to(player)
				patterns.select(self)
				boss_landed = false
				charges_left = 1
				guard_state = Guard.WINDUP
				guard_time = 0.55 if patterns.kind==3 else (0.95 if patterns.kind>0 else 0.8)
				_play("stone_charge")
			else:
				slime = _move(slime, slime.direction_to(player) * (32 if patterns.enraged else 28) * delta,true)
		Guard.WINDUP:
			if guard_time <= 0:
				guard_state = Guard.CHARGE
				guard_time = 0.32
				charge_hit = false
				_play("stone_dash")
		Guard.CHARGE:
			boss_dust -= delta
			if boss_dust <= 0:
				boss_dust = 0.06
				_stone_burst(slime - charge_direction * 7, 3, 0.25)
			var previous := slime
			slime = _move(slime, charge_direction * (145 if patterns.enraged else 135) * delta,true)
			var body_contact: bool = slime.distance_to(player)<=preload("res://scripts/guardian_body.gd").GAP+.05 and charge_direction.dot(slime.direction_to(player))>.3
			if not charge_hit and body_contact:
				charge_hit = true
				boss_landed = _hurt_player(charge_direction) or boss_landed
			if guard_state == Guard.CHARGE and (guard_time <= 0 or previous == slime or body_contact):
				_play("stone_stop")
				_stone_burst(slime, 10, 0.35)
				boss_ring = 0.3
				shake_time = 0.10
				if charges_left > 0:
					charges_left -= 1
					charge_direction = slime.direction_to(player)
					guard_state = Guard.WINDUP
					guard_time = 0.55
					_play("stone_charge")
				else:
					guard_state = Guard.RECOVERY
					guard_time = 0.6
					boss_counter = 0
		Guard.RECOVERY, Guard.STAGGER:
			if guard_time <= 0:
				guard_state = Guard.WATCH


func _stone_burst(point: Vector2, count: int, life: float) -> void:
	for i in range(count):
		var direction := Vector2.from_angle(i * 2.399 + clock)
		effects.append({"pos": point, "velocity": direction * (20 + (i % 8) * 7), "life": life, "color": [SHADE, Color("#aebbb3"), CREAM][i % 3], "bone": true})


func _draw_boss_effects() -> void:
	if slime_health <= 0:
		if island_art.boss(true): return
		if boss_death > 0:
			var scale_y := clampf(boss_death / 0.8, 0.1, 1)
			draw_set_transform(-camera.round() + slime, 0, Vector2(1.5 - scale_y * 0.5, scale_y))
			_sprite(SLIME, Vector2(-7, -4), false, boss_death > 0.65)
			draw_set_transform(-camera.round())
		else:
			for i in range(5):
				draw_rect(Rect2(slime + Vector2(i * 4 - 9, i % 2), Vector2(3, 3)), SHADE)


func _draw_slime() -> void:
	if island_art.boss(): return
	var original := slime
	if guard_state == Guard.WINDUP:
		slime += Vector2(1 if int(clock * 30) % 2 == 0 else -1, 0)
	super._draw_slime()
	slime = original
	if guard_state == Guard.CHARGE:
		for side in [-1, 1]:
			var origin: Vector2 = slime + charge_direction.orthogonal() * side * 7
			draw_line(origin - charge_direction * 22, origin - charge_direction * 8, CREAM)
	if guard_state == Guard.STAGGER:
		for i in range(3):
			var point := slime + Vector2(cos(clock * 5 + i * TAU / 3) * 9, -12 + sin(clock * 5 + i * TAU / 3) * 2)
			draw_rect(Rect2(point.round(), Vector2(2, 2)), GOLD)
	if slime_health < 4:
		draw_polyline(PackedVector2Array([slime + Vector2(-2, -4), slime + Vector2(1, -1), slime + Vector2(-1, 2)]), INK)
		if slime_health <= 2:
			draw_line(slime + Vector2(2, -3), slime + Vector2(5, 2), INK)


func _hurt_player(direction: Vector2 = Vector2.ZERO) -> bool:
	if hurt_time > 0 or dodge_time > 0.06:
		return false
	_clear_weapon_action()
	dodge_time = 0
	if growth.armor>0:
		growth.armor-=1
		hurt_time=.4
		_play("armor")
		return false
	health -= 1
	hurt_time = 1
	_play("hurt")
	shake_time = 0.18
	swing_pending = false
	attack_time = 0
	for i in range(5):
		player = _move(player, direction * 2)
	if health == 0:
		defeat_age=0;defeat_relocated=false
		_clear_weapon_action();moved=false;shake_time=0
		sword_presentation.reset()
	return true

func _tick_defeat(delta:float)->void:
	defeat_age+=delta
	if defeat_age>=2.2 and not defeat_relocated:
		defeat_relocated=true
		player=_center(checkpoint);camera=(player-Vector2(160,110)).clamp(Vector2(0,-200),Vector2(448,544))
		refined_hero.reset();refined_hero.update(self,0)
		health=max_health;hurt_time=.8;dodge_time=0;message_time=0
		if slime_health>0:_reset_guard()
		exploration.respawn()
		if story.training.active:story.training.retry(story)
	if defeat_age>=3.8:defeat_age=-1
	queue_redraw()

func draw_defeat()->void:
	if defeat_age<0:return
	draw_set_transform(Vector2.ZERO)
	var opacity:float=clampf((defeat_age-.65)/1.55,0,1) if defeat_age<2.6 else 1-clampf((defeat_age-2.6)/1.2,0,1)
	draw_rect(Rect2(0,0,320,224),Color(0.025,0.025,0.035,opacity))
	if defeat_age<2.6:
		var text:String=preload("res://scripts/game_locale.gd").text("Defeated")
		var alpha:float=minf(defeat_age/.2,1)*clampf((2.2-defeat_age)/.6,0,1)
		var width:float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,22).x
		draw_line(Vector2(111,91),Vector2(209,91),Color(.74,.63,.43,alpha*.7),1)
		draw_string(font,Vector2(160-width/2,119),text,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color(.92,.85,.71,alpha))
		draw_line(Vector2(111,131),Vector2(209,131),Color(.74,.63,.43,alpha*.7),1)


func _sprite(rows: Array, origin: Vector2, flip: bool, flash: bool = false) -> void:
	var palette := [INK, BLUE, CREAM]
	if rows == HERO:
		_draw_hero_sprite(origin, flip)
		return
	elif rows == SLIME:
		palette = [INK, Color("#718d9b"), CREAM]
	elif rows == exploration.BAT:
		palette = [INK, Color("#8d638b"), RED]
	elif rows == exploration.PLANT:
		palette = [INK, GRASS, RED]
	for y in range(rows.size()):
		var row: String = rows[y]
		for x in range(row.length()):
			var index := int(row[x])
			if index > 0:
				var column := row.length() - x - 1 if flip else x
				draw_rect(Rect2(origin + Vector2(column, y), Vector2.ONE), RED if rows == HERO and hurt_time > 0.86 else (CREAM if flash else palette[index - 1]))


func _draw_hero_sprite(origin: Vector2, flip: bool) -> void:
	if refined_hero.draw(self): return
	var rows := ["   11111    ","  1222221   "," 122232221  "," 122244441  ","  1444141   ","  1444441   ","  155511    "," 15556661   ","155556661   ","155556661   "," 15516661   ","  111711    ","   11 11    ","   88 88    "]
	var colors := [Color("#182431"),Color("#6f4939"),Color("#9c6947"),Color("#e6bd8a"),Color("#d5a653"),Color("#437e9c"),Color("#866347"),Color("#263342")]
	var bob := int(clock*9)%2 if moved else 0
	for y in range(rows.size()):
		for x in range(rows[y].length()):
			var index := int(rows[y][x])
			if index == 0: continue
			var px: int = rows[y].length()-x-1 if flip else x
			draw_rect(Rect2(origin+Vector2(px-1,y-2-bob),Vector2.ONE),RED if hurt_time > 0.86 else colors[index-1])


func _camera_kick()->Vector2:
	if shake_time<=0:return Vector2.ZERO
	var fade:=minf(1,shake_time/maxf(.01,shake_duration))
	var t:=shake_duration-shake_time
	return (shake_direction*sin(t*105+1.1)+shake_direction.orthogonal()*sin(t*77)*.25)*minf(shake_strength,3)*fade*fade

func _hero_behind_guard() -> bool:
	return slime_health > 0 and player.y < slime.y

func _draw() -> void:
	combat_signal.begin()
	var dry_river: bool = story_enabled and water_fill < 1.0
	draw_rect(Rect2(0,0,320,224),Color("#50564e").lerp(WATER,water_at(camera+Vector2(160,112))))
	draw_set_transform(-camera.round() + _camera_kick())
	landscape_ground.riverbed(dry_river)
	# Water ripples span the screen and move in discrete pixel steps.
	for y in range(-216, 770, 18):
		for x in range(0, 750, 30):
			var offset := int(clock * 3 + y) % 4
			draw_line(Vector2(x+offset,y),Vector2(x+offset+7,y),Color(BLUE,water_at(Vector2(x,y))*.7))
	landscape_ground.draw()
	island_art.ground()
	if not story_enabled:mine_art.background()
	for tile in floor_tiles:
		_draw_valley_tile(tile)
	landscape_ground.edge_props()
	landscape_ground.bank_props()
	if not story_enabled:landscape_ground.mine_rim()
	if not story_enabled:mine_art.props()
	village_art.ground_props()
	wild_art.ground_props()
	island_art.decorations()
	exploration.draw_world()
	_draw_fountain()
	story.draw_world()
	journey.draw(self)
	_draw_exploration_rewards()
	if not story_enabled:mine.draw()
	for camp: Vector2i in [VILLAGE, BRIDGE_CAMP]:
		_draw_camp(_center(camp))
	for i in range(SEALS.size()):
		_draw_seal(_center(SEALS[i]), i)
	if not gate_open: island_art.gate()
	_draw_boss_effects()
	# Sort bodies by foot position; a hero north of the guardian is behind it.
	if _hero_behind_guard():_draw_hero()
	if slime_health > 0:_draw_slime()
	if slime_health > 0:
		draw_rect(Rect2(slime + Vector2(-10, 10), Vector2(20, 3)), INK)
		draw_rect(Rect2(slime + Vector2(-9, 11), Vector2(slime_health / 18.0 * 18, 1)), RED)
	if not _hero_behind_guard():_draw_hero()
	preload("res://scripts/world_interaction.gd").draw(self)
	village_art.foreground()
	wild_art.foreground()
	for effect in effects:
		var point: Vector2 = effect.pos.round()
		if effect.has("streak"):
			draw_line(point - effect.streak * 5, point + effect.streak * 2, effect.color)
			continue
		draw_line(point - Vector2(2, 0), point + Vector2(2, 0), effect.color, 2 if effect.bone else 1)
		if not effect.bone:
			draw_line(point - Vector2(0, 2), point + Vector2(0, 2), effect.color)
	draw_set_transform(Vector2.ZERO)
	_draw_valley_hud()
	if map_open:
		exploration.draw_map()
	if not story_enabled and intro_time > 0:
		preload("res://scripts/ui_skin.gd").panel(self,Rect2(35,64,250,64),true)
		_label("PHASE 02 / Color Awakens", Vector2(55,86),14,preload("res://scripts/ui_skin.gd").INK)
		_label("Morningwind Valley / Find the seals, restore the spring",Vector2(55,110),11,preload("res://scripts/ui_skin.gd").SOFT)
		var fade := clampf(intro_time - 2.5, 0, 1)
		draw_rect(Rect2(0, 0, 320, 224), Color(0.08, 0.12, 0.16, fade))


func _draw_valley_tile(tile: Vector2i) -> void:
	if not island_art.layers.is_empty() and (island_art.contains(tile) or (tile.x in range(27,33) and tile.y in range(13,16))): return
	if not landscape_ground.layers.is_empty() and landscape_ground.contains(tile): return
	if village_art.floor_tile(tile): return
	if wild_art.floor_tile(tile): return
	if mine_art.is_mine(tile):
		mine_art.floor_tile(tile)
		return
	var point := Vector2(tile * 16)
	var color := GRASS
	if tile.x < 15 and tile.y >= 23:
		color = Color("#454c61")
	elif tile.x < 12:
		color = EARTH
	elif tile.y >= 22:
		color = Color("#858e8c")
	elif tile.x >= 32:
		color = Color("#7b9b65")
	var bridge := tile.x in range(26, 33) and tile.y in range(13, 16)
	if bridge:
		color = Color("#a7774b")
	draw_rect(Rect2(point, Vector2(16, 16)), color)
	var detail := posmod(tile.x * 13 + tile.y * 7, 11)
	if bridge:
		draw_line(point + Vector2(0, 1), point + Vector2(0, 15), INK)
		draw_line(point + Vector2(1, 2), point + Vector2(15, 2), GOLD)
	elif detail < 5:
		draw_line(point + Vector2(detail + 4, 10), point + Vector2(detail + 4, 7), SHADE)
		draw_line(point + Vector2(detail + 4, 9), point + Vector2(detail + 2, 7), SHADE)
		if detail == 1 and tile.y < 22:
			draw_rect(Rect2(point + Vector2(11, 5), Vector2(2, 2)), GOLD)
			draw_rect(Rect2(point + Vector2(10, 6), Vector2(4, 1)), RED)
	for neighbor: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if not floor_tiles.has(tile + neighbor):
			var start := point + Vector2(0, 15) if neighbor == Vector2i.DOWN else point
			var end := start + Vector2(15, 0)
			if neighbor.x != 0:
				start = point + Vector2(15 if neighbor.x > 0 else 0, 0)
				end = start + Vector2(0, 15)
			draw_line(start, end, GOLD if tile.x < 12 else MOSS)


func _draw_camp(point: Vector2) -> void:
	if point == _center(BRIDGE_CAMP) and village_art.props.texture != null:
		village_art.props.draw(self,3,Rect2(point+Vector2(-8,-9),Vector2(16,16)))
		return
	if village_art.ready() and point == _center(VILLAGE): return
	draw_rect(Rect2(point + Vector2(-7, 3), Vector2(14, 4)), SHADE)
	draw_line(point + Vector2(-5, 4), point + Vector2(5, 0), EARTH, 2)
	draw_line(point + Vector2(-5, 0), point + Vector2(5, 4), EARTH, 2)
	draw_rect(Rect2(point + Vector2(-2, -4), Vector2(4, 7)), RED)
	draw_rect(Rect2(point + Vector2(0, -6 - int(clock * 4) % 2), Vector2(2, 7)), GOLD)


func _draw_seal(point: Vector2, index: int) -> void:
	if not wild_art.pedestal(point):
		draw_rect(Rect2(point + Vector2(-7, 0), Vector2(14, 7)), SHADE)
		draw_rect(Rect2(point + Vector2(-5, -2), Vector2(10, 3)), CREAM)
	var color := Color("#77bec2") if index == 0 else RED
	if index in seals:
		color = GOLD
	draw_colored_polygon(PackedVector2Array([
		point + Vector2(0, -13), point + Vector2(5, -7),
		point + Vector2(0, -2), point + Vector2(-5, -7),
	]), color)


func _draw_fountain() -> void:
	if island_art.fountain(): return
	var point := _center(FOUNTAIN)
	draw_rect(Rect2(point + Vector2(-16, -10), Vector2(32, 24)), SHADE)
	draw_rect(Rect2(point + Vector2(-13, -7), Vector2(26, 18)), CREAM)
	draw_rect(Rect2(point + Vector2(-10, -4), Vector2(20, 12)), BLUE if fountain_awake else WATER)
	draw_rect(Rect2(point + Vector2(-3, -19), Vector2(6, 17)), Color("#aebbb3"))
	if fountain_awake:
		draw_line(point + Vector2(0, -23), point + Vector2(0, 2), BLUE, 3)


func _draw_valley_hud() -> void:
	if has_meta("opening_preview"): return
	if story.chapter_card_active():
		story.draw_ui();return
	hud.draw()
	if growth.opened:return
	story.draw_ui()


func _hint() -> String:
	var mine_hint: String = mine.hint()
	if not mine_hint.is_empty(): return mine_hint
	if relic_found and player.distance_to(_center(RELIC)) < 23: return "E Rest at the core camp / Explore south"
	if cleared:
		return "Phase Two Complete"
	if player.distance_to(_center(CRACK)) < 30 and not cave_open:
		return "E Break rock to open the mine" if rockbreak else "E Inspect cracked rock / Return later"
	if cave_open and player.distance_to(_center(RELIC)) < 23 and not relic_found:
		return "E Open the Echo relic chest"
	if player.distance_to(_center(VILLAGE)) < 25:
		return "J Light / K Heavy / E Rest / Head east"
	if player.distance_to(_center(BRIDGE_CAMP)) < 25:
		return "E Rest and set checkpoint"
	for i in range(SEALS.size()):
		if i not in seals and player.distance_to(_center(SEALS[i])) < 23:
			return "E Take river seal"
	if player.distance_to(_center(FOUNTAIN)) < 25 and slime_health <= 0:
		return "E Restore spring"
	if player.x >= 32 * TILE and slime_health > 0:return ""
	var tip: String = exploration.hint()
	if not tip.is_empty():
		return tip
	if seals.size() < 2:
		return "Find a seal in Northwood and the southern quarry."
	if rockbreak and not cave_open: return "Rockbreak ready. Return to the western quarry."
	if cave_open and not relic_found: return "Explore the mine; find the Echo Core"
	if relic_found: return "K Quake interrupts enemies / Return to the spring"
	return "Cross the eastern bridge and restore the spring."
