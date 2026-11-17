extends RefCounted

var trail: Array[Dictionary] = []
var impacts: Array[Dictionary] = []
var swing_id := 0

func reset() -> void:
	trail.clear()
	impacts.clear()
	swing_id = 0

func begin() -> void:
	swing_id += 1

func pose(g: Node2D) -> Dictionary:
	if g.has_method("combo_pose"):return g.combo_pose()
	var elapsed: float = 0.32-g.attack_time
	var reverse: bool = g.combo_step == 2
	var arc: float = g._sword_arc()+0.25
	var progress := smoothstep(0.075,0.205,elapsed)
	var angle: float = g.swing_direction.angle()+lerpf(arc if reverse else -arc,-arc if reverse else arc,progress)
	var direction := Vector2.from_angle(angle)
	var reach: float = g._weapon_reach()
	var grip: Vector2 = g.player+direction*(reach-15)+Vector2(0,-3)
	var float_angle := Vector2(0.35,-1).angle()
	var floating: Vector2 = g._floating_weapon_origin()
	if elapsed < 0.075:
		var t := smoothstep(0,0.075,elapsed)
		grip = floating.lerp(grip,t)
		angle = lerp_angle(float_angle,angle,t)
	elif elapsed > 0.205:
		var t := smoothstep(0.205,0.32,elapsed)
		grip = grip.lerp(floating,t)
		angle = lerp_angle(angle,float_angle,t)
	direction = Vector2.from_angle(angle)
	return {"grip":grip,"tip":grip+direction*15,"direction":direction,"active":elapsed >= 0.075 and elapsed <= 0.205,"reverse":reverse}

func update(g: Node2D, delta: float) -> void:
	for item in trail: item.life -= delta
	trail = trail.filter(func(t): return t.life > 0)
	for item in impacts: item.age += delta
	impacts = impacts.filter(func(t): return t.age < 0.24)
	if g.weapon == g.Weapon.SWORD and g.attack_time > 0:
		var p := pose(g)
		if p.active:
			trail.append({"base":p.grip.lerp(p.tip,0.22),"tip":p.tip,"life":0.14,"id":swing_id,"reverse":p.reverse,"move":g.move_name if g.has_method("combo_pose") else ""})

func impact(point: Vector2, direction: Vector2, heavy: bool, armor: bool) -> void:
	impacts.append({"pos":point+Vector2(0,-4),"direction":direction,"age":0.0,"heavy":heavy,"armor":armor})

func draw_trails(g: Node2D) -> void:
	for i in range(1,trail.size()):
		var a: Dictionary = trail[i-1]
		var b: Dictionary = trail[i]
		if a.id != b.id: continue
		var fade: float = clampf(a.life/0.14,0,1)
		var a_inner: Vector2 = a.tip.lerp(a.base,fade)
		var b_inner: Vector2 = b.tip.lerp(b.base,clampf(b.life/0.14,0,1))
		var hue := Color("#8fe4dd") if b.reverse else Color("#edc477")
		if b.get("move","") in ["light1","light2","light3"]:hue=Color("#e9f0e6")
		elif b.get("move","")in ["thrust","chase"]:hue=Color("#76d7ff")
		elif b.get("move","")=="spin":hue=Color("#89d5ca")
		elif b.get("move","") in ["heavy","charged"]:hue=Color("#ffb554")
		ribbon(g,[a_inner,a.tip,b.tip,b_inner],Color(hue,fade*0.65))
		ribbon(g,[a.tip.lerp(a_inner,0.2),a.tip,b.tip,b.tip.lerp(b_inner,0.2)],Color("#fff8d9",fade*0.92))
		# Detached short edge glints, not full circles drawn before the sword travels.
		if i%3 == 0:
			g.draw_line(a.tip,a.tip.lerp(b.tip,0.7),Color(hue,fade*0.5),0.5)

func draw_idle(g: Node2D) -> void:
	var direction := Vector2(0.35,-1).normalized()
	var grip: Vector2 = g._floating_weapon_origin()
	_blade(g,{"grip":grip,"tip":grip+direction*15,"direction":direction,"active":false})

func draw_weapon(g: Node2D) -> void:
	_blade(g,pose(g))

func _blade(g: Node2D, p: Dictionary) -> void:
	var grip: Vector2 = p.grip
	var tip: Vector2 = p.tip
	var d: Vector2 = p.direction
	var side := d.orthogonal()
	g.draw_colored_polygon(PackedVector2Array([grip-side*1.4,tip,grip+side*1.4]),Color("#e9f4ee"))
	g.draw_line(grip+side*0.7,tip,Color("#a1c5d1"),0.6)
	g.draw_line(grip-d*4,grip,Color("#9b633a"),1.5)
	g.draw_line(grip-side*3,grip+side*3,Color("#f4cb7c"),1)
	g.draw_circle(grip-d*4,0.9,Color("#f4cb7c"))
	if p.active: g.draw_circle(tip,1.0,Color("#fffbe5"))

func draw_impacts(g: Node2D) -> void:
	for hit in impacts:
		var t: float = hit.age/0.24
		var fade := pow(1-t,2)
		var p: Vector2 = hit.pos
		var extent: float = (14.0 if hit.heavy else 10.0)*(0.4+sqrt(t))
		var hue := Color("#8fd8e3") if hit.armor else Color("#ffe4a1")
		var axis: Vector2 = hit.direction.rotated(-0.65 if hit.heavy else 0.55)
		var side := axis.orthogonal()
		var width: float = maxf(0.1,2.5*(1-t))
		g.draw_colored_polygon(PackedVector2Array([p-axis*extent,p+side*width,p+axis*extent,p-side*width]),Color(hue,fade))
		g.draw_colored_polygon(PackedVector2Array([p-side*extent*0.65,p+axis*width,p+side*extent*0.65,p-axis*width]),Color("#fffbed",fade))
		if t < 0.3: g.draw_circle(p,3*(1-t/0.3),Color("#fffbed",fade))
		for i in range(6):
			var ray := Vector2.from_angle(i*TAU/6+0.3)
			var center: Vector2 = p+ray*(3+t*19)
			g.draw_line(center-ray*2*(1-t),center+ray*(1-t),Color(hue,fade),0.7)

# Fast direction changes can fold a trail quad; triangles stay renderable.
func ribbon(g,points:Array,color:Color):
	for ids in [[0,1,2],[0,2,3]]:
		var a:Vector2=points[ids[0]];var b:Vector2=points[ids[1]];var c:Vector2=points[ids[2]]
		if absf((b-a).cross(c-a))>0.1:g.draw_colored_polygon(PackedVector2Array([a,b,c]),color)
