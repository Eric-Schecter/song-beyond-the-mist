extends RefCounted
# Tapered strokes: translucent outer bloom, colored body, narrow light core.
static func stroke(g,points:PackedVector2Array,hue:Color,alpha:float,width:float):
	for i in range(1,points.size()):
		var t:float=(i-.5)/(points.size()-1)
		var taper:float=pow(sin(PI*t),.7)
		if taper<.03:continue
		for layer in range(3):
			var c:Color=hue.lerp(Color("#fffbed"),.8 if layer==2 else 0)
			c.a=alpha*taper*[.10,.42,.9][layer]
			g.draw_line(points[i-1],points[i],c,maxf(.35,width*taper*[2.6,1.0,.22][layer]),true)
static func draw(g,age:float,duration:float):
	var id:String=g.move_name
	var t:float=clampf(age/duration,0,1)
	var fade:float=pow(1-t,1.5)
	var d:Vector2=g.swing_direction
	var side:Vector2=d.orthogonal()
	var reach:float=g._weapon_reach()
	var center:Vector2=g.player+Vector2(0,-3)
	var warm:bool=id in ["heavy","charged"]
	var hue:=Color("#ffc473") if warm else (Color("#7de4ce") if id=="spin" else Color("#8ddcff"))
	if id in ["thrust","chase"]:
		for band in range(3):
			var points:=PackedVector2Array()
			for i in range(25):
				var u:float=i/24.0
				var bow:float=sin(u*PI)*(band-1)*(4 if id=="thrust" else 7)*(1-t)
				points.append(center+d*lerpf(-8 if id=="chase" else 5,reach,u)+side*bow)
			stroke(g,points,hue,fade*(1 if band==1 else .45),3.2 if band==1 else 1.6)
	else:
		var arc:float=2.8 if id=="spin" else (1.45 if id=="charged" else g._sword_arc()*2)
		var rotation:float=d.angle()+t*(2.8 if id=="spin" else .35)
		for band in range(3):
			var points:=PackedVector2Array()
			for i in range(33):
				var u:float=i/32.0
				var angle:float=rotation+lerpf(-arc*.5,arc*.5,u)
				var radius:float=reach*(.8+.2*t)-band*3+sin(u*PI)*2
				points.append(center+Vector2.from_angle(angle)*radius)
			stroke(g,points,hue,fade*(1-band*.24),6 if id=="charged" else (4 if id=="spin" else 2.5))
	# Short drifting fragments dissolve along the outer edge, not a solid outline.
	for i in range(7 if id in ["spin","charged"] else 4):
		var direction:Vector2=d.rotated(sin(i*2.4)*(.9 if warm else .6))
		var point:Vector2=center+direction*(reach*(.65+.05*i)+t*8)
		g.draw_line(point,point-direction*(2+3*(1-t)),Color(hue,fade*.65),.8,true)
