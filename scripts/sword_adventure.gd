extends "res://scripts/valley.gd"
@export var campaign_mode:=false
var controls=preload("res://scripts/control_guide.gd").new()
const MOVES={
 "light1":[.24,.08,24.0,.65,.8,0.0],
 "light2":[.28,.10,26.0,.75,.9,0.0],
 "light3":[.42,.16,30.0,.95,1.4,0.0],
 "thrust":[.55,.18,54.0,.15,2.2,22.0],
 "spin":[.75,.32,43.0,PI,1.3,30.0],
 "heavy":[.78,.32,30.0,.48,2.0,24.0],
 "charged":[1.0,.22,54.0,.75,3.8,35.0],
 "chase":[.48,.16,46.0,.25,1.6,12.0]}
var swing_sound_pending:=false
var feedback_fired:=false
var material_voices:Dictionary={}
var audio_variation:=0
var material_counts:Dictionary={}
var move_name:=""
var chain:=0
var link_time:=0.0
var queued:=""
var holding_heavy:=false
var charge_age:=0.0
const DODGE_COST:=18.0
const STAMINA_REGEN:=12.0
var stamina:=100.0
var stamina_delay:=0.0
var stamina_warning:=0.0
var landed:=false
var dash_follow:=0.0
var attack_origin:=Vector2.ZERO
var struck_enemies:Dictionary={}
var boss_struck:=false
var demo_title:="Floating Sword / Combo Trial"
var executed:Array[String]=[]
var hits:Dictionary={}
var combat_stats=preload("res://scripts/combat_roll.gd").new()
var target_evasion:=.08
var damage_popups:Array[Dictionary]=[]
var popup_serial:=0
var results:Array[Dictionary]=[]
var stats_open:=false
var critical_flash:=0.0
var critical_position:=Vector2.ZERO
func _ready():
	# Explicitly fill every window aspect, including fullscreen and live resize.
	get_window().content_scale_size=Vector2i(320,224)
	get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
	get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	super._ready()
	_add_sound("wheel_turn",load("res://assets/audio/cc0_combat/impact_wood.wav"))
	sounds.wheel_turn.volume_db=-23;sounds.wheel_turn.pitch_scale=.65
	for id in ["light1","light2","light3","thrust","spin","heavy","charged","chase","charge","impact","tap","critical"]:
		_add_sound("combo_"+id,preload("res://scripts/cc0_combat_audio.gd").gesture(id))
		sounds["combo_"+id].volume_db=-6
	for material_id in preload("res://scripts/cc0_combat_audio.gd").MATERIALS.keys():
		material_voices[material_id]=[]
		for variant in range(3):
			var voice:AudioStreamPlayer=sounds[material_id] if variant==0 else AudioStreamPlayer.new()
			if variant>0:add_child(voice)
			voice.stream=preload("res://scripts/cc0_combat_audio.gd").material(material_id,variant)
			voice.volume_db=-6
			material_voices[material_id].append(voice)
	for sound_id in ["combo_tap","combo_impact","combo_critical"]:
		sounds[sound_id].max_polyphony=2
		sounds[sound_id].volume_db=-10 if sound_id=="combo_tap" else (-12 if sound_id=="combo_critical" else -7)
	if campaign_mode:
		weapon=Weapon.SWORD;carried_weapon=Weapon.SWORD;return
	story_enabled=false;intro_time=0;gate_open=true;seals.assign([0,1])
	exploration.enemies.clear();player=Vector2(602,270);slime=Vector2(638,270)
	camera=Vector2(448,160);weapon=Weapon.SWORD;slime_health=18;guard_state=Guard.WATCH
	set_meta("motion_sample",true)
	var music:=AudioStreamPlayer.new();music.stream=load("res://assets/music/morning_adventure.wav");music.volume_db=-19;add_child(music);music.play()
func _play(id:String)->void:
	if material_voices.has(id):
		material_counts[id]=int(material_counts.get(id,-1))+1
		sounds[id]=material_voices[id][int(material_counts[id])%3]
	elif id.begins_with("combo_") and id!="combo_charge":
		audio_variation+=1
		sounds[id].pitch_scale=[.975,1.0,1.025][audio_variation%3]
	super._play(id)
	if material_voices.has(id) or id.begins_with("combo_"):
		sounds[id].pitch_scale*=preload("res://scripts/cc0_combat_audio.gd").pitch(id)

func _move_slime(delta:float):
	if campaign_mode:super._move_slime(delta)
func _input(event:InputEvent):
	if defeat_age>=0:return
	if campaign_mode and story.beats.memory_active() and not story.modal() and event is InputEventKey and event.physical_keycode in [KEY_J,KEY_K,KEY_Q,KEY_SPACE,KEY_F,KEY_P,KEY_M,KEY_TAB]:return
	if campaign_mode and controls.input(self,event):return
	if campaign_mode:
		var combat_key:bool=event is InputEventKey and event.physical_keycode in [KEY_J,KEY_K,KEY_Q,KEY_SPACE]
		if growth.opened or story.modal() or map_open or cleared or intro_time>2.5 or not combat_key:
			if event is InputEventKey and event.physical_keycode in [KEY_1,KEY_2] and not growth.opened:return
			super._input(event)
			if growth.opened or story.modal() or map_open:suspend_combo()
			return
	if not event is InputEventKey or event.echo:return
	var code:Key=event.physical_keycode
	if event.pressed and code==KEY_P:stats_open=not stats_open;queue_redraw();return
	if stats_open:
		if event.pressed and code==KEY_ESCAPE:stats_open=false
		return
	if code==KEY_K:
		if event.pressed:
			if attack_time>0:queued="heavy"
			elif dodge_time<=0:
				if stamina<move_cost(heavy_branch()):_reject_stamina()
				else:holding_heavy=true;charge_age=0
		elif holding_heavy:
			holding_heavy=false
			start_move("charged" if charge_age>=charge_limit() else heavy_branch())
		return
	if not event.pressed:return
	if code in [KEY_J,KEY_SPACE]:
		if holding_heavy:return
		if attack_time>0 or dodge_time>0:queued="light"
		else:start_move(light_branch())
	elif code==KEY_Q and not holding_heavy and attack_time<=.1:
		var was_dodging:bool=dodge_time>0
		_start_dodge()
		if not was_dodging and dodge_time>0:dash_follow=1.0;chain=0;link_time=0
func light_branch()->String:
	if dash_follow>0:return "chase"
	return "light%d"%(chain+1 if link_time>0 and chain<3 else 1)
func heavy_branch()->String:
	if link_time>0:
		if chain==1:return "thrust"
		if chain==2:return "spin"
	return "heavy"
func start_move(id:String):
	if stamina<move_cost(id):_reject_stamina();queued="";return
	sounds["combo_charge"].stop()
	feedback_fired=false
	dash_follow=0
	struck_enemies.clear();boss_struck=false
	attack_origin=player
	spend_stamina(move_cost(id));move_name=id;executed.append(id)
	if campaign_mode:controls.performed(id)
	if executed.size()>256:executed.pop_front()
	var aim:=Vector2(int(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-int(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),int(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-int(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if aim.length()>.1:facing=aim.normalized()
	swing_direction=facing;attack_time=MOVES[id][0];landed=false;swing_pending=false
	combo_queued=false;combo_window=0;combo_step=2 if id in ["light2","spin","heavy","charged"] else 1
	chain=int(id.right(1)) if id.begins_with("light") else 0
	if chain==3:chain=0
	link_time=attack_time+.5;queued="";sword_presentation.begin()
	swing_sound_pending=true
func _physics_process(delta:float):
	if defeat_age>=0:
		_tick_defeat(delta)
		return
	if campaign_mode:
		if controls.blocked():queue_redraw();return
		controls.tick(self,delta)
	if campaign_mode and (growth.opened or story.modal() or map_open or cleared):
		suspend_combo();super._physics_process(delta);return
	if stats_open:queue_redraw();return
	if hit_stop>0:
		super._physics_process(delta);return
	if campaign_mode:sync_stats()
	for popup in damage_popups:popup.age+=delta
	damage_popups=damage_popups.filter(func(p):return p.age<p.life)
	critical_flash=maxf(0,critical_flash-delta)
	combo_queued=false;swing_pending=false
	link_time=maxf(0,link_time-delta)
	if dodge_time<=0:dash_follow=maxf(0,dash_follow-delta)
	if holding_heavy:
		charge_age+=delta
		if charge_age>=.12 and charge_age-delta<.12:_play("combo_charge")
		if charge_age>=charge_limit() and charge_age-delta<charge_limit():_play("warning")
	_recover_stamina(delta)
	if campaign_mode and move_name in ["light1","light2","light3"] and attack_time>0:
		attack_time=maxf(.001,attack_time-delta*(growth.light_speed()-1))
	var stopped:bool=hit_stop>0
	super._physics_process(delta)
	if stopped:return
	if attack_time>0 and MOVES.has(move_name):
		var elapsed:float=MOVES[move_name][0]-attack_time
		if swing_sound_pending and elapsed>=float(MOVES[move_name][1])-.07:
			swing_sound_pending=false;_play("combo_"+move_name)
		if move_name in ["thrust","chase"] and elapsed>.02 and elapsed<float(MOVES[move_name][1]):
			for i in range(4):player=_move(player,swing_direction*(120 if move_name=="thrust" else 210)*delta/4)
		if move_name=="spin" and elapsed>=.20 and elapsed<=.55:strike()
		if not landed and elapsed>=float(MOVES[move_name][1]):
			landed=true;strike()
	if attack_time<=0 and dodge_time<=0 and not queued.is_empty():
		start_move(heavy_branch() if queued=="heavy" else light_branch())
func _move_player(delta:float):
	if not holding_heavy:super._move_player(delta)
	if campaign_mode and story.beats.memory_active():
		player=player.clamp(Vector2(72,264),Vector2(200,328))
func _weapon_reach()->float:
	if campaign_mode:
		if move_name=="charged" and growth.power>=3:return 72.0 if growth.power>=6 else 62.0
		if move_name=="heavy" and growth.power>=6:return 40.0
		if move_name=="thrust" and growth.agility>=3:return 96.0 if growth.agility>=6 else 74.0
		if move_name=="light3" and growth.vitality>=6:return 50.0
		if move_name=="light3" and growth.vitality>=3:return 40.0
	return float(MOVES[move_name][2]) if MOVES.has(move_name) else 27.0
func _sword_arc()->float:
	if campaign_mode and move_name=="light3":
		if growth.vitality>=6:return 1.85
		if growth.vitality>=3:return 1.5
	return float(MOVES[move_name][3]) if MOVES.has(move_name) else 1.0
func _in_reach(target:Vector2,depth:float,width:float)->bool:
	if move_name in ["thrust","chase"]:
		var offset:=target-player
		return offset.dot(swing_direction)>=0 and offset.dot(swing_direction)<=depth and absf(offset.cross(swing_direction))<=6.0
	return super._in_reach(target,depth,width)

func enemy_in_reach(target:Vector2,radius:float)->bool:
	if move_name not in ["thrust","chase"]:
		var offset:Vector2=target-player
		var reach:float=_weapon_reach()
		if offset.length()>reach+radius:return false
		if move_name=="spin" or offset.length()<=radius:return true
		var angle:float=absf(swing_direction.angle_to(offset))
		if angle<=_sword_arc():return true
		var edge:Vector2=swing_direction.rotated(signf(swing_direction.cross(offset))*_sword_arc())*reach
		return offset.distance_to(Geometry2D.get_closest_point_to_segment(offset,Vector2.ZERO,edge))<=radius
	var origin:Vector2=attack_origin if move_name=="chase" else player
	var tip:Vector2=player+swing_direction*_weapon_reach()
	var nearest:Vector2=Geometry2D.get_closest_point_to_segment(target,player,tip)
	var distance:float=target.distance_squared_to(nearest)
	if move_name=="chase":
		distance=minf(distance,target.distance_squared_to(Geometry2D.get_closest_point_to_segment(target,origin,player)))
	return distance<=pow(6.0+radius,2)

func strike():
	if campaign_mode:
		campaign_strike();return
	if not boss_struck and enemy_in_reach(slime,12):
		boss_struck=true
		var result:Dictionary=combat_stats.resolve(float(MOVES[move_name][4])*10,target_evasion)
		result["move"]=move_name;results.append(result)
		var value:String=str(result.damage) if result.damage>0 else ("Evade" if result.type=="evade" else "Miss")
		_add_damage_popup(slime,value,result.type=="critical",result.damage==0)
		if result.damage>0:
			slime_health=maxf(.1,slime_health-result.damage/10.0)
			slime_hurt_time=.12;hits[move_name]=int(hits.get(move_name,0))+1
			_impact(slime,"stone_hit");_stone_burst(slime,8,.3)
			impact_feedback(slime,result.type=="critical")
			if result.type=="critical":
				critical_position=slime;critical_flash=.18
				_stone_burst(slime,18,.4)
	if move_name in ["heavy","charged"]:
		_stone_burst(player+swing_direction*26,16 if move_name=="charged" else 8,.35)
func combo_pose()->Dictionary:
	if not MOVES.has(move_name):return {"grip":_floating_weapon_origin(),"tip":_floating_weapon_origin()+Vector2(0,-15),"direction":Vector2.UP,"active":false,"reverse":false}
	var duration:float=MOVES[move_name][0]
	var impact:float=MOVES[move_name][1]
	var elapsed:float=duration-attack_time
	var sweep:float=.12 if move_name=="charged" else (.23 if move_name=="spin" else (.045 if move_name in ["light1","light2","chase"] else .07))
	var t:float=smoothstep(impact-sweep,impact+sweep,elapsed)
	var arc:float=_sword_arc()
	var angle:float=swing_direction.angle()+lerpf(-arc,arc,t)
	if move_name=="light2":angle=swing_direction.angle()+lerpf(arc,-arc,t)
	if move_name=="spin":angle=swing_direction.angle()+lerpf(-PI,PI,t)
	var direction:=Vector2.from_angle(angle)
	var grip:Vector2=player+direction*(_weapon_reach()-15)
	if move_name in ["thrust","chase"]:
		direction=swing_direction;angle=direction.angle();grip=player+direction*lerpf(-9,39 if move_name=="thrust" else 31,t)
	if move_name in ["heavy","charged"]:
		var raised:Vector2=player+Vector2(0,-36 if move_name=="charged" else -27)-swing_direction*(12 if move_name=="charged" else 5)
		grip=raised.lerp(player+swing_direction*(_weapon_reach()-15),t)
		angle=lerp_angle(-PI/2,swing_direction.angle(),t)
	var floating:Vector2=_floating_weapon_origin()
	if elapsed<impact-sweep:
		var prepare:float=clampf(elapsed/maxf(.01,impact-sweep),0,1)
		grip=floating.lerp(grip,prepare)
		angle=lerp_angle(Vector2(.35,-1).angle(),angle,prepare)
	elif elapsed>impact+sweep:
		var recover:float=smoothstep(impact+sweep,duration,elapsed)
		grip=grip.lerp(floating,recover);angle=lerp_angle(angle,Vector2(.35,-1).angle(),recover)
	direction=Vector2.from_angle(angle)
	return {"grip":grip,"tip":grip+direction*15,"direction":direction,"active":elapsed>=impact-sweep and elapsed<=impact+sweep,"reverse":move_name in ["light2","spin"]}
func combo_animation_time()->float:
	if not MOVES.has(move_name):return 0
	var duration:float=MOVES[move_name][0]
	var impact:float=MOVES[move_name][1]
	var elapsed:float=duration-attack_time
	return .135*elapsed/impact if elapsed<impact else lerpf(.135,.32,(elapsed-impact)/(duration-impact))
func _draw_valley_hud():
	if campaign_mode and (growth.opened or story.modal() or map_open):
		super._draw_valley_hud();return
	for popup in damage_popups:
		var age:float=popup.age
		var life:float=popup.life
		var is_crit:bool=popup.critical
		var travel:=Vector2(popup.drift*age*.45,-65*age+38*age*age)
		if is_crit:travel=Vector2(popup.drift*age*.25,-12*smoothstep(0,.08,age)-25*maxf(0,age-.22))
		var pos:Vector2=popup.pos-camera.round()+travel
		var alpha:float=1.0-smoothstep(life-.2,life,age)
		var pop_scale:float=1.0
		if is_crit:pop_scale=lerpf(.78,1.25,smoothstep(0,.04,age)) if age<.04 else lerpf(1.25,1.12,smoothstep(.04,.12,age))
		draw_set_transform(pos,-.055 if is_crit else 0.0,Vector2.ONE*pop_scale)
		var label:String=popup.text
		var digits=preload("res://scripts/damage_digits.gd")
		if is_crit and age<.34:
			var opacity:float=1.0-smoothstep(.16,.34,age)
			var w:float=digits.width(label)/2+4
			var burst:=PackedVector2Array([Vector2(-w-4,-5),Vector2(-w+1,-7),Vector2(-w-1,-12),Vector2(-3,-9),Vector2(0,-14),Vector2(3,-9),Vector2(w+2,-12),Vector2(w,-7),Vector2(w+5,-4),Vector2(w,-2),Vector2(w+1,3),Vector2(3,0),Vector2(0,5),Vector2(-3,0),Vector2(-w-2,3),Vector2(-w,-2)])
			draw_colored_polygon(burst,Color(.69,.12,.09,opacity))
			var inner:=PackedVector2Array()
			for point in burst:inner.append(Vector2(point.x*.76,(point.y+4)*.66-4))
			draw_colored_polygon(inner,Color(1,.39,.13,opacity))
		if popup.zero:
			var color:=Color(.68,.75,.78,alpha)
			var origin:=Vector2(-font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,7).x/2,0)
			draw_string_outline(font,origin,label,HORIZONTAL_ALIGNMENT_LEFT,-1,7,1,Color(.12,.1,.08,alpha))
			_label(label,origin,7,color)
		else:digits.draw(self,label,is_crit,alpha,age)
		draw_set_transform(Vector2.ZERO)
	if critical_flash>0:
		var center:Vector2=critical_position-camera.round()+Vector2(0,-13)
		var length:float=20*(1-critical_flash/.18)+8
		for direction in [Vector2(1,.25),Vector2(-.25,1)]:
			draw_line(center-direction*length,center+direction*length,Color(1,.85,.5,critical_flash/.18),1.5,true)
	if campaign_mode:
		super._draw_valley_hud();return
	var skin=preload("res://scripts/ui_skin.gd")
	skin.panel(self,Rect2(65,8,190,22));_label(demo_title,Vector2(75,23),11,skin.TEXT)
	for i in range(3):
		var x:=110+i*34
		skin.panel(self,Rect2(x,190,28,26));_label(["J","K","Q"][i],Vector2(x+10,207),11,skin.TEXT)
	_label("Light",Vector2(114,185),8,skin.TEXT);_label("Heavy",Vector2(148,185),8,skin.TEXT);_label("Dash",Vector2(182,185),8,skin.TEXT)
	draw_rect(Rect2(110,219,96,2),skin.LINE);draw_rect(Rect2(110,219,96*stamina/mana_max(),2),skin.MANA)
	if holding_heavy:
		draw_rect(Rect2(144,172,28,2),skin.LINE);draw_rect(Rect2(144,172,28*minf(1,charge_age/charge_limit()),2),skin.GOLD)

	if stats_open:
		skin.panel(self,Rect2(32,45,256,126),true)
		_label("Combat Stats",Vector2(47,67),15,skin.INK)
		_label("Base Attack 10",Vector2(194,67),9,skin.SOFT)
		_label("Accuracy %d%% / Evasion %d%%"%[combat_stats.accuracy*100,combat_stats.evasion*100],Vector2(47,92),11,skin.INK)
		_label("Critical %d%% / Critical Damage x%.2f"%[combat_stats.critical*100,combat_stats.critical_multiplier],Vector2(47,113),11,skin.INK)
		_label("Target evasion %d%% / Accuracy, evasion, then critical"%(target_evasion*100),Vector2(47,138),9,skin.SOFT)
		_label("P / Esc Back",Vector2(192,158),9,skin.SOFT)
	else:
		_label("P Stats",Vector2(276,214),8,skin.TEXT)

func _hurt_player(direction:Vector2=Vector2.ZERO)->bool:
	if defeat_age>=0:return false
	if hurt_time>0 or dodge_time>.06:return false
	if combat_stats.rng.randf()<combat_stats.evasion:
		_add_damage_popup(player,"Evade",false,true)
		hurt_time=.15
		return false
	var follow_before_hit:float=dash_follow
	var hurt:bool=super._hurt_player(direction)
	if health>0 and defeat_age<0:dash_follow=follow_before_hit
	if hurt:
		_add_damage_popup(player,"-10",false,false)
		if campaign_mode and story.training.active:
			hurt_time=2.0
			story.training.recovery_age=0
	return hurt

func _tick_defeat(delta:float)->void:
	var was_relocated:bool=defeat_relocated
	super._tick_defeat(delta)
	if defeat_relocated and not was_relocated:
		damage_popups.clear();critical_flash=0;hit_stop=0

func charge_limit()->float:
	return .65
func sync_stats():
	combat_stats.accuracy=growth.accuracy()
	combat_stats.evasion=growth.evasion()
	combat_stats.critical=growth.critical()
func cancel_combo():
	if sounds.has("combo_charge"):sounds["combo_charge"].stop()
	queued="";holding_heavy=false;charge_age=0;chain=0;link_time=0;dash_follow=0
	attack_time=0;swing_pending=false;swing_sound_pending=false
func _clear_weapon_action():
	super._clear_weapon_action()
	if campaign_mode:cancel_combo()
func _reset():
	super._reset()
	if campaign_mode:
		controls.reset()
		cancel_combo();feedback_fired=false;shake_strength=2;stamina=100;stamina_delay=0;stamina_warning=0;damage_popups.clear();results.clear();critical_flash=0
		weapon=Weapon.SWORD;carried_weapon=weapon;sync_stats()
func _notification(what:int):
	super._notification(what)
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_combo()
		if controls.page=="peek":controls.page=""
func impact_feedback(point:Vector2,critical:bool):
	var profile:Array={"light1":[.045,.7],"light2":[.05,.9],"light3":[.075,1.3],"thrust":[.065,1.2],"spin":[.065,1.1],"heavy":[.09,1.9],"charged":[.115,2.7],"chase":[.07,1.3]}.get(move_name,[.045,.7])
	hit_stop=maxf(hit_stop,minf(.13,float(profile[0])+(.025 if critical else 0)))
	shake_strength=minf(3,float(profile[1])+(.5 if critical else 0))
	shake_direction=swing_direction.normalized();shake_duration=.18 if critical or move_name in ["heavy","charged"] else .12
	shake_time=maxf(shake_time,shake_duration)
	if not feedback_fired:
		_play("combo_impact" if move_name in ["heavy","charged"] else "combo_tap")
		feedback_fired=true
	if critical:_play("combo_critical")
	var heavy:bool=move_name in ["heavy","charged","light3"]
	sword_presentation.impact(point,swing_direction,heavy or critical,false)
	for i in range(9 if heavy or critical else 4):
		var direction:=swing_direction.rotated((i%5-2)*.32)
		effects.append({"pos":point+Vector2(0,-5),"velocity":direction*(55+i*7),"life":.16+i*.012,"color":GOLD if heavy or critical else CREAM,"bone":false,"streak":direction})

func combat_hit(point:Vector2,evasion:float,modifier:float=1.0)->float:
	sync_stats()
	var factor:float=MOVES.get(move_name,MOVES.light1)[4]
	var result:Dictionary=combat_stats.resolve(growth.damage()*10*factor*modifier*(growth.heavy_bonus() if move_name in ["heavy","charged"] else 1.0),evasion)
	result["move"]=move_name;results.append(result)
	if results.size()>256:results.pop_front()
	var value:String=str(result.damage) if result.damage>0 else ("Evade" if result.type=="evade" else "Miss")
	_add_damage_popup(point,value,result.type=="critical",result.damage==0)
	if result.type=="critical":
		critical_position=point;critical_flash=.18
	if result.damage>0:impact_feedback(point,result.type=="critical")
	return result.damage/10.0
func campaign_strike():
	exploration.attack(_weapon_reach(),12)
	if move_name in ["heavy","charged"]:
		_stone_burst(player+swing_direction*26,10,.3)
	if slime_health<=0 or boss_struck or not enemy_in_reach(slime,12):return
	if not exploration._visible(player,slime):return
	boss_struck=true
	var modifier:float=1.0 if guard_state in [Guard.RECOVERY,Guard.STAGGER] else .65
	var dealt:float=combat_hit(slime,.04,modifier)
	if dealt<=0:return
	if move_name=="charged" and guard_state==Guard.WINDUP:
		guard_state=Guard.STAGGER;guard_time=.85
	slime_health=maxf(0,slime_health-dealt);slime_hurt_time=.08
	_stone_burst(slime,9,.35);_play("stone_die" if slime_health==0 else "stone_hit")
	hit_stop=maxf(hit_stop,.09 if move_name in ["heavy","charged"] else .035)
	if slime_health==0:
		boss_death=.8;boss_ring=.5;shake_time=.35
		_stone_burst(slime,26,.8)
		if not story_enabled:
			_notice("Rockbreak gained. Return west of the quarry.");message_time=5
func _resolve_attack():
	if campaign_mode:campaign_strike()
	else:strike()

func _attack():
	start_move(light_branch())

func suspend_combo():
	if sounds.has("combo_charge"):sounds["combo_charge"].stop()
	queued="";holding_heavy=false;charge_age=0

func _add_damage_popup(point:Vector2,value:String,critical:bool,zero:bool):
	popup_serial+=1
	var side:float=-1.0 if popup_serial%2==0 else 1.0
	var lane:float=side*(4+popup_serial%3*3)
	damage_popups.append({"pos":point+Vector2(lane,-19),"age":0.0,"text":value,"critical":critical,"zero":zero,"drift":side*(22+popup_serial%3*5),"life":.86 if critical else (.62 if zero else .74)})

func _draw_hero():
	_draw_move_signature()
	super._draw_hero()

func _draw_move_signature():
	if holding_heavy:
		var t:float=clampf(charge_age/charge_limit(),0,1)
		var p:Vector2=_floating_weapon_origin()
		draw_line(p+Vector2(6,2),p+Vector2(6,-11),Color(.18,.17,.14,.85),2)
		draw_line(p+Vector2(6,2),p+Vector2(6,2-13*t),Color(1,.78,.4,.95),1)
		var blade_tip:Vector2=p+Vector2(.35,-1).normalized()*15
		draw_line(p,blade_tip,Color(1,.7,.25,t*.6),2+t*3)
		for mote in range(7):
			var phase:float=fposmod(charge_age*1.8+mote/7.0,1)
			var ray:Vector2=Vector2.from_angle(mote*TAU/7+charge_age)
			var at:Vector2=blade_tip+ray*(19*(1-phase)+2)
			draw_line(at,at+ray*3,Color(1,.8,.42,t*phase),1)
		if t>=1:
			var flash:float=.6+.4*sin(charge_age*15)
			draw_line(blade_tip-Vector2(6,0),blade_tip+Vector2(6,0),Color(1,.96,.76,flash),1)
			draw_line(blade_tip-Vector2(0,8),blade_tip+Vector2(0,8),Color(1,.96,.76,flash),1)
		for i in range(3):
			var ray:=Vector2.from_angle(-PI/2+i*TAU/3+charge_age*3)
			draw_line(p+ray*(13-7*t),p+ray*(16-8*t),Color(1,.72,.3,t*.8),.7)
	if attack_time<=0 or not MOVES.has(move_name):return
	var age:float=float(MOVES[move_name][0])-attack_time-float(MOVES[move_name][1])
	var effect_duration:float=.48 if move_name=="charged" else .25
	if age<0 or age>effect_duration:return
	preload("res://scripts/sword_energy.gd").draw(self,age,effect_duration)

func spend_stamina(cost:float):
	if cost<=0:return
	stamina=maxf(0,stamina-cost);stamina_delay=.8
func _reject_stamina():
	stamina_warning=.4;_play("armor")
func _recover_stamina(delta:float):
	stamina_warning=maxf(0,stamina_warning-delta)
	var remaining:float=maxf(0,delta-stamina_delay)
	stamina_delay=maxf(0,stamina_delay-delta)
	if dodge_time<=0 and (attack_time<=0 or move_name.begins_with("light")):
		stamina=minf(mana_max(),stamina+(growth.mana_regen() if campaign_mode else STAMINA_REGEN)*remaining)
func _start_dodge():
	if dodge_cooldown>0 or dodge_time>0 or attack_time>.1:return
	if stamina<DODGE_COST:_reject_stamina();return
	super._start_dodge()
	if dodge_time>0:
		spend_stamina(DODGE_COST)
		if campaign_mode:controls.performed("dodge")
func heavy_cost()->float:
	return move_cost("charged" if holding_heavy and charge_age>=charge_limit() else heavy_branch())

func _interact():
	if campaign_mode and story.beats.memory_active():story.interact();return
	if campaign_mode and _at_camp() and story.talk_position()==Vector2.INF:
		controls.interacted=true;rest_at_camp();_notice("Rested. Checkpoint recorded.");return
	super._interact()
	if story.modal():controls.interacted=true
func rest_at_camp():
	if not _at_camp():return
	var camps:Array=[VILLAGE,BRIDGE_CAMP]
	for camp in camps:
		if player.distance_to(_center(camp))<25:checkpoint=camp;break
	health=max_health;growth.armor=growth.max_armor();stamina=mana_max();stamina_delay=0;stamina_warning=0
	_play("confirm")

func _draw():
	super._draw()
	if defeat_age>=0:
		draw_defeat()
		return
	if campaign_mode:controls.draw(self)

func mana_max()->float:return growth.max_mana() if campaign_mode else 100.0
func move_cost(id:String)->float:
	var cost:float=MOVES[id][5]
	return cost*.85 if campaign_mode and growth.agility>=3 and id in ["thrust","spin","chase"] else cost
