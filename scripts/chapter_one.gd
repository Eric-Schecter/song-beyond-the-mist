extends RefCounted

enum Stage { INTRO, CHILD, RETURN, DEFEND, KNIGHT, KEYS, PRIEST, GUARD, SPRING, HOME, COMPLETE }
const MOTHER := Vector2i(8,16)
const CHILD := Vector2i(24,13)
const KNIGHT := Vector2i(7,17)
const RANGER := Vector2i(22,5)
const PRIEST := Vector2i(33,14)
var game: Node2D
var beats=preload("res://scripts/chapter_beats.gd").new()
var stage := Stage.INTRO
var pages: Array = []
var page := 0
var after_dialogue := -1
var journal_open := false
var complete_card := false
var logbook: Array[String] = []
var child_position := Vector2.ZERO
var footsteps: Array[Vector2] = []
var raid_indices: Array[int] = []
var child_enemy := -1
var tutorial_shown := false
var training=preload("res://scripts/tutorial_waves.gd").new()
var dialogue_age := 0.0
var reveal_all := false
var discoveries:Dictionary={}
const CLUES={"wheel":Vector2i(10,18),"marks":Vector2i(24,6),"manifest":Vector2i(23,25)}

func enabled() -> bool:
	return game != null and game.story_enabled

func modal() -> bool:
	return enabled() and (not pages.is_empty() or journal_open or complete_card or beats.revealing())

func reset() -> void:
	stage = Stage.INTRO
	beats.reset(self)
	pages.clear()
	reveal_all = false
	page = 0
	after_dialogue = -1
	journal_open = false
	complete_card = false
	logbook.clear()
	footsteps.clear()
	raid_indices.clear()
	training.reset()
	tutorial_shown = false
	discoveries.clear()
	if not enabled(): return
	child_position = game._center(CHILD)
	game.exploration.greeted = true
	game.exploration._add("bat",Vector2i(23,13),Rect2(336,192,80,80))
	child_enemy = game.exploration.enemies.size()-1
	logbook.append("The river has dried up. Noah is missing east of the village.")

func speak(lines: Array, next_stage: int = -1) -> void:
	preload("res://scripts/story_space.gd").stage_dialogue(self,lines)
	# Keep every dialogue page inside the portrait layout, including longer story beats.
	pages=[]
	for entry in lines:
		var chunks:Array[String]=wrapped(str(entry[1]),227)
		for start in range(0,chunks.size(),3):
			var text:=""
			for index in range(start,mini(start+3,chunks.size())):text+=chunks[index]
			pages.append([entry[0],text])
	page = 0
	reveal_all = false
	after_dialogue = next_stage
	dialogue_age = 0
	game._clear_weapon_action()
	game.sword_presentation.reset()
	game.attack_time = 0
	game.swing_pending = false
	game.dodge_time = 0
	game.moved = false
	game.message_time = 0
	game.queue_redraw()

func input(event: InputEventKey) -> bool:
	if not enabled(): return false
	if not modal(): return false
	if not event.pressed or event.echo: return true
	if event.physical_keycode not in [KEY_E,KEY_ENTER,KEY_SPACE,KEY_ESCAPE]: return true
	if dialogue_age < 0.12 and not journal_open: return true
	if journal_open:
		journal_open = false
	elif complete_card:
		if dialogue_age<preload("res://scripts/chapter_card.gd").MIN_CLOSING_TIME:return true
		complete_card = false
	elif not pages.is_empty():
		if visible_characters()<str(pages[page][1]).length():
			reveal_all=true
			dialogue_age=0
			game.queue_redraw()
			return true
		reveal_all=false
		page += 1
		dialogue_age = 0
		game._play("confirm")
		if page >= pages.size():
			pages.clear()
			if after_dialogue >= 0: advance(after_dialogue)
			after_dialogue = -1
	return true

func visible_characters()->int:
	if pages.is_empty():return 0
	var text:String=str(pages[page][1])
	if reveal_all or chapter_card_active():return text.length()
	var budget:=dialogue_age
	var count:=0
	for character in text:
		budget-=1.0/(28.0 if preload("res://scripts/game_locale.gd").language=="zh" else 48.0)
		if budget<0:break
		count+=1
		if character in ",;:，；：":budget-=.09
		elif character in ".!?。！？":budget-=.18
	return count

func advance(next_stage: int) -> void:
	stage = next_stage
	if next_stage in [Stage.RETURN,Stage.KEYS,Stage.PRIEST,Stage.HOME,Stage.COMPLETE]:
		game.growth.award(game,"story_%d"%next_stage,25)
	match stage:
		Stage.CHILD:
			game.intro_time = 0
		Stage.RETURN:
			footsteps = [game.player]
			logbook.append("Rescued Noah, who went to find water for a wounded knight. He saw black mist creeping upstream along the dry riverbed.")
		Stage.DEFEND:
			game.health = game.max_health
			training.start(self)
			game._notice("Village under attack!")
			logbook.append("Monsters have reached the village. Protect the villagers.")
		Stage.KEYS:
			game.health = game.max_health
			logbook.append("Roland says the Demon King took Princess Lia north. Seek Erin on Spring Isle to learn the way.")
		Stage.GUARD:
			game.health = game.max_health
			game.checkpoint = game.BRIDGE_CAMP
			logbook.append("Erin closed the gate to keep tainted water out of the village. Cleanse the spring's guardian to restore the flow safely.")
		Stage.HOME:
			beats.following=true
			beats.priest_trail.clear();beats.priest_trail.append(game.player)
			game.fountain_awake = true
			game.health = game.max_health
			logbook.append("The spring is clear. Erin will travel with you. Gather supplies and explore the old mine for a route north.")
		Stage.COMPLETE:
			complete_card = true
			dialogue_age = 0
			game.health = game.max_health
			game.checkpoint = game.VILLAGE
			logbook.append("Chapter One complete. Morningwind is safe. Further story content is not yet available; you may explore the existing areas.")

func objective() -> String:
	var beat_objective:String=beats.objective()
	if not beat_objective.is_empty():return beat_objective
	match stage:
		Stage.INTRO,Stage.CHILD: return "East Path: find Noah"
		Stage.RETURN: return "Bring Noah to his mother"
		Stage.DEFEND: return "Defend the village entrance"
		Stage.KNIGHT: return "Speak to the wounded knight"
		Stage.KEYS:
			if 0 not in game.seals and game.journey.restored.size()<2:return "Northwood sluices %d/2"%game.journey.restored.size()
			return "Find river seals %d/2" % game.seals.size()
		Stage.PRIEST: return "Cross the bridge; find Erin"
		Stage.GUARD: return "Defeat the tainted guardian"
		Stage.SPRING: return "Restore the spring's flow"
		Stage.HOME: return "Return to the village"
	return "Chapter complete / Free exploration"

func quest_symbol()->String:
	if stage==Stage.PRIEST and beats.island_confronted:return "!"
	return "?" if stage in [Stage.INTRO,Stage.KNIGHT,Stage.PRIEST] else "!"

func quest_marker_position()->Vector2:
	if stage==Stage.INTRO:return game._center(MOTHER)
	if stage==Stage.CHILD:return child_position
	if stage==Stage.PRIEST:
		if beats.island_confronted:
			if not beats.island_seen.has("water"):return game._center(beats.WATER)
			if not beats.island_seen.has("refugees"):return game._center(beats.REFUGEES)
		return beats.priest_pos if beats.following else game._center(priest_tile())
	return game._center(target())

func target() -> Vector2i:
	if beats.memory_active():return beats.GEAR if beats.memory_step==1 else (CLUES.wheel if beats.memory_step==2 else beats.LIA)
	match stage:
		Stage.INTRO,Stage.CHILD: return CHILD
		Stage.RETURN,Stage.HOME: return MOTHER
		Stage.DEFEND: return Vector2i(17,15)
		Stage.KNIGHT: return KNIGHT
		Stage.KEYS:
			for i in range(2):
				if i not in game.journey.restored:return game.journey.SWITCHES[i]
			return game.SEALS[0] if 0 not in game.seals else game.SEALS[1]
		Stage.PRIEST: return PRIEST
		Stage.GUARD: return Vector2i(37,16)
		Stage.SPRING: return game.FOUNTAIN
	return game.CRACK

func near(tile: Vector2i, distance: float = 19) -> bool:
	return game.player.distance_to(game._center(tile)) < distance

func priest_tile() -> Vector2i:
	if beats.purified or beats.purifying or beats.following:return Vector2i((beats.priest_pos/16).floor())
	return Vector2i(9,17) if stage >= Stage.HOME else PRIEST

func talk_position() -> Vector2:
	if not enabled() or modal(): return Vector2.INF
	if beats.memory_active():return Vector2.INF
	if stage == Stage.CHILD and near(CHILD): return child_position
	if near(MOTHER): return game._center(MOTHER)
	if stage >= Stage.KNIGHT and near(KNIGHT): return game._center(KNIGHT)
	if stage >= Stage.KEYS and near(RANGER): return game._center(RANGER)
	if stage >= Stage.PRIEST and near(priest_tile()) and not (stage==Stage.SPRING and near(game.FOUNTAIN,25)): return game._center(priest_tile())
	return Vector2.INF

func draw_talk_prompt() -> void:
	var position := talk_position()
	if position == Vector2.INF or game.has_meta("opening_preview"): return
	var p := (position+Vector2(-8,-36-roundf(sin(game.clock*4)*1))).round()
	var skin=preload("res://scripts/ui_skin.gd")
	skin.panel(game,Rect2(p,Vector2(16,14)))
	game.draw_colored_polygon(PackedVector2Array([p+Vector2(5,13),p+Vector2(9,17),p+Vector2(11,13)]),Color("#ddc899"))
	game._label("E",p+Vector2(5,11),10,skin.TEXT)

func hint() -> String:
	if not enabled(): return ""
	if near(CHILD) and stage == Stage.CHILD: return "E Talk to Noah"
	if near(MOTHER): return "E Talk to Noah's mother"
	if stage >= Stage.KNIGHT and near(KNIGHT): return "E Talk to Roland"
	if stage >= Stage.KEYS and near(RANGER): return "E Talk to the ranger"
	if stage >= Stage.PRIEST and near(priest_tile()) and not (stage==Stage.SPRING and near(game.FOUNTAIN,25)): return "E Talk to Erin"
	if stage == Stage.SPRING and near(game.FOUNTAIN,25): return "E Restore the spring"
	for i in range(2):
		if i not in game.seals and near(game.SEALS[i],16): return "E Take the river seal"
	return ""

func interact() -> bool:
	if not enabled(): return false
	if beats.interact():return true
	if near(game.CRACK,27):
		game._notice("The road ahead is not available yet.")
		return true
	if investigate_clue():return true
	if stage == Stage.CHILD and near(CHILD):
		if not game.exploration.finished_dying(child_enemy):
			game._notice("The bat is keeping Noah trapped.")
		elif not game.controls.basics_complete():
			game.controls.lesson_cue(game)
		else:
			speak([["Noah","I did not mean to wander off... The knight had a fever all night. Mum gave him the last of our water."],["Hero","So you went upstream to find more? Can you walk?"],["Noah","Yes. But my flask is still empty... Mum and the knight are waiting."],["Noah","I saw black mist crawling upstream along the riverbed. But there was no water at all."],["Hero","Let us get you home first. I will find water. No more going into the woods alone."]],Stage.RETURN)
		return true
	if near(MOTHER):
		if stage == Stage.RETURN:
			if child_position.distance_to(game._center(MOTHER)) > 40:
				game._notice("Wait for Noah. Bring him back with you.")
				return true
			speak([["Noah's Mother","Noah! We can always find more water... What would I do if you never came home?"],["Noah","I am sorry, Mum. I just did not want that man to die."],["Wounded Knight","I brought this danger here. Those skeletons have been following our convoy's banner."],["Hero","We can talk about that later. Get everyone indoors. I will hold the entrance."],["Wounded Knight","I can still hold a sword. Cover the canal. I will protect the children!"]],Stage.DEFEND)
		elif stage == Stage.HOME:
			speak([
				["Noah's Mother", "The water is back! But what happened up there?"],
				["Noah", "Mum, I filled the flask! This time I will stay and help you."],
				["Erin", "I closed the gate to stop the tainted water. I am sorry I could not get word to you sooner."],
				["Noah's Mother", "Sit down and tell us. The wounded have their water, and there is food for both of you."],
				["Hero", "Thank you. Erin, I could not have done this alone. Once our bags are ready, let us set out."],
				["Erin", "All right. I will lead the way. Together, we will find a way to help the princess."],
				["Narrator", "Water flows through Morningwind again. The hero and Erin will travel together, seeking a northern passage through the old mine."]
			],Stage.COMPLETE)
		else:
			speak([["Noah's Mother","Noah went east of the village. Please find him." if stage <= Stage.CHILD else "Thank you. We will be here, waiting for your safe return."]])
		return true
	if stage >= Stage.KNIGHT and near(KNIGHT):
		if stage == Stage.KNIGHT:
			speak([
				["Roland","Thank you for holding the entrance. I am Roland, a royal guard."],
				["Hero","Why were those monsters following you? What happened at the capital?"],
				["Roland","The Demon King attacked our convoy and took Princess Lia. I got the villagers out, but I could not save her."],
				["Hero","The princess who had our canals built? Where is she now?"],
				["Roland","A castle in the north. I tried to follow, but could not reach the pass. With these wounds, I can barely travel."],
				["Hero","Then who can go after her?"],
				["Roland","I sent for help, but the capital has not answered. I fear she cannot wait much longer."],
				["Hero","...I do not know if I can reach that castle. But we cannot just leave her waiting. Which way is north?"],
				["Roland","You want to go? Those skeletons were the weakest of them."],
				["Hero","I know. First I need a road, then a plan. Stay and help the village. I will find someone who knows the north."],
				["Roland","Erin on Spring Isle knows the roads. Take my badge; she will help you. Promise me you will not rush in alone."],
				["Hero","I will find her first. Can I still cross the bridge to the island?"],
				["Roland","It is locked. There is a river seal in Northwood and another in the quarry. Together they open it. Take care."]
			],Stage.KEYS)
		else:
			speak([["Roland","My wounds are still healing, but a sword is not the only way to help. I will build barricades and keep a light for late travelers." if stage<Stage.HOME else "The water has reached us. I will mend the road while you are away."]])
		return true
	if stage >= Stage.KEYS and near(RANGER):
		speak([["Ranger","Someone forced both sluices into reverse. Water does not turn back on its own."],["Ranger","I tracked them to the quarry and found black iron shards. A ranger's blade could never leave marks like those."],["Ranger","Follow the woodland paths and reset both sluices to release the seal. Speak to Erin before opening the spring gate."]])
		return true
	for i in range(2):
		if i in game.seals or not near(game.SEALS[i],16): continue
		if stage < Stage.KEYS:
			game._notice("Bring Noah home and speak to the knight first.")
			return true
		if i==0 and game.journey.restored.size()<2:
			game._notice("Water pressure holds the seal. Reset both Northwood sluices.")
			return true
		for index in ([0,1] if i == 0 else [2,3]):
			if not game.exploration.finished_dying(index):
				game._notice("Clear the nearby monsters before taking the seal.")
				return true
		game.seals.append(i)
		game.gate_open = game.seals.size() == 2
		game._play("ember")
		logbook.append("Northwood seal: black iron tools reversed the sluices, turning the river into a path for the mist." if i == 0 else "Quarry seal: Lia sent cleansing stones to the village rather than taking them with her convoy.")
		var discovery:Array
		if i==0:
			discovery=[["Hero","Fresh black marks beneath the seal. Just like the ones on the stones by the woods." if discoveries.has("marks") else "Fresh black marks beneath the seal. Someone forced this sluice into reverse."],["Hero","The mist is using the old riverbed to get in. This was never just about stealing our water."]]
		else:
			discovery=[["Hero","The royal stamp matches the seal. These cleansing stones really were sent by Princess Lia." if discoveries.has("manifest") else "A royal manifest beneath the stone: cleansing stones for Morningwind, by order of Princess Lia."],["Hero","She knew the convoy was in danger, and still left these supplies for us."]]
		if game.gate_open:
			discovery.append(["Hero","Both seals are responding. The bridge is open. I need to reach Erin before the mist does."])
			speak(discovery,Stage.PRIEST)
		else:
			discovery.append(["Hero","One seal found. One more to open the bridge."])
			speak(discovery)
		return true
	if stage >= Stage.PRIEST and near(priest_tile()) and not (stage==Stage.SPRING and near(game.FOUNTAIN,25)):
		if stage == Stage.PRIEST:
			speak([
				["Hero", "Roland asked me to give you his badge. He is recovering in the village. He says you know the northern roads."],
				["Erin", "He is alive... Thank goodness. Are you hoping to rescue the princess?"],
				["Hero", "Yes. I came to ask the way. But I saw the black water beyond the gate. We need to help the village first."],
				["Erin", "We can talk about the road afterward. The tainted guardian is poisoning the spring. I closed the gate, but cannot get near it."],
				["Erin", "Break the black crystals on its shell. Leave the core intact, and I can cleanse the water."],
				["Hero", "Only the outer crystals... I will try. Keep an eye on the core for me."],
				["Erin", "I will be here to help."]
			],Stage.GUARD)
		else:
			game.health = game.max_health
			speak([["Erin","Let me tend your wounds. The seal is weakening. Keep going." if stage < Stage.HOME else "The water is clear. Let us tell the village, then prepare for the old mine."]])
		return true
	if near(game.FOUNTAIN,25):
		if stage == Stage.SPRING:
			game.fountain_awake = true
			game._play("ember")
			speak([
				["Erin", "The sediment is gone. We can open the gate."],
				["Hero", "It is flowing again. No more searching everywhere for water."],
				["Erin", "The northern pass is blocked, but the old mine offers another way. We will need tools to clear the entrance."],
				["Hero", "Then let us start with the mine. Erin, will you show me the way?"],
				["Erin", "I will. First, tell the village we are safe. Then pack medicine and a lantern."]
			],Stage.HOME)
		elif stage < Stage.SPRING:
			game._notice("Meet Erin and defeat the tainted guardian first.")
		else:
			speak([["Spring","Clear water flows toward Morningwind once more."]])
		return true
	return false

func update(delta: float) -> void:
	if not enabled(): return
	dialogue_age += delta
	if beats.update(delta):return
	if modal() or game.map_open: return
	if stage == Stage.INTRO and game.intro_time <= 2.5:
		speak([["Narrator","Three days after the waterwheel stopped, Morningwind's last well ran dry. Last night, villagers carried in a wounded royal knight."],["Noah's Mother","I only stepped away to change the knight's damp cloth. When I came back, Noah and our empty flask were gone."],["Hero","There is an old watercourse east of the village. He may have followed it looking for water. I will check."],["Noah's Mother","He must be looking for water. Please bring him home before he reaches that black mist."],["Hero","I will find him. Leave the lantern by the door, so he can see his way home."]],Stage.CHILD)
	elif stage == Stage.CHILD and not tutorial_shown and game.player.distance_to(child_position) < 65:
		tutorial_shown = true
		pass
	elif stage == Stage.RETURN:
		if footsteps.is_empty() or footsteps.back().distance_to(game.player) > 6: footsteps.append(game.player)
		if not footsteps.is_empty() and child_position.distance_to(game.player) > 15:
			child_position = preload("res://scripts/story_space.gd").move_follower(self,child_position,child_position.direction_to(footsteps[0])*minf(70*delta,child_position.distance_to(footsteps[0])))
			if child_position.distance_to(footsteps[0]) < 2: footsteps.pop_front()
	elif stage == Stage.DEFEND:
		if training.active and not training.update(self,delta):return
		var alive := false
		for index in raid_indices:
			if not game.exploration.finished_dying(index): alive = true
		if not alive:
			if not game.controls.combat_complete():
				game.controls.lesson_cue(game)
				return
			game.health = game.max_health
			speak([["Wounded Knight","The entrance is safe. Those creatures ignored our food. They kept trying to reach the river..."],["Hero","Noah saw mist moving along the riverbed, too. The attack and the missing water are connected."],["Wounded Knight","You should hear the whole story. Once the children are safe inside, meet me by the campfire."]],Stage.KNIGHT)
	elif stage == Stage.GUARD and game.slime_health <= 0 and game.boss_death <= 0 and game.hit_stop <= 0:
		speak([["Hero","It stopped... It is turning toward the spring."],["Guardian's Echo","Escort civilians... Seal away the mist... By order of Princess Lia."],["Erin","Its last order. Lia told it to protect the refugees. The Demon King twisted that duty into a prison."],["Hero","We have set it free. Now let us bring the water home."]],Stage.SPRING)

func draw_npc(p: Vector2, coat: Color, small: bool = false) -> void:
	if coat.is_equal_approx(Color("#e6dfc9")) and game.island_art.npc(p): return
	if game.village_art.npc(p,coat,small): return
	var g := game
	g.draw_circle(p+Vector2(0,3),4,Color(0,0,0,0.18))
	g.draw_rect(Rect2(p+Vector2(-3,-5),Vector2(6,8 if not small else 6)),coat)
	g.draw_rect(Rect2(p+Vector2(-2,-9),Vector2(5,5)),Color("#e6bd8a"))
	g.draw_rect(Rect2(p+Vector2(-3,-11),Vector2(6,3)),Color("#6f4939"))
	g.draw_line(p+Vector2(-2,2),p+Vector2(-2,5),g.INK,2)
	g.draw_line(p+Vector2(2,2),p+Vector2(2,5),g.INK,2)

func draw_world() -> void:
	if not enabled(): return
	var g := game
	# A visible dry channel becomes flowing water after the spring is repaired.
	g.draw_rect(Rect2(37,292,145,9),Color("#786a54").lerp(g.WATER,g.water_at(Vector2(110,296))))
	for x in range(40,180,18):
		g.draw_line(Vector2(x,296),Vector2(x+8,296+(int(g.clock*3)%2 if g.fountain_awake else 1)),Color("#9e8a65").lerp(g.BLUE,g.water_at(Vector2(x,296))))
	draw_clues()
	beats.draw()
	if beats.memory_active():return
	draw_npc(g._center(MOTHER),Color("#a36b87"))
	if stage <= Stage.RETURN:
		draw_npc(child_position,Color("#c6a15e"),true)
	else:
		draw_npc(g._center(Vector2i(8,17)),Color("#c6a15e"),true)
	if stage >= Stage.DEFEND: draw_npc(g._center(KNIGHT),Color("#849aaf"))
	draw_npc(g._center(RANGER),Color("#849756"))
	draw_npc(beats.priest_pos if beats.following or beats.purifying or beats.purified else g._center(priest_tile()),Color("#e6dfc9"))
	if stage<Stage.COMPLETE:
		var symbol:=quest_symbol()
		var height:float=19 if stage==Stage.CHILD else 25
		var interaction:Dictionary=preload("res://scripts/world_interaction.gd").target(g)
		var show_symbol:bool=interaction.is_empty() or interaction.pos.distance_to(quest_marker_position())>=4
		var marker:Vector2=quest_marker_position()+Vector2(-g.font.get_string_size(symbol,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x/2,-height-sin(g.clock*3)*.6)
		if show_symbol:
			g.draw_string_outline(g.font,marker,symbol,HORIZONTAL_ALIGNMENT_LEFT,-1,12,2,Color("#272a30"))
			g._label(symbol,marker,12,g.GOLD)
	if stage < Stage.HOME and g.slime_health > 0:
		for i in range(5):
			var p: Vector2 = g.slime+Vector2(sin(g.clock+i)*14,-13-i*3)
			g.draw_circle(p,3,Color(0.19,0.10,0.27,0.32))

func wrapped(value: String, width: float) -> Array[String]:
	value=preload("res://scripts/game_locale.gd").text(value)
	var result: Array[String] = [""]
	if preload("res://scripts/game_locale.gd").language=="zh":
		for character in value:
			if game.font.get_string_size(result.back()+character,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x>width:result.append("")
			result[-1]+=character
		return result
	var pattern:=RegEx.new()
	pattern.compile("\\S+\\s*")
	for word in pattern.search_all(value.strip_edges()):
		var token:String=word.get_string()
		if not result.back().is_empty() and game.font.get_string_size(result.back()+token,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x>width:
			result.append("")
		# Preserve spaces across page boundaries; split only an overlong single token.
		for character in token:
			if game.font.get_string_size(result.back()+character,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x>width:result.append("")
			result[-1]+=character
	return result

func draw_portrait(speaker: String) -> bool:
	var atlas = game.village_art.cast
	var index: int = {"Hero":0,"Lia":4,"Refugee":4,"Noah's Mother":4,"Noah":8,"Wounded Knight":12,"Roland":12}.get(speaker,-1)
	if speaker == "Erin":
		atlas = game.island_art.priest
		index = 0
	if index < 0 or atlas.texture == null: return false
	var source: Rect2 = atlas.cells[index]
	source.size.y *= 0.56
	var size := source.size*(42.0/maxf(source.size.x,source.size.y))
	preload("res://scripts/ui_skin.gd").panel(game,Rect2(17,151,51,52),true)
	game.draw_texture_rect_region(atlas.texture,Rect2(Vector2(42.5,177)-size/2,size),source)
	return true

func chapter_card_active()->bool:
	return enabled() and (complete_card or (not pages.is_empty() and str(pages[page][0]).begins_with("Chapter One")))

func draw_ui() -> void:
	if game.has_meta("opening_preview"): return
	if not enabled(): return
	var g := game
	var skin = preload("res://scripts/ui_skin.gd")
	if chapter_card_active():
		preload("res://scripts/chapter_card.gd").draw(g,complete_card,dialogue_age)
		return
	if not pages.is_empty():
		skin.panel(g,Rect2(8,137,304,80),true)
		skin.panel(g,Rect2(15,126,minf(118,g.font.get_string_size(preload("res://scripts/game_locale.gd").text(str(pages[page][0])),HORIZONTAL_ALIGNMENT_LEFT,-1,11).x+18),23))
		g._label(str(pages[page][0]),Vector2(23,142),11,skin.TEXT)
		var portrait := draw_portrait(str(pages[page][0]))
		var lines := wrapped(str(pages[page][1]),227 if portrait else 278)
		var remaining:=visible_characters()
		for i in range(lines.size()):
			g._label(lines[i].left(maxi(0,remaining)),Vector2(76 if portrait else 21,161+i*13),10,skin.INK)
			remaining-=lines[i].length()
		var cue := Vector2(297,204+roundf(sin(g.clock*TAU/0.9)*1.5))
		if visible_characters()>=str(pages[page][1]).length():
			g.draw_colored_polygon(PackedVector2Array([cue+Vector2(-3,-2),cue+Vector2(3,-2),cue+Vector2(0,2)]),skin.INK)
	elif journal_open:
		skin.panel(g,Rect2(8,24,304,191),true)
		skin.rule(g,Vector2(18,65),Vector2(302,65))
		g._label("Journal / Chapter One",Vector2(18,44),14,skin.INK)
		g._label(objective(),Vector2(18,59),10,skin.SOFT)
		var y := 78
		var start := maxi(0,logbook.size()-5)
		for i in range(start,logbook.size()):
			for line in wrapped("· "+logbook[i],280):
				if y < 195: g._label(line,Vector2(18,y),9,skin.INK)
				y += 12
		g._label("M / Esc Back",Vector2(222,207),8,skin.SOFT)
func clue_available(id:String)->bool:
	return enabled() and (id=="wheel" or stage>=Stage.KEYS)
func clue_target()->Vector2:
	if modal() or beats.memory_active():return Vector2.INF
	for id in CLUES:
		if clue_available(id) and near(CLUES[id],15):return game._center(CLUES[id])
	return Vector2.INF
func investigate_clue()->bool:
	for id in CLUES:
		if not clue_available(id) or not near(CLUES[id],15):continue
		var lines:Array=[]
		match id:
			"wheel":
				lines=[["Hero","The wheel has been still for days. Small footprints follow the dry riverbed east."],["Hero","Round marks from a flask beside them. Noah must have gone this way."]] if stage<Stage.HOME else [["Hero","The wheel is turning again. At last, the village has clean water."]]
			"marks":lines=[["Hero","Every chisel mark runs the same way. Black iron shards are caught in the cracks. Someone forced the sluice shut."],["Hero","The iron gives off black smoke when it gets wet. Erin needs to hear about this."]]
			"manifest":lines=[["Torn Manifest","By order of Princess Lia: leave the cleansing stones for the downstream villages. Escort: Roland."],["Hero","These supplies were meant for our village. If we restore the sluices, we can help everyone."]]
		if not discoveries.has(id):
			discoveries[id]=true
			logbook.append({"wheel":"Old waterwheel: footprints and flask marks lead east along the dry riverbed. Noah likely followed the old watercourse.","marks":"Woodland marks: black iron tools reversed the sluice. The shards release black mist when wet.","manifest":"Quarry manifest: Lia left cleansing stones for the villages. Roland was their escort."}[id])
		speak(lines);return true
	return false
func draw_clues():
	for id in CLUES:
		if not clue_available(id):continue
		var p:Vector2=game._center(CLUES[id])
		if id=="wheel":
			game.draw_line(p+Vector2(-9,4),p+Vector2(9,4),Color("#635340"),2)
			game.draw_arc(p+Vector2(0,-2),7,0,TAU,16,Color("#9c7d51"),2)
			for i in range(6):
				var axis:=Vector2.from_angle(i*TAU/6+(game.clock if beats.wheel_turning() else 0))
				game.draw_line(p+Vector2(0,-2),p+Vector2(0,-2)+axis*6,Color("#c2a073"),1)
			if game.fountain_awake:game.draw_polyline(PackedVector2Array([p+Vector2(6,-8),p+Vector2(11,-6),p+Vector2(13,-8)]),game.BLUE,2)
		elif id=="marks":
			game.draw_colored_polygon(PackedVector2Array([p+Vector2(-7,3),p+Vector2(-5,-5),p+Vector2(4,-7),p+Vector2(8,2)]),Color("#8a8b78"))
			for i in range(3):game.draw_line(p+Vector2(-3+i*3,-3),p+Vector2(-5+i*3,1),Color("#49454b"),1)
		else:
			game.draw_rect(Rect2(p+Vector2(-6,-5),Vector2(12,9)),Color("#65513c"))
			game.draw_rect(Rect2(p+Vector2(-4,-7),Vector2(8,10)),Color("#d3c5a1"))
			for i in range(3):game.draw_line(p+Vector2(-2,-5+i*2),p+Vector2(2,-5+i*2),Color("#82735b"),.6)
		if not discoveries.has(id):
			var glow:=p+Vector2(0,-14-sin(game.clock*3)*1.5)
			game.draw_circle(glow,1,Color("#d9c38e"))
