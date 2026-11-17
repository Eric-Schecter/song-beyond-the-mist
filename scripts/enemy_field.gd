extends Node

const BAT := [
	"1         1", "11  111  11", "12112221121", " 122323221 ",
	"  1222221  ", "   11111   ",
]
const BONES := [
	"  11111  ", " 1333331 ", " 1313131 ", " 1333331 ",
	"  11111  ", "1 13131 1", "111333111", "  13131  ",
	"  11111  ", "  1   1  ",
]
const PLANT := [
	"   11111   ", "  1222221  ", " 123333321 ", "1231111321 ",
	" 123333321 ", "  1222221  ", "    121    ", " 111121111 ",
	"12222222221", " 111111111 ",
]
const DEATH_DURATION := 0.65

func finished_dying(index: int) -> bool:
	var enemy: Dictionary = enemies[index]
	return enemy.hp <= 0 and enemy.death <= 0 and game.hit_stop <= 0

var game: Node2D
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var seed_art=preload("res://scripts/plant_projectile_art.gd").new()



func body_gap(enemy: Dictionary) -> float:
	return 5.0+float({"bat":5.0,"skeleton":6.0,"plant":7.0}.get(enemy.kind,6.0))

func slide_player(origin: Vector2, candidate: Vector2) -> Vector2:
	for enemy in enemies:
		if enemy.hp>0:
			candidate=preload("res://scripts/guardian_body.gd").slide(origin,candidate,enemy.pos,body_gap(enemy))
	return candidate

func player_body_free(origin: Vector2, candidate: Vector2) -> bool:
	for enemy in enemies:
		if enemy.hp>0 and not preload("res://scripts/guardian_body.gd").allows(origin,candidate,enemy.pos,body_gap(enemy)):
			return false
	return true

func _add(kind: String, tile: Vector2i, area: Rect2) -> void:
	enemies.append({
		"kind": kind, "home": game._center(tile), "pos": game._center(tile),
		"area": area, "hp": {"bat":2.0,"plant":3.0,"skeleton":4.0}.get(kind,3.0),
		"max_hp": {"bat":2.0,"plant":3.0,"skeleton":4.0}.get(kind,3.0),
		"time": 0.6, "windup": false, "aim": Vector2.ZERO, "flash": 0.0, "counter": 0.0, "landed": false, "death": 0.0, "dash": 0.0, "stun": 0.0, "push": Vector2.ZERO,
	})


func add_arrival(kind:String, destination:Vector2i, area:Rect2) -> void:
	var grid:=AStarGrid2D.new()
	grid.region=Rect2i(-16,-20,80,100);grid.cell_size=Vector2(16,16)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER;grid.update()
	for y in range(-20,80):
		for x in range(-16,64):
			grid.set_point_solid(Vector2i(x,y),not game._fits(game._center(Vector2i(x,y))))
	var visible:=Rect2(game.camera,Vector2(320,224)).grow(28)
	var candidates:Array[Vector2i]=[]
	for tile in game.floor_tiles:
		if grid.is_in_boundsv(tile) and not grid.is_point_solid(tile) and not visible.has_point(game._center(tile)):
			candidates.append(tile)
	candidates.sort_custom(func(a,b):return game._center(a).distance_squared_to(game._center(destination))<game._center(b).distance_squared_to(game._center(destination)))
	for tile in candidates:
		var occupied:=false
		for other in enemies:
			if other.hp>0 and other.pos.distance_to(game._center(tile))<20:occupied=true;break
		if occupied:continue
		var path:=grid.get_id_path(tile,destination)
		if path.size()<2:continue
		_add(kind,tile,area)
		var route:Array[Vector2]=[]
		for cell in path:route.append(game._center(cell))
		enemies.back()["arrival"]=route
		return
	push_error("No offscreen arrival route to %s"%destination)

func _arriving(enemy:Dictionary, delta:float)->bool:
	if not enemy.has("arrival") or enemy.arrival.is_empty():return false
	if enemy.pos.distance_to(game.player)<float(enemy.get("arrival_stop",48)) and _visible(enemy.pos,game.player):
		enemy.arrival.clear();return false
	var target:Vector2=enemy.arrival[0]
	var offset:Vector2=target-enemy.pos
	enemy.pos=game._move(enemy.pos,offset.limit_length(float(enemy.get("arrival_speed",42 if enemy.kind=="bat" else 34))*delta),false,enemy)
	if enemy.pos.distance_to(target)<1:enemy.arrival.pop_front()
	return not enemy.arrival.is_empty()


func respawn() -> void:
	shots.clear()
	seed_art.bursts.clear()
	for enemy in enemies:
		enemy.pos = enemy.home
		enemy.windup = false
		enemy.time = 0.6
		enemy.counter = 0.0
		enemy.landed = false
		enemy.dash = 0.0
		enemy.death = 0.0
		enemy["exposed"] = 0.0
		enemy.stun = 0.0
		enemy.push = Vector2.ZERO


func _visible(from: Vector2, to: Vector2) -> bool:
	var count := maxi(1, int(from.distance_to(to) / 4.0))
	for i in range(1, count + 1):
		if not game._walkable(from.lerp(to, float(i) / count)):
			return false
	return true


func _update_enemies(delta: float) -> void:
	for enemy in enemies:
		enemy["attack_fx"]=maxf(0,enemy.get("attack_fx",0.0)-delta)
		enemy.counter = maxf(0, enemy.counter - delta)
		enemy["exposed"] = maxf(0, enemy.get("exposed", 0.0) - delta)
		enemy.death = maxf(0, enemy.death - delta)
		enemy.flash = maxf(0.0, enemy.flash - delta)
		if enemy.hp <= 0:
			continue
		if enemy.get("ambush",false) and not game.mine.prism_found: continue
		if enemy.stun > 0:
			enemy.stun -= delta
			enemy.pos = game._move(enemy.pos, enemy.push * delta,false,enemy)
			enemy.push = enemy.push.move_toward(Vector2.ZERO, 550 * delta)
			continue
		if _arriving(enemy,delta):continue
		enemy.time -= delta
		var position: Vector2 = enemy.pos
		var offset: Vector2 = game.player - position
		var active: bool = enemy.area.grow(20).has_point(game.player) and offset.length() < 85.0 and _visible(position, game.player)
		if enemy.kind == "bat":
			if enemy.dash > 0:
				enemy.dash -= delta
				enemy.pos = game._move(position, enemy.aim * 115 * delta,false,enemy)
				if enemy.pos.distance_to(game.player) <= body_gap(enemy)+.05 and _visible(enemy.pos, game.player):
					enemy.landed = game._hurt_player(enemy.aim) or enemy.landed
					enemy.dash = 0.0
					enemy.time = float(enemy.get("recovery_duration",.8))
				if enemy.dash <= 0 and not enemy.landed: enemy.counter = 0.8
			elif enemy.windup:
				if enemy.time <= 0:
					enemy.windup = false
					enemy.landed = false
					enemy.dash = 0.32
					enemy.time = 1.0
					game._play("bat_dash")
			elif active and enemy.time <= 0 and _can_begin_attack(enemy):
				if offset.length() < 48:
					enemy.windup = true
					enemy.time = float(enemy.get("windup_duration",0.4))
					enemy.aim = offset.normalized()
				else:
					enemy.pos = game._move(position, offset.normalized() * 32 * delta,false,enemy)
			continue
		if enemy.windup:
			if enemy.time <= 0.0:
				enemy.windup = false
				enemy["attack_fx"]=.28
				enemy.time = float(enemy.get("recovery_duration",1.41 if enemy.kind == "skeleton" else 1.25))
				if enemy.kind == "plant":
					shots.append({"pos": position, "velocity": enemy.aim * 76.0, "life": 3.0, "owner": enemy})
					game._enemy_effect(position, "plant_spit")
				else:
					game._play("swing")
					var landed := false
					if offset.length() < 25.0 and offset.normalized().dot(enemy.aim) >= cos(0.8) and _visible(position, game.player):
						landed = game._hurt_player(enemy.aim)
					if not landed: enemy.counter = 0.8
			continue
		if not active:
			continue
		var range_limit := 115.0 if enemy.kind == "plant" else 24.0
		if offset.length() < range_limit and enemy.time <= 0.0 and _can_begin_attack(enemy):
			enemy.windup = true
			enemy.time = float(enemy.get("windup_duration",0.32 if enemy.kind == "skeleton" else 0.65))
			enemy.aim = offset.normalized()
			if enemy.kind == "skeleton": game._play("warning")
			elif enemy.kind == "plant": game._play("plant_charge")
		elif enemy.kind == "skeleton" and enemy.time < 0.85 and offset.length() > 19.0:
			enemy.pos = game._move(position, offset.normalized() * 27.0 * delta,false,enemy)
	for i in range(shots.size() - 1, -1, -1):
		var shot: Dictionary = shots[i]
		shot.pos += shot.velocity * delta
		shot.life -= delta
		if not game._walkable(shot.pos) or shot.life <= 0:
			if shot.has("owner") and shot.owner.hp > 0: shot.owner.counter = 0.8
			game._enemy_effect(shot.pos, "seed_pop")
			seed_art.burst(shot.pos,game.clock)
			shots.remove_at(i)
		elif shot.pos.distance_to(game.player) < 8.0:
			game._enemy_effect(shot.pos, "seed_pop")
			seed_art.burst(shot.pos,game.clock)
			var landed: bool = game._hurt_player(shot.velocity.normalized())
			if not landed and shot.has("owner") and shot.owner.hp > 0: shot.owner.counter = 0.8
			# Respawning clears every projectile.
			if i < shots.size():
				shots.remove_at(i)
			break


func attack(reach: float, width: float) -> void:
	for enemy in enemies:
		var within:bool=game.enemy_in_reach(enemy.pos,body_gap(enemy)-5.0) if game.has_method("enemy_in_reach") else game._in_reach(enemy.pos,reach,width)
		if enemy.hp > 0 and within and _visible(game.player, enemy.pos):
			var campaign:bool=game.has_method("combat_hit") and game.campaign_mode
			if campaign:
				var target_id:int=enemies.find(enemy)
				if game.struck_enemies.has(target_id):continue
				game.struck_enemies[target_id]=true
			var charged: bool = game.move_name=="charged" if campaign else game.weapon == game.Weapon.SPEAR and game.spear_power
			var breaking:bool=campaign and game.move_name in ["heavy","charged"]
			var interrupting: bool = charged and (enemy.windup or enemy.dash > 0)
			if interrupting and not campaign: enemy["exposed"] = 0.9
			if enemy.get("plated", false) and enemy.get("exposed", 0.0) <= 0 and enemy.counter <= 0 and not breaking:
				game._impact(enemy.pos, "armor")
				continue
			var dealt:float=game.combat_hit(enemy.pos,.12 if enemy.kind=="bat" else .05) if campaign else game.growth.damage()
			if dealt<=0:continue
			if campaign:game.story.training.hit(game.story,enemy,game.move_name)
			if breaking:enemy["exposed"]=2.4 if campaign and game.growth.power>=3 else 1.4
			var countered: bool = enemy.counter > 0
			enemy.counter = 0
			enemy.hp -= dealt
			enemy.flash = 0.07
			var quick_thrust: bool = game.weapon == game.Weapon.SPEAR and not charged
			var preserve_windup: bool = (not breaking if campaign else quick_thrust) and (enemy.windup or enemy.dash > 0)
			enemy.stun = 0 if preserve_windup else ((.7 if charged else .45) if breaking else (.65 if countered else .12))
			if interrupting:
				game._play("confirm")
			if countered:
				game._play("confirm")
			var force: float = (170 if charged else 65) if game.weapon == game.Weapon.SPEAR else (145 if game.combo_step == 2 else 45)
			if campaign:
				force={"light1":15,"light2":20,"light3":45,"thrust":35,"spin":100,"heavy":65,"charged":120,"chase":15}.get(game.move_name,20)
			enemy.push = (game.player.direction_to(enemy.pos) if campaign and game.move_name=="spin" else game.swing_direction) * force
			if not preserve_windup:
				enemy.windup = false
				enemy.dash = 0.0
				enemy.time = float(enemy.get("recovery_duration",0.45))
			if enemy.hp <= 0: enemy.death = DEATH_DURATION
			if enemy.kind == "skeleton":
				game._impact(enemy.pos, "break" if enemy.hp <= 0 else "bone_hit")
			else:
				game._impact(enemy.pos, "bone_hit",false)
				game._enemy_effect(enemy.pos, enemy.kind.replace("skeleton", "bone") + ("_die" if enemy.hp <= 0 else "_hit"), enemy.hp <= 0)
				if enemy.hp <= 0: enemy.death = DEATH_DURATION
	for i in range(shots.size() - 1, -1, -1):
		if game._in_reach(shots[i].pos, reach, width):
			game._enemy_effect(shots[i].pos, "seed_pop")
			seed_art.burst(shots[i].pos,game.clock)
			shots.remove_at(i)


func _draw_enemies() -> void:
	for enemy in enemies:
		var point: Vector2 = enemy.pos.round()
		if enemy.hp <= 0:
			if enemy.death > 0 and not ("wild_art" in game and game.wild_art.enemy(enemy,point)):
				var collapse := Vector2(1 + (DEATH_DURATION - enemy.death) * 1.5, maxf(0.15, enemy.death / DEATH_DURATION))
				game.draw_set_transform(-game.camera.round() + point, 0, collapse)
				game._sprite(BAT if enemy.kind == "bat" else (BONES if enemy.kind == "skeleton" else PLANT), Vector2(-5, -7), false, enemy.death > 0.15)
				game.draw_set_transform(-game.camera.round())
			game.draw_line(point + Vector2(-4, 3), point + Vector2(4, 3), game.SHADE)
			continue
		var sprite: Array = BAT if enemy.kind == "bat" else BONES
		if enemy.kind == "plant":
			sprite = PLANT
		var shadow := PackedVector2Array()
		for step in range(12): shadow.append(point+Vector2(0,4)+Vector2(cos(step*TAU/12)*6,sin(step*TAU/12)*1.6))
		game.draw_colored_polygon(shadow,Color(0.05,0.08,0.08,0.3))
		var bob := int(game.clock * 9) % 2 if enemy.kind == "bat" else 0
		var refined: bool = "wild_art" in game and game.wild_art.enemy(enemy,point)
		if not refined: game._sprite(sprite, point + Vector2(-5, -7 - bob), false, enemy.flash > 0.0)
		_draw_attack_energy(enemy,point)
		if enemy.kind == "bat":
			var wing := 3.0 if int(game.clock * 16) % 2 == 0 else -3.0
			for side in ([] if refined else [-1, 1]):
				game.draw_line(point + Vector2(side * 3, -5), point + Vector2(side * 9, -5 + wing), Color("#ad83bf"), 2)
			if enemy.windup:
				game.draw_line(point + enemy.aim * 10, point + enemy.aim * 32, game.RED)
				game.draw_rect(Rect2(point + Vector2(-1, -26), Vector2(2, 4)), game.GOLD)
		if enemy.kind == "plant" and enemy.windup:
			var mouth: Vector2 = point + enemy.aim * 5 + Vector2(0, -12 if refined else -3)
			game.draw_circle(mouth, 2 + (0.7 - enemy.time) * 4, game.RED)
			game.draw_circle(mouth, 2, game.GOLD)
			for i in range(3):
				var spark: Vector2 = mouth + Vector2.from_angle(i * TAU / 3 + game.clock * 5) * (3 + enemy.time * 10)
				game.draw_rect(Rect2(spark.round(), Vector2(2, 2)), game.MOSS)
		if enemy.kind == "skeleton" and enemy.windup:
			var arc := PackedVector2Array()
			for step in range(13):
				arc.append(point + enemy.aim.rotated(-0.8 + step / 12.0 * 1.6) * 25)
			game.draw_polyline(arc, game.RED, 1)
			game.draw_line(point, point + enemy.aim.rotated(-0.8) * 19, game.CREAM, 2)
			game.draw_rect(Rect2(point + Vector2(-1, -26), Vector2(2, 5)), game.GOLD)
		var maximum:float=enemy.get("max_hp",enemy.hp)
		if enemy.hp<maximum:
			var bar:=Rect2(point+Vector2(-7,-31),Vector2(14,2))
			game.draw_rect(bar,Color("#292d29",.85))
			game.draw_rect(Rect2(bar.position,Vector2(14*clampf(enemy.hp/maximum,0,1),2)),Color("#ba7563"))
	for shot in shots:
		seed_art.projectile(game,shot)
	seed_art.draw_bursts(game)

func _draw_attack_energy(enemy:Dictionary,p:Vector2):
	var color:Color={"bat":Color("#bc8fe3"),"plant":Color("#b8d86b"),"skeleton":Color("#efb16b")}[enemy.kind]
	if enemy.windup and enemy.kind!="skeleton":
		var duration:float=float(enemy.get("windup_duration",.4 if enemy.kind=="bat" else (.65 if enemy.kind=="plant" else .58)))
		var charge:float=clampf(1-enemy.time/duration,0,1)
		var focus:Vector2=p+enemy.aim*(12 if enemy.kind=="skeleton" else 3)+Vector2(0,-5)
		for i in range(6):
			var a:float=i*TAU/6+game.clock*1.8
			var radius:float=17*(1-charge)+4+sin(i*3.0)*2
			var pos:Vector2=focus+Vector2.from_angle(a)*radius*Vector2(1,.65)
			game.draw_line(pos,pos-Vector2.from_angle(a)*(2+charge*3),Color(color,.3+charge*.6),1)
		game.draw_line(focus-Vector2(3+charge*3,0),focus+Vector2(3+charge*3,0),Color(color,.65),1)
		game.draw_circle(focus,1+charge,Color(1,.95,.77,.8))
	if enemy.kind=="skeleton" and enemy.get("attack_fx",0.0)>0:
		var fade:float=enemy.attack_fx/.28
		for band in range(3):
			var arc:=PackedVector2Array()
			for i in range(25):
				arc.append(p+enemy.aim.rotated(lerpf(-.8,.8,i/24.0))*(25-band*3))
			preload("res://scripts/sword_energy.gd").stroke(game,arc,color,fade*(1-band*.22),3.5-band*.7)
	if enemy.kind=="bat" and enemy.dash>0:
		for band in [-1,1]:
			var trail:=PackedVector2Array()
			for i in range(17):
				var t:float=i/16.0
				trail.append(p+Vector2(0,-8)-enemy.aim*(28*(1-t))+enemy.aim.orthogonal()*band*(3+sin(t*PI)*4))
			preload("res://scripts/sword_energy.gd").stroke(game,trail,color,.75,2.5)
	if enemy.kind=="plant" and enemy.get("attack_fx",0.0)>0:
		var t:float=1-enemy.attack_fx/.28
		for i in range(5):
			var ray:Vector2=enemy.aim.rotated((i-2)*.18)
			var at:Vector2=p+ray*(6+t*17)
			game.draw_line(at,at-ray*4,Color(color,(1-t)*.8),1.5,true)

# Teaching groups take turns attacking, while still gathering around the player.
func _can_begin_attack(enemy:Dictionary)->bool:
	if not enemy.has("training_wave"):return true
	for other in enemies:
		if other==enemy or other.hp<=0 or not other.has("training_wave"):continue
		if other.windup or other.dash>0:return false
	return true
