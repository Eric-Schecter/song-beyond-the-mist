extends RefCounted
const GuideStyle=preload("res://scripts/ui_skin.gd")
var page:=""
var selection:=0
var map_journal:=false
var journal_offset:=0
var lesson_age:=0.0
var walked:=0.0
var interacted:=false
var completed:=[-1.0,-1.0,-1.0]
var learned:Dictionary={}
var active_lesson:=""
var basic_encounter:=false
const LESSONS=["light1","light3","dodge","thrust","spin","heavy","charged","chase"]
const INPUTS={"light1":["J"],"light3":["J","J","J"],"dodge":["Q"],"thrust":["J","K"],"spin":["J","J","K"],"heavy":["K"],"charged":["K"],"chase":["Q","J"]}
func reset():
	learned.clear();active_lesson="";basic_encounter=false
	page="";selection=0;map_journal=false;journal_offset=0;lesson_age=0;walked=0;interacted=false;completed=[-1.0,-1.0,-1.0]
func blocked()->bool:return not page.is_empty()
func open_page(g:Node2D,value:String):
	page=value;g.suspend_combo();g.queue_redraw()
func choose(g:Node2D):
	match selection:
		0:page=""
		1:page="guide"
		2:page="";g.map_open=true;map_journal=false
	g.queue_redraw()
func input(g:Node2D,event:InputEvent)->bool:
	if event is InputEventKey and event.physical_keycode==KEY_TAB:
		if not event.pressed:
			if page=="peek":page="";g.queue_redraw()
		elif not event.echo and page.is_empty() and not g.map_open and not g.growth.opened and not g.story.modal() and g.intro_time<=0 and not g.cleared:
			open_page(g,"peek")
		return true
	if blocked():
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode==KEY_ESCAPE:
				page="pause" if page=="guide" else ""
			elif page=="pause":
				if event.physical_keycode in [KEY_UP,KEY_W]:selection=posmod(selection-1,3)
				elif event.physical_keycode in [KEY_DOWN,KEY_S]:selection=posmod(selection+1,3)
				elif event.physical_keycode in [KEY_ENTER,KEY_SPACE,KEY_E]:choose(g)
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			if page=="pause":
				for i in range(3):
					var hit_rect:Rect2=Rect2(75,68+i*32,170,26)
					if hit_rect.has_point(event.position):selection=i;choose(g);break
			elif page=="guide" and Rect2(235,22,62,22).has_point(event.position):page="pause"
		g.queue_redraw();return true
	if g.map_open:
		if event is InputEventKey and event.pressed and not event.echo:
			match event.physical_keycode:
				KEY_M,KEY_ESCAPE:g.map_open=false
				KEY_LEFT,KEY_RIGHT:map_journal=not map_journal;journal_offset=0
				KEY_UP:journal_offset+=1
				KEY_DOWN:journal_offset=maxi(0,journal_offset-1)
		elif event is InputEventMouseButton and event.pressed:
			if event.button_index==MOUSE_BUTTON_LEFT:
				if Rect2(25,35,57,19).has_point(event.position):map_journal=false
				elif Rect2(87,35,77,19).has_point(event.position):map_journal=true
				elif Rect2(235,35,59,19).has_point(event.position):g.map_open=false
			elif event.button_index==MOUSE_BUTTON_WHEEL_UP:journal_offset+=1
			elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:journal_offset=maxi(0,journal_offset-1)
		g.queue_redraw();return true
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_M:map_journal=false;journal_offset=0
		if event.physical_keycode==KEY_ESCAPE and not g.growth.opened and not g.story.modal() and g.intro_time<=0 and not g.cleared:
			selection=0;open_page(g,"pause");return true
	return false
func tick(g:Node2D,delta:float):
	if blocked() or g.map_open or g.story.modal() or g.growth.opened or g.has_meta("opening_preview") or g.intro_time>0:return
	if g.story_enabled and g.story.stage<g.story.Stage.CHILD and not g.story.beats.memory_active():return
	lesson_age+=delta
	if g.moved:walked+=delta
	lesson_cue(g)
func performed(kind:String):
	# Record successful actions even when performed before their prompt appears.
	if kind in LESSONS:learned[kind]=true
	var index:int=0 if kind.begins_with("light") else (2 if kind=="dodge" else 1)
	if completed[index]<0:completed[index]=lesson_age
func draw(g:Node2D):
	if blocked():
		g.draw_rect(Rect2(0,0,320,224),Color(.08,.08,.07,.48))
		if page=="pause":
			GuideStyle.panel(g,Rect2(61,31,198,155),true)
			center_label(g,"Take a Breath",Rect2(75,38,170,20),14,GuideStyle.INK)
			for i in range(3):
				var rect:=Rect2(75,68+i*32,170,26)
				GuideStyle.surface(g,rect,i==selection,4)
				center_label(g,["Resume","Controls & Moves","Map & Journal"][i],Rect2(rect.position+Vector2(12,3),Vector2(146,21)),11,GuideStyle.TEXT if i==selection else GuideStyle.INK)
			fit_label(g,"Arrows: Select / Enter: Confirm / Esc: Back",Rect2(76,164,170,16),8,GuideStyle.SOFT)
		else:draw_guide(g)
		return
	if g.map_open or g.story.modal() or g.growth.opened or g.has_meta("opening_preview") or g.intro_time>0 or lesson_age<=0:return
	var cue:=lesson_cue(g)
	if cue.is_empty():return
	if INPUTS.has(cue):
		draw_lesson(g,cue)
		return
	var p:=Vector2(144,185+sin(g.clock*3)*1.5)
	GuideStyle.panel(g,Rect2(p-Vector2(42,17) if cue=="move" else p-Vector2(5,5),Vector2(116,42) if cue=="move" else Vector2(42,26)))
	if cue=="move":
		for i in range(4):
			var offset:Vector2=[Vector2(9,-12),Vector2(-7,4),Vector2(9,4),Vector2(25,4)][i]
			keycap(g,["W","A","S","D"][i],p+offset-Vector2(33,0))
			keycap(g,["↑","←","↓","→"][i],p+offset+Vector2(33,0))
	else:keycap(g,cue,p+Vector2(7,1),18)
	# A short progress arc reacts to movement instead of dismissing on a timer.
	if cue=="move":g.draw_line(p+Vector2(-38,22),p+Vector2(-38+108*minf(walked/.65,1),22),GuideStyle.GOLD,1,true)
func lesson_cue(g)->String:
	active_lesson=""
	if g.story.beats.memory_active():return "move" if walked<.65 else ("E" if not g.story.beats.prompt().is_empty() else "")
	if g.story.stage>g.story.Stage.DEFEND:return ""
	if g.story.stage==g.story.Stage.DEFEND and g.story.training.active:
		active_lesson=g.story.training.lesson()
		return active_lesson
	if walked<.65:return "move"
	var index:int=g.story.child_enemy
	if index>=0 and index<g.exploration.enemies.size():
		var enemy:Dictionary=g.exploration.enemies[index]
		if enemy.hp>0 and enemy.pos.distance_to(g.player)<72 and Rect2(g.camera,Vector2(320,224)).has_point(enemy.pos) and g.exploration._visible(g.player,enemy.pos):basic_encounter=true
	for lesson in LESSONS:
		if learned.has(lesson):continue
		if lesson in ["light1","light3","dodge"]:
			if g.story.stage<g.story.Stage.DEFEND and not basic_encounter:break
		elif g.story.stage<g.story.Stage.DEFEND:break
		active_lesson=lesson
		return lesson
	if not interacted and not preload("res://scripts/world_interaction.gd").target(g).is_empty():return "E"
	return ""

func basics_complete()->bool:
	return learned.has("light1") and learned.has("light3") and learned.has("dodge")

func combat_complete()->bool:
	for lesson in LESSONS:
		if not learned.has(lesson):return false
	return true

func draw_lesson(g:Node2D,id:String):
	var keys:Array=INPUTS[id]
	var width:float=76+keys.size()*23
	var p:=Vector2(160-width/2,184)
	GuideStyle.panel(g,Rect2(p,Vector2(width,31)))
	var progress:int=g.chain if g.link_time>0 else 0
	if id=="chase":progress=1 if g.dash_follow>0 else 0
	for i in range(keys.size()):
		var at:=p+Vector2(9+i*23,8)
		keycap(g,keys[i],at)
		if i==mini(progress,keys.size()-1):
			g.draw_rect(Rect2(at-Vector2(1,1),Vector2(16,16)),Color(GuideStyle.GOLD,.6+.4*sin(g.clock*5)),false,1)
		if i>0:preload("res://scripts/move_guide_art.gd").arrow(g,at+Vector2(-7,7),at+Vector2(-2,7),GuideStyle.GOLD)
	var icon:=p+Vector2(width-28,15)
	preload("res://scripts/move_guide_art.gd").draw(g,"light" if id.begins_with("light") else ("dash" if id=="dodge" else id),icon)
	if id=="charged":
		g.draw_arc(p+Vector2(39,15),6,-PI/2,-PI/2+TAU*clampf(g.charge_age/g.charge_limit(),.04,1),24,GuideStyle.GOLD,1.5,true)
	if g.story.training.active:
		for i in range(6):
			g.draw_circle(Vector2(140+i*8,219),1.6 if i==g.story.training.wave else 1.3,GuideStyle.GOLD if i<=g.story.training.wave else GuideStyle.SOFT)
	else:
		for i in range(LESSONS.size()):
			g.draw_circle(Vector2(132+i*8,219),1.3,GuideStyle.GOLD if learned.has(LESSONS[i]) else GuideStyle.SOFT)

func fit_label(g:Node2D,text:String,rect:Rect2,size:int,color:Color):
	text=preload("res://scripts/game_locale.gd").text(text)
	while size>6 and g.font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>rect.size.x:size-=1
	g.draw_string(g.font,rect.position+Vector2(0,rect.size.y-2),text,HORIZONTAL_ALIGNMENT_LEFT,rect.size.x,size,color)
func keycap(g:Node2D,text:String,p:Vector2,width:float=14):
	GuideStyle.surface(g,Rect2(p,Vector2(width,14)),false,3)
	var size:=8
	var w:float=g.font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	fit_label(g,text,Rect2(p+Vector2(maxf(2,(width-w)/2),0),Vector2(width-4,13)),size,GuideStyle.INK)
func draw_guide(g:Node2D):
	GuideStyle.panel(g,Rect2(17,17,286,199),true)
	fit_label(g,"Moves",Rect2(28,23,120,16),12,GuideStyle.INK)
	fit_label(g,"Release Tab" if page=="peek" else "Esc Back",Rect2(235,24,57,12),7,GuideStyle.SOFT)
	fit_label(g,"Input",Rect2(30,42,70,11),7,GuideStyle.SOFT)
	fit_label(g,"Range / Role",Rect2(113,42,100,11),7,GuideStyle.SOFT)
	fit_label(g,"MP",Rect2(259,42,32,11),7,GuideStyle.MANA_INK)
	var rows=[[["J","J","J"],"light","Slash","0"],[["J","K"],"thrust","Thrust","22"],[["J","J","K"],"spin","Spin","30"],[["K"],"heavy","Break","24"],[["K"],"charged","Charge","35"],[["Q","J"],"chase","Chase","+12"],[["Q"],"dash","Dash","18"]]
	for i in range(rows.size()):
		var y:float=56+i*19
		GuideStyle.rule(g,Vector2(28,y-2),Vector2(292,y-2))
		for j in range(rows[i][0].size()):
			keycap(g,rows[i][0][j],Vector2(30+j*23,y+1))
			if j>0:preload("res://scripts/move_guide_art.gd").arrow(g,Vector2(46+(j-1)*23,y+8),Vector2(51+(j-1)*23,y+8),GuideStyle.SOFT)
		if rows[i][1]=="charged":
			g.draw_arc(Vector2(52,y+8),4,0,TAU,16,GuideStyle.SOFT,.7,true)
			g.draw_polyline(PackedVector2Array([Vector2(52,y+5),Vector2(52,y+8),Vector2(54,y+8)]),GuideStyle.SOFT,.7,true)
			fit_label(g,"Hold",Rect2(61,y+2,28,12),7,GuideStyle.SOFT)
		preload("res://scripts/move_guide_art.gd").draw(g,rows[i][1],Vector2(137,y+8))
		fit_label(g,rows[i][2],Rect2(179,y+1,50,14),9,GuideStyle.INK)
		GuideStyle.mana_icon(g,Vector2(250,y+8),GuideStyle.MANA_INK)
		fit_label(g,(["0",str(snappedf(g.move_cost("thrust"),.1)),str(snappedf(g.move_cost("spin"),.1)),"24","35","+"+str(snappedf(g.move_cost("chase"),.1)),"18"])[i],Rect2(260,y+1,30,14),9,GuideStyle.MANA_INK)
	GuideStyle.rule(g,Vector2(28,191),Vector2(292,191))
	var footer=[["WASD","Move"],["E","Use"],["M","Map"],["P","Stats"]]
	for i in range(4):
		var x:float=28+i*67
		var w:float=26 if i==0 else 14
		keycap(g,footer[i][0],Vector2(x,196),w)
		fit_label(g,footer[i][1],Rect2(x+w+3,196,32,14),7,GuideStyle.SOFT)
func map_tabs(g:Node2D):
	for i in range(2):
		var rect:=Rect2(25 if i==0 else 87,35,57 if i==0 else 77,19)
		GuideStyle.surface(g,rect,(i==1)==map_journal,4)
		center_label(g,"Map" if i==0 else "Journal",rect,10,GuideStyle.TEXT if (i==1)==map_journal else GuideStyle.INK)
	g._label("M / Esc Back",Vector2(236,48),8,GuideStyle.SOFT)
func draw_journal(g:Node2D):
	fit_label(g,g.story.objective(),Rect2(28,57,264,14),10,GuideStyle.INK)
	GuideStyle.rule(g,Vector2(28,75),Vector2(292,75))
	var lines:Array[String]=[]
	for entry in g.story.logbook:
		for line in g.story.wrapped("· "+entry,260):lines.append(line)
	journal_offset=clampi(journal_offset,0,maxi(0,lines.size()-7))
	var start:int=maxi(0,lines.size()-7-journal_offset)
	for i in range(mini(7,lines.size()-start)):g._label(lines[start+i],Vector2(28,89+i*12),9,GuideStyle.INK)
	if lines.is_empty():g._label("A new journey awaits.",Vector2(28,91),10,GuideStyle.SOFT)
	fit_label(g,"Left / Right: Tabs   Up / Down / Wheel: Scroll",Rect2(28,165,264,15),8,GuideStyle.SOFT)


func center_label(g:Node2D,text:String,rect:Rect2,size:int,color:Color):
	text=preload("res://scripts/game_locale.gd").text(text)
	while size>6 and g.font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>rect.size.x:size-=1
	var width:float=g.font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	g.draw_string(g.font,rect.position+Vector2((rect.size.x-width)/2,(rect.size.y-g.font.get_height(size))/2+g.font.get_ascent(size)),text,HORIZONTAL_ALIGNMENT_LEFT,rect.size.x,size,color)
