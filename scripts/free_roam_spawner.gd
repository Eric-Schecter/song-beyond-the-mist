extends RefCounted
var age:=0.0
const LIMIT=8
func eligible(g,p:Vector2)->bool:
	if Rect2(g.camera,Vector2(320,224)).grow(48).has_point(p):return false
	if p.distance_to(g.player)<160:return false
	if not ((p.y<128 and p.x>=240 and p.x<=416) or (p.y>=352 and p.y<480 and p.x>=240 and p.x<=432)):return false
	for landmark in g.SEALS:
		if p.distance_to(g._center(landmark))<28:return false
	return g._fits(p)
func update(g,field,delta:float):
	if not g.story_enabled or g.story.stage!=g.story.Stage.COMPLETE or g.story.modal() or g.map_open or g.growth.opened or g.defeat_age>=0:return
	age+=delta
	if age<8:return
	age=0
	var living:=0
	for e in field.enemies:
		if e.hp>0:living+=1
	if living>=LIMIT:return
	var tiles:Array=g.floor_tiles.keys()
	tiles.shuffle()
	for tile in tiles:
		var point:Vector2=g._center(tile)
		if not eligible(g,point):continue
		var crowded:=false
		for e in field.enemies:
			if e.hp>0 and e.pos.distance_to(point)<32:crowded=true;break
		if crowded:continue
		var slot:=-1
		for i in range(field.enemies.size()):
			var old:Dictionary=field.enemies[i]
			if old.get("free_roam",false) and old.hp<=0 and old.death<=0:slot=i;break
		var kind:String=["bat","skeleton","plant"].pick_random()
		field._add(kind,tile,Rect2(point-Vector2(72,72),Vector2(144,144)))
		field.enemies.back()["free_roam"]=true
		if slot>=0:field.enemies[slot]=field.enemies.pop_back()
		return
