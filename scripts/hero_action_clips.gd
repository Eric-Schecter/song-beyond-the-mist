extends RefCounted

var sheet: Texture2D
var regions: Array[Rect2] = []
var baselines: Array[float] = []
var feet: Array[Vector2] = []
var soles: Array[Vector2] = []
var body_axes: Array[float] = []
var cell := Vector2.ZERO
var pixels_per_unit := 10.0

func _init() -> void:
	if not ResourceLoader.exists("res://assets/refined/hero/east_action_sheet.png"): return
	sheet = load("res://assets/refined/hero/east_action_sheet.png")
	cell = Vector2(sheet.get_size())/Vector2(6,3)
	var picture := sheet.get_image()
	for row in range(3):
		for column in range(6):
			var start := Vector2i(Vector2(column,row)*cell)
			var end := Vector2i(Vector2(column+1,row+1)*cell)
			var bounds := Rect2i(start,end-start)
			var used := _opaque_bounds(picture,bounds)
			regions.append(Rect2(Vector2(start+used.position),Vector2(used.size)))
			baselines.append(float(used.end.y))
			soles.append(preload("res://scripts/refined_atlas.gd").new().foot_anchor(picture,Rect2i(start+used.position,used.size),0.025))
			feet.append(preload("res://scripts/refined_atlas.gd").new().foot_anchor(picture,Rect2i(start+used.position,used.size)))
			# Anchor the torso, not the alternating leading boot.
			var body:=Rect2i(start+used.position+Vector2i(0,int(used.size.y*.08)),Vector2i(used.size.x,int(used.size.y*.24)))
			body_axes.append(preload("res://scripts/refined_atlas.gd").new().foot_anchor(picture,body,1.0).x)
	# One scale for all frames; crouching and raised hands retain their real height.
	pixels_per_unit = regions[6].size.y/23.0

func frame(g: Node2D, stride: float, locomotion: float) -> int:
	if g.attack_time > 0 and g.weapon == g.Weapon.SWORD:
		var t: float = g.combo_animation_time() if g.has_method("combo_animation_time") else 0.32-g.attack_time
		var index := 0
		for boundary in [0.035,0.075,0.135,0.215,0.275]:
			if t >= boundary: index += 1
		return (12 if g.combo_step == 2 else 6)+index
	if g.moved and locomotion > 0.15 and g.attack_time <= 0:
		return [0,1,3,2,4,5][int(fposmod(stride/TAU,1.0)*6)%6]
	return 6

func draw(g: Node2D, stride: float, locomotion: float) -> bool:
	if sheet == null: return false
	var index := frame(g,stride,locomotion)
	var region := regions[index]
	var column := index%6
	var row := index/6
	var offset: Vector2 = region.position-Vector2(column,row)*cell
	var unit := 1.0/pixels_per_unit
	var mirrored: bool = (g.swing_direction.x if g.attack_time > 0 else g.facing.x) < 0
	var locomotion_pose:bool=g.attack_time<=0
	var x: float = (region.position.x-feet[index].x)*unit
	if locomotion_pose:x=(region.position.x-body_axes[index])*unit
	var size := region.size*unit
	if mirrored: x = -(region.end.x-feet[index].x)*unit
	if mirrored and locomotion_pose:x=-(region.end.x-body_axes[index])*unit
	var target := Rect2(g.player+Vector2(x,4+(offset.y-baselines[index])*unit),size)
	if mirrored:
		target.position.x += target.size.x
		target.size.x = -target.size.x
	var color := Color(1.4,0.65,0.6) if g.hurt_time > 0.86 else Color.WHITE
	if locomotion_pose:
		preload("res://scripts/contact_shadow.gd").draw_at(g,Rect2(0,0,1,1),Rect2(g.player+Vector2(0,4),Vector2.ONE),Vector2.ZERO)
	else:preload("res://scripts/contact_shadow.gd").draw_at(g,region,target,soles[index])
	preload("res://scripts/contact_shadow.gd").draw_sprite(g,sheet,region,target,color)
	return true

# Generated transparent sheets can contain almost-invisible alpha outside the art.
# Derive alignment from solid pixels only; the original atlas is not modified.
func _opaque_bounds(image: Image, bounds: Rect2i) -> Rect2i:
	var left := bounds.size.x
	var right := 0
	var top := bounds.size.y
	var bottom := 0
	for y in range(bounds.size.y):
		var row_left := bounds.size.x
		var row_right := -1
		var count := 0
		for x in range(bounds.size.x):
			if image.get_pixel(bounds.position.x+x,bounds.position.y+y).a > 0.6:
				row_left = mini(row_left,x)
				row_right = maxi(row_right,x)
				count += 1
		if count < 4: continue
		left = mini(left,row_left)
		right = maxi(right,row_right)
		top = mini(top,y)
		bottom = maxi(bottom,y)
	return Rect2i(Vector2i(left,top),Vector2i(right-left+1,bottom-top+1))
