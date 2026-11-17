extends RefCounted
# Footprints only: upper artwork stays passable behind tall objects.
static func bodies(g)->Array[Rect2]:
	var result:Array[Rect2]=[]
	for tile in g.journey.SWITCHES:
		result.append(Rect2(g._center(tile)+Vector2(-9,-4),Vector2(18,10)))
	for tile in g.SEALS:
		result.append(Rect2(g._center(tile)+Vector2(-7,-3),Vector2(14,8)))
	result.append(Rect2(g._center(g.exploration.HEALING_CHEST)+Vector2(-6,-4),Vector2(12,10)))
	result.append(Rect2(g._center(g.FOUNTAIN)+Vector2(-12,-5),Vector2(24,12)))
	if g.story_enabled:
		if g.story.clue_available("wheel"):
			result.append(Rect2(g._center(g.story.CLUES.wheel)+Vector2(-8,-3),Vector2(16,8)))
		if g.story.clue_available("marks"):
			result.append(Rect2(g._center(g.story.CLUES.marks)+Vector2(-6,-3),Vector2(12,7)))
	return result
static func blocked(g,p:Vector2)->bool:
	for rect in bodies(g):
		if rect.has_point(p):return true
	return false
