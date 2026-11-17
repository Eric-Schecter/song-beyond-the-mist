extends RefCounted
const MIN_CLOSING_TIME=5.0
const GOLD=Color("#bba16e")
const TEXT=Color("#e4d8bd")
static func centered(g,text:String,y:float,size:int,color:Color):
	text=preload("res://scripts/game_locale.gd").text(text)
	var width:float=g.font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	g._label(text,Vector2((320-width)/2,y),size,color)
static func draw(g,closing:bool,age:float):
	g.draw_rect(Rect2(0,0,320,224),Color(.075,.069,.059,.87))
	var fade:float=smoothstep(0,.6,age)
	g.draw_set_transform(Vector2(0,(1-fade)*5))
	# Open corners and fine rules keep the scene visible without a paper panel.
	for x in [19,301]:
		var d:int=1 if x<160 else -1
		for y in [18,206]:
			var v:int=1 if y<112 else -1
			g.draw_polyline(PackedVector2Array([Vector2(x+d*19,y),Vector2(x,y),Vector2(x,y+v*16)]),Color(GOLD,.55*fade),.7,true)
	for side in [-1,1]:
		g.draw_line(Vector2(160+side*28,45),Vector2(160+side*103,45),Color(GOLD,.5*fade),.6,true)
		for i in range(3):
			var p:=Vector2(160+side*(34+i*7),45)
			g.draw_line(p,p+Vector2(side*4,-3),Color(GOLD,.6*fade),.7,true)
	# A lantern over the river: the chapter's recurring promise to leave a light.
	g.draw_arc(Vector2(160,42),15,PI*1.12,TAU*.94,24,Color(GOLD,.6*fade),.7,true)
	g.draw_polyline(PackedVector2Array([Vector2(155,34),Vector2(165,34),Vector2(164,45),Vector2(156,45),Vector2(155,34)]),Color(GOLD,fade),.8,true)
	g.draw_line(Vector2(160,29),Vector2(160,34),Color(GOLD,fade),.7,true)
	g.draw_circle(Vector2(160,40),1.5,Color(TEXT,fade))
	for i in range(2):
		var river:=PackedVector2Array()
		for x in range(-12,13):river.append(Vector2(160+x,50+i*4+sin(x*.22)*1.3))
		g.draw_polyline(river,Color(GOLD,.55*fade),.6,true)
	centered(g,"CHAPTER ONE / COMPLETE" if closing else "CHAPTER ONE",91,9,Color(GOLD,fade))
	centered(g,"A Valley in Need",124,23,Color(TEXT,fade))
	g.draw_line(Vector2(126,143),Vector2(194,143),Color(GOLD,.4*fade),.6,true)
	if closing:
		centered(g,"TO BE CONTINUED",165,15,Color(GOLD,fade))
		centered(g,"More story to come. You may keep exploring.",183,8,Color(TEXT,.75*fade))
	if not closing or age>=MIN_CLOSING_TIME:
		var p:=Vector2(160,200+sin(g.clock*3)*1.4)
		g.draw_polyline(PackedVector2Array([p+Vector2(-3,-2),p+Vector2(0,1),p+Vector2(3,-2)]),Color(GOLD,fade),1,true)
	g.draw_set_transform(Vector2.ZERO)
