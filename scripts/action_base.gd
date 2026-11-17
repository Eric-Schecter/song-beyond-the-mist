extends Node2D

enum Weapon { NONE, SWORD, SPEAR }
enum Guard { WATCH, WINDUP, CHARGE, RECOVERY, STAGGER }

var INK := Color("#172b23")
var SHADE := Color("#3f5b44")
var MOSS := Color("#829565")
var LIGHT := Color("#d4dea9")
const TILE := 16
const SPEED := 67.0
const CHARGE_RADIUS := 12.0
const WEAPONS := {
	Weapon.SWORD: {"name": "Shortsword", "reach": 25.0, "width": 13.0, "cooldown": 0.28},
	Weapon.SPEAR: {"name": "Spear", "reach": 40.0, "width": 7.0, "cooldown": 0.46},
}
const HERO := [
	"   1111   ", "  122221  ", " 12222221 ", " 11333311 ",
	"  131313  ", "  133333  ", " 11111111 ", "1322222231",
	"1312222131", "  122221  ", "  111111  ", "  11  11  ",
]
const KEEPER_SPRITE := [
	"   1111   ", "  133331  ", "  131131  ", "  133331  ",
	"   1331   ", "  112211  ", " 122222211", " 122222213",
	" 122222211", "  111111  ", "  11  11  ",
]
const SLIME := [
	"    111111    ", "   12222221   ", "  1223332221  ", " 122222222221 ",
	" 122122212221 ", "12221222122221", "12222222222221", " 111111111111 ",
]

var floor_tiles: Dictionary[Vector2i, bool] = {}
var player := Vector2.ZERO
var facing := Vector2.RIGHT
var camera := Vector2.ZERO
var slime := Vector2.ZERO
var health := 3
var max_health := 3
var map_open := false
var exploration: Node
var slime_health := 2.0
var gate_open := false
var weapon := Weapon.NONE
var guard_state := Guard.WATCH
var guard_time := 0.0
var charge_direction := Vector2.ZERO
var charge_hit := false
var cleared := false
var attack_time := 0.0
var hurt_time := 0.0
var slime_hurt_time := 0.0
var message := ""
var message_time := 0.0
var clock := 0.0
var moved := false
var font: FontFile = preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
var sounds: Dictionary[String, AudioStreamPlayer] = {}


func _move_player(delta: float) -> void:
	var right := Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D)
	var left := Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A)
	var down := Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S)
	var up := Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W)
	var direction := Vector2(
		int(right) - int(left),
		int(down) - int(up)
	)
	var previous := player
	if direction != Vector2.ZERO and attack_time <= 0.1:
		if direction.x != 0.0:
			facing = Vector2(signf(direction.x), 0)
		else:
			facing = Vector2(0, signf(direction.y))
		player = _move(player, direction.normalized() * SPEED * delta)
	moved = player != previous


func _center(tile: Vector2i) -> Vector2:
	return Vector2(tile * TILE) + Vector2(8, 8)


func _walkable(point: Vector2) -> bool:
	return floor_tiles.has(Vector2i((point / TILE).floor()))


func _fits(point: Vector2) -> bool:
	for corner in [Vector2(-4, -4), Vector2(4, -4), Vector2(-4, 4), Vector2(4, 4)]:
		if not _walkable(point + corner):
			return false
	return true


func _move(point: Vector2, offset: Vector2, guardian_body: bool = false, enemy_body: Dictionary = {}) -> Vector2:
	var is_player: bool = not guardian_body and enemy_body.is_empty() and point.is_equal_approx(player)
	var story_body: bool = is_player and get("story_enabled")==true
	var steps:=maxi(1,int(ceil(offset.length()/3.0)))
	for step in range(steps):
		for axis in [Vector2(offset.x/steps,0),Vector2(0,offset.y/steps)]:
			if axis.is_zero_approx():continue
			var candidate:Vector2=point+axis
			if not _fits(candidate):continue
			if story_body:candidate=preload("res://scripts/story_space.gd").slide(get("story"),point,candidate)
			if slime_health>0 and (is_player or guardian_body):
				candidate=preload("res://scripts/guardian_body.gd").slide(point,candidate,player if guardian_body else slime)
			if not enemy_body.is_empty() and enemy_body.hp>0:
				candidate=preload("res://scripts/guardian_body.gd").slide(point,candidate,player,exploration.body_gap(enemy_body))
			if is_player and exploration!=null:
				candidate=exploration.slide_player(point,candidate)
				if not exploration.player_body_free(point,candidate):continue
			# A projection around one enemy may touch another body: validate all constraints.
			if slime_health>0 and (is_player or guardian_body) and not preload("res://scripts/guardian_body.gd").allows(point,candidate,player if guardian_body else slime):continue
			if not _fits(candidate):continue
			if story_body and not preload("res://scripts/story_space.gd").body_free(get("story"),candidate):continue
			point=candidate
	return point


func _in_reach(target: Vector2, depth: float, width: float) -> bool:
	var offset := target - player
	var forward := offset.dot(facing)
	return forward >= -2.0 and forward <= depth and absf(offset.cross(facing)) <= width


func _notice(value: String) -> void:
	message = value
	message_time = 2.0


func _tone(notes: Array, duration: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	var frames := int(duration * stream.mix_rate)
	var data := PackedByteArray()
	data.resize(frames * notes.size() * 2)
	for note in range(notes.size()):
		for i in range(frames):
			var wave := signf(sin(TAU * notes[note] * i / stream.mix_rate))
			var envelope := minf(i / 80.0, 1.0) * (1.0 - float(i) / frames)
			data.encode_s16((note * frames + i) * 2, int(2200.0 * envelope * wave))
	stream.data = data
	return stream


func _add_sound(id: String, stream: AudioStreamWAV) -> void:
	var sound := AudioStreamPlayer.new()
	sound.stream = stream
	add_child(sound)
	sounds[id] = sound


func _play(id: String) -> void:
	sounds[id].play()


func _draw_slime() -> void:
	var point := slime.round()
	var bob := int(clock * 5.0) % 3
	draw_rect(Rect2(point + Vector2(-7, 3), Vector2(14, 3)), SHADE)
	match guard_state:
		Guard.WINDUP:
			bob = -1
			var side := charge_direction.orthogonal() * CHARGE_RADIUS
			for offset: float in [8.0, 16.0, 24.0, 32.0, 40.0, 48.0]:
				var mark := point + charge_direction * offset
				draw_line(mark - side, mark + side, INK, 2)
				draw_line(mark - side * 0.7, mark + side * 0.7, LIGHT, 1)
			draw_rect(Rect2(point + Vector2(-1, -13), Vector2(2, 4)), LIGHT)
			draw_rect(Rect2(point + Vector2(-1, -8), Vector2(2, 1)), LIGHT)
		Guard.CHARGE:
			draw_line(point, point - charge_direction * 12.0, SHADE, 3)
		Guard.RECOVERY:
			bob = -2
			draw_rect(Rect2(point + Vector2(-8, -7), Vector2(16, 14)), LIGHT, false)
	_sprite(SLIME, point + Vector2(-7, -4 - bob), false, slime_hurt_time > 0.0)


func _draw_hero() -> void:
	var point := player.round()
	draw_rect(Rect2(point + Vector2(-5, 3), Vector2(10, 3)), SHADE)
	if hurt_time <= 0.0 or int(hurt_time * 14.0) % 2 == 0:
		var bob := int(clock * 10.0) % 2 if moved else 0
		_sprite(HERO, point + Vector2(-5, -9 - bob), facing == Vector2.LEFT)
	if weapon == Weapon.SPEAR and attack_time > 0.28:
		var tip := point + facing * 40.0
		draw_line(point + facing * 6.0, tip, INK, 4)
		draw_line(point + facing * 6.0, tip, LIGHT, 2)
		var side := facing.orthogonal() * 3.0
		draw_colored_polygon(PackedVector2Array([
			tip, tip - facing * 7.0 + side, tip - facing * 7.0 - side,
		]), LIGHT)
	elif weapon == Weapon.SWORD and attack_time > 0.11:
		var side := facing.orthogonal()
		var tip := point + facing * 21.0
		draw_polyline(PackedVector2Array([
			point + facing * 6.0 - side * 10.0,
			tip - side * 5.0, tip + side * 4.0,
			point + facing * 10.0 + side * 11.0,
		]), INK, 4)
		draw_polyline(PackedVector2Array([
			point + facing * 6.0 - side * 10.0,
			tip - side * 5.0, tip + side * 4.0,
			point + facing * 10.0 + side * 11.0,
		]), LIGHT, 2)


func _sprite(rows: Array, origin: Vector2, flip: bool, flash: bool = false) -> void:
	var palette := [INK, LIGHT if flash else SHADE, LIGHT]
	for y in range(rows.size()):
		var row: String = rows[y]
		for x in range(row.length()):
			var index := int(row[x])
			if index > 0:
				var column := row.length() - x - 1 if flip else x
				draw_rect(Rect2(origin + Vector2(column, y), Vector2.ONE), palette[index - 1])


func _label(value: String, position: Vector2, size: int, color: Color) -> void:
	draw_string(font, position, preload("res://scripts/game_locale.gd").text(value), HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
