extends "res://tests/record_roll.gd"
var first := true
func perform_roll(code: Key,label: String,blocked: bool = false) -> bool:
	var result := await super.perform_roll(code,label,blocked)
	if first:
		first=false
		game.relic_found=true
		tap(KEY_K)
		await frames(80)
	if label == "spear right":
		await hold(KEY_J,80)
		await frames(45)
	return result
