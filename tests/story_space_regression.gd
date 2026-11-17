extends "res://tests/chapter_one_regression.gd"
const SPACE=preload("res://scripts/story_space.gd")
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	var s=g.story;s.stage=s.Stage.CHILD;s.pages.clear()
	var npc:Vector2=g._center(s.MOTHER)
	for dir in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		g.player=npc+dir*28
		g.player=g._move(g.player,-dir*60)
		assert(g.player.distance_to(npc)>=SPACE.GAP,"swept dash cannot tunnel through NPC")
	g.player=npc
	s.speak([["Noah's Mother","测试"]])
	assert(SPACE.body_free(s,g.player),"repair overlapping scripted position")
	assert(g.facing.dot((npc-g.player).normalized())>.99,"face dialogue partner")
	dismiss(g)
	g.player=npc+Vector2(32,0)
	var child:Vector2=g.player+Vector2(16,0)
	assert(SPACE.move_follower(s,child,Vector2(-10,0)).distance_to(g.player)>=SPACE.GAP)
	g.camera=Vector2(0,144)
	g.exploration.add_arrival("skeleton",Vector2i(10,17),Rect2(32,224,224,96))
	var enemy:Dictionary=g.exploration.enemies.back()
	assert(not Rect2(g.camera,Vector2(320,224)).grow(24).has_point(enemy.pos))
	assert(not enemy.arrival.is_empty())
	for i in range(1800):
		var before:Vector2=enemy.pos
		var arriving:bool=g.exploration._arriving(enemy,1.0/60)
		assert(enemy.pos.distance_to(before)<=34.0/60+.01,"continuous arrival without teleport")
		assert(g._fits(enemy.pos),"arrival stays on walkable terrain")
		if not arriving:break
	assert(enemy.arrival.is_empty(),"arrival reaches encounter")
	assert(root.content_scale_aspect==Window.CONTENT_SCALE_ASPECT_IGNORE)
	g.queue_free();await process_frame
	print("PASS four-direction swept NPC collision, dialogue separation/facing, follower gap, offscreen continuous routed arrival and window fill")
	quit()
