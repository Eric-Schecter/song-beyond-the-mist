extends RefCounted

var game: Node2D
const UIStyle = preload("res://scripts/ui_skin.gd")

func objective() -> String:
	if game.story_enabled: return game.story.objective()
	var adventure: String = game.mine.objective()
	if not adventure.is_empty(): return adventure
	if game.mine.treasure_found: return "Exploration complete / Return to the spring"
	if game.relic_found:
		if not game.mine.wall_open: return "Deep Mine / K to break loose rock"
		if not game.mine.door_open: return "Activate both stone pillars together"
		return "Explore the vault; find the Mine Heart"
	if game.cave_open: return "Explore the mine; find the Echo Core"
	if game.rockbreak: return "Rockbreak gained / Return west of the quarry"
	if game.seals.size() < 2: return "River seals %d/2 / Northwood and Quarry" % game.seals.size()
	return "Reach Spring Isle; defeat the guardian"

func interaction() -> String:
	if game.story_enabled:return game.story.hint()
	if game.story_enabled and not game.story.hint().is_empty():
		return "" if game.story.talk_position() != Vector2.INF else game.story.hint()
	var adventure: String = game.mine.interaction_hint()
	if not adventure.is_empty(): return adventure
	var p: Vector2 = game.player
	if p.distance_to(game._center(game.mine.CACHE)) < 22 and not game.mine.cache_found: return "E Supplies"
	if p.distance_to(game._center(game.mine.TREASURE)) < 22 and game.mine.door_open and not game.mine.treasure_found: return "E Mine Heart"
	if p.distance_to(game._center(game.CRACK)) < 27 and not game.cave_open: return "E Break rock" if game.rockbreak else "E Inspect cracked rock"
	if p.distance_to(game._center(game.RELIC)) < 23 and game.cave_open: return "E Camp" if game.relic_found else "E Relic chest"
	if p.distance_to(game._center(game.VILLAGE)) < 25: return "E Camp"
	if p.distance_to(game._center(game.BRIDGE_CAMP)) < 25: return "E Camp"
	for i in range(game.SEALS.size()):
		if i not in game.seals and p.distance_to(game._center(game.SEALS[i])) < 23: return "E Take river seal"
	if p.distance_to(game._center(game.FOUNTAIN)) < 25: return "E Restore spring" if game.slime_health <= 0 else "E Inspect spring"
	return ""

func draw() -> void:
	var g := game
	if g.growth.opened:
		g.growth.draw(g)
		return
	_draw_health_bar()
	var area: String = preload("res://scripts/game_locale.gd").text(g.exploration.area_name())
	var area_width: float = g.font.get_string_size(area,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x + 40
	_panel(Rect2(313-area_width,7,area_width,20))
	g._label(area,Vector2(321-area_width,21),10,TEXT)
	_keycap(Vector2(296,11),"M")
	g.growth.draw(g)
	if g.growth.opened:return
	var goal := preload("res://scripts/game_locale.gd").text(objective())
	var goal_width: float = minf(306,g.font.get_string_size(goal,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x+25)
	_panel(Rect2(7,49,goal_width,18))
	g.draw_colored_polygon(PackedVector2Array([Vector2(17,54),Vector2(20,57),Vector2(17,60),Vector2(14,57)]),ACCENT)
	g._label(goal,Vector2(25,62),10,TEXT)
	if (g.story_enabled and g.story.modal()): return
	if g.message_time > 0 and not g.cleared and not in_combat():
		_toast(g.message)
	if g.cleared:
		UIStyle.panel(g,Rect2(30,64,260,94))
		g._label("The Valley Flows Again", Vector2(77,91), 20, UIStyle.TEXT)
		g._label("C Keep exploring", Vector2(99,115), 12, UIStyle.TEXT)
		g._label("Enter: Starbridge Highlands", Vector2(91,139), 12, UIStyle.PAPER)

const TEXT := UIStyle.TEXT
const ACCENT := UIStyle.MINT
const MUTED := UIStyle.SOFT
const BORDER := UIStyle.LINE

func _panel(rect: Rect2) -> void:
	UIStyle.panel(game,rect)

func _keycap(p: Vector2, key: String) -> void:
	UIStyle.surface(game,Rect2(p,Vector2(12,12)),false,3)
	game._label(key,p+Vector2(3,10),9,UIStyle.INK)

func _toast(value: String) -> void:
	# Wrap rather than spilling long reward messages out of the 320px viewport.
	var lines:Array[String]=game.story.wrapped(value,254)
	var width: float = 0
	for line in lines: width = maxf(width,game.font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x)
	var left := (320-width-20)/2
	_panel(Rect2(left,65,width+20,lines.size()*14+8))
	game.draw_rect(Rect2(left,65,2,lines.size()*14+8), UIStyle.GOLD)
	for i in range(lines.size()): game._label(lines[i],Vector2(left+10,79+i*14),10,UIStyle.TEXT)

func in_combat()->bool:
	if game.player.x>=512 and game.slime_health>0:return true
	for enemy in game.exploration.enemies:
		if enemy.hp>0 and enemy.pos.distance_to(game.player)<80:return true
	return false

var hp_previous:=-1
var hp_max_previous:=-1
var hp_echo:=1.0
var hp_changed_at:=0.0
func _draw_health_bar():
	var g:=game
	var ratio:float=clampf(float(g.health)/maxi(1,g.max_health),0,1)
	if hp_previous<0 or hp_max_previous!=g.max_health or g.health>=hp_previous:
		if g.health!=hp_previous or hp_max_previous!=g.max_health:hp_echo=ratio
	elif g.health<hp_previous:
		hp_echo=float(hp_previous)/g.max_health
		hp_changed_at=g.clock
	hp_previous=g.health;hp_max_previous=g.max_health
	var echo:float=lerpf(hp_echo,ratio,smoothstep(.12,.48,g.clock-hp_changed_at))
	UIStyle.surface(g,Rect2(7,7,132,37),true,5)
	# Reuse the dialogue portrait, with a compact level plate at its foot.
	UIStyle.surface(g,Rect2(11,10,29,29),true,4)
	var atlas=g.village_art.cast
	if atlas.texture!=null:
		var source:Rect2=atlas.cells[0]
		source.size.y*=.56
		var portrait_size:Vector2=source.size*(26.0/maxf(source.size.x,source.size.y))
		g.draw_texture_rect_region(atlas.texture,Rect2(Vector2(25.5,23)-portrait_size/2,portrait_size),source)
	UIStyle.surface(g,Rect2(12,32,27,9),true,2)
	var level_text:="Lv.%d"%g.growth.level
	var level_size:=6 if level_text.length()<6 else 5
	var level_width:float=g.font.get_string_size(level_text,HORIZONTAL_ALIGNMENT_LEFT,-1,level_size).x
	g._label(level_text,Vector2(25.5-level_width/2,38.7),level_size,UIStyle.GOLD)
	var hp_color:=Color("#b35d50") if ratio>.25 else Color("#b9473e")
	_status_bar(Rect2(44,11,89,10),ratio,hp_color,"HP","%d / %d"%[g.health*10,g.max_health*10],echo)
	var mana_color:=UIStyle.MANA if g.stamina_warning<=0 else Color("#bedfff")
	_status_bar(Rect2(44,24,89,9),g.stamina/g.mana_max(),mana_color,"MP","%d / %d"%[int(g.stamina),int(g.mana_max())])
	var experience:float=clampf(float(g.growth.xp)/g.growth.needed(),0,1)
	if xp_previous>=0 and (xp_previous!=g.growth.xp or level_previous!=g.growth.level):
		xp_changed_at=g.clock
		if level_previous!=g.growth.level:level_changed_at=g.clock
	xp_previous=g.growth.xp;level_previous=g.growth.level
	var track:=Rect2(44,38,89,2.5)
	g.draw_style_box(_bar_style(Color("#252522")),track)
	if experience>0:
		var color:Color=UIStyle.GOLD.lerp(Color("#ead7a5"),maxf(0,1-(g.clock-xp_changed_at)/.7))
		g.draw_style_box(_bar_style(color),Rect2(track.position,Vector2(track.size.x*experience,track.size.y)))
	var sweep:float=(g.clock-level_changed_at)/.75
	if sweep>=0 and sweep<1:
		var x:float=track.position.x+sweep*(track.size.x-8)
		g.draw_rect(Rect2(x,track.position.y,8,track.size.y),Color(1,.91,.65,sin(sweep*PI)))

var xp_previous:=-1
var level_previous:=-1
var xp_changed_at:=-10.0
var level_changed_at:=-10.0
var bar_styles:Dictionary={}
func _bar_style(color:Color)->StyleBoxFlat:
	if not bar_styles.has(color):
		var style:=StyleBoxFlat.new()
		style.bg_color=color;style.set_corner_radius_all(2);style.anti_aliasing=true
		# Only stable colors are cached; animated XP tint is transient.
		if bar_styles.size()<12:bar_styles[color]=style
		return style
	return bar_styles[color]
func _status_bar(rect:Rect2,amount:float,color:Color,label:String,value:String,echo:float=0):
	var g:=game
	# Straight frame and straight fills share exactly the same bounds.
	g.draw_rect(rect,Color("#252a2e"))
	if echo>amount:g.draw_rect(Rect2(rect.position,Vector2(rect.size.x*clampf(echo,0,1),rect.size.y)),Color("#c89b70"))
	if amount>0:g.draw_rect(Rect2(rect.position,Vector2(rect.size.x*clampf(amount,0,1),rect.size.y)),color)
	g.draw_rect(rect,Color(UIStyle.LINE,.55),false,.45)
	var baseline:float=rect.position.y+(rect.size.y+7)/2-1
	g._label(label,Vector2(rect.position.x+3,baseline),7,UIStyle.TEXT)
	var width:float=g.font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,7).x
	var pos:=Vector2(rect.end.x-3-width,baseline)
	g.draw_string_outline(g.font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,7,1,Color("#32312e"))
	g._label(value,pos,7,UIStyle.TEXT)
