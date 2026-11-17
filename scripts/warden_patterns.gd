extends RefCounted
var cycle:=0
var kind:=0
var marks:Array[Vector2]=[]
var fired:=false
var skill_cooldown:=0.0
var enraged:=false
var followups:=0
var phase_flash:=0.0
const MELEE_RADIUS:=34.0
const MELEE_HALF_ARC:=1.25
const MELEE_DURATION:=.24
var melee_landed:=false
var sweep_previous:=0.0
func reset():cycle=0;kind=0;marks.clear();fired=false;skill_cooldown=0.0;enraged=false;followups=0;phase_flash=0.0
func select(g:Node2D):
	fired=false;marks.clear();followups=0;melee_landed=false;sweep_previous=0.0
	if skill_cooldown>0:
		kind=3
		followups=1 if enraged else 0
	else:
		kind=cycle%3;cycle+=1;skill_cooldown=3.8 if enraged else 4.8
	if kind==1:
		# A directional fan: retreat or pass behind the guardian.
		for i in range(-2,3):marks.append(g.slime+g.charge_direction.rotated(i*.28)*29)
	elif kind==2:
		# Lock three falling rocks to distinct ground positions, leaving room to move.
		marks.assign([g.player,g.player+Vector2(23,5),g.player+Vector2(-19,-17)])
func update(g:Node2D,delta:float)->bool:
	phase_flash=maxf(0,phase_flash-delta)
	if not enraged and g.slime_health<=9 and g.slime_health>0:
		enraged=true;phase_flash=.7;skill_cooldown=0;cycle=2
		g._play("stone_charge")
	if kind==0:return false
	if g.guard_state==g.Guard.WINDUP:
		if kind==3 and g.guard_time>.22:
			g.charge_direction=g.slime.direction_to(g.player)
		if g.guard_time<=0:
			g.guard_state=g.Guard.CHARGE;g.guard_time=MELEE_DURATION if kind==3 else .24;fired=false;melee_landed=false;sweep_previous=0.0
		return true
	if g.guard_state==g.Guard.CHARGE:
		if not fired:
			fired=true;g._play("swing" if kind==3 else "stone_stop");g.shake_time=.035 if kind==3 else .12
			var hit:=false
			for p in marks:
				g._stone_burst(p,8,.4)
				if kind==2 and p.distance_to(g.player)<12:hit=true
			if kind==1:
				var offset:Vector2=g.player-g.slime
				hit=offset.length()<=44 and (offset.length()<1 or offset.normalized().dot(g.charge_direction)>=cos(.75))
			if hit:g._hurt_player(g.slime.direction_to(g.player))
		if kind==3:
			var progress:float=clampf(1.0-g.guard_time/MELEE_DURATION,0,1)
			var offset:Vector2=g.player-g.slime
			var angle:float=g.charge_direction.angle_to(offset)
			var start:float=lerpf(-MELEE_HALF_ARC,MELEE_HALF_ARC,sweep_previous)-.16
			var end:float=lerpf(-MELEE_HALF_ARC,MELEE_HALF_ARC,progress)+.16
			if not melee_landed and offset.length()<=MELEE_RADIUS and angle>=start and angle<=end:
				melee_landed=true
				g._hurt_player(g.slime.direction_to(g.player))
			sweep_previous=progress
		if g.guard_time<=0:
			if kind==3 and followups>0:
				followups-=1
				g.guard_state=g.Guard.WINDUP;g.guard_time=.5
				g.charge_direction=g.slime.direction_to(g.player)
				g._play("stone_charge")
			else:
				g.guard_state=g.Guard.RECOVERY;g.guard_time=.48 if kind==3 else .55;g.boss_counter=0
		return true
	return false
func draw(g:Node2D):
	if kind==3:return
	if g.guard_state!=g.Guard.WINDUP:return
	if kind==0:
		var start:Vector2=g.slime
		var end:=start
		# Use the same collision checks as the charge; warning stops at the bank.
		for i in range(1,48 if enraged else 45):
			var p:Vector2=start+g.charge_direction*i
			if not g._walkable(p):break
			end=p
		end+=g.charge_direction*12
		start-=g.charge_direction*8
		var side:Vector2=g.charge_direction.orthogonal()*12
		g.draw_colored_polygon(PackedVector2Array([start-side,end-side,end+side,start+side]),Color(.8,.35,.16,.20))
		g.draw_line(start-side,end-side,Color(.94,.65,.30,.8),1)
		g.draw_line(start+side,end+side,Color(.94,.65,.30,.8),1)
		var tip:Vector2=end-g.charge_direction*5
		g.draw_polyline(PackedVector2Array([tip-side*.5,end,tip+side*.5]),g.GOLD,1)
	elif kind==1:
		var fan:=PackedVector2Array([g.slime])
		for i in range(17):fan.append(g.slime+g.charge_direction.rotated(-.75+i*1.5/16)*44)
		fan.append(g.slime)
		g.draw_colored_polygon(fan,Color(.82,.36,.16,.18))
		g.draw_polyline(fan,Color(.94,.65,.30,.65),1)
	else:
		for p in marks:
			var diamond:=PackedVector2Array([p+Vector2(0,-18),p+Vector2(18,0),p+Vector2(0,18),p+Vector2(-18,0),p+Vector2(0,-18)])
			g.draw_colored_polygon(diamond,Color(.82,.36,.16,.16))
			g.draw_polyline(diamond,Color(.94,.65,.30,.7),1)
			g.draw_polyline(PackedVector2Array([p+Vector2(-5,2),p+Vector2(0,-3),p+Vector2(4,1)]),g.GOLD,1)
			if g.guard_time<.4:
				var drop:Vector2=p+Vector2(-6,-8-70*g.guard_time/.4)
				g.wild_art.props.draw(g,3,Rect2(drop,Vector2(12,10)))

func draw_melee(g:Node2D):
	if kind!=3 or g.guard_state!=g.Guard.CHARGE:return
	var progress:float=clampf(1.0-g.guard_time/MELEE_DURATION,0,1)
	var head:float=lerpf(-MELEE_HALF_ARC,MELEE_HALF_ARC,progress)
	var tail:float=maxf(-MELEE_HALF_ARC-.16,head-.8)
	# The bright outer edge uses the exact same radius as the swept hit test.
	var ribbon:=PackedVector2Array()
	var edge:=PackedVector2Array()
	for i in range(17):
		var a:float=lerpf(tail,head+.16,i/16.0)
		var p:Vector2=g.slime+g.charge_direction.rotated(a)*MELEE_RADIUS
		ribbon.append(p);edge.append(p)
	for i in range(16,-1,-1):
		var a:float=lerpf(tail,head+.16,i/16.0)
		ribbon.append(g.slime+g.charge_direction.rotated(a)*15)
	preload("res://scripts/sword_energy.gd").stroke(g,edge,Color("#efb36b"),1.0,6)
	for i in range(5):
		var ray:Vector2=g.charge_direction.rotated(head-i*.13)
		var chip:Vector2=g.slime+ray*(MELEE_RADIUS-3+i)
		g.draw_line(chip,chip-ray*4,Color(1,.8,.5,.7-i*.1),1.3,true)
	var tip:Vector2=g.slime+g.charge_direction.rotated(head)*MELEE_RADIUS
	g.draw_line(g.slime+g.charge_direction.rotated(head)*18,tip,Color(1,.97,.84),2)
