extends "res://tests/record_chapter_one.gd"
var moving_samples := 0
var observed := ""
var last_position := Vector2.ZERO

func check_motion() -> void:
	if observed.is_empty():return
	var p:Vector2=game.story.child_position if observed=="child" else game.story.beats.priest_pos
	if p.distance_to(last_position)>.01:
		var state:Dictionary=game.village_art.motion.at(p)
		assert(not state.is_empty(),"moving NPC must resolve its animation at the rendered position")
		assert(state.weight>0 and state.stride>0,"walking clip must actually advance")
		moving_samples+=1
	last_position=p

func snap(id:String) -> void:
	if DisplayServer.get_name()!="headless":root.get_texture().get_image().save_png("res://recordings/depth-npc-"+id+".png")

func run() -> void:
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.intro_time=0;game.story.pages.clear();game.story.beats.memory_done=true
	game.controls.walked=200;game.controls.interacted=true
	# The guardian is stationary before its story encounter; same production draw path.
	game.story.stage=game.story.Stage.PRIEST
	game.slime=Vector2(606,267);game.player=Vector2(606,249);game.camera=Vector2(448,145)
	await frames(80);assert(game._hero_behind_guard());snap("behind")
	await hold(KEY_RIGHT,25);await hold(KEY_DOWN,32);await hold(KEY_LEFT,25);await frames(40)
	assert(not game._hero_behind_guard());snap("front")
	await hold(KEY_RIGHT,25);await hold(KEY_UP,32);await hold(KEY_LEFT,25);await frames(40)
	assert(game._hero_behind_guard());snap("behind-again")
	tap(KEY_J);await frames(30);await hold(KEY_RIGHT,25);await hold(KEY_DOWN,32);await hold(KEY_LEFT,25);tap(KEY_J);await frames(50)
	# Process-frame checks run after the physics movement and before rendering.
	game.slime_health=0
	process_frame.connect(check_motion)
	game.story.stage=game.story.Stage.RETURN;game.story.beats.child_confided=true
	game.player=Vector2(220,240);game.story.child_position=Vector2(195,240);game.story.footsteps.clear()
	game.camera=Vector2(60,130)
	await frames(3)
	last_position=game.story.child_position;observed="child"
	await hold(KEY_RIGHT,70);snap("child-right");await hold(KEY_LEFT,60);snap("child-left")
	assert(moving_samples>45,"child gait is rendered while following")
	print("PASS child moving animation samples: ",moving_samples)
	observed=""
	# Priestess follows the actual breadcrumb system, including vertical movement.
	game.story.stage=game.story.Stage.HOME;game.story.beats.bridge_talk=true
	game.fountain_awake=true;game.water_fill=1
	game.story.beats.following=true;game.story.beats.purified=true
	game.player=Vector2(610,235);game.story.beats.priest_pos=Vector2(580,235)
	game.story.beats.priest_trail.clear();game.camera=Vector2(448,125)
	await frames(3)
	last_position=game.story.beats.priest_pos;observed="priest";moving_samples=0
	await hold(KEY_RIGHT,50);snap("priest-right")
	await hold(KEY_DOWN,70);snap("priest-down")
	await hold(KEY_LEFT,60);snap("priest-left")
	await hold(KEY_UP,65);snap("priest-up")
	assert(moving_samples>100,"priestess gait is rendered in multiple directions")
	print("PASS foot-depth ordering and priest moving animation samples: ",moving_samples)
	observed="";process_frame.disconnect(check_motion)
	await frames(60)
	game.queue_free();await process_frame;quit()
