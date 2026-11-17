extends "res://tests/record_chapter_one.gd"
var monitor := false
var contact_frames := 0
func check_body() -> void:
	if monitor and game.slime_health>0:
		assert(game.player.distance_to(game.slime)>=14.98,"no penetration in rendered frame")
		if game.player.distance_to(game.slime)<15.2:contact_frames+=1
func snap(id:String) -> void:
	if DisplayServer.get_name()!="headless":root.get_texture().get_image().save_png("res://recordings/body-"+id+".png")
func run() -> void:
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.beats.memory_done=true;game.story.pages.clear();game.story.stage=game.story.Stage.PRIEST
	game.intro_time=0;game.gate_open=true;game.controls.walked=200;game.controls.interacted=true
	game.slime=Vector2(610,265);game.player=Vector2(610,227);game.camera=Vector2(448,125)
	process_frame.connect(check_body);monitor=true
	await frames(65)
	await hold(KEY_DOWN,65);snap("walk-blocked")
	assert(game.player.y<game.slime.y)
	tap(KEY_Q);await hold(KEY_DOWN,50);snap("dash-blocked")
	assert(game.player.y<game.slime.y,"dash cannot cross body")
	await hold(KEY_RIGHT,32);await hold(KEY_DOWN,43);await hold(KEY_LEFT,30)
	await hold(KEY_UP,35);snap("front-contact")
	assert(game.player.y>game.slime.y,"can walk around to the front")
	var hp:float=game.slime_health
	tap(KEY_J);await frames(35)
	assert(game.slime_health<hp,"basic attack works at contact")
	await frames(45)
	# Stage one ordinary charge so the contact response is clearly visible.
	monitor=false;game.cancel_combo();game.hurt_time=0;game.dodge_time=0
	game.player=Vector2(610,310);game.slime=Vector2(610,265)
	game.health=3;game.combat_stats.rng.seed=17
	game.story.stage=game.story.Stage.GUARD;game.patterns.reset()
	game.guard_state=game.Guard.WINDUP;game.guard_time=.8;game.charge_direction=Vector2.DOWN;game.charges_left=0
	monitor=true
	await frames(65);snap("charge-contact")
	assert(game.charge_hit,"charge reaches body contact")
	assert(game.slime.y<game.player.y,"charge does not pass player")
	# Continue normal input after the hit; no frozen actors in the demonstration.
	await hold(KEY_RIGHT,30);await hold(KEY_UP,35)
	await frames(40)
	assert(contact_frames>45)
	print("PASS actual-input walking/dash blockage, circling, contact attack, guardian charge; contact frames=",contact_frames)
	monitor=false;process_frame.disconnect(check_body)
	game.queue_free();await process_frame;quit()
