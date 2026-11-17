extends RefCounted

# Retains the dodge presentation interface; movement and invulnerability remain in valley.gd.
const DURATION := 0.30
var elapsed := DURATION
var direction := Vector2.RIGHT
var traces: Array[Dictionary] = []
var last := Vector2.INF

func start(vector: Vector2) -> void:
	direction=vector
	elapsed=0
	last=Vector2.INF
	traces.clear()

func reset() -> void:
	elapsed=DURATION
	traces.clear()
	last=Vector2.INF

func update(g: Node2D,delta: float) -> void:
	elapsed=minf(DURATION,elapsed+delta)
	for trace in traces: trace.life-=delta
	traces=traces.filter(func(t):return t.life>0)
	if g.dodge_time>0 and (last==Vector2.INF or last.distance_to(g.player)>=5):
		var index:=1 if direction.x>=0 else 3
		if absf(direction.y)>absf(direction.x):index=2 if direction.y<0 else 0
		traces.append({"pos":g.player,"index":index,"life":0.17})
		last=g.player
	if g.attack_time>0 or g.spear_charging or (g.dodge_time<=0 and g.hurt_time>0.86):elapsed=DURATION

func sprite(g: Node2D,index: int,position: Vector2,color: Color,shadow: bool) -> void:
	var atlas=g.village_art.cast
	var source: Rect2=atlas.cells[index]
	var unit: float=23.0/atlas.cells[0].size.y
	var target:=Rect2(position.round()+Vector2((source.position.x-atlas.feet[index].x)*unit,4-source.size.y*unit),source.size*unit)
	if shadow:preload("res://scripts/contact_shadow.gd").draw_at(g,source,target,atlas.soles[index])
	atlas.draw(g,index,target,color)

func draw(g: Node2D) -> bool:
	if g.village_art.cast.texture==null:return false
	for trace in traces:
		var alpha: float=0.34*pow(trace.life/0.17,1.3)
		sprite(g,trace.index,trace.pos,Color(0.68,0.88,0.85,alpha),false)
	if g.dodge_time<=0:return false
	var index:=1 if direction.x>=0 else 3
	if absf(direction.y)>absf(direction.x):index=2 if direction.y<0 else 0
	var side:=direction.orthogonal()
	for offset in [-5.0,5.0]:
		var end: Vector2=g.player-direction*5+side*offset+Vector2(0,-7)
		g.draw_line(end-direction*9,end,Color(0.78,0.88,0.78,0.32),1)
	sprite(g,index,g.player,Color.WHITE,true)
	return true
