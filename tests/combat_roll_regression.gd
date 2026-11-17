extends SceneTree
func _initialize():
	var stats=load("res://scripts/combat_roll.gd").new()
	assert(stats.evaluate(10,.08,.96,.9,.9).type=="miss")
	assert(stats.evaluate(10,.08,.1,.01,.9).type=="evade")
	assert(stats.evaluate(10,.08,.1,.9,.9).damage==10)
	assert(stats.evaluate(32,.08,.1,.9,.1).damage==56)
	assert(stats.evaluate(10,stats.evasion,.1,.05,.9).type=="evade")
	print("PASS accuracy, evasion, normal damage, critical multiplier and defender evasion")
	quit()
