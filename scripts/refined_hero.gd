extends RefCounted

var poses: Dictionary = {}
var roll = preload("res://scripts/hero_roll.gd").new()
var action_clips = preload("res://scripts/hero_action_clips.gd").new()
var stride := 0.0
var locomotion := 0.0
var previous := Vector2.ZERO
var initialized := false
var floating := Vector2.ZERO
var cloth := 0.0

func _init() -> void:
	for direction in ["south","north","east","west"]:
		var path: String = "res://assets/refined/hero/rotations/%s.png" % direction
		if ResourceLoader.exists(path): poses[direction] = load(path)

func reset() -> void:
	roll.reset()
	initialized = false
	stride = 0
	locomotion = 0
	cloth = 0

func update(g: Node2D, delta: float) -> void:
	roll.update(g,delta)
	var desired: Vector2 = g.player-g.facing*12+Vector2(7 if g.facing.x == 0 else 0,-5)
	if not initialized or previous.distance_to(g.player) > 12:
		previous = g.player
		floating = desired
		initialized = true
	var travel: Vector2 = g.player-previous
	previous = g.player
	var walking: bool = travel.length() > 0.01 and g.attack_time <= 0 and g.dodge_time <= 0
	locomotion = move_toward(locomotion,1.0 if walking else 0.0,delta*9)
	if walking: stride += travel.length()*TAU/40.0
	floating = floating.lerp(desired,1-exp(-delta*15))
	cloth = lerpf(cloth,clampf(-travel.x*2,-2.0,2.0),1-exp(-delta*8))

func weapon_origin(g: Node2D) -> Vector2:
	var desired: Vector2 = g.player-g.facing*12+Vector2(7 if g.facing.x == 0 else 0,-5)
	return (floating if initialized else desired)+Vector2(0,sin(g.clock*TAU/1.8)*2)

# Transform textured pieces without disturbing the world's camera/zoom transform.
func piece(g: Node2D, texture: Texture2D, source: Rect2, origin: Vector2, unit: float, pivot: Vector2, angle: float, offset: Vector2, stretch: Vector2, tint: Color) -> void:
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	for p in [source.position,source.position+Vector2(source.size.x,0),source.end,source.position+Vector2(0,source.size.y)]:
		points.append(origin+((p-pivot)*stretch).rotated(angle)*unit+(pivot+offset)*unit)
		uv.append(p/Vector2(texture.get_size()))
	g.draw_polygon(points,PackedColorArray([tint]),uv,texture)

func draw(g: Node2D) -> bool:
	if roll.draw(g): return true
	if g.story_enabled and g.village_art.draw_hero(self): return true
	if g.has_meta("motion_sample") and action_clips.draw(g,stride,locomotion): return true
	var facing: Vector2 = g.swing_direction if g.attack_time > 0 else g.facing
	var direction := "south"
	if facing.x > 0: direction = "east"
	elif facing.x < 0: direction = "west"
	elif facing.y < 0: direction = "north"
	if not poses.has(direction): return false
	var texture: Texture2D = poses[direction]
	var unit: float = float(g.get_meta("hero_art_scale",1.0))/3.0
	var origin: Vector2 = g.player+Vector2(0,5)-Vector2(24,48)*unit
	preload("res://scripts/contact_shadow.gd").draw_at(g,Rect2(0,0,48,48),Rect2(origin,Vector2(48,48)*unit),Vector2(24,48))
	var side_view: bool = direction in ["east","west"]
	var gait := sin(stride)*locomotion
	var bob := -absf(sin(stride))*1.2*locomotion + sin(g.clock*2.4)*0.3*(1-locomotion)
	var thrust := 0.0
	var twist := 0.0
	var crouch := 0.0
	if g.spear_charging:
		var charge: float = clampf(g.spear_charge/g._charge_duration(),0,1)
		thrust = -2.5*smoothstep(0,0.7,charge)
		crouch = charge*1.1
	elif g.attack_time > 0:
		var spear: bool = g.weapon == g.Weapon.SPEAR
		var duration: float = g.WEAPONS[g.weapon].cooldown if spear else 0.32
		var elapsed: float = g.combo_animation_time() if not spear and g.has_method("combo_animation_time") else duration-g.attack_time
		var prep := 0.10 if spear else 0.08
		var strike_end := 0.17 if spear else 0.15
		if elapsed < prep:
			thrust = lerpf(-2.5 if spear and g.spear_power else 0,-3.0,smoothstep(0,prep,elapsed))
		elif elapsed < strike_end:
			thrust = lerpf(-3.0,5.0 if spear else 3.5,smoothstep(prep,strike_end,elapsed))
		else:
			thrust = lerpf(5.0 if spear else 3.5,0,smoothstep(strike_end,duration,elapsed))
		twist = sin(clampf(elapsed/duration,0,1)*PI)*(1 if g.combo_step != 2 else -1)*0.10
		crouch = absf(thrust)*0.16
	if g.dodge_time > 0:
		thrust = 3.0
		crouch = 2.0
	var tint := Color(1.5,0.7,0.6) if g.hurt_time > 0.86 else Color.WHITE
	var torso_offset := Vector2(facing.x*thrust, bob+crouch+facing.y*thrust*0.35)
	var lean: float = facing.x*thrust*0.028+twist
	# Side sprites have one visible leg. Reuse it as the occluded rear leg,
	# with a darker tint, a separate hip pivot and an opposing stride.
	if side_view:
		var leg := Rect2(20,37,10,11) if direction == "east" else Rect2(18,37,10,11)
		for i in range(2):
			var sign_step := 1.0 if i == 0 else -1.0
			var rotation: float = gait*0.48*sign_step + facing.x*thrust*0.018
			piece(g,texture,leg,origin,unit,Vector2(25 if direction == "east" else 23,37),rotation,Vector2(-facing.x if i == 0 else 0,-maxf(0,gait*sign_step)*1.3),Vector2.ONE,tint.darkened(0.22) if i == 0 else tint)
	else:
		for i in range(2):
			var step := sin(stride+i*PI)*locomotion
			var leg := Rect2(14 if i == 0 else 25,37,10,11)
			piece(g,texture,leg,origin,unit,Vector2(19 if i == 0 else 30,37),step*0.06,Vector2(0,-maxf(0,step)*2.5),Vector2(1,1-absf(step)*0.13),tint)
	# Overlap the hip seam; upper silhouette stays intact while the hem trails.
	var hem_shift := cloth*locomotion+sin(stride-0.7)*locomotion*0.7
	piece(g,texture,Rect2(0,28,48,11),origin,unit,Vector2(24,28),lean*0.7,torso_offset+Vector2(hem_shift,0),Vector2.ONE,tint)
	piece(g,texture,Rect2(0,13,48,17),origin,unit,Vector2(24,36),lean,torso_offset,Vector2.ONE,tint)
	piece(g,texture,Rect2(0,0,48,15),origin,unit,Vector2(24,36),lean*0.65,torso_offset,Vector2.ONE,tint)
	return true
