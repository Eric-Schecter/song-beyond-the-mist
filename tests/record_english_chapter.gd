extends "res://tests/record_campaign_combos.gd"
func walk_to(tile:Vector2i)->bool:
	if not await super.walk_to(tile):return false
	if tile==game.VILLAGE:
		tap(KEY_E);await frames(150)
		if not verify(game.controls.page.is_empty(),"Direct camp rest"):return false
		key(KEY_TAB,true);await frames(180);key(KEY_TAB,false)
	return true
