extends RefCounted
var accuracy:=.95
var evasion:=.10
var critical:=.20
var critical_multiplier:=1.75
var rng:=RandomNumberGenerator.new()
func _init():rng.randomize()
func resolve(base_damage:float,target_evasion:float)->Dictionary:
	return evaluate(base_damage,target_evasion,rng.randf(),rng.randf(),rng.randf())
func evaluate(base_damage:float,target_evasion:float,aim_roll:float,dodge_roll:float,crit_roll:float)->Dictionary:
	if aim_roll>=clampf(accuracy,0,1):return {"type":"miss","damage":0}
	if dodge_roll<clampf(target_evasion,0,1):return {"type":"evade","damage":0}
	var crit:bool=crit_roll<clampf(critical,0,1)
	return {"type":"critical" if crit else "normal","damage":maxi(1,roundi(base_damage*(critical_multiplier if crit else 1.0)))}
