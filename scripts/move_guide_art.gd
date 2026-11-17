extends RefCounted
const INK=Color("#494940")
const ACCENT=Color("#9c7543")
static func arrow(g:Node2D,a:Vector2,b:Vector2,color:Color=INK):
	g.draw_line(a,b,color,1,true)
	var d:Vector2=(b-a).normalized();var s:=d.orthogonal()
	g.draw_colored_polygon(PackedVector2Array([b,b-d*4+s*2,b-d*4-s*2]),color)
static func draw(g:Node2D,kind:String,p:Vector2):
	g.draw_circle(p+Vector2(-13,0),2,INK)
	match kind:
		"light":
			for i in range(3):g.draw_arc(p+Vector2(-13+i*4,0),7,-.9,.9,12,ACCENT,1,true)
		"thrust":
			g.draw_rect(Rect2(p+Vector2(-8,-3),Vector2(30,6)),Color(.6,.49,.3,.15))
			arrow(g,p+Vector2(-9,0),p+Vector2(23,0),ACCENT)
			for x in [5,16]:g.draw_arc(p+Vector2(x,0),3,0,TAU,12,INK,.7,true)
		"spin":
			g.draw_arc(p+Vector2(-5,0),6,-PI*.8,PI*.95,24,ACCENT,1.4,true)
			arrow(g,p+Vector2(-12,-5),p+Vector2(-8,-8),ACCENT)
			for offset in [Vector2(7,0),Vector2(-5,8),Vector2(-5,-8)]:g.draw_circle(p+offset,1.2,INK)
		"heavy","charged":
			arrow(g,p+Vector2(-3,-8),p+Vector2(9,6),ACCENT)
			var shield:=PackedVector2Array([p+Vector2(12,-3),p+Vector2(21,-3),p+Vector2(20,5),p+Vector2(16,8),p+Vector2(12,5),p+Vector2(12,-3)])
			g.draw_polyline(shield,INK,.8,true)
			g.draw_polyline(PackedVector2Array([p+Vector2(17,-3),p+Vector2(14,1),p+Vector2(18,3),p+Vector2(16,7)]),ACCENT,.8,true)
			if kind=="charged":
				for i in range(3):g.draw_line(p+Vector2(-9+i*3,-5),p+Vector2(-7+i*3,-8),ACCENT,.8,true)
		"chase":
			for i in range(3):g.draw_circle(p+Vector2(-19+i*6,0),2,Color(INK,.2+i*.25))
			arrow(g,p+Vector2(-3,0),p+Vector2(14,0),ACCENT)
			g.draw_line(p+Vector2(16,-6),p+Vector2(23,5),INK,1.5,true)
		"dash":
			for i in range(3):g.draw_circle(p+Vector2(-19+i*6,0),2,Color(INK,.2+i*.25))
			arrow(g,p+Vector2(-3,0),p+Vector2(22,0),ACCENT)
