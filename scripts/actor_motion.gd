extends RefCounted
# Feet are tracked in world space; render frequency never changes animation speed.
var tracks: Dictionary = {}

func reset() -> void:
	tracks.clear()

func update(g, delta: float) -> void:
	if not g.story_enabled or g.story.game == null: return
	for actor in preload("res://scripts/story_space.gd").actors(g.story):
		var id: String = actor.name
		if not tracks.has(id):
			tracks[id] = {"pos":actor.pos,"facing":Vector2.DOWN,"stride":0.0,"weight":0.0}
		var state: Dictionary = tracks[id]
		var travel: Vector2 = actor.pos-state.pos
		state.pos = actor.pos
		var walking: bool = travel.length() > .015 and travel.length() < 8
		if walking:
			state.facing = travel.normalized()
			state.stride += travel.length()*TAU/30.0
		state.weight = move_toward(state.weight,1.0 if walking else 0.0,delta*12)

func at(p: Vector2) -> Dictionary:
	for state in tracks.values():
		if state.pos.distance_squared_to(p)<1: return state
	return {}

# An articulated cutout rig: head, torso, two arms and two feet have separate
# joints and contact poses. No full-sprite squash, sliding shadow or frame bob.
static func part(g, atlas, index: int, p: Vector2, unit: float, box: Rect2,
		pivot: Vector2, angle: float, shift: Vector2, tint: Color) -> void:
	var region: Rect2 = atlas.cells[index]
	var foot: Vector2 = atlas.feet[index]
	var source := Rect2(region.position+box.position*region.size,box.size*region.size)
	var joint: Vector2 = region.position+pivot*region.size
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for v in [source.position,source.position+Vector2(source.size.x,0),source.end,source.position+Vector2(0,source.size.y)]:
		points.append(p+Vector2(0,4)+(joint-foot+(v-joint).rotated(angle))*unit+shift)
		uvs.append(v/Vector2(atlas.texture.get_size()))
	g.draw_polygon(points,PackedColorArray([tint]),uvs,atlas.texture)

static func shadow(g, p: Vector2, small: bool=false) -> void:
	var points := PackedVector2Array()
	for i in range(16): points.append(p+Vector2(0,3.3)+Vector2(cos(i*TAU/16)*(2.8 if small else 3.7),sin(i*TAU/16)*1.0))
	g.draw_colored_polygon(points,Color(.04,.06,.07,.23))

func walking(g, atlas, index: int, p: Vector2, unit: float, tint: Color) -> bool:
	var state := at(p)
	if state.is_empty() or state.weight < .03: return false
	var side: bool = index%4 in [1,3]
	var gait: float = sin(state.stride)*state.weight
	shadow(g,p,atlas.cells[index].size.y*unit<20)
	var leg_start := .88 if atlas == g.island_art.priest or index/4==1 else .76
	# Rear foot leads while the near foot plants; hems conceal hip seams.
	for i in range(2):
		var sign_step := 1.0 if i==0 else -1.0
		var shift := Vector2(gait*sign_step*1.65 if side else 0,-maxf(0,gait*sign_step)*1.1)
		var box := Rect2(.25 if side else .12+i*.38,leg_start,.58 if side else .40,1-leg_start)
		part(g,atlas,index,p,unit,box,Vector2(.5,leg_start),gait*sign_step*.13 if side else 0,shift,tint.darkened(.15) if i==0 and side else tint)
	var lift := Vector2(0,-absf(gait)*.35)
	part(g,atlas,index,p,unit,Rect2(0,0,1,leg_start+.015),Vector2(.5,.65),gait*.018,lift,tint)
	return true

static func attack_pose(g) -> int:
	var t: float = clampf(g.combo_animation_time()/.32,0,1)
	# Anticipation -> wind-up -> contact -> follow-through -> settle.
	if t<.12:return 0
	if t<.28:return 1
	if t<.40:return 2
	if t<.68:return 3
	if t<.86:return 4
	return 5

static func vertical_attack(g, atlas, index: int, unit: float, tint: Color) -> void:
	var pose := attack_pose(g)
	var north: bool = g.swing_direction.y<0
	var direction := -1.0 if north else 1.0
	var heavy: bool = g.move_name in ["heavy","charged"]
	var strength := 1.25 if heavy else 1.0
	var thrust: float = [0.0,-1.1,-1.8,2.1,1.0,0.0][pose]*strength
	var arm: float = [.0,-.18,-.38,.52,.20,.0][pose]*strength
	var twist: float = [0.0,-.04,-.07,.055,.025,0.0][pose]
	if g.move_name=="light2": arm=-arm;twist=-twist
	var p: Vector2 = g.player
	shadow(g,p)
	# A braced rear foot and a planted lead foot keep the action grounded.
	for i in range(2):
		part(g,atlas,index,p,unit,Rect2(.14+i*.36,.78,.38,.22),Vector2(.33+i*.36,.79),0,
			Vector2((-1 if i==0 else 1)*absf(thrust)*.22,thrust*direction*(.4 if i==0 else -.16)),tint)
	var shift := Vector2(0,thrust*direction*.45)
	if north:
		# The back view is a continuous cloak, not two arms: never pull it apart.
		var hand := p+Vector2(4.0+absf(arm)*2,-10.0-arm*10)+shift
		g.draw_line(p+Vector2(3.5,-10)+shift,hand,Color("#704e2d"),2.4)
		g.draw_rect(Rect2(hand-Vector2(.8,.8),Vector2(1.6,1.6)),Color("#d9b18a"))
		part(g,atlas,index,p,unit,Rect2(0,.34,1,.48),Vector2(.5,.73),twist,shift,tint)
	else:
		part(g,atlas,index,p,unit,Rect2(0,.37,.29,.43),Vector2(.27,.43),arm*.25,shift,tint)
		part(g,atlas,index,p,unit,Rect2(.71,.37,.29,.43),Vector2(.73,.43),arm,shift,tint)
		part(g,atlas,index,p,unit,Rect2(.26,.34,.48,.49),Vector2(.5,.73),twist,shift,tint)
	part(g,atlas,index,p,unit,Rect2(0,0,1,.38),Vector2(.5,.73),twist*.45,shift,tint)
