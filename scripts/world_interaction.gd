extends RefCounted

static func target(g: Node2D) -> Dictionary:
	if g.growth.opened or g.story.modal() or g.map_open or g.cleared or g.has_meta("opening_preview"): return {}
	var beat_prompt:Dictionary=g.story.beats.prompt()
	if not beat_prompt.is_empty():return beat_prompt
	if g.story.beats.memory_active():return {}
	var npc: Vector2=g.story.talk_position()
	if npc!=Vector2.INF:return {"pos":npc,"key":"E","height":36}
	var clue:Vector2=g.story.clue_target()
	if clue!=Vector2.INF:return {"pos":clue,"key":"E","height":25}
	var candidates: Array = []
	# Match E interaction priority; only advertise unclaimed or reusable objects.
	if g.story_enabled:
		if g.story.stage==g.story.Stage.SPRING:candidates.append([g.FOUNTAIN,25,true,36])
		for i in range(2):candidates.append([g.SEALS[i],16,i not in g.seals,26])
	candidates.append([g.VILLAGE,25,true,24])
	candidates.append([g.BRIDGE_CAMP,25,true,24])
	if not g.story_enabled:
		for i in range(2):candidates.append([g.SEALS[i],23,i not in g.seals,26])
		candidates.append([g.FOUNTAIN,25,not g.fountain_awake,36])
	for c in candidates:
		if c[2] and g.player.distance_to(g._center(c[0]))<c[1]:
			var camp: bool=c[0] in [g.VILLAGE,g.BRIDGE_CAMP]
			return {"pos":Vector2(91,247) if c[0]==g.VILLAGE else g._center(c[0]),"key":"E","height":c[3]}
	return {}

static func draw(g: Node2D) -> void:
	var item:=target(g)
	if item.is_empty():return
	var skin=preload("res://scripts/ui_skin.gd")
	var width:=38.0 if item.key.length()>1 else 16.0
	var p: Vector2=(item.pos+Vector2(-width/2,-item.height-roundf(sin(g.clock*4)))).round()
	var quest:bool=g.story_enabled and g.story.stage<g.story.Stage.COMPLETE and item.pos.distance_to(g.story.quest_marker_position())<4
	if quest:
		var height:float=19 if g.story.stage==g.story.Stage.CHILD else 25
		p=(item.pos+Vector2(-width/2,-height-11)).round()
	skin.panel(g,Rect2(p,Vector2(width,14)))
	if not quest:g.draw_colored_polygon(PackedVector2Array([p+Vector2(width/2-3,13),p+Vector2(width/2,17),p+Vector2(width/2+3,13)]),Color(skin.INK,0.94))
	g._label(item.key,p+Vector2(5,11),10,skin.TEXT)
