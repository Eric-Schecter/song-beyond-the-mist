extends RefCounted
var s
var g
var memory_step:=0
var memory_done:=true
var island_seen:Dictionary={}
var island_confronted:=false
var child_confided:=false
var purifying:=false
var purified:=false
var purification:=0.0
var threats:Array[int]=[]
var bridge_talk:=false
var following:=false
var priest_trail:Array[Vector2]=[]
var priest_pos:=Vector2.ZERO
var home_seen:=false
var home_age:=0.0
var wheel_clock:=0.0
const LIA=Vector2i(11,18)
const GEAR=Vector2i(8,19)
const WATER=Vector2i(35,12)
const REFUGEES=Vector2i(32,12)
func reset(story):
	s=story;g=s.game;memory_step=0;memory_done=true;island_seen.clear();island_confronted=false;child_confided=false;purifying=false;purified=false;purification=0;threats.clear();bridge_talk=false;following=false;home_seen=false;home_age=0;wheel_clock=0
	priest_trail.clear();priest_pos=g._center(s.PRIEST)
func memory_active()->bool:return false # No prior relationship or playable flashback.
func revealing()->bool:return home_seen and home_age<2.8
func wheel_turning()->bool:return g.water_at(g._center(s.CLUES.wheel))>.8
func objective()->String:
	if s.stage==s.Stage.PRIEST and island_confronted and island_seen.size()<2:return "Spring Isle: investigate %d/2"%island_seen.size()
	if purifying:return "Protect the spring from monsters"
	return ""
func prompt()->Dictionary:
	if s.modal():return {}
	if s.stage==s.Stage.PRIEST:
		for tile in [WATER,REFUGEES]:
			if s.near(tile,18):return {"pos":g._center(tile),"key":"E","height":28}
	return {}
func interact()->bool:
	if s.stage==s.Stage.PRIEST:
		if s.near(WATER,18):
			island_seen.water=true;s.speak([["Narrator","Black flakes drift in the shallows beyond the gate. A soaked root is turning black at the edges."],["Hero","If this water reaches our wells... What is Erin holding back?"]]);return true
		if s.near(REFUGEES,18):
			island_seen.refugees=true;s.speak([["Refugee","Do not open the gate! We fled here with our children after drinking the water upstream."],["Refugee","Erin gave us her clean water. She has kept watch for two nights. She says there are families downstream, too."]]);return true
		if s.near(s.PRIEST) and island_seen.size()<2:
			island_confronted=true;s.speak([["Hero","Our wells are dry. This gate... did you close it?"],["Erin","I did. But look at the water beyond it, and speak to the people by the bridge. I cannot let the black mist reach your village."]]);return true
	if s.stage==s.Stage.SPRING and s.near(g.FOUNTAIN,25) and not purified:
		if not purifying:
			purifying=true;purification=0;priest_pos=g._center(g.FOUNTAIN)+Vector2(-22,10)
			for tile in [Vector2i(38,11),Vector2i(42,11)]:
				g.exploration.add_arrival("bat",tile,Rect2(576,128,144,96));threats.append(g.exploration.enemies.size()-1)
			s.speak([["Erin","The core is intact. More black mist is gathering. Guard the spring while I cleanse it."]])
		return true
	return false
func update(delta:float)->bool:
	if g.has_meta("opening_preview"):return false
	if not s.pages.is_empty() or g.map_open or g.growth.opened:return false
	if s.stage==s.Stage.RETURN and not child_confided and g.player.x<335:
		child_confided=true;s.speak([["Noah","Wait... I said I was not scared, but my legs were shaking."],["Hero","It is all right to be scared. Hold my sleeve. We will walk together."],["Noah","My flask is still in one piece. When the river returns, I will not have to come so far for water."]]);return true
	if purifying:
		var alive:=false
		for index in threats:
			if not g.exploration.finished_dying(index):alive=true
		if not alive and g.player.distance_to(g._center(g.FOUNTAIN))<75:purification+=delta
		if purification>=2:
			purifying=false;purified=true
			s.speak([["Erin","The black sediment is clearing. Open the gate."]])
	if s.stage==s.Stage.HOME:
		if not bridge_talk and g.player.x<415:
			bridge_talk=true;following=true
			s.speak([["Erin","I should wait here. If they find out I closed the gate..."],["Hero","You protected them, but they have waited a long time. Come back with me and tell them what happened."],["Erin","...All right. No more hiding behind the gate."]]);return true
		if following:
			if priest_trail.is_empty() or priest_trail.back().distance_to(g.player)>6:priest_trail.append(g.player)
			if not priest_trail.is_empty() and priest_pos.distance_to(g.player)>24:
				var waypoint:Vector2=priest_trail[0]
				priest_pos=preload("res://scripts/story_space.gd").move_follower(s,priest_pos,priest_pos.direction_to(waypoint)*minf(64*delta,priest_pos.distance_to(waypoint)))
				if priest_pos.distance_to(waypoint)<2:priest_trail.pop_front()
		if not home_seen and g.player.x<220:
			home_seen=true;home_age=.001;g._clear_weapon_action()
		if revealing():
			home_age+=delta
			if home_age>=2.8:s.speak([["Narrator","Before you reach home, you hear the waterwheel turning. Villagers emerge with buckets as water flows through Morningwind once more."],["Noah","You are back! Mum, the water really came back!"]])
			return true
	if wheel_turning() and g.player.distance_to(g._center(s.CLUES.wheel))<150:
		wheel_clock-=delta
		if wheel_clock<=0:
			wheel_clock=.8
			if g.sounds.has("wheel_turn"):g._play("wheel_turn")
	return false
func draw():
	if s.stage>=s.Stage.PRIEST and s.stage<s.Stage.HOME:
		var p:Vector2=g._center(WATER)
		g.draw_colored_polygon(PackedVector2Array([p+Vector2(-9,-5),p+Vector2(8,-4),p+Vector2(10,6),p+Vector2(-7,7)]),Color("#393240") if not purified else g.WATER)
		for i in range(4):g.draw_line(p+Vector2(-5+i*3,-1),p+Vector2(-2+i*3,1),Color("#78667c") if not purified else g.BLUE,1)
		var r:Vector2=g._center(REFUGEES)
		g.village_art.actor(1,r,Vector2.DOWN,23);g.village_art.actor(2,r+Vector2(-12,4),Vector2.RIGHT,17)
	if purifying:
		g.draw_line(priest_pos+Vector2(0,-15),g._center(g.FOUNTAIN),Color(.65,.85,.8,.65),1)
		for i in range(5):g.draw_circle(g._center(g.FOUNTAIN)+Vector2.from_angle(g.clock+i*TAU/5)*16,1,g.CREAM)
	if home_seen:
		var p:Vector2=g._center(Vector2i(11,17))+Vector2(sin(g.clock)*9,0)
		g.village_art.actor(1,p,Vector2.RIGHT,23)
		g.draw_rect(Rect2(p+Vector2(5,-1),Vector2(5,5)),Color("#8d7250"));g.draw_line(p+Vector2(5,-1),p+Vector2(10,-1),g.BLUE,1)
