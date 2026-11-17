extends RefCounted
const INK := Color("#343330")
const SOFT := Color("#68645b")
const TEXT := Color("#e3dfd5")
const MANA := Color("#619fe0")
const MANA_INK := Color("#306aa2")
const GOLD := Color("#b8a071")
const PAPER := Color("#c8c3b5")
const MINT := Color("#b8a071")
const LINE := Color("#938d7d")
static var styles:Dictionary={}

static func surface(g:Node2D,rect:Rect2,dark:bool=false,radius:int=5):
	var key:=str(dark)+str(radius)
	if not styles.has(key):
		var style:=StyleBoxFlat.new()
		style.bg_color=Color(INK,0.94) if dark else PAPER
		style.border_color=LINE
		style.set_border_width_all(1)
		style.set_corner_radius_all(radius)
		style.anti_aliasing=true
		style.shadow_size=0
		styles[key]=style
	styles[key].draw(g.get_canvas_item(),rect)
static func panel(g:Node2D,rect:Rect2,paper:bool=false):
	surface(g,rect,not paper,5)
static func rule(g:Node2D,a:Vector2,b:Vector2):
	g.draw_line(a,b,LINE,0.6,true)

static func mana_icon(g:Node2D,p:Vector2,color:Color):
	g.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-4),p+Vector2(3,0),p+Vector2(3,2),p+Vector2(1,4),p+Vector2(-1,4),p+Vector2(-3,2),p+Vector2(-3,0)]),color)
	g.draw_line(p+Vector2(-1,0),p+Vector2(-1,2),Color("#bddcfa"),.7,true)
