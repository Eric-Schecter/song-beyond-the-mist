extends "res://tests/record_chapter_one.gd"
func run():
	game=load("res://main.tscn").instantiate();root.add_child(game)
	game.story.pages.clear();game.story.stage=game.story.Stage.KNIGHT;game.intro_time=0
	game.exploration.enemies.clear()
	for direction in [Vector2.RIGHT,Vector2.UP,Vector2(1,1).normalized()]:
		game.stamina=100;game.player=Vector2(280,248);game.start_move("chase");game.swing_direction=direction
		game.player+=direction*20+direction.orthogonal()*5
		if not verify(game.enemy_in_reach(game.player+direction*15+direction.orthogonal()*10,6),"target body intersects thrust"):return
		if not verify(game.enemy_in_reach(game.attack_origin+direction*5,6),"dash path retained after slide"):return
		if not verify(not game.enemy_in_reach(game.player+direction*15+direction.orthogonal()*24,6),"outside sideways remains miss"):return
		if not verify(not game.enemy_in_reach(game.attack_origin-direction*20,6),"behind attack remains miss"):return
		game.stamina=100
	game.queue_free();await process_frame;quit()
