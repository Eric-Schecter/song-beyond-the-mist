extends RefCounted
const Motion=preload("res://scripts/actor_motion.gd")

# A single silhouette for idle and movement: no inconsistent generated frames,
# no raised-foot idle and no per-frame scaling of the head or torso.
static func draw(g:Node2D,atlas,index:int,stride:float,weight:float,tint:Color):
	var unit:float=23.0/atlas.cells[0].size.y
	var gait:float=sin(stride)*weight
	var lift:float=-absf(sin(stride))*.28*weight
	Motion.shadow(g,g.player)
	# Hips overlap the torso. Feet alternate, while the shadow stays on the floor.
	for i in range(2):
		var step:float=gait*(1 if i==0 else -1)
		var offset:=Vector2(step*.12,-maxf(step,0)*1.6)
		Motion.part(g,atlas,index,g.player,unit,Rect2(i*.5,.74,.5,.26),Vector2(.25+i*.5,.74),step*.035,offset,tint)
	# Separate hands/forearms from a stable head and chest; the back view's cloak
	# hides the arms, so only its lower edge sways very slightly.
	if index==0:
		for i in range(2):
			var sign_step:float=1 if i==0 else -1
			Motion.part(g,atlas,index,g.player,unit,Rect2(i*.8,.48,.2,.26),Vector2(.17+i*.66,.48),-gait*sign_step*.055,Vector2(0,lift+gait*sign_step*.55),tint)
		Motion.part(g,atlas,index,g.player,unit,Rect2(.2,.48,.6,.28),Vector2(.5,.7),0,Vector2(0,lift),tint)
		Motion.part(g,atlas,index,g.player,unit,Rect2(0,0,1,.48),Vector2(.5,.7),0,Vector2(0,lift),tint)
	else:
		Motion.part(g,atlas,index,g.player,unit,Rect2(0,.44,1,.32),Vector2(.5,.44),gait*.012,Vector2(0,lift),tint)
		Motion.part(g,atlas,index,g.player,unit,Rect2(0,0,1,.46),Vector2(.5,.7),0,Vector2(0,lift),tint)
