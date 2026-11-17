extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	g.story.stage=g.story.Stage.KEYS;g.story.beats.memory_done=true;g.story.pages.clear();g.intro_time=0
	g.slime_health=0;g.exploration.enemies.clear()
	var center:=Vector2(610,265)
	for kind in ["bat","skeleton","plant"]:
		g.exploration.enemies.clear();g.exploration._add(kind,Vector2i(38,16),Rect2(520,160,180,190))
		var enemy:Dictionary=g.exploration.enemies[0]
		var gap:float=g.exploration.body_gap(enemy)
		for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
			enemy.pos=center;g.player=center+direction*32
			g.player=g._move(g.player,-direction*90)
			assert(g.player.distance_to(enemy.pos)>=gap-.01 and (g.player-enemy.pos).dot(direction)>0,kind+" player sweep")
			g.player=center;enemy.pos=center+direction*32
			enemy.pos=g._move(enemy.pos,-direction*90,false,enemy)
			assert(g.player.distance_to(enemy.pos)>=gap-.01 and (enemy.pos-g.player).dot(direction)>0,kind+" enemy sweep")
		enemy.pos=center;g.player=center+Vector2(-gap-.01,0)
		var old:Vector2=g.player
		g.player=g._move(g.player,Vector2(7,-10))
		assert(g.player.y<old.y-5 and g.player.distance_to(center)>=gap-.01,kind+" tangential slide")
		g.player=center+Vector2(-gap-.01,0);g.facing=Vector2.RIGHT;g.swing_direction=Vector2.RIGHT
		g.move_name="light1";g.combat_stats.rng.seed=17
		var hp:float=enemy.hp;g.campaign_strike()
		assert(enemy.hp<hp,kind+" basic attack reaches from contact")
		enemy.hp=0;g.player=center+Vector2(-30,0)
		g.player=g._move(g.player,Vector2(60,0));assert(g.player.x>center.x,kind+" death releases body")
	# One projection must not push the player into another monster.
	g.exploration.enemies.clear()
	for y in [250,270]:
		g.exploration._add("plant",Vector2i(38,16),Rect2(520,160,180,190));g.exploration.enemies.back().pos=Vector2(610,y)
	g.player=Vector2(580,260)
	g.player=g._move(g.player,Vector2(80,0))
	for enemy in g.exploration.enemies:assert(g.player.distance_to(enemy.pos)>=11.99)
	assert(g.player.x<610,"cannot squeeze through gap narrower than player")
	# Bat impact still connects at the new physical contact radius.
	g.exploration.enemies.clear();g.exploration._add("bat",Vector2i(38,16),Rect2(520,160,180,190))
	var bat:Dictionary=g.exploration.enemies[0]
	bat.pos=center;bat.aim=Vector2.RIGHT;bat.dash=.32
	g.player=center+Vector2(22,0);g.health=3;g.hurt_time=0;g.dodge_time=0;g.growth.armor=0;g.combat_stats.evasion=0;g.hit_stop=0
	g.exploration._update_enemies(.15)
	assert(g.health==2 and bat.dash==0 and bat.pos.distance_to(g.player)>=9.99,"bat deals contact damage without crossing")
	g.queue_free();await process_frame
	print("PASS all enemy bodies: bilateral sweep, sliding, basic attacks, death release, crowd gap and bat contact damage")
	quit()
