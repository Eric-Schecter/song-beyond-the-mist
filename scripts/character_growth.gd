extends RefCounted
var level:=1
var xp:=0
var points:=0
var power:=0
var vitality:=0
var agility:=0
var armor:=0
var opened:=false
var rewards:Dictionary={}
var allocation_taught:=false
func reset():
	allocation_taught=false
	level=1;xp=0;points=0;power=0;vitality=0;agility=0;armor=0;opened=false;selected=0;rewards.clear()
func needed()->int:return 35+(level-1)*25
# power = 刚毅, vitality = 疾锋, agility = 灵巧. Stored fields remain compatible.
var selected:=0
func accuracy()->float:return minf(.99,.95+agility*.005)
func evasion()->float:return minf(.30,.10+vitality*.015)
func critical()->float:return minf(.45,.20+vitality*.02)
func damage()->float:return 1.0+(level-1)*0.08
func heavy_bonus()->float:return 1.0+power*.12
func light_speed()->float:return minf(1.30,1.0+vitality*.05)
func max_mana()->float:return 100.0+agility*10
func mana_regen()->float:return 12.0+agility*1.5
func max_armor()->int:return power/2
func dodge_cooldown()->float:return 1.0
func allocate(g:Node2D,index:int):
	selected=index
	if points<=0:return
	points-=1
	allocation_taught=true
	match index:
		0:power+=1;g.max_health+=1;g.health+=1;armor=max_armor()
		1:vitality+=1
		2:agility+=1
	g._play("confirm")
func refund(g:Node2D):
	points+=power+vitality+agility;g.max_health-=power;g.health=mini(g.health,g.max_health)
	power=0;vitality=0;agility=0;armor=0;g.stamina=minf(g.stamina,100)
	g._play("confirm")
func mouse(g:Node2D,event:InputEvent):
	if event is InputEventMouseMotion:
		for i in range(3):
			if Rect2(20+i*94,52,88,109).has_point(event.position):selected=i
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		if Rect2(280,18,24,23).has_point(event.position):opened=false
		for i in range(3):
			if Rect2(20+i*94,52,88,109).has_point(event.position):selected=i
			if Rect2(48+i*94,138,32,18).has_point(event.position):allocate(g,i)
		if Rect2(278,192,25,19).has_point(event.position):refund(g)
func award(g:Node2D,id:String,amount:int):
	if rewards.has(id):return
	rewards[id]=true;xp+=amount
	var gained:=false
	while xp>=needed():
		xp-=needed();level+=1;points+=1;gained=true
		if level%2==0:g.max_health+=1;g.health+=1
	if gained:g._play("ember");g._notice("Lv.%d! Attribute point earned. Press P to allocate."%level)
func update(g:Node2D):
	for e in g.exploration.enemies:
		if e.hp<=0:award(g,str(e.kind)+str(e.home),12 if e.kind=="bat" else 18)
	if g.slime_health<=0:award(g,"warden",65)
func input(g:Node2D,event:InputEventKey)->bool:
	if event.pressed and event.physical_keycode==KEY_P:
		opened=not opened;return true
	if not opened:return false
	if event.pressed and event.physical_keycode==KEY_ESCAPE:opened=false
	if event.pressed and not event.echo:
		if event.physical_keycode in [KEY_LEFT,KEY_UP,KEY_A,KEY_W]:selected=posmod(selected-1,3)
		if event.physical_keycode in [KEY_RIGHT,KEY_DOWN,KEY_D,KEY_S]:selected=posmod(selected+1,3)
		if event.physical_keycode in [KEY_E,KEY_ENTER]:allocate(g,selected)
		if event.physical_keycode in [KEY_1,KEY_2,KEY_3]:allocate(g,[KEY_1,KEY_2,KEY_3].find(event.physical_keycode))
		if event.physical_keycode==KEY_R:refund(g)
	return true

func draw(g:Node2D):
	if opened:preload("res://scripts/build_panel.gd").draw(g,self)
	elif points>0 and not allocation_taught and not g.story.modal() and not g.map_open and not g.has_meta("opening_preview") and g.defeat_age<0:
		var s=preload("res://scripts/ui_skin.gd")
		s.panel(g,Rect2(115,150,90,26))
		g.controls.keycap(g,"P",Vector2(123,156))
		g.controls.fit_label(g,"Spend a point",Rect2(144,155,57,15),8,s.GOLD)
