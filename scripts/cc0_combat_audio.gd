extends RefCounted
const BASE="res://assets/audio/cc0_combat/"
const MATERIALS={
"hurt":["impact_meat02","impact_meat01"],
"bone_hit":["impact_wood"],"break":["impact_wood"],
"plant_hit":["impact_meat01","impact_meat02"],"plant_die":["impact_meat02"],
"bat_hit":["impact_meat02"],"bat_die":["impact_meat01"],
"stone_hit":["impact_stone"],"stone_die":["impact_stone"],
"armor":["sword_clash.2","sword_clash.4","sword_clash.5"]}
const GESTURES={"light1":"sword.6","light2":"sword.4","light3":"sword.3","thrust":"sword.2","spin":"sword.8","heavy":"sword.7","charged":"sword.10","chase":"sword.9","tap":"impact_wood","impact":"impact_stone","critical":"sword_clash.5"}
static func material(id:String,variant:int)->AudioStreamWAV:
	var choices:Array=MATERIALS[id]
	return load(BASE+choices[variant%choices.size()]+".wav")
static func gesture(id:String)->AudioStreamWAV:
	return load(BASE+GESTURES[id]+".wav") if GESTURES.has(id) else preload("res://scripts/combo_audio.gd").build(id)
static func pitch(id:String)->float:
	return {"combo_impact":.78,"combo_critical":1.3,"combo_heavy":.88,"combo_charged":.82,"break":.83,"stone_die":.72,"bat_hit":1.15,"hurt":.88}.get(id,1.0)
