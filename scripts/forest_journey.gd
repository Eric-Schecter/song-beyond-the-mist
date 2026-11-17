extends RefCounted
const SWITCHES := [Vector2i(16,-6),Vector2i(24,-2)]
var restored:Array[int]=[]
func reset():restored.clear()
func interact(g:Node2D)->bool:
	if g.story_enabled and g.story.stage<g.story.Stage.KEYS:return false
	for i in range(2):
		if i not in restored and g.player.distance_to(g._center(SWITCHES[i]))<20:
			restored.append(i)
			g.growth.award(g,"forest_sluice_%d"%i,20)
			g._play("confirm")
			g._notice("Northwood sluices %d/2 / Follow the woodland paths"%restored.size() if restored.size()<2 else "Both sluices reset. The river seal is released.")
			return true
	return false
func draw(g:Node2D):
	for i in range(2):
		var p:Vector2=g._center(SWITCHES[i])
		g.wild_art.props.draw(g,5,Rect2(p+Vector2(-11,-12),Vector2(22,18)))
		g.draw_line(p+Vector2(-5,-3),p+Vector2(5,-3),g.GOLD if i in restored else g.BLUE,2)
		if i not in restored and g.player.distance_to(p)<20 and not g.story.modal() and not g.growth.opened:
			var skin=preload("res://scripts/ui_skin.gd")
			skin.panel(g,Rect2(p+Vector2(-8,-32),Vector2(16,14)))
			g._label("E",p+Vector2(-3,-21),10,skin.TEXT)
