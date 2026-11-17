extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);g.set_physics_process(false)
	for tile in [Vector2i(35,12),Vector2i(32,12),Vector2i(38,11),Vector2i(42,11),Vector2i(8,19),Vector2i(11,18)]:print(tile," walkable ",g._walkable(g._center(tile)))
	quit()
