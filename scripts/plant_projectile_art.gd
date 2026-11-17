extends RefCounted
var bursts:Array[Dictionary]=[]
func burst(p:Vector2,time:float):
	bursts.append({"pos":p,"time":time})
	if bursts.size()>24:bursts.pop_front()
func projectile(g,shot:Dictionary):
	var p:Vector2=shot.pos
	var d:Vector2=shot.velocity.normalized()
	var side:=d.orthogonal()
	var age:float=3-shot.life
	# Tapered sap trail, separated droplets, and a dark husk enclosing a bright core.
	for i in range(7):
		var t:float=float(i)/7
		var center:Vector2=p-d*(3+i*2.4)+side*sin(age*17-i*.75)*(1+t)
		g.draw_circle(center,2.5*(1-t),Color(.46,.66,.23,(1-t)*.42))
	for i in range(3):
		var t:float=fposmod(age*2+i*.33,1)
		var droplet:Vector2=p-d*(8+t*16)+side*sin(i*4.2+age*4)*(2+t*3)
		g.draw_rect(Rect2(droplet.round(),Vector2.ONE*(2-t)),Color(.74,.84,.37,(1-t)*.65))
	var stream:=PackedVector2Array()
	for i in range(17):
		var t:float=i/16.0
		stream.append(p-d*(22*(1-t))+side*sin(t*PI*2-age*12)*2*(1-t))
	preload("res://scripts/sword_energy.gd").stroke(g,stream,Color("#b6d565"),.65,3)
	var outline:=PackedVector2Array()
	for v in [Vector2(6,0),Vector2(2,-3),Vector2(-2,-4),Vector2(-5,-2),Vector2(-4,2),Vector2(-1,4),Vector2(3,2)]:
		outline.append(p+d*v.x+side*v.y)
	g.draw_colored_polygon(outline,Color("#263d2c"))
	var shell:=PackedVector2Array()
	for v in [Vector2(4,0),Vector2(1,-2),Vector2(-2,-2),Vector2(-3,0),Vector2(-1,2),Vector2(2,1)]:
		shell.append(p+d*v.x+side*v.y)
	g.draw_colored_polygon(shell,Color("#809b3d"))
	g.draw_line(p-d*2-side,p+d*3-side,Color("#e4d98b"),1)
	g.draw_line(p-d,p+d*2,Color("#bed768"),2)
	for sign_side in [-1,1]:
		var thorn:=PackedVector2Array([p-d*2+side*sign_side*2,p-d*5+side*sign_side*5,p+side*sign_side*3])
		g.draw_colored_polygon(thorn,Color("#526d35"))
func draw_bursts(g):
	bursts=bursts.filter(func(b):return g.clock-b.time<.5)
	for b in bursts:
		var age:float=g.clock-b.time
		var fade:float=1-age/.5
		for i in range(9):
			var d:=Vector2.from_angle(i*TAU/9+.2)
			var p:Vector2=b.pos+d*(3+age*(19+i%3*11))+Vector2(0,age*age*34)
			g.draw_line(p,p-d*(2+fade*2),Color(Color("#b4ce63") if i%2==0 else Color("#58733c"),fade),1.5)
		if age<.12:
			g.draw_line(b.pos-Vector2(5,0),b.pos+Vector2(5,0),Color(1,.96,.72,1-age/.12),1)
			g.draw_line(b.pos-Vector2(0,4),b.pos+Vector2(0,4),Color(1,.96,.72,1-age/.12),1)
