extends RefCounted
const LESSONS=["light3","thrust","spin","heavy","charged","chase"]
const KINDS=["skeleton","skeleton","bat","skeleton","skeleton","plant"]
const COUNTS=[1,2,3,1,1,1]
var active:=false
var wave:=-1
var demonstrated:=false
var pause:=0.0
var recovery_age:=0.0
func reset():active=false;wave=-1;demonstrated=false;pause=0;recovery_age=0
func lesson()->String:return LESSONS[wave] if active and wave>=0 and wave<LESSONS.size() else ""
func start(s):
	reset();active=true;spawn(s,0)
func spawn(s,index:int):
	wave=index;demonstrated=false;pause=0;recovery_age=0;s.raid_indices.clear()
	var g=s.game
	var destinations=[Vector2i(17,14),Vector2i(18,14),Vector2i(17,15)]
	for i in range(COUNTS[wave]):
		var count:int=g.exploration.enemies.size()
		g.exploration.add_arrival(KINDS[wave],destinations[i],Rect2(32,208,352,112))
		if g.exploration.enemies.size()==count:continue
		var e:Dictionary=g.exploration.enemies.back()
		e["training_wave"]=wave;e["arrival_speed"]=135.0;e["arrival_stop"]=60.0 if wave==5 else 22.0
		e["plated"]=wave in [3,4]
		e["windup_duration"]=.4 if KINDS[wave]=="skeleton" else .9
		e["recovery_duration"]=(2.7 if wave==4 else 2.3) if KINDS[wave]=="skeleton" else 1.8
		e.time=1.2+i*.45
		e.hp=5.0 if wave==0 else (4.5 if wave==2 else 4.0)
		e["max_hp"]=e.hp
		s.raid_indices.append(g.exploration.enemies.size()-1)
	g.stamina=g.mana_max()
	g.health=g.max_health
	g.controls.active_lesson=lesson()
func hit(_s,enemy:Dictionary,move:String):
	if active and enemy.get("training_wave",-1)==wave and move==lesson():demonstrated=true
func update(s,delta:float)->bool:
	recovery_age+=delta
	if recovery_age>=5:
		recovery_age=0
		s.game.health=mini(s.game.max_health,s.game.health+1)
	for index in s.raid_indices:
		if not s.game.exploration.finished_dying(index):return false
	pause+=delta
	if pause<.65:return false
	if not demonstrated:
		spawn(s,wave);return false
	if wave+1<LESSONS.size():
		spawn(s,wave+1);return false
	active=false
	return true

func retry(s):
	for index in s.raid_indices:
		s.game.exploration.enemies[index].hp=0
		s.game.exploration.enemies[index].death=0
	spawn(s,wave)
