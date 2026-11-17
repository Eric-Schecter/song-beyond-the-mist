extends RefCounted
const S=preload("res://scripts/ui_skin.gd")
static func icon(g:Node2D,id:int,p:Vector2,scale:float=1.0):
	g.draw_set_transform(p,0,Vector2.ONE*scale)
	match id:
		0:
			g.draw_colored_polygon(PackedVector2Array([Vector2(-7,5),Vector2(5,-9),Vector2(10,-11),Vector2(9,-6),Vector2(-3,8)]),S.TEXT)
			g.draw_line(Vector2(-9,3),Vector2(-1,11),S.GOLD,2)
			g.draw_line(Vector2(-6,7),Vector2(-11,12),S.GOLD,3)
		1:
			g.draw_colored_polygon(PackedVector2Array([Vector2(-10,-8),Vector2(0,-11),Vector2(10,-8),Vector2(8,4),Vector2(0,12),Vector2(-8,4)]),S.GOLD)
			g.draw_colored_polygon(PackedVector2Array([Vector2(-7,-6),Vector2(0,-8),Vector2(7,-6),Vector2(5,3),Vector2(0,8),Vector2(-5,3)]),Color("#777e83"))
			g.draw_line(Vector2(0,-7),Vector2(0,7),S.TEXT,1)
		2:
			g.draw_colored_polygon(PackedVector2Array([Vector2(-8,9),Vector2(-4,-3),Vector2(11,-11),Vector2(8,3)]),S.TEXT)
			g.draw_line(Vector2(-9,11),Vector2(8,-7),S.GOLD,1.5)
			for i in range(3):g.draw_line(Vector2(-2+i*3,3-i*3),Vector2(7+i,3-i*3),S.INK,1)
		3:
			S.mana_icon(g,Vector2.ZERO,S.MANA)
		4:
			g.draw_arc(Vector2.ZERO,6,0,TAU,20,S.GOLD,1)
			g.draw_line(Vector2(-9,0),Vector2(9,0),S.GOLD,1);g.draw_line(Vector2(0,-9),Vector2(0,9),S.GOLD,1)
		5:
			for i in range(4):
				var d:=Vector2.from_angle(i*PI/4)*8
				g.draw_line(-d,d,S.GOLD,1.5)
	g.draw_set_transform(Vector2.ZERO)
static func center(g:Node2D,t:String,x:float,y:float,size:int=9,color:Color=S.TEXT):
	t=preload("res://scripts/game_locale.gd").text(t)
	var w:float=g.font.get_string_size(t,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	g._label(t,Vector2(x-w/2,y),size,color)
static func draw(g:Node2D,b):
	g.draw_rect(Rect2(0,0,320,224),Color(0,0,0,.4))
	S.panel(g,Rect2(12,12,296,205))
	g.draw_texture_rect(preload("res://assets/refined/hero/rotations/south.png"),Rect2(20,16,16,25),false)
	g._label("Traveler",Vector2(42,32),13,S.TEXT)
	g._label("Lv.%d"%b.level,Vector2(108,31),9,S.TEXT)
	g.draw_rect(Rect2(145,30,55,2),S.SOFT);g.draw_rect(Rect2(145,30,55*float(b.xp)/b.needed(),2),S.GOLD)
	S.panel(g,Rect2(221,19,46,21));center(g,"＋%d"%b.points,244,34,11,S.GOLD)
	center(g,"×",292,33,14)
	S.rule(g,Vector2(20,44),Vector2(300,44))
	var values=[b.power,b.vitality,b.agility]
	var names=["Fortitude","Swiftblade","Finesse"]
	var can_add:bool=b.points>0
	for i in range(3):
		var x:float=20+i*94
		S.panel(g,Rect2(x,52,88,109))
		if b.selected==i:
			var border:=StyleBoxFlat.new();border.bg_color=Color.TRANSPARENT;border.border_color=S.GOLD;border.set_border_width_all(1);border.set_corner_radius_all(5)
			g.draw_style_box(border,Rect2(x,52,88,109))
		icon(g,[1,2,3][i],Vector2(x+44,72),1.0 if i<2 else 2.5)
		if i!=1:icon(g,0,Vector2(x+56,79),.45)
		center(g,names[i],x+44,99,11)
		center(g,str(values[i]),x+44,115,13)
		g.controls.fit_label(g,["Heavy / Guard","Fast / Critical","Mana / Skills"][i],Rect2(x+5,119,78,14),8,S.GOLD)
		S.panel(g,Rect2(x+28,138,32,18))
		center(g,"+" if can_add else "·",x+44,152,15,S.GOLD if can_add else S.SOFT)
	S.rule(g,Vector2(20,167),Vector2(300,167))
	for i in range(3):
		icon(g,[4,2,5][i],Vector2(30+i*93,179),.55)
		g._label("%.1f%%"%([b.accuracy(),b.evasion(),b.critical()][i]*100),Vector2(42+i*93,183),8,S.TEXT)
	var previews=[
		"Heavy +12%% / HP +10 / Armor %d > %d"%[b.max_armor(),int((b.power+1)/2)],
		"Speed %.0f > %.0f%% / Crit +%.1f%% / Evade +%.1f%%"%[b.light_speed()*100,minf(130,b.light_speed()*100+5),(minf(.45,.20+(b.vitality+1)*.02)-b.critical())*100,(minf(.30,.10+(b.vitality+1)*.015)-b.evasion())*100],
		"MP %.0f > %.0f / Regen %.1f > %.1f / Hit +%.1f%%"%[b.max_mana(),b.max_mana()+10,b.mana_regen(),b.mana_regen()+1.5,(minf(.99,.95+(b.agility+1)*.005)-b.accuracy())*100]]
	g.controls.fit_label(g,previews[b.selected],Rect2(22,187,250,14),7,S.TEXT)
	var perks=["3 pts: Rift 48, Break 2.4s / 6 pts: Rift 64","3 pts: Finisher 40, wide arc / 6 pts: Reach 50","3 pts: Wave 74, MP -15% / 6 pts: Wave 96"]
	g.controls.fit_label(g,perks[b.selected],Rect2(22,200,250,14),7,S.GOLD if values[b.selected]>=3 else S.PAPER)
	S.panel(g,Rect2(278,192,25,19))
	var reset_color:Color=S.GOLD
	g.draw_arc(Vector2(290,201),5,-PI*.75,PI*.8,20,reset_color,1)
	g.draw_polyline(PackedVector2Array([Vector2(283,197),Vector2(286,197),Vector2(286,194)]),reset_color,1)
