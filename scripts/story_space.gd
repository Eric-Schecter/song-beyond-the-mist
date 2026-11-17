extends RefCounted
# Foot-space bodies, independent of sprite size and facing.
const GAP := 15.0
static func actors(s) -> Array[Dictionary]:
	var g=s.game
	if not s.enabled():return []
	if s.beats.memory_active():return [{"name":"Lia","pos":g._center(s.beats.LIA)}]
	var list:Array[Dictionary]=[
		{"name":"Noah's Mother","pos":g._center(s.MOTHER)},
		{"name":"Noah","pos":s.child_position if s.stage<=s.Stage.RETURN else g._center(Vector2i(8,17))},
		{"name":"Ranger","pos":g._center(s.RANGER)},
		{"name":"Erin","pos":s.beats.priest_pos if s.beats.following or s.beats.purifying or s.beats.purified else g._center(s.priest_tile())}]
	if s.stage>=s.Stage.DEFEND:list.append({"name":"Roland","pos":g._center(s.KNIGHT)})
	if s.stage>=s.Stage.PRIEST and s.stage<s.Stage.HOME:
		list.append({"name":"Refugee","pos":g._center(s.beats.REFUGEES)})
		list.append({"name":"Refugee Child","pos":g._center(s.beats.REFUGEES)+Vector2(-12,4)})
	if s.beats.home_seen:list.append({"name":"Villager","pos":g._center(Vector2i(11,17))+Vector2(sin(g.clock)*9,0)})
	return list
static func body_free(s, p:Vector2, ignore:Vector2=Vector2.INF, gap:float=GAP)->bool:
	for actor in actors(s):
		if actor.pos.distance_to(ignore)<.1:continue
		if p.distance_to(actor.pos)<gap:return false
	return true
static func stage_dialogue(s, lines:Array):
	var g=s.game
	var focus:=Vector2.INF
	var distance:=100.0
	for actor in actors(s):
		for line in lines:
			var name:String=str(line[0])
			if name=="Wounded Knight":name="Roland"
			if name==actor.name and g.player.distance_to(actor.pos)<distance:
				focus=actor.pos;distance=g.player.distance_to(focus)
	# Repair old spawn/teleport overlaps once; ordinary movement never penetrates bodies.
	if not body_free(s,g.player):
		var origin:Vector2=g.player
		var found:=false
		for radius in [16,20,24,32,40]:
			for i in range(16):
				var candidate:Vector2=origin+Vector2.from_angle(i*TAU/16)*radius
				if g._fits(candidate) and body_free(s,candidate):
					g.player=candidate;found=true;break
			if found:break
	if focus.is_finite():g.facing=(focus-g.player).normalized()
static func move_follower(s, point:Vector2, offset:Vector2)->Vector2:
	var candidate:Vector2=s.game._move(point,offset)
	if candidate.distance_to(s.game.player)<GAP:return point
	return candidate if body_free(s,candidate,point,12.0) else point

static func slide(s, origin:Vector2, candidate:Vector2)->Vector2:
	for actor in actors(s):
		var delta:Vector2=candidate-actor.pos
		if delta.length()<GAP and delta.length()>.001:
			candidate=actor.pos+delta.normalized()*(GAP+.001)
	return candidate if s.game._fits(candidate) and body_free(s,candidate) and origin.distance_to(candidate)<4.5 else origin
